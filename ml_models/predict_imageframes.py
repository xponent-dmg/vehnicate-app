from ultralytics import YOLO
import cv2
import glob
import os

print("Script started")

model = YOLO(r"C:\Users\pragy\Downloads\new-best.pt")
image_folder = r"C:\Users\pragy\prototype\ml_models\new_images_cumta"
image_paths = sorted(glob.glob(os.path.join(image_folder, "*.jpg")))

print("Found images:", image_paths)
target_width, target_height = 960, 540

if not image_paths:
    exit()

for image_path in image_paths:
    print("Processing:", image_path)
    img = cv2.imread(image_path)
    if img is None:
        print(f"Failed to load {image_path}")
        continue
    height, width = img.shape[:2]
    results = model.predict(source=img, imgsz=(width, height), rect=True)
    annotated_img = results[0].plot()

    annotated_img_resized = cv2.resize(annotated_img, (target_width, target_height))

    cv2.imshow('YOLO Frame Playback', annotated_img_resized)
    if cv2.waitKey(10) & 0xFF == ord('q'):
        break

cv2.destroyAllWindows()
print("Playback done.")
