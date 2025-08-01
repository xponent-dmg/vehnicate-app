from ultralytics import YOLO
import cv2

model = YOLO(r"C:\Users\pragy\Downloads\new-best.pt")

image_path = r"C:\Users\pragy\prototype\ml_models\assets\trial9.jpg"

img = cv2.imread(image_path)
height, width = img.shape[:2]

results = model.predict(
        source=img,
        imgsz=(width, height),  
        rect=True               
    )


annotated_img = results[0].plot() 
annotated_img_resized = cv2.resize(annotated_img, (960,540))
cv2.imshow('Detection', annotated_img_resized)
cv2.waitKey(0)  
cv2.destroyAllWindows()
