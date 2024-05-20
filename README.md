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

To set up the necessary environment for running the scripts in this repository, follow the steps below:

## 0. **Check Python version**

In order to use the MATLAB App, your MATLAB and Python versions must be compatible. You can check the Python compatible versions with MATLAB by release [here](https://es.mathworks.com/support/requirements/python-compatibility.html). To check what your Python version is, open a terminal and type `python --version` or simply `python -V`.

## 1. **Clone the Repository:**
Open a terminal and navigate with `cd` to the directory you want to clone the repository. Then run the following commands:
 ```bash
git clone https://github.com/PabMM/SDM-ANN
cd <repository_directory>
```

## 2. **Create Virtual Environment (Optional but recommended)**
We do recommend using virtual environments in order to avoid conflicts with other libraries in your system. 

### INSTRUCTIONS:
   
   1-Open a terminal (or use VSCODE terminal for instance) in the folder where you extracted this repository
   
   2-Create the virtual environment (optionally you can just type python instead of python3):
   ```bash
   python3 -m venv .venv 
   ```
   
   3-Activate the virtual environment:
   - Linux:
   ```bash
   source .venv/bin/activate
   ```

   - Windows:
   ```bash
   .\.venv\Scripts\activate
   ```

   4-If you want to deactivate the virtual environment simply execute `deactivate` in the terminal where the venv is active
   ```bash
   deactivate
   ```
   5-Now, when the virtual environment is active, all libraries and dependencies will be installed in the `.venv` folder. Simply remove this folder to recover disk space taken by this project's libraries.

   [Here](https://docs.python.org/3/library/venv.html) you have additional information about virtual environments.
   
   
## 3. **Install Dependencies:**
In order to use the repository, you must install the python libraries in the script `requirements.txt`. You can do this with
```bash
pip install -r requirements.txt (optionally you can use pip3)
```

## 4. **Python configuration in MATLAB**

To change the default environment of the Python interpreter in MATLAB, run the following command in the MATLAB Command Window:

```bash
>> pyenv('Version', ... 
            '/location/of/python/executable', ... 
            'ExecutionMode','OutOfProcess')
```

You can easily find the `/location/of/python/executable` running python in a terminal and then executing the following commands:

```bash
python
>>> import sys
>>> sys.executable
```

In the following links you can also find additional information on [pyenv](https://es.mathworks.com/help/matlab/ref/pyenv.html) and [virtual environments with Matlab](https://es.mathworks.com/matlabcentral/answers/1750425-python-virtual-environments-with-matlab).
