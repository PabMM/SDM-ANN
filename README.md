# Repository overview

The objective of this repository is to provide machine learning tools to assist in the design of Sigma-Delta modulators (SDM) given certain specifications, although its usage can certainly be generalized to other tasks. The content of the repository enables training models that are capable of learning useful design patterns for this task. Next, we describe the content of its main folders and their functionality:

## 1. utils
- **dataset_processing.py**: This script processes the datasets provided in the utils/DATASET0/ folder, allowing them to be used by classifiers and neural networks for training. It also saves plottings of the dataset used by the classifiers in CLASSIFIERS/plots/.

## 2. CLASSIFIERS
- **classifiers.py**: A script for building, training, and evaluating various classification models. It uses scikit-learn and includes model evaluation metrics and confusion matrix plotting.
- **Lib.py**: Contains functions that allow plotting confussion matrices and saving models.

## 3. REGRESSION-ANN
- **regression_ann_NSA.py**: A script for building, training, and evaluating a neural network-based regression model using TensorFlow and Keras. The script includes hyperparameter tuning and outputs various results, including model visualizations and Mean Squared Error (MSE) metrics.
