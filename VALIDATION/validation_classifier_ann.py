# %% Cross Validation using Classifier + ANN

#%% Imports
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

diractual = os.getcwd()
print('Current directory: ',diractual)
dirscript = os.path.dirname(__file__)
print('Script directory: ', dirscript)

# Changing working directory to the script directory:
os.chdir(dirscript)
print('Working directory changed to: ', os.getcwd())

#%%Defs

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

def validation_SC(df_val, model_name, classifier_model=''):
    """
    Perform validation using a classifier model.

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

    # Load regression model
    model = keras.models.load_model('../REGRESSION-ANN/models/RNN_' + model_name)

    # Load scaler
    y_scaler = joblib.load('../REGRESSION-ANN/scalers/model_RNN_' + model_name + '_scaler.gz')

    # Validation in SIMSIDES
    specs = df_val[['SNR', 'Bw', 'Power']].values
    num_iterations = 10
    print('Making predictions...')

    y_reg = model.predict(specs, verbose=0)
    y_reg = y_scaler.inverse_transform(y_reg)

    for i in tqdm(range(num_iterations)):
        range_val = 0.05
        if i == 0:
            range_val = 0

        y_reg_predict = random_factor_vec(y_reg, range_val=range_val)
        y_reg_predict = pd.DataFrame(y_reg_predict, columns=dv_name)

        specs_val = df_val[['SNR', 'Bw', 'Power']]
        df_predict = pd.concat([specs_val.reset_index(drop=True), y_reg_predict.reset_index(drop=True)],
                              axis=1)
        df_predict.to_csv(f'/VAL-DS/Multiple-Iterations-ANN/classifier{classifier_model}_{model_name}_val_{i + 1}.csv', index=False)

#%% Validation data set
dataset_folder = 'DATASET/'
classifier_name = 'classifier'
datalist = []
for file in os.listdir(dataset_folder):
    data = pd.read_csv(dataset_folder+file)
    data = data[['SNR','Bw','Power']]
    datalist = datalist + [data]
df_val = pd.concat(datalist,axis=0)


#%% Encoder
encoder = LabelEncoder()
encoder.classes_ = np.load('../CLASSIFIERS/model/' + classifier_name + '_classes.npy', allow_pickle=True)

model = 'GB'  # '' for ANN

print(f'Classifier Model {model}')
classifier_scaler = joblib.load('../CLASSIFIERS/classifier_scaler.gz')
X_val = df_val[['SNR', 'Bw', 'Power']]
column_names = X_val.columns.to_list()
scaled_values = pd.DataFrame(classifier_scaler.transform(X_val), columns=column_names)

classifier = pickle.load(open(f'../CLASSIFIERS/model/{model}_model.sav', 'rb'))
y_class_predict = classifier.predict(scaled_values)

# Divide df_val into different sub-dfs by y_class_predict
dfs = [df_val[y_class_predict == model_name] for model_name in encoder.classes_]

# Make predictions
for df_val, model_name in zip(dfs, encoder.classes_):
    print(model_name)
    validation_SC(df_val, model_name, classifier_model=model)