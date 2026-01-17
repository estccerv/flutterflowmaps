import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DriversRecord extends FirestoreRecord {
  DriversRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userRef" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "isAvailable" field.
  bool? _isAvailable;
  bool get isAvailable => _isAvailable ?? false;
  bool hasIsAvailable() => _isAvailable != null;

  // "lastAvailable" field.
  DateTime? _lastAvailable;
  DateTime? get lastAvailable => _lastAvailable;
  bool hasLastAvailable() => _lastAvailable != null;

  // "currentZone" field.
  ZoneStruct? _currentZone;
  ZoneStruct get currentZone => _currentZone ?? ZoneStruct();
  bool hasCurrentZone() => _currentZone != null;

  // "lastZone" field.
  ZoneStruct? _lastZone;
  ZoneStruct get lastZone => _lastZone ?? ZoneStruct();
  bool hasLastZone() => _lastZone != null;

  void _initializeFields() {
    _userRef = snapshotData['userRef'] as DocumentReference?;
    _status = snapshotData['status'] as String?;
    _isAvailable = snapshotData['isAvailable'] as bool?;
    _lastAvailable = snapshotData['lastAvailable'] as DateTime?;
    _currentZone = snapshotData['currentZone'] is ZoneStruct
        ? snapshotData['currentZone']
        : ZoneStruct.maybeFromMap(snapshotData['currentZone']);
    _lastZone = snapshotData['lastZone'] is ZoneStruct
        ? snapshotData['lastZone']
        : ZoneStruct.maybeFromMap(snapshotData['lastZone']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('drivers');

  static Stream<DriversRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DriversRecord.fromSnapshot(s));

  static Future<DriversRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DriversRecord.fromSnapshot(s));

  static DriversRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DriversRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DriversRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DriversRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DriversRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DriversRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createDriversRecordData({
  DocumentReference? userRef,
  String? status,
  bool? isAvailable,
  DateTime? lastAvailable,
  ZoneStruct? currentZone,
  ZoneStruct? lastZone,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userRef': userRef,
      'status': status,
      'isAvailable': isAvailable,
      'lastAvailable': lastAvailable,
      'currentZone': ZoneStruct().toMap(),
      'lastZone': ZoneStruct().toMap(),
    }.withoutNulls,
  );

  // Handle nested data for "currentZone" field.
  addZoneStructData(firestoreData, currentZone, 'currentZone');

  // Handle nested data for "lastZone" field.
  addZoneStructData(firestoreData, lastZone, 'lastZone');

  return firestoreData;
}

class DriversRecordDocumentEquality implements Equality<DriversRecord> {
  const DriversRecordDocumentEquality();

  @override
  bool equals(DriversRecord? e1, DriversRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.status == e2?.status &&
        e1?.isAvailable == e2?.isAvailable &&
        e1?.lastAvailable == e2?.lastAvailable &&
        e1?.currentZone == e2?.currentZone &&
        e1?.lastZone == e2?.lastZone;
  }

  @override
  int hash(DriversRecord? e) => const ListEquality().hash([
        e?.userRef,
        e?.status,
        e?.isAvailable,
        e?.lastAvailable,
        e?.currentZone,
        e?.lastZone
      ]);

  @override
  bool isValidKey(Object? o) => o is DriversRecord;
}
