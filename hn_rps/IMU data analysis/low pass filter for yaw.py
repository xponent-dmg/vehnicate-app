import pandas as pd
import matplotlib.pyplot as plt
from scipy.signal import butter, filtfilt
import numpy as np
from scipy.fft import fft, fftfreq
import csv

# Load and slice
df = pd.read_csv(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\csv file with yaw.csv")
df.columns = ['time_ms', 'acc_x', 'acc_y', 'acc_z', 'gyro_x', 'gyro_y', 'gyro_z','Yaw']

df = df.iloc[13270:16506].copy()  # segment
#df = df.iloc[7722:10820].copy()
#df = df.iloc[6507:7177].copy()
#df = df.iloc[13264:16200].copy()


# Convert time
df["time_ms"] = pd.to_numeric(df["time_ms"], errors="coerce")
df["timestamp"] = pd.to_timedelta(df["time_ms"], unit="ms")
df = df.set_index("timestamp")

# Resample
fs = 50  # Hz
df_resampled = df.resample(f"{1000/fs}ms").mean()
df_resampled = df_resampled.interpolate()

# Butterworth low-pass filter
def butter_lowpass_filter(data, cutoff, fs, order=4):
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype='low')
    return filtfilt(b, a, data)


# --- FFT with detrending + window ---
#print(df_resampled["time_ms"],"hello")
y = df_resampled["Yaw"].values
N = len(y)
T = 1.0 / fs

# Detrend (remove mean)
y_detrended = y - np.mean(y)

# Apply Hann window
window = np.hanning(N)
y_win = y_detrended * window

# FFT
yf = fft(y_win)
xf = fftfreq(N, T)[:N//2]
#print(type(xf),"type_xf")
# Correct magnitude spectrum (single-sided, with window compensation)
magnitude = 2.0 / N * np.abs(yf[:N//2])
magnitude /= window.mean()   # compensate for Hann window loss

#print(np.mean(xf),'mean')
#sum_mag,count = 0,0
#sum_xf,count1=0,0
d_magnitude=[]
for i in range(len(xf)):
    try:
        d_magnitude.append(magnitude[i+1]-magnitude[i])
    except:
        d_magnitude.append(0)
        break

d_magnitude = np.array(d_magnitude)

#mask = magnitude > 0.02 #needs to be dynamically fixed
#xf = xf[mask]
#magnitude = magnitude[mask]
#d_magnitude = d_magnitude[mask]

a=(np.mean(xf*magnitude)/np.mean(magnitude))
#print((np.sqrt(np.mean(xf**2))+a)/2)
#print(np.mean(xf/np.sqrt(magnitude))*np.mean(magnitude),"this")

# --- Plot ---
#plt.figure(figsize=(10,5))
#plt.subplot(1,2,1)
#plt.plot(xf, magnitude, color="blue")
#plt.xlim(0, fs/2)   # up to Nyquist frequency
#plt.xlabel("Frequency [Hz]")
#plt.ylabel("Magnitude")
#plt.title("FFT of Yaw (detrended + Hann window)")
#plt.grid(True)
#plt.show()

#plt.subplot(1,2,2)
#plt.plot(xf,(np.exp(-1*xf*xf1))/(magnitude**magnitude))
#plt.xlabel("frequency")
#plt.ylabel("xf/magnitude")
#plt.show()

#print(((np.exp(-1*xf*xf1))/(magnitude**magnitude))[0],"testing")
#print(max((np.exp(-1*xf*xf1))/(magnitude**magnitude)),"max")


##########################################################################################
# the function that chooses the cutoff frequency from the fourier transform of yaw.
function = (np.exp(-1*xf*d_magnitude))/(magnitude**magnitude)
##########################################################################################


for i in range(len(function)):
    if function[i]>=max(function):
        cutoff = (xf[i])
        break


#cutoff = 0.04 # Hz (adjust this for yaw smoothing)
df_resampled["filtered"] = butter_lowpass_filter(df_resampled["Yaw"].values, cutoff, fs)
#print(np.mean(df_resampled["Yaw"]))

time = list(np.array(df_resampled.index.total_seconds()))
yaw = list(np.array(df_resampled["filtered"]))
data=[]
columns = ['time_ms','filtered yaw']
data.append(columns)
for i in range(len(time)):
    l = []
    l.append(time[i]*1000)
    l.append(yaw[i])
    data.append(l)

with open(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\filtered yaw.csv", "a", newline="") as file:
    writer = csv.writer(file)
    writer.writerows(data)
    


# Plot
plt.figure(figsize=(10,5))
plt.plot(df_resampled.index.total_seconds(), df_resampled["Yaw"], label="Original (resampled)")
plt.plot(df_resampled.index.total_seconds(), df_resampled["filtered"], label=f"Filtered (cutoff={cutoff}Hz)")
plt.legend()
plt.xlabel("Time [s]")
plt.ylabel("Yaw [deg]")  # or rad, depending on your data
plt.grid(True)
plt.show()
