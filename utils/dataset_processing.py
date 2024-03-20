# %% Dataset processing for training the classifiers and the RNNs
# P. Manrique, March 2024

# %% Libraries
import pandas as pd
import os

dirrepo = os.path.dirname(os.path.dirname(__file__))
os.chdir(dirrepo)

# %% Load datasets
# The default datasets folder name is 'DATASET0/'. If dataset files are in other folder, replace the next line by
# '<folder_name>/'. 
datasetrawfolder = 'DATASET-raw/'
datasetfolder = 'DATASET/'
datasetspath = 'utils/' + datasetrawfolder
datasetfiles = os.listdir(datasetspath)

dataframes = []

for file in datasetfiles:
    filepath = datasetspath + file
    dataframe = pd.read_csv(filepath)
    dataframes.append(dataframe)

# %% Filtering points by SNR

def filter_snr(df,snr_min,snr_max):
    snr = df['SNR']
    idx = (snr_min < snr) & (snr < snr_max)
    filtered_df = df[idx]
    return filtered_df

# SNR bounds

print('Specify SNR bounds. If inputs are not numbers, default values are (50,150) ')
try:
    snr_min = float(input('Minimum SNR value (dB): '))
    print('Your choice: {}'.format(snr_min))
except ValueError:
    snr_min = 50
    print('Input is not a number. Minimum SNR set to 50 dB.')

try:
    snr_max = float(input('Maximum SNR value (dB): '))
    print('Your choice: {}'.format(snr_max))
except ValueError:
    snr_min = 150
    print('Input is not a number. Maximum SNR set to 150 dB.')

filtereddataframes = [filter_snr(df,snr_min=snr_min,snr_max=snr_max) for df in dataframes]

# %% Saving RNN training datasets
# Dataframes in filtereddataframes are the datasets that we will use for training the networks
num_dfs = len(filtereddataframes)
rnndatasetspath = 'REGRESSION-ANN/' + datasetfolder

# Verifying if the directory exists. If not, create it
if not os.path.exists(rnndatasetspath):
    os.makedirs(rnndatasetspath)

print('\nSaving RNN datasets...\n')

for i in range(num_dfs):
    df = filtereddataframes[i]
    filename = rnndatasetspath + 'RNN_' + datasetfiles[i]
    df.to_csv(filename, index=False)

# %% Creating total dataset for classifiers training

# Obtaining dataframes with only specs columns
specs = ['SNR','Bw','Power']
specsdataframes = [df[specs] for df in filtereddataframes]

# The smallest dataset determines the size of the total dataset. We obtain a subset of each dataframe with as many rows as the smallest one
min_len = min([len(df) for df in specsdataframes])
sampleddataframes = [df.sample(n = min_len, random_state = 1) for df in specsdataframes]

# We add a categorical column corresponding to each model (dataset)
modelnames = [name.replace('.csv','') for name in datasetfiles]
modeldataframes = []
for i in range(num_dfs):
    df = sampleddataframes[i]
    name = modelnames[i]
    df['Category'] = name
    modeldataframes.append(df)

# Final result
df_total = pd.concat(modeldataframes)

print('Saving Classifiers dataset...\n')

# %% Saving total dataset
clsfpath = 'CLASSIFIERS/'
clsfdatasetpath = clsfpath + 'CLSF_total_dataset.csv'
df_total.to_csv(clsfdatasetpath, index=False)

# %% Plotting the final classifiers dataset
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

print('Generating and saving plots...\n')

fig = plt.figure(figsize=(15, 15))
ax = fig.add_subplot(221, projection='3d')

# Create a color palette for the categories
palette = sns.color_palette(n_colors=len(df_total['Category'].unique()))

# Plot each category separately with a legend
for i, cat in enumerate(df_total['Category'].unique()):
    subset = df_total[df_total['Category'] == cat]
    ax.scatter(subset['SNR'], np.log10(subset['Bw']), subset['Power'], label=cat, c=[palette[i]], s=10, alpha=0.5, marker='.')

# Set axis labels
ax.set_xlabel('SNR (dB)')
ax.set_ylabel('Bw (Hz, 10^)')
ax.set_zlabel('Power (W)')

ax2 = fig.add_subplot(224)

for i, cat in enumerate(df_total['Category'].unique()):
    subset = df_total[df_total['Category'] == cat]
    ax2.scatter(subset['SNR'], np.log10(subset['Bw']), label=cat, c=[palette[i]], s=10, alpha=0.5, marker='.')

ax2.set_xlabel('SNR (dB)')
ax2.set_ylabel('BW (Hz, 10^)')

ax3 = fig.add_subplot(223)

for i, cat in enumerate(df_total['Category'].unique()):
    subset = df_total[df_total['Category'] == cat]
    ax3.scatter(subset['Power'], np.log10(subset['Bw']), label=cat, c=[palette[i]], s=10, alpha=0.5, marker='.')

ax3.set_xlabel('Power (W)')
ax3.set_ylabel('BW (Hz, 10^)')

ax4 = fig.add_subplot(222)

for i, cat in enumerate(df_total['Category'].unique()):
    subset = df_total[df_total['Category'] == cat]
    ax4.scatter(subset['SNR'], subset['Power'], label=cat, c=[palette[i]], s=10, alpha=0.5, marker='.')

ax4.set_xlabel('SNR (dB)')
ax4.set_ylabel('Power (W)')


# Add a legend
legend = ax4.legend()
for handle in legend.legend_handles:
    handle.set_sizes([100])

# Title
plt.title(datasetfolder.replace('/',''))


# Save the plot
plotpath = 'CLASSIFIERS/plots/'
scatterpath = plotpath + 'scatter/CLSF_total_dataset_scatter.png'
plt.savefig(scatterpath)

plt.clf()

# %% FOM histogram
from math import log10

# Compute FOM
l = len(df_total)
fom = [0 for k in range(l)]

for i in range(l):
    snr = df_total.iat[i,0]
    bw = df_total.iat[i,1]
    power = df_total.iat[i,2]
    fom[i] = snr + 10*log10(bw/power)

fomdf = pd.DataFrame()

for i in range(5):
    fom_list = fom[min_len*i:min_len*(i+1)]
    fomdf[modelnames[i]] = fom_list

# Plot histogram
sns.histplot(data=fomdf, kde=True)

plt.xlabel('FOM (dB)')

plt.title(datasetfolder.replace('/',''))

# Saving data
histogrampath = plotpath + 'FOMhistogram/CLSF_total_dataset_histogram.png'
plt.savefig(histogrampath)