import pandas as pd
import matplotlib.pyplot as plt
import math as m
from scipy.fft import fft,fftfreq
import numpy as np
import math
from scipy.stats import skew,kurtosis
import csv
from scipy.signal import butter, sosfiltfilt

# Load CSV
df = pd.read_csv("D:\\Vehnicate\\Prototype\\data\\testdrive5\\sensor.csv", header=None)
df.columns = ['time_ms', 'acc_x', 'acc_y', 'acc_z', 'gyro_x', 'gyro_y', 'gyro_z']

#to obtain roll, pitch and yaw---------------
l=len((df['time_ms']))
yaw,roll,pitch=0,0,0
Yaw,Roll,Pitch=[0],[0],[0]
#print(df['time_ms'][8855])
vx,vy,vz=0,0,0
Vx,Vy,Vz=[],[],[]
x,y=0,0
X,Y={},{}
r=0
T={}
length=0
velocity=0.4*(5/18) #40kmph-->mps
a=[1]*l #weights for ML model
yaw_time={}
for i in range(1,l):
    
    if ((df['acc_x'][i])<=0.05 and (df['acc_x'][i])>=0) or ((df['acc_x'][i])>=-0.05 and (df['acc_x'][i])<=0):
        acc_x=0
    else:
        acc_x=df['acc_x'][i]

    if abs(df['acc_y'][i])<=0.09:
        acc_y=0
    else:
        acc_y=df['acc_y'][i]

    if abs(df['acc_z'][i])<=0.05:
        acc_z=0
    else:
        acc_z=df['acc_z'][i]
    
    yaw+=(df['time_ms'][i]-df['time_ms'][i-1])*df['gyro_z'][i]/1000
    roll+=(df['time_ms'][i]-df['time_ms'][i-1])*df['gyro_x'][i]/1000
    pitch+=(df['time_ms'][i]-df['time_ms'][i-1])*df['gyro_y'][i]/1000
    
    vx+=(df['time_ms'][i]-df['time_ms'][i-1])*acc_x/1000
    vy+=(df['time_ms'][i]-df['time_ms'][i-1])*acc_y/1000
    vz+=(df['time_ms'][i]-df['time_ms'][i-1])*acc_z/1000
    
    
    Vx.append(vx)
    Vy.append(vy)
    Vz.append(vz)
    #r+=((df['time_ms'][i]-df['time_ms'][i-1])*vx)/1000
    r=a[i]*1
    x+=r*m.cos(m.radians(yaw))
    y+=r*m.sin(m.radians(yaw))
    #x=1*m.cos(m.radians(yaw))
    #y=1*m.sin(m.radians(yaw))
    #X.append(x)
    #Y.append(y)
    
    X[i]=x
    Y[i]=y
    Yaw.append(yaw)
    Roll.append(roll)
    Pitch.append(pitch)
    T[i]=(df['time_ms'][i])
    length+=1
    yaw_time[df['time_ms'][i-1]]=yaw
    #print(i)
#print(l,'-------',df['time_ms'][0])
#print(len(Yaw),'\t',len(df['time_ms']))
LabelledData={} #"timeframe" : " label-sta/st/lt/rt/la/ra/u "
df['Yaw']=Yaw
df.to_csv(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\csv file with yaw.csv", index=False)



'''
plt.figure(figsize=(12, 6))
#plt.plot(df['time_ms'], Roll, label='Gyro X')
plt.plot(T.values(), Vx, label='vel X')
#plt.plot(T.values(), Vy, label='vel Y')
#plt.plot(T.values(), Vz, label='vel Z')
plt.title('Vehicle heading angle vs Time')
plt.xlabel('Time (ms)')
plt.ylabel('Angle (degrees))')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()
'''

def_ChunkSize=10
pointer=0 #points to the beginning of the next chunk.
end=False
Chunks={}
while not end:
    initial_pointer=pointer
    s=df['Yaw'][initial_pointer]

    if abs(df['gyro_z'][pointer]-df['gyro_z'][pointer+def_ChunkSize-1])<= 0.1: #0.5 degree
        pointer+=def_ChunkSize
    else:
        pointer+=def_ChunkSize
        
        q=abs(df['gyro_z'][pointer+1]) #increment by 1. this is the equivalent of having the def_ChunkSize as 1.
        
        while q >= 0.2:
            pointer+=1 #def_ChunkSize
            q=abs(df['gyro_z'][pointer])
    e=df['Yaw'][pointer-1]
        
    
    if def_ChunkSize>l-pointer-1:
        def_ChunkSize=l-pointer
        end=True
        pointer+=def_ChunkSize #points to the start of the beginning of the next chunk.
        
    Chunks[initial_pointer] = pointer-1
#print(Chunks)



#############################################################################

#############################################################################


L=len(df['time_ms'])
Chunks_lanes={}
# **merging 2 arc chunks to together form potential lane change**
i1=0
e1=Chunks[i1]
i2 = e1+1
e2 = Chunks[i2]
d_yaw1 = abs(df['Yaw'][e1]-df['Yaw'][i1])
d_yaw2 = abs(df['Yaw'][e2]-df['Yaw'][i2])
while True:
    initial_yaw=df['Yaw'][i1]
    while abs(e1-i1>9) and abs(e2-i2>9) and (d_yaw1 < 30) and (d_yaw1 > 1.5) and (d_yaw2 < 30) and (d_yaw2 > 1.5):# and abs(df['Yaw'][e2] - df['Yaw'][i1]) < 2:
        print(df['time_ms'][e1])
        Chunks_lanes[i1] = e2
        del Chunks[i1]
        i1 = i2
        e1=Chunks[i1]
        i2 = e1+1
        try:
            e2 = Chunks[i2]
            if df['Yaw'][e2]>initial_yaw:
                print(df['time_ms'][e2])
                #print(df['time_ms'][i1])
                #print(df['time_ms'][i2])
                for i in range(i2,e2):
                    if df['yaw'][i]==i1:
                        e2 = i
        except:
            break
        d_yaw1 = abs(df['Yaw'][e1]-df['Yaw'][i1])
        d_yaw2 = abs(df['Yaw'][e2]-df['Yaw'][i2])
    #else:
    #    i1=i2
    i1 = i2
    e1=Chunks[i1]
    i2 = e1+1
    try:
        e2 = Chunks[i2]
    except:
        break
    d_yaw1 = abs(df['Yaw'][e1]-df['Yaw'][i1])
    d_yaw2 = abs(df['Yaw'][e2]-df['Yaw'][i2])

################## "Chunks" is where the chunks are stored. Format- dictionary with:
################## key = starting position of each chunk (index starts from 0),
################## value = ending position of that chunk.

# this now moves down to the next function block as Pragya and I designed. i.e., computing the "INFO" of the gyro_z (& yaw)
# of all the chunks.

#re-formatting the "Chunks"
# new format- Chunks={[start, end]:[end-start+1(length of chunk), [mean, sd, variance, skewness, time autocorrelation, etc](of gyro_z),[mean,sd,var,etc](of yaw)],...}

Chunks01={}
road_curvature=[]
initial = 0
for i in Chunks:
    #approximating the road curvature wrt time
    initYaw = df['Yaw'][initial]
    #if df['Yaw'][Chunks[i]]-initYaw >
    l=[]
    l.append(i)
    l.append(Chunks[i])
    if Chunks[i]-i>9:
        l.append(min(df['Yaw'][i],df['Yaw'][Chunks[i]]))
    else:
        l.append(np.mean(df['Yaw'][i:Chunks[i]+1]))
    road_curvature.append(l)

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

#for i in Chunks01:
#    print(i, '\t',Chunks01[i])
#print(len(Chunks01))

### plotting data
#plt.subplot(2,1,1)
plt.plot(df['time_ms'],Yaw, label='yaw')
plt.plot(df['time_ms'],Roll, label='roll')
plt.plot(df['time_ms'],Pitch, label='pitch')
plt.xlabel('Time (ms)')
plt.ylabel('Angle (degrees))')
plt.legend()

for i in Chunks:
    plt.plot(df['time_ms'][i],df['Yaw'][i],marker='o',color='green')
    plt.plot(df['time_ms'][Chunks[i]],df['Yaw'][Chunks[i]],marker='o',color='red')
#for i in Chunks_lanes:
    #plt.plot(df['time_ms'][i],df['Yaw'][i],marker='o',color='blue')
    #plt.plot(df['time_ms'][Chunks_lanes[i]],df['Yaw'][Chunks_lanes[i]],marker='o',color='yellow')
plt.grid(True)
plt.tight_layout()
plt.show()




#format of the content stores in chunk01:
#((30607, 30616), (733402, 733637))       [10, [-0.012, 0.009797958971132713, 9.6e-05, 1.2405649780820631, -0.010416666666667407]]
#((30617, 30632), (733663, 734057))       [16, [-0.014375, 0.011162856937182344, 0.000124609375, -0.17363172479309066, -1.3333791924214582]]

data = []
columns = ['ChunkStart_index','ChunkEnd_index','ChunkStart_time','ChunkEnd_time','ChunkSize','ChunkLifetime','d(yaw)','mean_gz','std_gz','var_gz','skewness_gz','kurtosis_gz']
data.append(columns)
for i in Chunks01:
    l = []
    l.append(i[0][0])
    l.append(i[0][1])
    l.append(i[1][0])
    l.append(i[1][1])
    l.append(Chunks01[i][0])
    l.append(Chunks01[i][1])
    l.append(Chunks01[i][2])
    l.append(Chunks01[i][3][0])
    l.append(Chunks01[i][3][1])
    l.append(Chunks01[i][3][2])
    l.append(Chunks01[i][3][3])
    l.append(Chunks01[i][3][4])
    data.append(l)
with open(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\statistics of testdrive.csv", "w", newline="") as file:
    writer = csv.writer(file)
    writer.writerows(data)


#############statistics of potential lane changes
Chunks01={}
for i in Chunks_lanes:
    Chunks01[(
        (i,Chunks_lanes[i]),
        (df['time_ms'][i],df['time_ms'][Chunks_lanes[i]])
        )] = [] #this is the placeholder for mean,std,var,skew,kurtosis
    
    #appending the number of ROWS in each chunk
    Chunks01[
        (i,Chunks_lanes[i]),
        (df['time_ms'][i],df['time_ms'][Chunks_lanes[i]])
        ].append(Chunks_lanes[i]-i+1)
    
    #appending the lifetime of that chunk in milliseconds
    Chunks01[
        (i,Chunks_lanes[i]),
        (df['time_ms'][i],df['time_ms'][Chunks_lanes[i]])
        ].append(df['time_ms'][Chunks_lanes[i]] - df['time_ms'][i])
    
    #appending the change in yaw during that chunk
    Chunks01[
        (i,Chunks_lanes[i]),
        (df['time_ms'][i],df['time_ms'][Chunks_lanes[i]])
        ].append(df['Yaw'][Chunks_lanes[i]] - df['Yaw'][i])
    #add mean
    l_gz=[]
    l_gz.append(np.mean(df['gyro_z'][i:Chunks_lanes[i]+1]))

    #add population standard deviation
    l_gz.append(np.std(df['gyro_z'][i:Chunks_lanes[i]+1],ddof=0))

    #add variance
    l_gz.append(np.var(df['gyro_z'][i:Chunks_lanes[i]+1],ddof=0))

    #add skewness
    l_gz.append(skew(df['gyro_z'][i:Chunks_lanes[i]+1],bias=False))

    #add kurtosis
    l_gz.append(kurtosis(df['gyro_z'][i:Chunks_lanes[i]+1],fisher=True))

    Chunks01[(i,Chunks_lanes[i]),
        (df['time_ms'][i],df['time_ms'][Chunks_lanes[i]])].append(l_gz)


data = []
columns = ['ChunkStart_index','ChunkEnd_index','ChunkStart_time','ChunkEnd_time','ChunkSize','ChunkLifetime','d(yaw)','mean_gz','std_gz','var_gz','skewness_gz','kurtosis_gz']
data.append(columns)
for i in Chunks01:
    l = []
    l.append(i[0][0])
    l.append(i[0][1])
    l.append(i[1][0])
    l.append(i[1][1])
    l.append(Chunks01[i][0])
    l.append(Chunks01[i][1])
    l.append(Chunks01[i][2])
    l.append(Chunks01[i][3][0])
    l.append(Chunks01[i][3][1])
    l.append(Chunks01[i][3][2])
    l.append(Chunks01[i][3][3])
    l.append(Chunks01[i][3][4])
    data.append(l)
with open(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\statistics of potential lane changes.csv", "w", newline="") as file:
    writer = csv.writer(file)
    writer.writerows(data)


########statistics of non-straight chunks (also includes potential lane changes ofc)
df1 = pd.read_csv(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\statistics of testdrive.csv", header=None)
df1.columns = columns
l1 = len(df1)
#print(df1['ChunkSize'][1])


#creating a csv file only with entries that have larger chunk size (>10)
data=[]
columns = ['ChunkStart_index','ChunkEnd_index','ChunkStart_time','ChunkEnd_time','ChunkSize','ChunkLifetime','d(yaw)','mean_gz','std_gz','var_gz','skewness_gz','kurtosis_gz']
data.append(columns)
for i in range(1, l1):
    #print(df1['ChunkSize'][1])
    if (int(df1['ChunkSize'][i])>10):
        data.append(df1.iloc[i])
with open(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\statistics of non-st chunks.csv", "w", newline="") as file:
    writer = csv.writer(file)
    writer.writerows(data)





