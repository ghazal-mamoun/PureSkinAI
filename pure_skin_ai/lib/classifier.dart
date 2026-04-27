import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class SkinClassifier {
  Interpreter? _interpreter;
  List<String>? _labels;

  // تحميل النموذج والملصقات من مجلد assets
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      print("Model and Labels loaded successfully ✅");
    } catch (e) {
      print("Error loading model: $e ❌");
    }
  }

  // تحويل الصورة لتناسب مدخلات النموذج (Normalization)
  Uint8List _imageToByteListFloat32(img.Image image) {
    var convertedBytes = Float32List(1 * 224 * 224 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    
    for (int i = 0; i < 224; i++) {
      for (int j = 0; j < 224; j++) {
        var pixel = image.getPixel(j, i);
        
        // تحويل قيم البكسلات إلى نطاق بين -1 و 1
        buffer[pixelIndex++] = (pixel.r / 127.5) - 1.0;
        buffer[pixelIndex++] = (pixel.g / 127.5) - 1.0;
        buffer[pixelIndex++] = (pixel.b / 127.5) - 1.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  // دالة تحليل الصورة واستخراج النتائج
  Future<List<Map<String, dynamic>>> predict(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      print("Interpreter or Labels are null!");
      return [];
    }

    // معالجة وتحجيم الصورة لـ 224x224
    final imageData = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return [];

    img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);
    var input = _imageToByteListFloat32(resizedImage);
    var output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

    // تشغيل نموذج الذكاء الاصطناعي
    _interpreter!.run(input, output);
    
    print("Raw Output from AI: ${output[0]}");

    List<Map<String, dynamic>> results = [];

    for (int i = 0; i < _labels!.length; i++) {
      double confidence = output[0][i];
      
      print("Check -> Label: ${_labels![i]}, Confidence: $confidence");

      // المنطق المطلوب:
      // الفئة الأولى (مثل Acne) تظهر إذا كانت النسبة أكبر من 1%
      if (i == 0) {
        if (confidence > 0.01) {
          results.add({
            'label': _labels![i],
            'score': (confidence * 100).toStringAsFixed(1)
          });
        }
      } 
      // الفئات الإضافية (Oily, Dry) لا تظهر إلا إذا كانت أكبر من 35%
      else {
        if (confidence > 0.05) { 
          results.add({
            'label': _labels![i],
            'score': (confidence * 100).toStringAsFixed(1)
          });
        }
      }
    }

    print("Final Results List: $results");
    return results;
  }
}