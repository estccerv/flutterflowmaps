import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class OrdersRecord extends FirestoreRecord {
  OrdersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "business" field.
  BusinessInfoStruct? _business;
  BusinessInfoStruct get business => _business ?? BusinessInfoStruct();
  bool hasBusiness() => _business != null;

  // "driverInfo" field.
  UserInfoStruct? _driverInfo;
  UserInfoStruct get driverInfo => _driverInfo ?? UserInfoStruct();
  bool hasDriverInfo() => _driverInfo != null;

  // "businessRef" field.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "driverRef" field.
  DocumentReference? _driverRef;
  DocumentReference? get driverRef => _driverRef;
  bool hasDriverRef() => _driverRef != null;

  // "businessZone" field.
  ZoneStruct? _businessZone;
  ZoneStruct get businessZone => _businessZone ?? ZoneStruct();
  bool hasBusinessZone() => _businessZone != null;

  // "customer" field.
  UserInfoStruct? _customer;
  UserInfoStruct get customer => _customer ?? UserInfoStruct();
  bool hasCustomer() => _customer != null;

  // "customerRef" field.
  DocumentReference? _customerRef;
  DocumentReference? get customerRef => _customerRef;
  bool hasCustomerRef() => _customerRef != null;

  // "customerZone" field.
  ZoneStruct? _customerZone;
  ZoneStruct get customerZone => _customerZone ?? ZoneStruct();
  bool hasCustomerZone() => _customerZone != null;

  // "driver" field.
  UserInfoStruct? _driver;
  UserInfoStruct get driver => _driver ?? UserInfoStruct();
  bool hasDriver() => _driver != null;

  // "deliveryRef" field.
  DocumentReference? _deliveryRef;
  DocumentReference? get deliveryRef => _deliveryRef;
  bool hasDeliveryRef() => _deliveryRef != null;

  void _initializeFields() {
    _status = snapshotData['status'] as String?;
    _business = snapshotData['business'] is BusinessInfoStruct
        ? snapshotData['business']
        : BusinessInfoStruct.maybeFromMap(snapshotData['business']);
    _driverInfo = snapshotData['driverInfo'] is UserInfoStruct
        ? snapshotData['driverInfo']
        : UserInfoStruct.maybeFromMap(snapshotData['driverInfo']);
    _businessRef = snapshotData['businessRef'] as DocumentReference?;
    _driverRef = snapshotData['driverRef'] as DocumentReference?;
    _businessZone = snapshotData['businessZone'] is ZoneStruct
        ? snapshotData['businessZone']
        : ZoneStruct.maybeFromMap(snapshotData['businessZone']);
    _customer = snapshotData['customer'] is UserInfoStruct
        ? snapshotData['customer']
        : UserInfoStruct.maybeFromMap(snapshotData['customer']);
    _customerRef = snapshotData['customerRef'] as DocumentReference?;
    _customerZone = snapshotData['customerZone'] is ZoneStruct
        ? snapshotData['customerZone']
        : ZoneStruct.maybeFromMap(snapshotData['customerZone']);
    _driver = snapshotData['driver'] is UserInfoStruct
        ? snapshotData['driver']
        : UserInfoStruct.maybeFromMap(snapshotData['driver']);
    _deliveryRef = snapshotData['deliveryRef'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('orders');

  static Stream<OrdersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => OrdersRecord.fromSnapshot(s));

  static Future<OrdersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => OrdersRecord.fromSnapshot(s));

  static OrdersRecord fromSnapshot(DocumentSnapshot snapshot) => OrdersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static OrdersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      OrdersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'OrdersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is OrdersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createOrdersRecordData({
  String? status,
  BusinessInfoStruct? business,
  UserInfoStruct? driverInfo,
  DocumentReference? businessRef,
  DocumentReference? driverRef,
  ZoneStruct? businessZone,
  UserInfoStruct? customer,
  DocumentReference? customerRef,
  ZoneStruct? customerZone,
  UserInfoStruct? driver,
  DocumentReference? deliveryRef,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'status': status,
      'business': BusinessInfoStruct().toMap(),
      'driverInfo': UserInfoStruct().toMap(),
      'businessRef': businessRef,
      'driverRef': driverRef,
      'businessZone': ZoneStruct().toMap(),
      'customer': UserInfoStruct().toMap(),
      'customerRef': customerRef,
      'customerZone': ZoneStruct().toMap(),
      'driver': UserInfoStruct().toMap(),
      'deliveryRef': deliveryRef,
    }.withoutNulls,
  );

  // Handle nested data for "business" field.
  addBusinessInfoStructData(firestoreData, business, 'business');

  // Handle nested data for "driverInfo" field.
  addUserInfoStructData(firestoreData, driverInfo, 'driverInfo');

  // Handle nested data for "businessZone" field.
  addZoneStructData(firestoreData, businessZone, 'businessZone');

  // Handle nested data for "customer" field.
  addUserInfoStructData(firestoreData, customer, 'customer');

  // Handle nested data for "customerZone" field.
  addZoneStructData(firestoreData, customerZone, 'customerZone');

  // Handle nested data for "driver" field.
  addUserInfoStructData(firestoreData, driver, 'driver');

  return firestoreData;
}

class OrdersRecordDocumentEquality implements Equality<OrdersRecord> {
  const OrdersRecordDocumentEquality();

  @override
  bool equals(OrdersRecord? e1, OrdersRecord? e2) {
    return e1?.status == e2?.status &&
        e1?.business == e2?.business &&
        e1?.driverInfo == e2?.driverInfo &&
        e1?.businessRef == e2?.businessRef &&
        e1?.driverRef == e2?.driverRef &&
        e1?.businessZone == e2?.businessZone &&
        e1?.customer == e2?.customer &&
        e1?.customerRef == e2?.customerRef &&
        e1?.customerZone == e2?.customerZone &&
        e1?.driver == e2?.driver &&
        e1?.deliveryRef == e2?.deliveryRef;
  }

  @override
  int hash(OrdersRecord? e) => const ListEquality().hash([
        e?.status,
        e?.business,
        e?.driverInfo,
        e?.businessRef,
        e?.driverRef,
        e?.businessZone,
        e?.customer,
        e?.customerRef,
        e?.customerZone,
        e?.driver,
        e?.deliveryRef
      ]);

  @override
  bool isValidKey(Object? o) => o is OrdersRecord;
}
