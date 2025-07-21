this section contains the code for the Data Acquisition Module (DAM).   

DAM consists of:  
a. ESP32 S3 & EC200U both on the same board. its datasheet- https://evelta.com/content/datasheets/ESP32-S3-EC200U-2.0.pdf  
b. microSD card reader module & 32GB MicroSD card for logging data locally before transmission  
c. ESP32 Camera Module with OV2640 2MP Camera. also has a 4GB sd card on-board  
d. airtel sim card with a basic plan- Rs.200/month  

there are 3 different codes:  
a. one that goes into the esp32 board that collects, logs and transmits IMU data over cellular  
b. for the esp32 camera module that takes images continously and transmits them over wifi (for now)  
c. the server (flask) that receives the IMU data from ec200u via ngrok and logs it onto a csv file  

dataflow:  
--> esp32s3 continously collects and logs IMU data into the 32GB sd card.   
--> esp32 camera module takes images and sends them to a server using mobile hotspot.  
--> once the "boot" button is pressed on the esp32s3 board, collection of IMU data stops and it begins transmitting logged data to our local server via ngrok by HTTP.  
--> sd cards are cleared only after transmission is complete.  

power supply: both the esp32s3 and the camera module are powered from the USB jack on the car. 
