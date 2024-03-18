# %% Species Classifier using different classifiers
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
print('Current path: ',MYPATH)
sys.path.append(str(MYPATH))

from Lib.Lib import calculate_confusion_matrix
from Lib.Lib import save_model

import timeit

#%% datareading and normalizatino
csv_file=os.path.join(MYPATH,"DATASETS/FinalDataSets/dataset_total_V2.csv")
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




#%%# First the GNB model
from sklearn.naive_bayes import GaussianNB

GNBmodel = GaussianNB()
tstart=time.time()
GNBmodel.fit(x_train, y_train)
tend=time.time()
ETA=tend-tstart
print(f'GNB fitting time {ETA:.3f}s')
#Evaluate model
model_eval(GNBmodel,x_train,y_train,'GNB','Train',MYPATH)
model_eval(GNBmodel,x_test,y_test,'GNB','Test',MYPATH)
model_eval(GNBmodel,x,y,'GNB','Whole',MYPATH)
print_bar()

# save model
path_save_model = str(MYPATH)+'/CLASSIFIERS/model/'
save_model(GNBmodel,'GNB',path_save_model)

#%% Now the logisticRegresion model
from sklearn import linear_model

classifier_name='logisticRegresion'
classifier_logreg = linear_model.LogisticRegression(max_iter=1000, random_state=0,penalty='elasticnet',solver='saga',l1_ratio=0.5)
tstart=time.time()
classifier_logreg.fit(x_train, y_train)
tend=time.time()
ETA=tend-tstart
print(f'logreg fitting time {ETA:.3f}s')
#Evaluate model
model_eval(classifier_logreg,x_train,y_train,'logreg','Train',MYPATH)
model_eval(classifier_logreg,x_test,y_test,'logreg','Test',MYPATH)
model_eval(classifier_logreg,x,y,'logreg','Whole',MYPATH)
print_bar()

# save model
save_model(classifier_logreg,'logreg',path_save_model)

#%% Now the MultinomialNB model
from sklearn.naive_bayes import MultinomialNB

classifier_MNB = MultinomialNB()
tstart=time.time()
classifier_MNB.fit(x_train, y_train)
tend=time.time()
ETA=tend-tstart
print(f'MNB fitting time {ETA:.3f}s')
#Evaluate model
model_eval(classifier_MNB,x_train,y_train,'MNB','Train',MYPATH)
model_eval(classifier_MNB,x_test,y_test,'MNB','Test',MYPATH)
model_eval(classifier_MNB,x,y,'MNB','Whole',MYPATH)
print_bar()

# save model
save_model(classifier_MNB,'MNB',path_save_model)

#%% First the QDA model
from sklearn.discriminant_analysis import QuadraticDiscriminantAnalysis

classifier_name='Quadratic Discriminant Analysis'
classifier_QDA = QuadraticDiscriminantAnalysis(reg_param=0.6)
tstart=time.time()
classifier_QDA.fit(x_train, y_train)
tend=time.time()
ETA=tend-tstart
print(f'QDA fitting time {ETA:.3f}s')
#Evaluate model
model_eval(classifier_QDA,x_train,y_train,'QDA','Train',MYPATH)
model_eval(classifier_QDA,x_test,y_test,'QDA','Test',MYPATH)
model_eval(classifier_QDA,x,y,'QDA','Whole',MYPATH)
print_bar()

# save model
save_model(classifier_QDA,'QDA',path_save_model)

#%% Now the Random Forest model
from sklearn.ensemble import RandomForestClassifier

classifier_name='Random Forest'
classifier_RF = RandomForestClassifier(n_estimators=25, random_state=42,max_depth=32)
tstart=time.time()
classifier_RF.fit(x_train, y_train)
tend=time.time()
ETA=tend-tstart
print(f'RF fitting time {ETA:.3f}s')
#Evaluate model
model_eval(classifier_RF,x_train,y_train,'RF','Train',MYPATH)
model_eval(classifier_RF,x_test,y_test,'RF','Test',MYPATH)
model_eval(classifier_RF,x,y,'RF','Whole',MYPATH)
print_bar()

# save model
save_model(classifier_RF,'RF',path_save_model)

#%% Now the LDA model
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis 

LDAmodel = LinearDiscriminantAnalysis()
tstart=time.time()
LDAmodel.fit(x_train, y_train)
tend=time.time()
LDATime=tend-tstart
print(f'LDA fitting time {LDATime:.3f}s')
#Evaluate model
model_eval(LDAmodel,x_train,y_train,'LDA','Train',MYPATH)
model_eval(LDAmodel,x_test,y_test,'LDA','Test',MYPATH)
model_eval(LDAmodel,x,y,'LDA','Whole',MYPATH)
print_bar()

# save model
save_model(LDAmodel,'LDA',path_save_model)

#%% ######Now decission tree
from sklearn.tree import DecisionTreeClassifier

DTmodel = DecisionTreeClassifier(criterion="gini", random_state=42,max_depth=None, min_samples_leaf=1)   
tstart=time.time()

DTmodel.fit(x_train,y_train)
tend=time.time()
ETA = tend-tstart
print(f'DT fitting time {ETA:.3f}s')
#Evaluate model
model_eval(DTmodel,x_train,y_train,'DT','Train',MYPATH)
model_eval(DTmodel,x_test,y_test,'DT','Test',MYPATH)
model_eval(DTmodel,x,y,'DT','Whole',MYPATH)
print_bar()

# save model
save_model(DTmodel,'DT',path_save_model)

#%% ###### Now using SVM
#from sklearn import svm
#SVM_time=[]

#for kernel in ("linear", "poly", "rbf"):
#  SVMModel = svm.SVC(kernel=kernel, gamma=2)

  #Train the model using the training sets
#  tstart=time.time()
#  SVMModel.fit(x_train,y_train)
#  tend=time.time()
#  ThisTime=tend-tstart
#  SVM_time.append(ThisTime)
#  print(f'SVM fitting time {ThisTime:.3f}s')
#  #Evaluate model
#  model_eval(SVMModel,x_train,y_train,'SVM'+kernel,'Train',MYPATH)
#  model_eval(SVMModel,x_test,y_test,'SVM'+kernel,'Test',MYPATH)
#  model_eval(SVMModel,x,y,'SVM'+kernel,'Whole',MYPATH)
#  print_bar()

  # save model
#  save_model(SVMModel,'SVM_'+kernel,'model/')   

print_bar()

#%% Gradient boosting algorithm
from sklearn.ensemble import GradientBoostingClassifier
#lr_list = [0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1]
if(input("Adjust learning rate in Gradient Boosting Classifier or use default value?(1-Yes)")=="1"):
  lr_list=np.linspace(0.02,1,40)
  GB_time=[]
  GB_accuracy=[]
  GB_model =[]
  
  for learning_rate in lr_list:
    GBModel = GradientBoostingClassifier(n_estimators=100,learning_rate=learning_rate, max_features=2, max_depth=2, random_state=0)
    tstart=time.time()
    GBModel.fit(x_train, y_train)
    tend=time.time()
    ThisTime=tend-tstart
    predictionsGB=GBModel.predict(x_test)
    scoresGB = np.mean(accuracy_score(y_test, predictionsGB))
    print(f'Learning rate {learning_rate}, accuracy {scoresGB}')
    GB_model.append(GBModel)
    GB_time.append(ThisTime)
    GB_accuracy.append(scoresGB)


#Finding best performing GB model
  BestPerformingGB=np.argmax(GB_accuracy)
  BestLearningRateGB=lr_list[BestPerformingGB]
  BestAccuracyGB=GB_accuracy[BestPerformingGB]
  BestGBTime=GB_time[BestPerformingGB]
  BestModelGB = GB_model[BestPerformingGB]
  print(f'GB fitting time {BestGBTime:.3f}s')
  #Evaluate model
  model_eval(BestModelGB,x_train,y_train,'GB','Train',MYPATH)
  model_eval(BestModelGB,x_test,y_test,'GB','Test',MYPATH)
  model_eval(BestModelGB,x,y,'GB','Whole',MYPATH)
  print_bar()

  # save model
  save_model(BestModelGB,'GB',path_save_model)

else:
  GBModel = GradientBoostingClassifier(n_estimators=100,learning_rate=0.52, max_features=2, max_depth=2, random_state=0)
  tstart=time.time()
  GBModel.fit(x_train, y_train)
  tend=time.time()
  ThisTime=tend-tstart
  predictionsGB=GBModel.predict(x_test)
  scoresGB = np.mean(accuracy_score(y_test, predictionsGB))
  model_eval(GBModel,x_train,y_train,'GB','Train',MYPATH)
  model_eval(GBModel,x_test,y_test,'GB','Test',MYPATH)
  model_eval(GBModel,x,y,'GB','Whole',MYPATH)
  print(f' Gradient Boosting Classifier accuracy on the test data: {scoresGB:.3f} execution time {ThisTime:.3f}s')    
  print_bar()
  save_model(GBModel,'GB',path_save_model)

#%% Now using tensorflow
import tensorflow as tf
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
history = model.fit(train_dataset, epochs=15, verbose=0, callbacks=[tf.keras.callbacks.History()])

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


# Compute confusion matrices

CCM.plot_confusion_matrix(Y_test_integer_test,y_pred_binary_integer_test,'ANN','Test',MYPATH)
CCM.plot_confusion_matrix(Y_test_integer,y_pred_binary_integer,'ANN','Total',MYPATH)

save_model(model,'ANN',path_save_model)
