/// A data failure with a [message] that is safe and helpful to show users.
/// Screens catch this type only — they never see HTTP status codes or JSON.
class DataException implements Exception {
  const DataException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The text to show users for any error: friendly for [DataException], generic otherwise.
String userMessage(Object error) =>
    error is DataException ? error.message : 'Something unexpected happened. Please try again.';
