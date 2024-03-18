from sklearn.metrics import confusion_matrix
import matplotlib.pyplot as plt
import numpy as np
from itertools import product
import pickle
import os

class calculate_confusion_matrix:
    def __init__(self, classes, show=False):
        """
        Initializes the Confusion Matrix Calculator.

        Args:
        - classes (list): List of class labels.
        - show (bool): Flag to control whether to display the confusion matrix plot.
        """
        self.classes = classes
        self.show = show

    def plot_confusion_matrix(self, true_class, predict_class, model_name, name, PATH):
        """
        Plots a normalized confusion matrix and saves it as an EPS file.

        Args:
        - true_class (array-like): True class labels.
        - predict_class (array-like): Predicted class labels.
        - model_name (str): Name of the classification model.
        - name (str): Name identifier for the confusion matrix.

        Returns:
        None
        """
        # Plot confusion matrix
        classes = self.classes
        conf_matrix = confusion_matrix(true_class, predict_class)
        normalized_conf_matrix = conf_matrix.astype('float') / conf_matrix.sum(axis=1)[:, np.newaxis]  # normalize here
        plt.imshow(normalized_conf_matrix, cmap=plt.cm.Blues)

        # Add labels
        plt.title("Normalized Confusion Matrix " + name)  # change title to reflect normalization
        plt.colorbar()
        tick_marks = np.arange(len(classes))
        plt.xticks(tick_marks, classes, rotation=45)
        plt.yticks(tick_marks, classes)

        # Add values to cells
        thresh = normalized_conf_matrix.max() / 2.
        for i, j in product(range(normalized_conf_matrix.shape[0]), range(normalized_conf_matrix.shape[1])):
            plt.text(j, i, format(normalized_conf_matrix[i, j], '.2f'),  # format to display two decimal places
                     horizontalalignment="center",
                     color="white" if normalized_conf_matrix[i, j] > thresh else "black")

        plt.ylabel('True Label')
        plt.xlabel('Predicted Label')
        plt.title(model_name)
        plt.tight_layout()

        plt.savefig(os.path.join(PATH,'CLASSIFIERS/Confusion_Matrices/')+'Confusion_Matrix_' + model_name + '_' + name + '.eps', format='eps')

        if self.show:
            plt.pause(3)
        plt.close()

def save_model(model, name, relative_path=''):
    """
    Saves a trained machine learning model to a file using pickle.

    Args:
    - model: The trained machine learning model.
    - name (str): Name identifier for the saved model file.
    - relative_path (str): Relative path where the model file will be saved.

    Returns:
    None
    """
    os.makedirs(relative_path, exist_ok=True)

    filename = os.path.join(relative_path + name + '_model.sav')
    pickle.dump(model, open(filename, 'wb'))
