import 'package:image_picker/image_picker.dart';

import 'storefront_editor_screen.dart';

/// Normalizes a picked file name or path, appending `.jpg` when missing an extension.
String normalizePickedPhotoFilename(String rawNameOrPath) {
  final trimmed = rawNameOrPath.trim();
  if (trimmed.isEmpty) {
    return 'gym_photo.jpg';
  }
  final segments = trimmed.split(RegExp(r'[/\\]'));
  final basename = segments.last.trim();
  if (basename.isEmpty) {
    return 'gym_photo.jpg';
  }
  if (!basename.contains('.') || basename.endsWith('.')) {
    return '${basename.replaceAll(RegExp(r'\.+$'), '')}.jpg';
  }
  return basename;
}

/// Picks and natively compresses a gym storefront photo from the device gallery.
Future<PickedGymPhoto?> pickGymPhotoFromGallery({
  ImagePicker? picker,
  ImageSource source = ImageSource.gallery,
}) async {
  final effectivePicker = picker ?? ImagePicker();
  final XFile? file = await effectivePicker.pickImage(
    source: source,
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 85,
    requestFullMetadata: false,
  );
  if (file == null) {
    return null;
  }

  final bytes = await file.readAsBytes();
  final rawName = file.name.isNotEmpty ? file.name : file.path;
  return (bytes: bytes, filename: normalizePickedPhotoFilename(rawName));
}
