import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class BusinessesRecord extends FirestoreRecord {
  BusinessesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "phoneNumber" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "location" field.
  LocationStruct? _location;
  LocationStruct get location => _location ?? LocationStruct();
  bool hasLocation() => _location != null;

  // "ownersRefs" field.
  List<DocumentReference>? _ownersRefs;
  List<DocumentReference> get ownersRefs => _ownersRefs ?? const [];
  bool hasOwnersRefs() => _ownersRefs != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _phoneNumber = snapshotData['phoneNumber'] as String?;
    _status = snapshotData['status'] as String?;
    _location = snapshotData['location'] is LocationStruct
        ? snapshotData['location']
        : LocationStruct.maybeFromMap(snapshotData['location']);
    _ownersRefs = getDataList(snapshotData['ownersRefs']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('businesses');

  static Stream<BusinessesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => BusinessesRecord.fromSnapshot(s));

  static Future<BusinessesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => BusinessesRecord.fromSnapshot(s));

  static BusinessesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      BusinessesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BusinessesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BusinessesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'BusinessesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BusinessesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createBusinessesRecordData({
  String? name,
  String? phoneNumber,
  String? status,
  LocationStruct? location,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'phoneNumber': phoneNumber,
      'status': status,
      'location': LocationStruct().toMap(),
    }.withoutNulls,
  );

  // Handle nested data for "location" field.
  addLocationStructData(firestoreData, location, 'location');

  return firestoreData;
}

class BusinessesRecordDocumentEquality implements Equality<BusinessesRecord> {
  const BusinessesRecordDocumentEquality();

  @override
  bool equals(BusinessesRecord? e1, BusinessesRecord? e2) {
    const listEquality = ListEquality();
    return e1?.name == e2?.name &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.status == e2?.status &&
        e1?.location == e2?.location &&
        listEquality.equals(e1?.ownersRefs, e2?.ownersRefs);
  }

  @override
  int hash(BusinessesRecord? e) => const ListEquality()
      .hash([e?.name, e?.phoneNumber, e?.status, e?.location, e?.ownersRefs]);

  @override
  bool isValidKey(Object? o) => o is BusinessesRecord;
}
