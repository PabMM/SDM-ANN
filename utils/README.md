# Data processing

The script `dataset_processing.py` loads the datasets in the directory `utils/DATASET0/`. To use a different set of datasets, it is enough to add a new directory `utils/<new_dir_name>/` containing the new `.csv` files and change the folder name in line 14.

## Filtering by SNR: RNN datasets

For each given dataset, we create a new dataset whose points are those such that 50 < SNR < 150. These bounds can also be modified in lines 34 and 35.

The obtained datasets will be used to train the RNN; `dataset_processing.py` saves them in the folder `REGRESSION-ANN/DATASET0/`. Of course, if we are using another folder, it will create the corresponding subfolder in `REGRESSION-ANN/`.

## Total classifiers dataset

Once the datasets points have been filtered by SNR, we obtain a total dataset consisting of the specifications columns and a categorical column corresponding to each original dataset. The different classes are balanced: each class contains the same number of points.

This total dataset will be used to train the classifiers, so it is saved in the folder `CLASSIFIERS/`.
