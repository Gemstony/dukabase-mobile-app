/// Result of a Firestore write that may sync to the server later.
class RecordWriteResult {
  final bool success;
  final bool pendingSync;

  const RecordWriteResult({
    required this.success,
    this.pendingSync = false,
  });
}
