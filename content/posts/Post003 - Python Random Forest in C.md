---
title: Python Random Forest in C
date: 2020-03-15
linktitle: Python Random Forest in C
categories: ["Code", "Python"]
tags: ["Python", "Machine Learning", "C"]
draft: false
description: An attempt at making C code that can use the model in a random forest regression from Python to make predictions.
mathjax: true
slug: python-random-forest-c
---


I had occasion a while back to try to do a random forest prediction in C.  This is a highly situational need -- I only did it because I needed to get a random forest that could work with other stuff written in C, no Python allowed -- but it was interesting to try to pull apart scikit-learn's `RandomForestRegressor` and restructure it in another way.

<!--more-->

There didn't seem to be any way to do this already, unfortunately.  I found the [sklearn-porter](https://github.com/nok/sklearn-porter) package, which translates a few different models into various languages, but it doesn't handle the `RandomForestRegressor` at all.  And for the `RandomForestClassifier`, it turns the entire forest into a human-readable function, which ends up manifesting as an enormous mass of nested if statements, which I find a bit awkward.  (Though my own solution isn't the neatest.)

I structured this to have three stages:
1. Train the random forest in Python -- no point in reinventing the wheel and coding the training in C is *way* beyond my abilities there.
2. Translate the structure of the random forest into a binary file so you could avoid the issue of having to recompile the C code whenever you need to retrain the model.
3. Have some compiled C code use the binary file to make the prediction.

### The Python Part

For this post, I used the Boston housing dataset included with scikit-learn.  I trained a pretty simple `RandomForestRegressor`:

{{< highlight python3 >}}
from sklearn.ensemble import RandomForestRegressor
from sklearn.datasets import load_boston
import numpy as np
import pandas as pd

b = load_boston()
X = b["data"][:500,:]
y = b["target"][:500]
rf = RandomForestRegressor(n_estimators=10, max_depth=5)
rf.fit(X, y)
{{< / highlight >}}

And then I pulled it apart:

{{< highlight python3 >}}
for i in range(len(rf.estimators_)):
    tree = rf.estimators_[i].tree_
    df = pd.DataFrame({"Column":tree.feature, "Threshold":tree.threshold,
                        "LeftChild":tree.children_left, "RightChild":tree.children_right,
                        "Value":tree.value.reshape(-1)})
    df = df[["Column","Threshold", "LeftChild", "RightChild", "Value"]]
    df_string = f"{len(df)}\n{df.to_csv(header=False, index=False)}"
    with open(f"tree{i}.csv", "w") as f:
        f.write(df_string)
{{< / highlight >}}

As you could guess if you didn't already know, the `RandomForestRegressor` object contains a list of the individual estimators trained by the model (the `estimators_` property), and each estimator has it's own tree element (`tree_`).  In the tree, we get the information needed for prediction later on and arrange it in a dataframe:
* `feature` is the index of the variable used at that node.  If it's a leaf node, the value will be -2.
* `threshold` is the threshold value for determining which child to go to.
* `children_left` and `children_right` are the indices of the nodes.
* `value` is the value returned if the node is a leaf.  I'm not sure what it does otherwise -- it might be an average of the training examples that reach that node -- but it's not used unless it's a leaf node.

Instead of just writing the dataframe to a file, though, we instead append the number of rows in the dataframe to the start of the file, and then write the dataframe after it. (That's a neat thing that I learned in making this -- you can get `pd.DataFrame.to_csv()` to output the dataframe as a comma-delimited string if you call it without a file argument.)  This is included for simplicity, as we'll get to in a moment.  The process repeated for each tree, so there's a bunch of intermediate CSV files, but we only need them to make the binary file, so they can be deleted afterwards.

### CSV To Binary File

Next, we turn the output dataframes into binary files.  This is done with C, as I didn't want to chance some subtlety of Python-generated binary files causing issues.

{{< highlight c >}}
struct TreeNode{
    long int column;
    float threshold;
    long int left_child;
    long int right_child;
    float value;
};

struct TreeNode get_node(char *line){
    struct TreeNode node;
    node.column = strtol(strtok(line,","), NULL, 10);
    node.threshold = strtof(strtok(NULL,","), NULL);
    node.left_child = strtol(strtok(NULL,","), NULL, 10);
    node.right_child = strtol(strtok(NULL,","), NULL, 10);
    node.value = strtof(strtok(NULL,","), NULL);
    return node;
};

void main(int argc, char *argv[]){
    char line[512];
    char * token;
    int nrows;
    int ntrees = argc - 1;
    FILE *binary_file = fopen("forest.bin", "wb");
    struct TreeNode node;
    
    int i;
    int j;
    
    fwrite(&ntrees, sizeof(int), 1, binary_file);
    for(i=1; i<argc; i++){
        j=0;
        FILE *f = fopen(argv[i], "r");
        nrows = atoi(fgets(line, 512, f));
        struct TreeNode tree[nrows];
        fwrite(&nrows, sizeof(int), 1, binary_file);
        while(fgets(line, 512, f)){
            tree[j] = get_node(line);
            printf("%f\n", tree[j].value);
            j++;
        };
        fwrite(tree, sizeof(struct TreeNode)*nrows, 1, binary_file);
        fclose(f);
    };
    fclose(binary_file);
}
{{< / highlight >}}

The compiled code is supposed to be called with a list of the trees' files, or just with `tree*.csv` to take advantage of wildcards.  The first thing that's written to the file is the number of trees.  After that, the integer at the top of the first file gives the number of nodes in the tree, which allows us to quickly define the size of the array that we need and avoid something more involved, like memory allocation.  Then a file is read a line at a time -- `fgets()` stops at line breaks, conveniently -- and each line is processed into a node, which `strtok()` makes pretty easy.  Then the number of rows and array of structs is written to the binary file, and repeated for all of the dataframe files.

### Make A Prediction

Then we make the prediction:

{{< highlight c >}}
float predict(int argc, char *argv[]){
    int ntrees;
    int nrows;
    long int current_node;
    float prediction_sum = 0;
    FILE *binary_file = fopen("forest.bin", "rb");
    fread(&ntrees, sizeof(int), 1, binary_file);

    int i;
    int j;
    float predictors[13];
    for(i=0; i<13; i++){
        predictors[i] = strtof(argv[i+1], NULL);
    };

    long int column;
    float value;
    float threshold;
    for(i=0; i<ntrees; i++){
        fread(&nrows, sizeof(int), 1, binary_file);
        struct TreeNode tree[nrows];
        fread(tree, sizeof(struct TreeNode)*nrows, 1, binary_file);
        
        // work through the 
        current_node = 0;
        while(tree[current_node].column > -1){
            value = predictors[tree[current_node].column];
            threshold = tree[current_node].threshold;
            current_node = value < threshold ? tree[current_node].left_child : tree[current_node].right_child;
        };
        prediction_sum = prediction_sum + tree[current_node].value;
    };
    return(prediction_sum/ntrees);
};

void main(int argc, char *argv[]){
    float prediction;
    prediction = predict(argc, argv);
    printf("Prediction: %f\n", prediction);
}
{{< / highlight >}}

The first thing that's read from the file is the number of trees, so we know how many struct arrays we're going to need to load.  Then each one is read in, and we find the prediction value like so:

1. Start from node 0, which is the topmost node in the tree.
2. Determine which column is being used for a prediction at that node, and get both the threshold value and the value for that column from the new data.
3. Check whether the threshold is greater or less than the new data's value, and figure out whether to go to the left or the right child.
4. Check the column number in the child node: If the value of column is -2, then we've reached a leaf node and can report back the result; if not, return to step 2.
5. Average the prediction values together.

And that's it.

### Final Note
This was my first experience working with C, so I expect this code is a bit shaky.  But it seemed to work fairly well.  I was hoping to get some profiling done on to compare the prediction speed of the C code versus Python, but I couldn't come up with a comparison that I liked and I had a hard time with using `gprof` to profile the C code.
