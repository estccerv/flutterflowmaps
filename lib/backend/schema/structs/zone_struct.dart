// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class ZoneStruct extends FFFirebaseStruct {
  ZoneStruct({
    String? geohash,
    LatLng? geopoint,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _geohash = geohash,
        _geopoint = geopoint,
        super(firestoreUtilData);

  // "geohash" field.
  String? _geohash;
  String get geohash => _geohash ?? '';
  set geohash(String? val) => _geohash = val;

  bool hasGeohash() => _geohash != null;

  // "geopoint" field.
  LatLng? _geopoint;
  LatLng? get geopoint => _geopoint;
  set geopoint(LatLng? val) => _geopoint = val;

  bool hasGeopoint() => _geopoint != null;

  static ZoneStruct fromMap(Map<String, dynamic> data) => ZoneStruct(
        geohash: data['geohash'] as String?,
        geopoint: data['geopoint'] as LatLng?,
      );

  static ZoneStruct? maybeFromMap(dynamic data) =>
      data is Map ? ZoneStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'geohash': _geohash,
        'geopoint': _geopoint,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'geohash': serializeParam(
          _geohash,
          ParamType.String,
        ),
        'geopoint': serializeParam(
          _geopoint,
          ParamType.LatLng,
        ),
      }.withoutNulls;

  static ZoneStruct fromSerializableMap(Map<String, dynamic> data) =>
      ZoneStruct(
        geohash: deserializeParam(
          data['geohash'],
          ParamType.String,
          false,
        ),
        geopoint: deserializeParam(
          data['geopoint'],
          ParamType.LatLng,
          false,
        ),
      );

  @override
  String toString() => 'ZoneStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ZoneStruct &&
        geohash == other.geohash &&
        geopoint == other.geopoint;
  }

  @override
  int get hashCode => const ListEquality().hash([geohash, geopoint]);
}

ZoneStruct createZoneStruct({
  String? geohash,
  LatLng? geopoint,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ZoneStruct(
      geohash: geohash,
      geopoint: geopoint,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ZoneStruct? updateZoneStruct(
  ZoneStruct? zone, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    zone
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addZoneStructData(
  Map<String, dynamic> firestoreData,
  ZoneStruct? zone,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (zone == null) {
    return;
  }
  if (zone.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields = !forFieldValue && zone.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final zoneData = getZoneFirestoreData(zone, forFieldValue);
  final nestedData = zoneData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = zone.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getZoneFirestoreData(
  ZoneStruct? zone, [
  bool forFieldValue = false,
]) {
  if (zone == null) {
    return {};
  }
  final firestoreData = mapToFirestore(zone.toMap());

  // Add any Firestore field values
  zone.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getZoneListFirestoreData(
  List<ZoneStruct>? zones,
) =>
    zones?.map((e) => getZoneFirestoreData(e, true)).toList() ?? [];
