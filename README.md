# Repository overview

The objective of this repository is to provide machine learning tools to assist in the design of Sigma-Delta modulators (SDM) given certain specifications, although its usage can certainly be generalized to other tasks. The content of the repository enables training models that are capable of learning useful design patterns for this task. Next, we describe the content of its main folders and their functionality:

## 1. PROCESSING
- **dataset_processing.py**: This script processes the datasets provided in the `PROCESSING/DATASET/` folder, allowing them to be used by classifiers and neural networks for training. It also saves plottings of the dataset used by the classifiers in `CLASSIFIERS/plots/`.

## 2. CLASSIFIERS
- **classifiers.py**: A script for building, training, and evaluating various classification models. It uses scikit-learn and includes model evaluation metrics and confusion matrix plotting.
- **Lib.py**: Contains functions that allow plotting confussion matrices and saving models.

## 3. REGRESSION-ANN
- **regression_ann_NSA.py**: A script for building, training, and evaluating a neural network-based regression model using TensorFlow and Keras. The script includes hyperparameter tuning and outputs various results, including model visualizations and Mean Squared Error (MSE) metrics.

## 4. VALIDATION
- to complete

## 5. GUI
- to complete

# Installation
In order to use the repository, you must install the python libraries in the script `requirements.txt`. You can do this with

```bash
pip install -r requirements.txt
```

Also, to use the MATLAB GUI, your MATLAB and Python versions must be compatible. You can check the Python compatible versions with MATLAB by release [here](https://es.mathworks.com/support/requirements/python-compatibility.html).

To change the default environment of the Python interpreter in MATLAB, run the following command in the MATLAB Command Window:

```bash
>> pyenv('Version', ... 
            '/location/of/python/executable', ... 
            'ExecutionMode','OutOfProcess')
```

You can easily find the `/location/of/python/executable` this way:

```bash
/home/username$ python
>>> import sys
>>> sys.executable
```

In the following links you can also find additional information on [pyenv](https://es.mathworks.com/help/matlab/ref/pyenv.html) and [virtual environments](https://es.mathworks.com/matlabcentral/answers/1750425-python-virtual-environments-with-matlab).
