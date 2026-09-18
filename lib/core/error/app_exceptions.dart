/// Thrown when a gallery save is attempted without the necessary photo
/// permission, after an in-flow request was denied. Caught by the UI to
/// show the polished permission-explanation view instead of a raw error.
class PhotoPermissionDeniedException implements Exception {
  const PhotoPermissionDeniedException();
}
