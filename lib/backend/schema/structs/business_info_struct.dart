// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class BusinessInfoStruct extends FFFirebaseStruct {
  BusinessInfoStruct({
    String? uid,
    String? name,
    String? address,
    String? phoneNumber,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _uid = uid,
        _name = name,
        _address = address,
        _phoneNumber = phoneNumber,
        super(firestoreUtilData);

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  set uid(String? val) => _uid = val;

  bool hasUid() => _uid != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  set name(String? val) => _name = val;

  bool hasName() => _name != null;

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  set address(String? val) => _address = val;

  bool hasAddress() => _address != null;

  // "phoneNumber" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  set phoneNumber(String? val) => _phoneNumber = val;

  bool hasPhoneNumber() => _phoneNumber != null;

  static BusinessInfoStruct fromMap(Map<String, dynamic> data) =>
      BusinessInfoStruct(
        uid: data['uid'] as String?,
        name: data['name'] as String?,
        address: data['address'] as String?,
        phoneNumber: data['phoneNumber'] as String?,
      );

  static BusinessInfoStruct? maybeFromMap(dynamic data) => data is Map
      ? BusinessInfoStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'uid': _uid,
        'name': _name,
        'address': _address,
        'phoneNumber': _phoneNumber,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'uid': serializeParam(
          _uid,
          ParamType.String,
        ),
        'name': serializeParam(
          _name,
          ParamType.String,
        ),
        'address': serializeParam(
          _address,
          ParamType.String,
        ),
        'phoneNumber': serializeParam(
          _phoneNumber,
          ParamType.String,
        ),
      }.withoutNulls;

  static BusinessInfoStruct fromSerializableMap(Map<String, dynamic> data) =>
      BusinessInfoStruct(
        uid: deserializeParam(
          data['uid'],
          ParamType.String,
          false,
        ),
        name: deserializeParam(
          data['name'],
          ParamType.String,
          false,
        ),
        address: deserializeParam(
          data['address'],
          ParamType.String,
          false,
        ),
        phoneNumber: deserializeParam(
          data['phoneNumber'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'BusinessInfoStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is BusinessInfoStruct &&
        uid == other.uid &&
        name == other.name &&
        address == other.address &&
        phoneNumber == other.phoneNumber;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([uid, name, address, phoneNumber]);
}

BusinessInfoStruct createBusinessInfoStruct({
  String? uid,
  String? name,
  String? address,
  String? phoneNumber,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    BusinessInfoStruct(
      uid: uid,
      name: name,
      address: address,
      phoneNumber: phoneNumber,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

BusinessInfoStruct? updateBusinessInfoStruct(
  BusinessInfoStruct? businessInfo, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    businessInfo
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addBusinessInfoStructData(
  Map<String, dynamic> firestoreData,
  BusinessInfoStruct? businessInfo,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (businessInfo == null) {
    return;
  }
  if (businessInfo.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && businessInfo.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final businessInfoData =
      getBusinessInfoFirestoreData(businessInfo, forFieldValue);
  final nestedData =
      businessInfoData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = businessInfo.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getBusinessInfoFirestoreData(
  BusinessInfoStruct? businessInfo, [
  bool forFieldValue = false,
]) {
  if (businessInfo == null) {
    return {};
  }
  final firestoreData = mapToFirestore(businessInfo.toMap());

  // Add any Firestore field values
  businessInfo.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getBusinessInfoListFirestoreData(
  List<BusinessInfoStruct>? businessInfos,
) =>
    businessInfos?.map((e) => getBusinessInfoFirestoreData(e, true)).toList() ??
    [];
