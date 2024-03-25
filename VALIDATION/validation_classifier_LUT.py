# %% Cross validation using classifier + LUT

import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
from pandas import read_csv
from tensorflow import keras
import numpy as np
import pandas as pd
import random
from sklearn.preprocessing import LabelEncoder
import joblib
from tqdm import tqdm
import pickle
from sklearn.metrics.pairwise import manhattan_distances
from sklearn.preprocessing import MinMaxScaler
from sklearn.model_selection import train_test_split
import sys
import pathlib

diractual = os.getcwd()
print('Current directory: ',diractual)
dirscript = os.path.dirname(__file__)
print('Script directory: ', dirscript)

# Changing working directory to the script directory:
os.chdir(dirscript)
print('Working directory changed to: ', os.getcwd())


# %%
def look_up_table(df, look):
    """
    Find the rows in the DataFrame `df` that are closest to the specified rows in `look`
    based on Manhattan distance using a look-up table approach.

    Parameters:
    - df: pandas DataFrame, the dataset.
    - look: pandas DataFrame, the rows to compare.

    Returns:
    numpy array: Rows in `df` that are closest to the rows in `look`.
    """
    df_train, df_val = train_test_split(df, test_size=0.2, random_state=1)

    # Assume X is your original dataset and rows_to_compare are the rows to compare in X
    X_train = df_train[['SNR', 'Bw', 'Power']].values
    Y_train = df_train.drop(['SNR', 'Bw', 'Power'], axis=1).values

    scaler = MinMaxScaler()
    X_train_norm = scaler.fit_transform(X_train)
    look_norm = scaler.transform(look)

    # Calculating the Manhattan distance between the normalized rows and rows to compare
    distances = manhattan_distances(X_train_norm, look_norm)

    # Index of the row in X with the minimum distance to each row to compare
    closest_row_indices = distances.argmin(axis=0)

    # The rows in X that are closest to the rows to compare
    closest_rows = Y_train[closest_row_indices]
    return closest_rows

def random_factor(value, range_val=0.05):
    """
    Add a random factor to the given value within the specified range.

    Parameters:
    - value: float, the original value to which a random factor will be applied.
    - range_val: float, the range within which the random factor will be generated.

    Returns:
    float: the value multiplied by (1 + alpha), where alpha is a random factor.
    """
    alpha = random.uniform(-range_val, range_val)
    return value * (1 + alpha)

# Vectorize the random_factor function
random_factor_vec = np.vectorize(random_factor)

def validation_SC(df_val, model_name, classifier_model='',PATH='.'):
    """
    Perform validation using a classifier model and a look-up table approach.

    Parameters:
    - df_val: pandas DataFrame, the validation dataset.
    - model_name: str, the name of the regression model.
    - classifier_model: str, the name of the classifier model (default is an empty string).

    Saves:
    - Multiple CSV files with predictions for each iteration.

    Returns:
    None
    """
    # Load dataset
    file_name = 'DATASET/RNN_' + model_name + '_Validation.csv'
    df = read_csv(file_name)
    dv_name = df.columns.tolist()
    for name in ['SNR', 'Bw', 'Power']:
        dv_name.remove(name)

    # Unscaling design vars
    df_specs = df[['SNR','Bw','Power']]
    df_dvars = df.drop(columns=['SNR','Bw','Power']).values
    y_scaler = joblib.load('../REGRESSION-ANN/scalers/model_RNN_'+model_name+'_scaler.gz')
    scaled_dvars = y_scaler.inverse_transform(df_dvars)
    scaled_dvars = pd.DataFrame(scaled_dvars)
    df = pd.concat([df_specs,scaled_dvars],axis=1)

    num_iterations = 10
    print('Making predictions...')
    specs_val = df_val[['SNR', 'Bw', 'Power']].values
    y_predict = look_up_table(df, specs_val)

    for i in tqdm(range(num_iterations)):
        range_val = 0.05
        if i == 0:
            range_val = 0

        y_predict_var = random_factor_vec(y_predict, range_val=range_val)
        y_predict_var = pd.DataFrame(y_predict_var, columns=dv_name)

        specs_val = df_val[['SNR', 'Bw', 'Power']]
        df_predict = pd.concat([specs_val.reset_index(drop=True), y_predict_var.reset_index(drop=True)],
                              axis=1)
        df_predict.to_csv(PATH + '/VAL-DS/Multiple-Iterations-LUT/classifier'+classifier_model+'_'+model_name+'_val_'+str(i + 1)+'.csv', index=False)

# %% Validation data set
dataset_folder = 'DATASET/'
classifier_name = 'classifier'
datalist = []
for file in os.listdir(dataset_folder):
    data = pd.read_csv(dataset_folder+file)
    data = data[['SNR','Bw','Power']]
    datalist = datalist + [data]
df_val = pd.concat(datalist,axis=0)


# Encoder
encoder = LabelEncoder()
encoder.classes_ = np.load('../CLASSIFIERS/model/' + classifier_name + '_classes.npy', allow_pickle=True)

model = 'GB'  # '' for ANN

print(f'Classifier Model {model}')
classifier_scaler = joblib.load('../CLASSIFIERS/classifier_scaler.gz')
X_val = df_val[['SNR', 'Bw', 'Power']]
column_names = X_val.columns.to_list()
scaled_values = pd.DataFrame(classifier_scaler.transform(X_val), columns=column_names)


classifier = pickle.load(open('../CLASSIFIERS/model/'+model+'_model.sav', 'rb'))
y_class_predict = classifier.predict(scaled_values)

# Divide df_val into different sub-dfs by y_class_predict
dfs = [df_val[y_class_predict == model_name] for model_name in encoder.classes_]

# Make predictions
for df_val, model_name in zip(dfs, encoder.classes_):
    print(model_name)
    validation_SC(df_val, model_name, classifier_model=model)