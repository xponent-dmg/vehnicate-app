#### vAlI- vehnicate Algorithm for IMU data analysis

#**************************************************************

import csv
import pandas as pd
import matplotlib.pyplot as plt
import math as m
import numpy as np
from scipy.fft import fft,fftfreq
from scipy.stats import skew,kurtosis
from scipy.signal import butter, sosfiltfilt, filtfilt


#**************************************************************
#### importing the raw drive data
#### timestamp- millisec
#### ax,ay,az- m/s2
#### gx,gy,gz- deg/sec
df = pd.read_csv("D:\\Vehnicate\\Prototype\\data\\testdrive5\\sensor.csv", header=None)
df.columns = ['time_ms', 'acc_x', 'acc_y', 'acc_z', 'gyro_x', 'gyro_y', 'gyro_z']

#**************************************************************

#### obtaining yaw, roll and pitch
l=len((df['time_ms']))
yaw,roll,pitch=0,0,0
Yaw,Roll,Pitch=[0.00001],[0.00001],[0.00001]
for i in range(1,l):
    yaw+=(df['time_ms'][i]-df['time_ms'][i-1])*df['gyro_z'][i]/1000
    roll+=(df['time_ms'][i]-df['time_ms'][i-1])*df['gyro_x'][i]/1000
    pitch+=(df['time_ms'][i]-df['time_ms'][i-1])*df['gyro_y'][i]/1000
    
    Yaw.append(yaw)
    Roll.append(roll)
    Pitch.append(pitch)

df['Yaw']=Yaw
df.to_csv(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\csv file with yaw.csv", index=False)
# the file now has an additional column - yaw i.e, the vehicle's heading angle at any given instant



#**************************************************************
#### chunking.
def Chunking(df):
    l = len(df['time_ms'])-1
    def_ChunkSize=10
    pointer=0 #points to the beginning of the next chunk.
    end=False
    Chunks={}
    while not end:
        initial_pointer=pointer
        #s=df['Yaw'][initial_pointer]

        if abs(float(df['gyro_z'][pointer+def_ChunkSize-1]))<= 0.05: #0.5 degree
            pointer+=def_ChunkSize
        else:
            initialPointer = pointer
            y1 = float(df['Yaw'][initialPointer])
            pointer+=def_ChunkSize
            y2 = float(df['Yaw'][pointer])
            i_dYaw = (y2 -y1)#/(df['time_ms'][initialPointer]-df['time_ms'][pointer])
            f_dYaw = i_dYaw
            #try:
            q=abs(float(df['gyro_z'][pointer+1])) #increment by 1. this is the equivalent of having the def_ChunkSize as 1.
            #except:
            #    print("this is the last one",df['gyro_z'][pointer])
            while q >= 0.05 and f_dYaw * i_dYaw > 0 and pointer+5<l-1:
                y1 = float(df['Yaw'][pointer])
                y2 = float(df['Yaw'][pointer+5])
                f_dYaw = (y2 -y1)
                pointer += 5
                try:
                    q=abs(float(df['gyro_z'][pointer]))
                except:
                    q = 0
        #e=df['Yaw'][pointer-1]
            
        
        if def_ChunkSize>l-pointer-1:
            def_ChunkSize=l-pointer
            end=True
            pointer+=def_ChunkSize #points to the start of the beginning of the next chunk.
            
        Chunks[initial_pointer] = pointer-1
    return Chunks


#Chunks = [start index: end index]



#**************************************************************
#### computing the statistics of the CHUNKS
def ChunksStats(df):
    Chunks = Chunking(df)
    Chunks01={}
    for i in Chunks:
        l=[]
        l.append(i)
        l.append(Chunks[i])
        #computing the statistics of gyro_z for each chunk
        Chunks01[(
            (i,Chunks[i]),
            (df['time_ms'][i],df['time_ms'][Chunks[i]])
            )] = [] #this is the placeholder for mean,std,var,skew,kurtosis
        
        #appending the number of ROWS in each chunk
        Chunks01[
            (i,Chunks[i]),
            (df['time_ms'][i],df['time_ms'][Chunks[i]])
            ].append(Chunks[i]-i+1)
        
        #appending the lifetime of that chunk in milliseconds
        Chunks01[
            (i,Chunks[i]),
            (df['time_ms'][i],df['time_ms'][Chunks[i]])
            ].append(df['time_ms'][Chunks[i]] - df['time_ms'][i])
        
        #appending the change in yaw during that chunk
        Chunks01[
            (i,Chunks[i]),
            (df['time_ms'][i],df['time_ms'][Chunks[i]])
            ].append(df['Yaw'][Chunks[i]] - df['Yaw'][i])
        #add mean
        l_gz=[]
        l_gz.append(np.mean(df['gyro_z'][i:Chunks[i]+1]))

        #add population standard deviation
        l_gz.append(np.std(df['gyro_z'][i:Chunks[i]+1],ddof=0))

        #add variance
        l_gz.append(np.var(df['gyro_z'][i:Chunks[i]+1],ddof=0))

        #add skewness
        l_gz.append(skew(df['gyro_z'][i:Chunks[i]+1],bias=False))

        #add kurtosis
        l_gz.append(kurtosis(df['gyro_z'][i:Chunks[i]+1],fisher=True))

        Chunks01[(i,Chunks[i]),
            (df['time_ms'][i],df['time_ms'][Chunks[i]])].append(l_gz)
    return Chunks01

Chunks01=ChunksStats(df)
#Chunks01 = {(("chunkStart_index","chunkEnd_index"),("chunkStart_time","chunkEnd_time")):[lengthOfChunk, lifetime, D_Yaw,[meanGyroZ,std,var,skew,kurtosis]]}

#**************************************************************
#### based on the chunks, make partitions of the drive.
#### each partition roughly represents the portions of the drive that were straight.

def partitioning(Chunks01):
    partitions,l = [],[]
    for i in Chunks01:
        #l = []
        #print(Chunks01[i][2])
        if abs(Chunks01[i][2])<30: #delta yaw
            l.append(i[0][0])
            l.append(i[0][1])
        else:
            try:
                x=[]
                x.append(l[0])
                x.append(l[-1])
                x.append(df['time_ms'][l[0]])
                x.append(df['time_ms'][l[-1]])
                #l = list(l[0],l[-1],df['time_ms'][l[0]],df['time_ms'][l[-1]])
                partitions.append(x)
                l = []
                #l.append(i[0][0])
            except:
                continue
    return partitions
partitions = partitioning(Chunks01)
#partitions = [[partition start, partition end, time start, time end],[....],...]
data=[]
columns = ['partition start','partition end','strt time','end time']
data.append(columns)
for i in partitions:
    l = []
    l.append(i[0])
    l.append(i[1])
    l.append(df['time_ms'][i[0]])
    l.append(df['time_ms'][i[1]])
    data.append(l)

with open(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\partitions start & end.csv", "w", newline="") as file:
    writer = csv.writer(file)
    writer.writerows(data)


def filtered_yaw(df,l,u):
    df1 = df
    df = df.iloc[l:u].copy()  # partition

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
        if len(data) <= 3 * max(len(a), len(b)):  # filtfilt padlen check
            return data  # or np.zeros_like(data)
        else:
            return filtfilt(b, a, data)


    # --- FFT with detrending + window ---
    #print(df_resampled["time_ms"],"hello")
    gyroscope_z = df_resampled["gyro_z"].values
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
            #d_magnitude.append(magnitude[i+1]-magnitude[i])
            d_magnitude.append(magnitude[i+1]-magnitude[i])
        except:
            d_magnitude.append(0)
            break

    d_magnitude = np.array(d_magnitude)

    #mask = magnitude > 0.02 #needs to be dynamically fixed
    #xf = xf[mask]
    #magnitude = magnitude[mask]
    #d_magnitude = d_magnitude[mask]

    #a=(np.mean(xf))
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
    
    if cutoff <= 0 and l+10<=u:
        print(cutoff)
        l+=10
        filtered_yaw(df1,l,u)
        print("hello",l,u,df1['time_ms'][l])
        return None
    
    df_resampled["filtered"] = butter_lowpass_filter(df_resampled["Yaw"].values, cutoff, fs)
    #print(np.mean(df_resampled["Yaw"]))

    time = list(np.array(df_resampled.index.total_seconds()))
    yaw = list(np.array(df_resampled["filtered"]))
    gyroscope_z = list(np.array(df_resampled["gyro_z"]))
    data=[]
    for i in range(len(time)):
        l = []
        l.append(time[i]*1000)
        l.append(gyroscope_z[i])
        l.append(yaw[i])
        data.append(l)
    with open(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\filtered yaw for each partition.csv", "a", newline="") as file:
        writer = csv.writer(file)
        writer.writerows(data)
        #writer.writerows('\n'*5)

    # Plot
    #plt.figure(figsize=(10,5))
    #plt.plot(df_resampled.index.total_seconds(), df_resampled["Yaw"], label="Original (resampled)")
    #plt.plot(df_resampled.index.total_seconds(), df_resampled["filtered"], label=f"Filtered (cutoff={cutoff}Hz)")
    #plt.legend()
    #plt.xlabel("Time [s]")
    #plt.ylabel("Yaw [deg]")  # or rad, depending on your data
    #plt.grid(True)
    #plt.show()


data=[]
columns = ['time_ms','gyro_z','Yaw']
data.append(columns)
with open(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\filtered yaw for each partition.csv", "a", newline="") as file:
    writer = csv.writer(file)
    writer.writerows(data)


for i in range(len(partitions)):
    print(df['time_ms'][partitions[i][0]],df['time_ms'][partitions[i][1]],"start")
    if i == len(partitions)-1:
        a = partitions[i][0]
    else:
        a = partitions[i+1][0]
    filtered_yaw(df,partitions[i][0],partitions[i][1]) #data is written into above opened file within the function "filtered_yaw"

    # insert the transition blocks in the file - unfiltered yaw.
    data = []
    for i in range(partitions[i][1]+1,a):
        l =[]
        l.append(df['time_ms'][i])
        l.append(df['gyro_z'][i])
        l.append(df['Yaw'][i])
        data.append(l)
    with open(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\filtered yaw for each partition.csv", "a", newline="") as file:
        writer = csv.writer(file)
        writer.writerows(data)
print("all done")


# Chunking for identification of lane changes
df_filtered = pd.read_csv(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\filtered yaw for each partition.csv")
df_filtered.columns = ['time_ms', 'gyro_z','Yaw']

filteredChunks = Chunking(df_filtered)

plt.plot(df_filtered['time_ms'],df_filtered['Yaw'], label='filtered yaw')
plt.plot(df['time_ms'],df['Yaw'],label = 'og yaw')
plt.xlabel('Time (ms)')
plt.ylabel('Angle (degrees))')
plt.legend()

for i in filteredChunks:
    plt.plot(df_filtered['time_ms'][i],df_filtered['Yaw'][i],marker='o',color='green')
    plt.plot(df_filtered['time_ms'][filteredChunks[i]],df_filtered['Yaw'][filteredChunks[i]],marker='o',color='red')
plt.grid(True)
plt.tight_layout()
plt.show()



