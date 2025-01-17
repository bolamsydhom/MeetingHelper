// Mocks generated by Mockito 5.2.0 from annotations
// in meetinghelper/test/views/root_test.dart.
// Do not manually edit this file.

import 'dart:async' as _i8;
import 'dart:io' as _i12;
import 'dart:typed_data' as _i11;

import 'package:firebase_auth/firebase_auth.dart' as _i10;
import 'package:firebase_core/firebase_core.dart' as _i4;
import 'package:firebase_database/firebase_database.dart' as _i9;
import 'package:firebase_storage/firebase_storage.dart' as _i5;
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart'
    as _i6;
import 'package:meetinghelper/models.dart' as _i3;
import 'package:meetinghelper/repositories.dart' as _i7;
import 'package:mockito/mockito.dart' as _i1;
import 'package:rxdart/rxdart.dart' as _i2;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types

class _FakeBehaviorSubject_0<T> extends _i1.Fake
    implements _i2.BehaviorSubject<T> {}

class _FakeValueStream_1<T> extends _i1.Fake implements _i2.ValueStream<T> {}

class _FakeMHPermissionsSet_2 extends _i1.Fake implements _i3.MHPermissionsSet {
}

class _FakeUser_3 extends _i1.Fake implements _i3.User {}

class _FakeFirebaseApp_4 extends _i1.Fake implements _i4.FirebaseApp {}

class _FakeDuration_5 extends _i1.Fake implements Duration {}

class _FakeReference_6 extends _i1.Fake implements _i5.Reference {}

class _FakeFirebaseStorage_7 extends _i1.Fake implements _i5.FirebaseStorage {}

class _FakeFullMetadata_8 extends _i1.Fake implements _i6.FullMetadata {}

class _FakeListResult_9 extends _i1.Fake implements _i5.ListResult {}

class _FakeUploadTask_10 extends _i1.Fake implements _i5.UploadTask {}

class _FakeDownloadTask_11 extends _i1.Fake implements _i5.DownloadTask {}

/// A class which mocks [MHAuthRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockMHAuthRepository extends _i1.Mock implements _i7.MHAuthRepository {
  MockMHAuthRepository() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.BehaviorSubject<_i3.User?> get userSubject =>
      (super.noSuchMethod(Invocation.getter(#userSubject),
              returnValue: _FakeBehaviorSubject_0<_i3.User?>())
          as _i2.BehaviorSubject<_i3.User?>);
  @override
  _i2.BehaviorSubject<_i3.Person?> get userDataSubject =>
      (super.noSuchMethod(Invocation.getter(#userDataSubject),
              returnValue: _FakeBehaviorSubject_0<_i3.Person?>())
          as _i2.BehaviorSubject<_i3.Person?>);
  @override
  set userTokenListener(
          _i8.StreamSubscription<_i9.DatabaseEvent>? _userTokenListener) =>
      super.noSuchMethod(
          Invocation.setter(#userTokenListener, _userTokenListener),
          returnValueForMissingStub: null);
  @override
  set connectionListener(
          _i8.StreamSubscription<_i9.DatabaseEvent>? _connectionListener) =>
      super.noSuchMethod(
          Invocation.setter(#connectionListener, _connectionListener),
          returnValueForMissingStub: null);
  @override
  set personListener(_i8.StreamSubscription<_i3.Person>? _personListener) =>
      super.noSuchMethod(Invocation.setter(#personListener, _personListener),
          returnValueForMissingStub: null);
  @override
  set authListener(_i8.StreamSubscription<_i10.User?>? _authListener) =>
      super.noSuchMethod(Invocation.setter(#authListener, _authListener),
          returnValueForMissingStub: null);
  @override
  _i2.ValueStream<_i3.User?> get userStream =>
      (super.noSuchMethod(Invocation.getter(#userStream),
              returnValue: _FakeValueStream_1<_i3.User?>())
          as _i2.ValueStream<_i3.User?>);
  @override
  bool get isSignedIn =>
      (super.noSuchMethod(Invocation.getter(#isSignedIn), returnValue: false)
          as bool);
  @override
  _i2.ValueStream<_i3.Person?> get userDataStream =>
      (super.noSuchMethod(Invocation.getter(#userDataStream),
              returnValue: _FakeValueStream_1<_i3.Person?>())
          as _i2.ValueStream<_i3.Person?>);
  @override
  bool connectionChanged(_i9.DatabaseEvent? snapshot) =>
      (super.noSuchMethod(Invocation.method(#connectionChanged, [snapshot]),
          returnValue: false) as bool);
  @override
  _i3.MHPermissionsSet permissionsFromIdToken(
          Map<String, dynamic>? idTokenClaims) =>
      (super.noSuchMethod(
          Invocation.method(#permissionsFromIdToken, [idTokenClaims]),
          returnValue: _FakeMHPermissionsSet_2()) as _i3.MHPermissionsSet);
  @override
  _i8.Future<_i3.User> refreshFromIdToken(Map<String, dynamic>? idTokenClaims,
          {_i10.User? firebaseUser,
          String? uid,
          String? name,
          String? email,
          String? phone}) =>
      (super.noSuchMethod(
              Invocation.method(#refreshFromIdToken, [
                idTokenClaims
              ], {
                #firebaseUser: firebaseUser,
                #uid: uid,
                #name: name,
                #email: email,
                #phone: phone
              }),
              returnValue: Future<_i3.User>.value(_FakeUser_3()))
          as _i8.Future<_i3.User>);
  @override
  _i8.Future<void> refreshSupabaseToken([String? supabaseToken]) => (super
      .noSuchMethod(Invocation.method(#refreshSupabaseToken, [supabaseToken]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i8.Future<void>);
  @override
  void initListeners() =>
      super.noSuchMethod(Invocation.method(#initListeners, []),
          returnValueForMissingStub: null);
  @override
  void onUserChanged(_i10.User? user) =>
      super.noSuchMethod(Invocation.method(#onUserChanged, [user]),
          returnValueForMissingStub: null);
  @override
  _i8.Future<void> refreshIdToken(_i10.User? firebaseUser,
          [bool? force = false]) =>
      (super.noSuchMethod(
          Invocation.method(#refreshIdToken, [firebaseUser, force]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i8.Future<void>);
  @override
  void refreshFromDoc(_i3.Person? userData) =>
      super.noSuchMethod(Invocation.method(#refreshFromDoc, [userData]),
          returnValueForMissingStub: null);
  @override
  void scheduleOnDisconnect() =>
      super.noSuchMethod(Invocation.method(#scheduleOnDisconnect, []),
          returnValueForMissingStub: null);
  @override
  _i8.Future<void> recordActive() =>
      (super.noSuchMethod(Invocation.method(#recordActive, []),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i8.Future<void>);
  @override
  _i8.Future<void> recordLastSeen() =>
      (super.noSuchMethod(Invocation.method(#recordLastSeen, []),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i8.Future<void>);
  @override
  _i8.Future<void> signOut() =>
      (super.noSuchMethod(Invocation.method(#signOut, []),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i8.Future<void>);
  @override
  _i8.Future<void> dispose() =>
      (super.noSuchMethod(Invocation.method(#dispose, []),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i8.Future<void>);
}

/// A class which mocks [FirebaseStorage].
///
/// See the documentation for Mockito's code generation for more information.
class MockFirebaseStorage extends _i1.Mock implements _i5.FirebaseStorage {
  MockFirebaseStorage() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.FirebaseApp get app => (super.noSuchMethod(Invocation.getter(#app),
      returnValue: _FakeFirebaseApp_4()) as _i4.FirebaseApp);
  @override
  set app(_i4.FirebaseApp? _app) =>
      super.noSuchMethod(Invocation.setter(#app, _app),
          returnValueForMissingStub: null);
  @override
  String get bucket =>
      (super.noSuchMethod(Invocation.getter(#bucket), returnValue: '')
          as String);
  @override
  set bucket(String? _bucket) =>
      super.noSuchMethod(Invocation.setter(#bucket, _bucket),
          returnValueForMissingStub: null);
  @override
  Duration get maxOperationRetryTime =>
      (super.noSuchMethod(Invocation.getter(#maxOperationRetryTime),
          returnValue: _FakeDuration_5()) as Duration);
  @override
  Duration get maxUploadRetryTime =>
      (super.noSuchMethod(Invocation.getter(#maxUploadRetryTime),
          returnValue: _FakeDuration_5()) as Duration);
  @override
  Duration get maxDownloadRetryTime =>
      (super.noSuchMethod(Invocation.getter(#maxDownloadRetryTime),
          returnValue: _FakeDuration_5()) as Duration);
  @override
  Map<dynamic, dynamic> get pluginConstants =>
      (super.noSuchMethod(Invocation.getter(#pluginConstants),
          returnValue: <dynamic, dynamic>{}) as Map<dynamic, dynamic>);
  @override
  _i5.Reference ref([String? path]) =>
      (super.noSuchMethod(Invocation.method(#ref, [path]),
          returnValue: _FakeReference_6()) as _i5.Reference);
  @override
  _i5.Reference refFromURL(String? url) =>
      (super.noSuchMethod(Invocation.method(#refFromURL, [url]),
          returnValue: _FakeReference_6()) as _i5.Reference);
  @override
  void setMaxOperationRetryTime(Duration? time) =>
      super.noSuchMethod(Invocation.method(#setMaxOperationRetryTime, [time]),
          returnValueForMissingStub: null);
  @override
  void setMaxUploadRetryTime(Duration? time) =>
      super.noSuchMethod(Invocation.method(#setMaxUploadRetryTime, [time]),
          returnValueForMissingStub: null);
  @override
  void setMaxDownloadRetryTime(Duration? time) =>
      super.noSuchMethod(Invocation.method(#setMaxDownloadRetryTime, [time]),
          returnValueForMissingStub: null);
  @override
  _i8.Future<void> useEmulator({String? host, int? port}) =>
      (super.noSuchMethod(
          Invocation.method(#useEmulator, [], {#host: host, #port: port}),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i8.Future<void>);
  @override
  _i8.Future<void> useStorageEmulator(String? host, int? port) =>
      (super.noSuchMethod(Invocation.method(#useStorageEmulator, [host, port]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i8.Future<void>);
}

/// A class which mocks [Reference].
///
/// See the documentation for Mockito's code generation for more information.
class MockReference extends _i1.Mock implements _i5.Reference {
  MockReference() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i5.FirebaseStorage get storage =>
      (super.noSuchMethod(Invocation.getter(#storage),
          returnValue: _FakeFirebaseStorage_7()) as _i5.FirebaseStorage);
  @override
  String get bucket =>
      (super.noSuchMethod(Invocation.getter(#bucket), returnValue: '')
          as String);
  @override
  String get fullPath =>
      (super.noSuchMethod(Invocation.getter(#fullPath), returnValue: '')
          as String);
  @override
  String get name =>
      (super.noSuchMethod(Invocation.getter(#name), returnValue: '') as String);
  @override
  _i5.Reference get root => (super.noSuchMethod(Invocation.getter(#root),
      returnValue: _FakeReference_6()) as _i5.Reference);
  @override
  _i5.Reference child(String? path) =>
      (super.noSuchMethod(Invocation.method(#child, [path]),
          returnValue: _FakeReference_6()) as _i5.Reference);
  @override
  _i8.Future<void> delete() =>
      (super.noSuchMethod(Invocation.method(#delete, []),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i8.Future<void>);
  @override
  _i8.Future<String> getDownloadURL() =>
      (super.noSuchMethod(Invocation.method(#getDownloadURL, []),
          returnValue: Future<String>.value('')) as _i8.Future<String>);
  @override
  _i8.Future<_i6.FullMetadata> getMetadata() => (super.noSuchMethod(
          Invocation.method(#getMetadata, []),
          returnValue: Future<_i6.FullMetadata>.value(_FakeFullMetadata_8()))
      as _i8.Future<_i6.FullMetadata>);
  @override
  _i8.Future<_i5.ListResult> list([_i6.ListOptions? options]) =>
      (super.noSuchMethod(Invocation.method(#list, [options]),
              returnValue: Future<_i5.ListResult>.value(_FakeListResult_9()))
          as _i8.Future<_i5.ListResult>);
  @override
  _i8.Future<_i5.ListResult> listAll() =>
      (super.noSuchMethod(Invocation.method(#listAll, []),
              returnValue: Future<_i5.ListResult>.value(_FakeListResult_9()))
          as _i8.Future<_i5.ListResult>);
  @override
  _i8.Future<_i11.Uint8List?> getData([int? maxSize = 10485760]) =>
      (super.noSuchMethod(Invocation.method(#getData, [maxSize]),
              returnValue: Future<_i11.Uint8List?>.value())
          as _i8.Future<_i11.Uint8List?>);
  @override
  _i5.UploadTask putData(_i11.Uint8List? data,
          [_i6.SettableMetadata? metadata]) =>
      (super.noSuchMethod(Invocation.method(#putData, [data, metadata]),
          returnValue: _FakeUploadTask_10()) as _i5.UploadTask);
  @override
  _i5.UploadTask putBlob(dynamic blob, [_i6.SettableMetadata? metadata]) =>
      (super.noSuchMethod(Invocation.method(#putBlob, [blob, metadata]),
          returnValue: _FakeUploadTask_10()) as _i5.UploadTask);
  @override
  _i5.UploadTask putFile(_i12.File? file, [_i6.SettableMetadata? metadata]) =>
      (super.noSuchMethod(Invocation.method(#putFile, [file, metadata]),
          returnValue: _FakeUploadTask_10()) as _i5.UploadTask);
  @override
  _i5.UploadTask putString(String? data,
          {_i6.PutStringFormat? format = _i6.PutStringFormat.raw,
          _i6.SettableMetadata? metadata}) =>
      (super.noSuchMethod(
          Invocation.method(
              #putString, [data], {#format: format, #metadata: metadata}),
          returnValue: _FakeUploadTask_10()) as _i5.UploadTask);
  @override
  _i8.Future<_i6.FullMetadata> updateMetadata(_i6.SettableMetadata? metadata) =>
      (super.noSuchMethod(Invocation.method(#updateMetadata, [metadata]),
              returnValue:
                  Future<_i6.FullMetadata>.value(_FakeFullMetadata_8()))
          as _i8.Future<_i6.FullMetadata>);
  @override
  _i5.DownloadTask writeToFile(_i12.File? file) =>
      (super.noSuchMethod(Invocation.method(#writeToFile, [file]),
          returnValue: _FakeDownloadTask_11()) as _i5.DownloadTask);
}
