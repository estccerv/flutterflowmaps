// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class LocationStruct extends FFFirebaseStruct {
  LocationStruct({
    String? address,
    ZoneStruct? zone,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _address = address,
        _zone = zone,
        super(firestoreUtilData);

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  set address(String? val) => _address = val;

  bool hasAddress() => _address != null;

  // "zone" field.
  ZoneStruct? _zone;
  ZoneStruct get zone => _zone ?? ZoneStruct();
  set zone(ZoneStruct? val) => _zone = val;

  void updateZone(Function(ZoneStruct) updateFn) {
    updateFn(_zone ??= ZoneStruct());
  }

  bool hasZone() => _zone != null;

  static LocationStruct fromMap(Map<String, dynamic> data) => LocationStruct(
        address: data['address'] as String?,
        zone: data['zone'] is ZoneStruct
            ? data['zone']
            : ZoneStruct.maybeFromMap(data['zone']),
      );

  static LocationStruct? maybeFromMap(dynamic data) =>
      data is Map ? LocationStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'address': _address,
        'zone': _zone?.toMap(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'address': serializeParam(
          _address,
          ParamType.String,
        ),
        'zone': serializeParam(
          _zone,
          ParamType.DataStruct,
        ),
      }.withoutNulls;

  static LocationStruct fromSerializableMap(Map<String, dynamic> data) =>
      LocationStruct(
        address: deserializeParam(
          data['address'],
          ParamType.String,
          false,
        ),
        zone: deserializeStructParam(
          data['zone'],
          ParamType.DataStruct,
          false,
          structBuilder: ZoneStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'LocationStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is LocationStruct &&
        address == other.address &&
        zone == other.zone;
  }

  @override
  int get hashCode => const ListEquality().hash([address, zone]);
}

LocationStruct createLocationStruct({
  String? address,
  ZoneStruct? zone,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    LocationStruct(
      address: address,
      zone: zone ?? (clearUnsetFields ? ZoneStruct() : null),
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

LocationStruct? updateLocationStruct(
  LocationStruct? location, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    location
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addLocationStructData(
  Map<String, dynamic> firestoreData,
  LocationStruct? location,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (location == null) {
    return;
  }
  if (location.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && location.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final locationData = getLocationFirestoreData(location, forFieldValue);
  final nestedData = locationData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = location.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getLocationFirestoreData(
  LocationStruct? location, [
  bool forFieldValue = false,
]) {
  if (location == null) {
    return {};
  }
  final firestoreData = mapToFirestore(location.toMap());

  // Handle nested data for "zone" field.
  addZoneStructData(
    firestoreData,
    location.hasZone() ? location.zone : null,
    'zone',
    forFieldValue,
  );

  // Add any Firestore field values
  location.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getLocationListFirestoreData(
  List<LocationStruct>? locations,
) =>
    locations?.map((e) => getLocationFirestoreData(e, true)).toList() ?? [];
