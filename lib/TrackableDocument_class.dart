// Enum for Document Status
import 'package:footprint3/DocumentRecord_class.dart';
import 'package:footprint3/HolderTracker_class.dart';
import 'package:footprint3/database_helper.dart';

enum DocumentStatus {
  registered,
  onHold,
  forwarded,
  received,
  archived,
  cancelled,
}

enum ScanOptions {
  None,
  OCR,
  qrCode,
  barcode,
}

extension ScanOptionsExtension on ScanOptions {
  String get label {
    switch (this) {
      case ScanOptions.None:
        return "None";
      case ScanOptions.OCR:
        return "OCR";
      case ScanOptions.qrCode:
        return "QR Code";
      case ScanOptions.barcode:
        return "Barcode";
    }
  }
}

extension DocumentStatusExtension on DocumentStatus {
  String get label {
    switch (this) {
      case DocumentStatus.registered:
        return "Registered";
      case DocumentStatus.onHold:
        return "On Hold";
      case DocumentStatus.forwarded:
        return "Forwarded";
      case DocumentStatus.received:
        return "Received";
      case DocumentStatus.archived:
        return "Archived";
      case DocumentStatus.cancelled:
        return "Cancelled";
    }
  }
}
class TrackableDocument {
  String title;
  List<DocumentRecord> records;
  String currentHolderKey;
  DocumentStatus status;
  String type;
  DateTime createdDate;
  DateTime lastUpdatedDate;
  String remarks;
  String key;
  List<String> embeddings;
  List<String> imageRefs;
  ScanOptions scanOption;
  bool isScanRequiredUponReceiving;
  String scancode;
  int privacy;
  List<bool>? checklistStatus;
  String trackingCode;

  TrackableDocument({
    required this.title,
    required this.records,
    required this.currentHolderKey,
    required this.status,
    required this.type,
    required this.createdDate,
    required this.lastUpdatedDate,
    required this.remarks,
    required this.key,
    required this.embeddings,
    required this.imageRefs,
    required this.scanOption,
    required this.isScanRequiredUponReceiving,
    required this.scancode,
    required this.privacy,
    required this.trackingCode, // <-- Added here
    this.checklistStatus,
  });

  TrackableDocument.empty()
      : title = '',
        records = [],
        currentHolderKey = '',
        status = DocumentStatus.onHold,
        type = '',
        createdDate = DateTime.now(),
        lastUpdatedDate = DateTime.now(),
        remarks = '',
        key = '',
        embeddings = [],
        imageRefs = [],
        scanOption = ScanOptions.OCR,
        isScanRequiredUponReceiving = false,
        scancode = '',
        privacy = 0,
        checklistStatus = null,
        trackingCode = '';

  factory TrackableDocument.fromJson(Map<String, dynamic> data) {
    return TrackableDocument(
      title: data['title'] ?? '',
      records: (data['records'] as List<dynamic>?)
              ?.map((record) => DocumentRecord.fromJson(record))
              .toList() ??
          [],
      currentHolderKey: data['currentHolderKey'] ?? '',
      status: DocumentStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'onHold'),
        orElse: () => DocumentStatus.onHold,
      ),
      type: data['type'] ?? '',
      createdDate:
          DateTime.tryParse(data['createdDate'] ?? '') ?? DateTime.now(),
      lastUpdatedDate:
          DateTime.tryParse(data['lastUpdatedDate'] ?? '') ?? DateTime.now(),
      remarks: data['remarks'] ?? '',
      key: data['key'] ?? '',
      embeddings: List<String>.from(data['embeddings'] ?? []),
      imageRefs: List<String>.from(data['imageRefs'] ?? []),
      isScanRequiredUponReceiving: data['isScanRequiredUponReceiving'] ?? false,
      scanOption: ScanOptions.values.firstWhere(
        (e) => e.name == (data['scanOptions'] ?? 'OCR'),
        orElse: () => ScanOptions.OCR,
      ),
      scancode: data['scancode'] ?? '',
      privacy: data['privacy'] ?? 0,
      trackingCode: data['trackingCode'] ?? '', // <-- From JSON
      checklistStatus: data['checklistStatus'] != null
          ? List<bool>.from(data['checklistStatus'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'records': records.map((record) => record.toJson()).toList(),
      'currentHolderKey': currentHolderKey,
      'status': status.name,
      'type': type,
      'createdDate': createdDate.toIso8601String(),
      'lastUpdatedDate': lastUpdatedDate.toIso8601String(),
      'remarks': remarks,
      'key': key,
      'embeddings': embeddings,
      'imageRefs': imageRefs,
      'scanOptions': scanOption.name,
      'isScanRequiredUponReceiving': isScanRequiredUponReceiving,
      'scancode': scancode,
      'privacy': privacy,
      'trackingCode': trackingCode, // <-- To JSON
      if (checklistStatus != null) 'checklistStatus': checklistStatus,
    };
  }

  set setCurrentHolder(String newHolderKey) {
    records.last.date = DateTime.now();
    records.add(DocumentRecord(
      holder: newHolderKey,
      date: DateTime.now(),
      remarks: remarks,
      status: status,
      imageRefs: imageRefs,
    ));
    currentHolderKey = newHolderKey;
    updateLastModified();
  }

  void updateLastModified() {
    lastUpdatedDate = DateTime.now();
  }

  void forwardDocument(String receiverKey, String remarks) {
    status = DocumentStatus.forwarded;
    records.add(DocumentRecord(
      holder: currentHolderKey,
      receiverKey: receiverKey,
      date: DateTime.now(),
      remarks: remarks,
      status: status,
      checklistStatus: checklistStatus,
      imageRefs: imageRefs,
    ));
    updateLastModified();
    print("Document has been forwarded to $receiverKey.");
  }

  void receivedDocument(String receiverKey, String remarks) {
    status = DocumentStatus.received;
    records.add(DocumentRecord(
      holder: currentHolderKey,
      receiverKey: receiverKey,
      date: DateTime.now(),
      remarks: remarks,
      status: status,
      checklistStatus: checklistStatus,
      imageRefs: imageRefs,
    ));
    currentHolderKey = receiverKey;
    this.remarks = remarks;
    status = DocumentStatus.onHold;
    updateLastModified();
    print("Document has been received by $receiverKey.");
  }

  void cancelTransfer(String remarks) {
    status = DocumentStatus.cancelled;
    this.remarks = remarks;
    records.add(DocumentRecord(
      holder: currentHolderKey,
      receiverKey: null,
      date: DateTime.now(),
      remarks: remarks,
      status: status,
      checklistStatus: checklistStatus,
      imageRefs: imageRefs,
    ));
    status = DocumentStatus.onHold;
    updateLastModified();
    print("Document transfer has been cancelled.");
  }
}
