from ultralytics import YOLO
import cv2

model = YOLO("C:/Users/pragy/prototype/ml_models/runs/detect/train2/weights/best.pt")

image_path = r"C:\Users\pragy\OneDrive\Pictures\Screenshots\Screenshot 2025-06-20 171233.png";
results = model(image_path)

annotated_img = results[0].plot() 
cv2.imshow('Detection', annotated_img)
cv2.waitKey(0)  
cv2.destroyAllWindows()
