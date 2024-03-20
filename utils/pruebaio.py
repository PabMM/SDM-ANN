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