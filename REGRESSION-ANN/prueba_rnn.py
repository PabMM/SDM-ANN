import tensorflow as tf
from tensorflow import keras
import numpy as np
import os

diractual = os.getcwd()
print('Current directory: ',diractual)
dirscript = os.path.dirname(__file__)
print('Script directory: ', dirscript)

# Changing working directory to the script directory:
os.chdir(dirscript)
print('Working directory changed to: ', os.getcwd())


model = keras.models.load_model('models/2ndSCSDM_SingleBit')

input_data = np.array([[100, 100000, 0.02]])
prediction = model.predict(input_data)

print("Predicción: ", prediction)

