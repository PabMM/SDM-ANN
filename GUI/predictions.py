# %% Classifier and RNN predictions
# P. Manrique April 1st, 2024

import os
#os.environ["TF_USE_LEGACY_KERAS"] = "1"

import pandas as pd
import numpy as np
import joblib
#from tensorflow import keras
import pickle
import keras

filedir = os.path.dirname(__file__)
os.chdir(filedir)

# %% Defs

def classifier_prediction(sndr,bw,power,classifier='GB'):
    """
    Perform best SDM model predicition of given specifications using a classification model.

    Args:
        - sndr: Signal-to-Noise Ratio value in dB
        - bw: Signal Bandwidth value in Hz
        - power: Power consumption value in W
        - classifier: Classifier model to use. Default is GB.

    Returns:
        - predicted_class: SDM model to use.
    """

    specs = pd.DataFrame([[sndr,bw,power]], columns=['SNDR','Bw','Power'])

    # Load classifier scaler
    classifier_scaler = joblib.load('../CLASSIFIERS/classifier_scaler.gz')
    scaled_specs = pd.DataFrame(classifier_scaler.transform(specs), columns=['SNDR','Bw','Power'])

    # Load classifier model
    classifier = pickle.load(open(f'../CLASSIFIERS/model/{classifier}_model.sav', 'rb'))

    # Make prediction
    predicted_class = classifier.predict(scaled_specs)[0]
    pc = classifier.predict(scaled_specs)
    #print(pc)
   

    return predicted_class


def rnn_prediction(sndr,bw,power,model):
    """
    Perform SDM design variables prediction using a RNN model.

    Args:
        - sndr: Signal-to-Noise Ratio value in dB
        - bw: Signal Bandwidth value in Hz
        - power: Power consumption value in W
        - model: SDM model RNN to use

    Saves:
        - dvars.csv: CSV file containing predicted design variables
    """

    specs = pd.DataFrame([[sndr,bw,power]], columns=['SNDR','Bw','Power'])

    file_name = '../REGRESSION-ANN/DATASET/RNN_' + model + '.csv'
    df = pd.read_csv(file_name)
    dv_name = df.columns.tolist()
    for name in ['SNDR', 'Bw', 'Power']:
        dv_name.remove(name)

    # Load scaler
    scaler = joblib.load('../REGRESSION-ANN/scalers/model_RNN_' + model + '_scaler.gz')

    # Load RNN model and perform predictions
    model = keras.saving.load_model('../REGRESSION-ANN/models/RNN_' + model + '.keras')
    predicted_dvars = model.predict(specs, verbose=0)
    predicted_dvars = scaler.inverse_transform(predicted_dvars)
    predicted_dvars = pd.DataFrame(predicted_dvars, columns = dv_name)
    #predicted_dvars = predicted_dvars.tolist()[0]
    #predicted_dvars = dict(zip(dv_name, predicted_dvars))

    predicted_dvars.to_csv('dvars.csv', index=False)

    #return predicted_dvars


# %%
#pred1 = classifier_prediction(80,600000,0.008)
#print('Chosen modulator by classifier: ',pred1)
#pred2 = rnn_prediction(70,100000,0.008,pred1)
#print('Predicted design variables: \n', pred2)

#l1 = ['a','b','c']
#l2 = [1,2,3]
#l = zip(l1,l2)
#d = dict(l)
#print(l)
#print(d)
