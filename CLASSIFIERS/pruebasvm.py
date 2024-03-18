from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import pandas as pd
import numpy as np
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
# from sklearn.externals import joblib
import time #To measure fitting time
from joblib import dump
import sys
import os
import pathlib
MYPATH=pathlib.Path(__file__).parent.parent.absolute()
sys.path.append(str(MYPATH))

from Lib.Lib import calculate_confusion_matrix
from Lib.Lib import save_model

import timeit

csv_file=os.path.join(MYPATH,"DATASETS/FinalDataSets/dataset_total.csv")
dataframe = pd.read_csv(csv_file)

def print_hash():
  print("########################################")
def print_bar():
  print("________________________________________")



#%%
modelsList=dataframe["Category"].unique().tolist()
Nmodels=len(modelsList)


print_hash()
print(f'{Nmodels} models')
print_bar()


for sp in modelsList:
    print(f'Model name: {sp}')
print_hash()
#Explicitily creating Species code as target

dataframe["target"]=dataframe["Category"]

#Removing variables which will not be used by the classifier

VarsToRemove=["Category"]

dataframe=dataframe.drop(columns=VarsToRemove)


Column_Names=dataframe.columns.to_list()

Column_Names.remove("target")

for var in Column_Names:
    print(f'Variable Name: {var}')
print_bar()
if(input("Perform minmax scaling? [1 for YES]")=="1"):
  scaler=MinMaxScaler()
  scaled_values=scaler.fit_transform(dataframe[Column_Names])
  dataframe[Column_Names]=scaled_values
  scaler_path = os.path.join(MYPATH,'CLASSIFIERS/model/classifier_scaler.gz')
  dump(scaler,scaler_path)
print_bar()
print(dataframe.head(5))
print_bar()

#split original DataFrame into training and testing sets
train, test = train_test_split(dataframe, test_size=0.2, random_state=0)

x_train=train[Column_Names]
Ninputs= len(Column_Names)

y_train=train["target"]
Noutputs=1

print(f'All models will be trained for {Ninputs} input(s) and {Noutputs} output(s)')
x_test=test[Column_Names]
y_test=test["target"]

x=pd.concat((x_train,x_test),axis=0,ignore_index=True)
y=pd.concat((y_train,y_test),axis=0,ignore_index=True)

# Init calculate confusion Matrix

from sklearn.preprocessing import LabelEncoder
le = LabelEncoder()
le.fit_transform(dataframe["target"].values)
classes_path = os.path.join(MYPATH,'CLASSIFIERS/model/classifier_classes.npy')
np.save(classes_path, le.classes_,allow_pickle=True)

CCM = calculate_confusion_matrix(le.classes_)

# Def function for calculating accuracy and displays

def model_eval(model,x,y_true,model_name,key,PATH):
  # evaluate model
  tstart = timeit.default_timer()
  y_predict = model.predict(x)
  tend = timeit.default_timer()
  ETA = tend - tstart
  # accuracy
  scores = accuracy_score(y_true,y_predict)
  # disp
  n = np.size(y_true)
  tn = ETA/n
  print(f'{model_name} accuracy on the {key} dataset : {np.mean(scores):.3f} prediction time {ETA:.8f}s, prediction time per point {tn:.8f}s')
  # confusion Matrix
  CCM.plot_confusion_matrix(y_true,y_predict,model_name,key,PATH)

 
# %% SVM model
# %% NN
import tensorflow as tf

print("Num GPUs Available: ", len(tf.config.list_physical_devices('GPU')))
print(tf.config.list_physical_devices('GPU'))

print("TensorFlow version:", tf.__version__)


# Split the dataframe into inputs (X) and target (y)
X = dataframe.drop('target', axis=1)
y = dataframe['target']
# Convert target to integers

y = le.transform(y.values)

# Convert the target column into a one-hot encoded representation
y = tf.keras.utils.to_categorical(y, num_classes=Nmodels)

# Split the inputs and target into training (80%) and test (20%) sets
X_train, X_test, Y_train, Y_test = train_test_split(X, y, test_size=0.2, random_state=0)

# Convert the training and test sets into TensorFlow datasets

train_dataset = tf.data.Dataset.from_tensor_slices((X_train.values, Y_train))
test_dataset = tf.data.Dataset.from_tensor_slices((X_test.values, Y_test))
batch_size=64
# Batch and shuffle the training set
train_dataset = train_dataset.shuffle(len(X_train)).batch(batch_size)

# Batch the test set
test_dataset = test_dataset.batch(batch_size)

# Create a simple model using the inputs and target (architecture is the result of NAS)
model = tf.keras.Sequential([
    tf.keras.layers.BatchNormalization(input_shape=(X.shape[1],)),
    tf.keras.layers.Dense(256, activation='relu'),
    tf.keras.layers.Dropout(0.4),
    tf.keras.layers.Dense(238, activation='relu'),
    tf.keras.layers.Dropout(0.4),
    tf.keras.layers.Dense(Nmodels, activation="softmax")
])
print(model.summary())
# Compile the model
model.compile(optimizer='adam',
              loss=tf.keras.losses.CategoricalCrossentropy(from_logits=False),
              metrics=["accuracy"])

# Train the model
history = model.fit(train_dataset, epochs=1, verbose=0, callbacks=[tf.keras.callbacks.History()])

test_loss, test_accuracy = model.evaluate(test_dataset)
print(f'Tensorflow Network trained with {test_accuracy:.2f} accuracy on the test data')


# Make predictions 
y_pred = model.predict(X)
y_pred_test = model.predict(X_test)
# Convert predictions to a binary format
y_pred_binary = np.round(y_pred)
y_pred_binary_test = np.round(y_pred_test)

Y_test_integer = np.argmax(y, axis=1)
Y_test_integer_test = np.argmax(Y_test, axis=1)
y_pred_binary_integer = np.argmax(y_pred_binary, axis=1)
y_pred_binary_integer_test = np.argmax(y_pred_binary_test, axis=1)


