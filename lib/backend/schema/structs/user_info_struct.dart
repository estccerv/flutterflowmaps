// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class UserInfoStruct extends FFFirebaseStruct {
  UserInfoStruct({
    String? uid,
    String? displayName,
    String? email,
    String? phoneNumber,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _uid = uid,
        _displayName = displayName,
        _email = email,
        _phoneNumber = phoneNumber,
        super(firestoreUtilData);

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  set uid(String? val) => _uid = val;

  bool hasUid() => _uid != null;

  // "displayName" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  set displayName(String? val) => _displayName = val;

  bool hasDisplayName() => _displayName != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  set email(String? val) => _email = val;

  bool hasEmail() => _email != null;

  // "phoneNumber" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  set phoneNumber(String? val) => _phoneNumber = val;

  bool hasPhoneNumber() => _phoneNumber != null;

  static UserInfoStruct fromMap(Map<String, dynamic> data) => UserInfoStruct(
        uid: data['uid'] as String?,
        displayName: data['displayName'] as String?,
        email: data['email'] as String?,
        phoneNumber: data['phoneNumber'] as String?,
      );

  static UserInfoStruct? maybeFromMap(dynamic data) =>
      data is Map ? UserInfoStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'uid': _uid,
        'displayName': _displayName,
        'email': _email,
        'phoneNumber': _phoneNumber,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'uid': serializeParam(
          _uid,
          ParamType.String,
        ),
        'displayName': serializeParam(
          _displayName,
          ParamType.String,
        ),
        'email': serializeParam(
          _email,
          ParamType.String,
        ),
        'phoneNumber': serializeParam(
          _phoneNumber,
          ParamType.String,
        ),
      }.withoutNulls;

  static UserInfoStruct fromSerializableMap(Map<String, dynamic> data) =>
      UserInfoStruct(
        uid: deserializeParam(
          data['uid'],
          ParamType.String,
          false,
        ),
        displayName: deserializeParam(
          data['displayName'],
          ParamType.String,
          false,
        ),
        email: deserializeParam(
          data['email'],
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
  String toString() => 'UserInfoStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is UserInfoStruct &&
        uid == other.uid &&
        displayName == other.displayName &&
        email == other.email &&
        phoneNumber == other.phoneNumber;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([uid, displayName, email, phoneNumber]);
}

UserInfoStruct createUserInfoStruct({
  String? uid,
  String? displayName,
  String? email,
  String? phoneNumber,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    UserInfoStruct(
      uid: uid,
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

UserInfoStruct? updateUserInfoStruct(
  UserInfoStruct? userInfo, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    userInfo
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addUserInfoStructData(
  Map<String, dynamic> firestoreData,
  UserInfoStruct? userInfo,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (userInfo == null) {
    return;
  }
  if (userInfo.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && userInfo.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final userInfoData = getUserInfoFirestoreData(userInfo, forFieldValue);
  final nestedData = userInfoData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = userInfo.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getUserInfoFirestoreData(
  UserInfoStruct? userInfo, [
  bool forFieldValue = false,
]) {
  if (userInfo == null) {
    return {};
  }
  final firestoreData = mapToFirestore(userInfo.toMap());

  // Add any Firestore field values
  userInfo.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getUserInfoListFirestoreData(
  List<UserInfoStruct>? userInfos,
) =>
    userInfos?.map((e) => getUserInfoFirestoreData(e, true)).toList() ?? [];
