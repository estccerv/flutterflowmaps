import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DeliveriesRecord extends FirestoreRecord {
  DeliveriesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "orderRef" field.
  DocumentReference? _orderRef;
  DocumentReference? get orderRef => _orderRef;
  bool hasOrderRef() => _orderRef != null;

  // "driverRef" field.
  DocumentReference? _driverRef;
  DocumentReference? get driverRef => _driverRef;
  bool hasDriverRef() => _driverRef != null;

  // "businessRef" field.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "originZone" field.
  ZoneStruct? _originZone;
  ZoneStruct get originZone => _originZone ?? ZoneStruct();
  bool hasOriginZone() => _originZone != null;

  // "destinationZone" field.
  ZoneStruct? _destinationZone;
  ZoneStruct get destinationZone => _destinationZone ?? ZoneStruct();
  bool hasDestinationZone() => _destinationZone != null;

  // "acceptanceZone" field.
  ZoneStruct? _acceptanceZone;
  ZoneStruct get acceptanceZone => _acceptanceZone ?? ZoneStruct();
  bool hasAcceptanceZone() => _acceptanceZone != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  // "customerRef" field.
  DocumentReference? _customerRef;
  DocumentReference? get customerRef => _customerRef;
  bool hasCustomerRef() => _customerRef != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _orderRef = snapshotData['orderRef'] as DocumentReference?;
    _driverRef = snapshotData['driverRef'] as DocumentReference?;
    _businessRef = snapshotData['businessRef'] as DocumentReference?;
    _originZone = snapshotData['originZone'] is ZoneStruct
        ? snapshotData['originZone']
        : ZoneStruct.maybeFromMap(snapshotData['originZone']);
    _destinationZone = snapshotData['destinationZone'] is ZoneStruct
        ? snapshotData['destinationZone']
        : ZoneStruct.maybeFromMap(snapshotData['destinationZone']);
    _acceptanceZone = snapshotData['acceptanceZone'] is ZoneStruct
        ? snapshotData['acceptanceZone']
        : ZoneStruct.maybeFromMap(snapshotData['acceptanceZone']);
    _status = snapshotData['status'] as String?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _customerRef = snapshotData['customerRef'] as DocumentReference?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('deliveries');

  static Stream<DeliveriesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DeliveriesRecord.fromSnapshot(s));

  static Future<DeliveriesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DeliveriesRecord.fromSnapshot(s));

  static DeliveriesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DeliveriesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DeliveriesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DeliveriesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DeliveriesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DeliveriesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createDeliveriesRecordData({
  DocumentReference? orderRef,
  DocumentReference? driverRef,
  DocumentReference? businessRef,
  ZoneStruct? originZone,
  ZoneStruct? destinationZone,
  ZoneStruct? acceptanceZone,
  String? status,
  DateTime? timestamp,
  DocumentReference? customerRef,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'orderRef': orderRef,
      'driverRef': driverRef,
      'businessRef': businessRef,
      'originZone': ZoneStruct().toMap(),
      'destinationZone': ZoneStruct().toMap(),
      'acceptanceZone': ZoneStruct().toMap(),
      'status': status,
      'timestamp': timestamp,
      'customerRef': customerRef,
      'createdAt': createdAt,
    }.withoutNulls,
  );

  // Handle nested data for "originZone" field.
  addZoneStructData(firestoreData, originZone, 'originZone');

  // Handle nested data for "destinationZone" field.
  addZoneStructData(firestoreData, destinationZone, 'destinationZone');

  // Handle nested data for "acceptanceZone" field.
  addZoneStructData(firestoreData, acceptanceZone, 'acceptanceZone');

  return firestoreData;
}

class DeliveriesRecordDocumentEquality implements Equality<DeliveriesRecord> {
  const DeliveriesRecordDocumentEquality();

  @override
  bool equals(DeliveriesRecord? e1, DeliveriesRecord? e2) {
    return e1?.orderRef == e2?.orderRef &&
        e1?.driverRef == e2?.driverRef &&
        e1?.businessRef == e2?.businessRef &&
        e1?.originZone == e2?.originZone &&
        e1?.destinationZone == e2?.destinationZone &&
        e1?.acceptanceZone == e2?.acceptanceZone &&
        e1?.status == e2?.status &&
        e1?.timestamp == e2?.timestamp &&
        e1?.customerRef == e2?.customerRef &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(DeliveriesRecord? e) => const ListEquality().hash([
        e?.orderRef,
        e?.driverRef,
        e?.businessRef,
        e?.originZone,
        e?.destinationZone,
        e?.acceptanceZone,
        e?.status,
        e?.timestamp,
        e?.customerRef,
        e?.createdAt
      ]);

  @override
  bool isValidKey(Object? o) => o is DeliveriesRecord;
}
