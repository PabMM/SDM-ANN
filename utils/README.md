# Data processing

The script `dataset_processing.py` loads the datasets in the directory `utils/DATASET0/`.

## Filtering by SNR: RNN datasets

For each given dataset, we create a new dataset whose points are those such that SNR_min < SNR < SNR_max. These bounds must by specified by the user (default values are (50,150)).

The obtained datasets will be used to train the RNN; `dataset_processing.py` saves them in the folder `REGRESSION-ANN/DATASET0/`.

## Total classifiers dataset

Once the datasets points have been filtered by SNR, we obtain a total dataset consisting of the specifications columns and a categorical column corresponding to each original dataset. The different classes are balanced: each class contains the same number of points.

This total dataset will be used to train the classifiers, so it is saved in the folder `CLASSIFIERS/`.
