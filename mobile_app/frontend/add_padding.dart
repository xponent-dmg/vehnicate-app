import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  // Read the original logo
  final originalFile = File('assets/vehnicate_logo.png');
  final originalBytes = await originalFile.readAsBytes();
  final originalImage = img.decodeImage(originalBytes);
  
  if (originalImage == null) {
    print('Error: Could not decode image');
    return;
  }

  // Calculate new size with 30% padding on each side (60% total padding)
  // Original will be 70% of new size, with 15% padding on each side
  final originalWidth = originalImage.width;
  final originalHeight = originalImage.height;
  final newWidth = (originalWidth / 0.7).round();
  final newHeight = (originalHeight / 0.7).round();
  
  // Create new image with transparent/dark background
  final newImage = img.Image(width: newWidth, height: newHeight);
  
  // Fill with dark background color (#1a1a1a)
  img.fill(newImage, color: img.ColorRgb8(26, 26, 26));
  
  // Calculate position to center the original image
  final offsetX = ((newWidth - originalWidth) / 2).round();
  final offsetY = ((newHeight - originalHeight) / 2).round();
  
  // Composite the original image onto the new image
  img.compositeImage(newImage, originalImage, dstX: offsetX, dstY: offsetY);
  
  // Save the padded image
  final paddedFile = File('assets/vehnicate_logo_padded.png');
  await paddedFile.writeAsBytes(img.encodePng(newImage));
  
  print('✓ Created padded icon: ${paddedFile.path}');
  print('  Original size: ${originalWidth}x$originalHeight');
  print('  New size: ${newWidth}x$newHeight');
}
