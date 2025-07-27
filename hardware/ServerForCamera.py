from flask import Flask, request
import os

app = Flask(__name__)
UPLOAD_FOLDER = 'D:\Vehnicate\Prototype\data\images'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route('/upload', methods=['POST'])
def upload_image():
    image_file = request.files.get('file')
    if image_file:
        filename = image_file.filename   # This comes from ESP32
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        image_file.save(filepath)
        return 'Image received', 200
    return 'No image data received', 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
