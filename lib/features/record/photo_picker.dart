import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => ImagePickerPhotoPicker(ImagePicker()),
);

abstract class PhotoPicker {
  /// 撮った写真の一時ファイルのパス。キャンセル・カメラが使えないときはnull。
  Future<String?> takePhoto();

  Future<String?> pickFromGallery();

  /// Androidでカメラの起動中にアプリが終了させられたとき、撮った写真を取り戻す。
  Future<String?> retrieveLostPhoto();
}

class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker(this._picker);

  static const _maxSize = 2000.0;
  static const _quality = 85;

  final ImagePicker _picker;

  @override
  Future<String?> takePhoto() => _pick(ImageSource.camera);

  @override
  Future<String?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<String?> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: _maxSize,
        maxHeight: _maxSize,
        imageQuality: _quality,
      );
      return file?.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> retrieveLostPhoto() async {
    try {
      final response = await _picker.retrieveLostData();
      return response.file?.path;
    } catch (_) {
      return null;
    }
  }
}
