import 'TrackableDocument_class.dart';

class DocumentRecord {
  String holder;
  DateTime date; // Keeping this as requested
  DocumentStatus status; // Enum-based status tracking
  String remarks;
  String? receiverKey; // Optional field
  List<bool>? checklistStatus;
  List<String> imageRefs;

  DocumentRecord({
    required this.holder,
    required this.date,
    required this.status,
    required this.remarks,
    this.receiverKey, // Optional receiverKey
    this.checklistStatus,
    required this.imageRefs,
  });

  // Convert DocumentRecord to JSON
  Map<String, dynamic> toJson() {
    return {
      'holder': holder,
      'date': date.toIso8601String(),
      'status': status.name, // Store as a string
      'remarks': remarks,
      'receiverKey': receiverKey, // Include receiverKey if not null
      'checklistStatus': checklistStatus ?? [], // Ensure it's always a list
      'imageRefs': imageRefs, // Include imageRefs
    };
  }

  // Create DocumentRecord from JSON
  factory DocumentRecord.fromJson(Map<String, dynamic> data) {
    return DocumentRecord(
      holder: data['holder'] ?? '',
      date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
      status: DocumentStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'onHold'),
        orElse: () => DocumentStatus.onHold,
      ),
      remarks: data['remarks'] ?? '',
      receiverKey: data['receiverKey'], 
      checklistStatus: data['checklistStatus'] != null
          ? List<bool>.from(data['checklistStatus'])
          : null, // Ensure checklistStatus is always a list
      imageRefs: List<String>.from(data['imageRefs'] ?? []),
    );
  }
}
