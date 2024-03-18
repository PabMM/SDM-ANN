import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

from pandas import read_csv
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
from joblib import dump
from tensorflow import keras
import keras_tuner
import timeit
import numpy as np

import os

diractual = os.getcwd()
print('Current directory: ',diractual)
dirscript = os.path.dirname(__file__)
print('Script directory: ', dirscript)

# Changing working directory to the script directory:
os.chdir(dirscript)
print('Working directory changed to: ', os.getcwd())



#%% Dataset readout and train/val split

# load dataset
model_name = '2ndSCSDM_SingleBit'
file_name = 'DATASETS/dataset_'+model_name+'.csv'
df = read_csv(file_name)

# split into input (x) and output (y) variables
specs_columns = df[['SNR','Bw','Power']].values
design_vars = df.drop(['SNR', 'Bw','Power'], axis=1).values


num_inputs = specs_columns.shape[1] #specs should be the same regardless the architecture
num_outputs_params = design_vars.shape[1]

# escale design_vars
y_scaler = MinMaxScaler((0,1))
y_scaled = y_scaler.fit_transform(design_vars)
y_scaler_path = 'scalers/model_'+model_name+'_scaler.gz'
dump(y_scaler,y_scaler_path)

# split data into train, validation and test sets
x_train, x_val, y_train, y_val = train_test_split(specs_columns, y_scaled, test_size=0.2, random_state=1)
x_val, x_test, y_val, y_test = train_test_split(x_val, y_val, test_size=0.2, random_state=1)

#%%
# Tune Model architecture
def call_existing_code(units,num_layers,dropout,activation,optimizer):
    """
    Define and compile a neural network model with hyperparameters.

    Args:
    - units (int): Number of units in the dense layers.
    - num_layers (int): Number of dense layers.
    - dropout (bool): Whether to use dropout.
    - activation (str): Activation function for dense layers.
    - optimizer (str): Optimizer for compiling the model.

    Returns:
    - model: Compiled Keras model.
    """

    input_vector = keras.layers.Input(shape=(num_inputs,))
    x = keras.layers.BatchNormalization(scale=True, center=True)(input_vector)
    x = keras.layers.Dense(units=units, activation=activation)(x)
    if dropout:
        x = keras.layers.Dropout(rate=0.25)(x)
    x1 = keras.layers.LayerNormalization( scale=True, center=True, axis=-1)(x)
    x = keras.layers.Dense(units=units, activation=activation)(x1)
    if dropout:
        x = keras.layers.Dropout(rate=0.25)(x)
    x = keras.layers.LayerNormalization( scale=True, center=True, axis=-1)(x)
    x  = keras.layers.concatenate([x1,x])
    for i in range(num_layers):
        x = keras.layers.Dense(units=units, activation=activation)(x)
        if dropout:
            x = keras.layers.Dropout(rate=0.25)(x)
        x = keras.layers.LayerNormalization( scale=True, center=True, axis=-1)(x)

    # regression output
    out_reg = keras.layers.Dense(num_outputs_params, activation=activation,name = 'regression')(x)

    # define model
    model = keras.Model(inputs=input_vector, outputs = out_reg)

    # compile the keras model
    model.compile(loss= 'mse',
            metrics={'regression': 'mse'},optimizer= optimizer)

    return model

def build_model(hp):
    """
    Build a hyperparameter-tuned model using Keras Tuner.

    Args:
    - hp (keras_tuner.HyperParameters): Hyperparameters for the model.

    Returns:
    - model: Keras model.
    """
    units = hp.Int("units", min_value=32, max_value=64, step=32)
    num_layers = hp.Int("num_layers", 1, 2) 
    dropout = hp.Boolean("dropout")
    activation = hp.Choice("activation", ["relu", "tanh"])
    optimizer = hp.Choice("optimizer", ["adam", "SGD"])
    # call existing model-building code with the hyperparameter values.
    model = call_existing_code(units=units,num_layers=num_layers,dropout=dropout,activation=activation,optimizer=optimizer)
    return model

build_model(keras_tuner.HyperParameters())

# callbacks
early_stop = keras.callbacks.EarlyStopping(monitor='loss', patience=50, min_delta=0.000001,restore_best_weights=True,verbose = 1)

# Start the search
tuner = keras_tuner.GridSearch(
    hypermodel=build_model,
    objective="val_loss",
    max_trials=130,
    executions_per_trial=2,
    overwrite=False,
    directory="REGRESSION-ANN",
    project_name='NSA/'+model_name,
)

tuner.search_space_summary()
tuner.search(x_train, y_train, 
             validation_data=(x_val,y_val),epochs=1, batch_size=256,verbose=2,callbacks=[early_stop])
tuner.results_summary()

# Query the results 
models = tuner.get_best_models(num_models=30)
model = models[0]



# Re-Train the model
callbacks = [keras.callbacks.TensorBoard('tb_logs/'+model_name),early_stop]

tstart = timeit.default_timer()
model.fit(x_train, y_train, 
             validation_data=(x_val,y_val),epochs=1, batch_size=256,callbacks = callbacks,verbose=1)

tend = timeit.default_timer()
ETA = tend - tstart
print(f'{model_name} re-training time: {ETA:.2f}s')
model.save('models/'+model_name,overwrite= True)

# print model
print(model.summary())

# plot graph of model
keras.utils.plot_model(model, to_file='models/'+model_name+'.png', show_shapes=True)



# make predictions on test set
# eval_results
tstart = timeit.default_timer()
eval_results = model.evaluate(x_test,y_test,verbose=0)
tend = timeit.default_timer()
ETA = tend-tstart
print(f'Inference time: {ETA:.8f}s. Per iteration: {ETA/np.size(x_test):.8f}s')
print('MSE test set: %.3f' % eval_results[1])


# make predictions on total data set
# eval_results
eval_results = model.evaluate(x_train,y_train,verbose=0)

print('MSE train set: %.3f' % eval_results[1])

print('_________________________________________________________________________________________________')
print(f'Model trained and saved for the {model_name} SDM architecture')

exit('__________________________________________________________________________________________________')