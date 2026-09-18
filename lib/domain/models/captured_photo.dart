/// A photograph captured through Help me Pose and saved to the device
/// gallery, plus the bookkeeping needed to show it in "Recent Captures".
class CapturedPhoto {
  const CapturedPhoto({
    required this.id,
    required this.filePath,
    required this.capturedAt,
    this.galleryAssetId,
    this.poseIdUsed,
    this.width,
    this.height,
  });

  final String id;

  /// Local app-cache copy of the saved photo, used for fast thumbnail
  /// display in-app without repeatedly querying the system photo library.
  final String filePath;
  final DateTime capturedAt;

  /// Identifier of the asset in the system photo library, if available.
  final String? galleryAssetId;

  /// The pose reference (if any) that was active as an alignment guide when
  /// this photo was captured. Recorded for the user's own reference only.
  final String? poseIdUsed;
  final int? width;
  final int? height;

  factory CapturedPhoto.fromJson(Map<String, dynamic> json) {
    return CapturedPhoto(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      galleryAssetId: json['galleryAssetId'] as String?,
      poseIdUsed: json['poseIdUsed'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    'capturedAt': capturedAt.toIso8601String(),
    'galleryAssetId': galleryAssetId,
    'poseIdUsed': poseIdUsed,
    'width': width,
    'height': height,
  };
}
