///
//  Generated code. Do not modify.
//  source: cosmos/authz/v1beta1/authz.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../../google/protobuf/any.pb.dart' as $3;
import '../../../google/protobuf/timestamp.pb.dart' as $4;

class GenericAuthorization extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GenericAuthorization', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'cosmos.authz.v1beta1'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'msg')
    ..hasRequiredFields = false
  ;

  GenericAuthorization._() : super();
  factory GenericAuthorization({
    $core.String? msg,
  }) {
    final _result = create();
    if (msg != null) {
      _result.msg = msg;
    }
    return _result;
  }
  factory GenericAuthorization.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GenericAuthorization.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GenericAuthorization clone() => GenericAuthorization()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GenericAuthorization copyWith(void Function(GenericAuthorization) updates) => super.copyWith((message) => updates(message as GenericAuthorization)) as GenericAuthorization; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GenericAuthorization create() => GenericAuthorization._();
  GenericAuthorization createEmptyInstance() => create();
  static $pb.PbList<GenericAuthorization> createRepeated() => $pb.PbList<GenericAuthorization>();
  @$core.pragma('dart2js:noInline')
  static GenericAuthorization getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GenericAuthorization>(create);
  static GenericAuthorization? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get msg => $_getSZ(0);
  @$pb.TagNumber(1)
  set msg($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMsg() => $_has(0);
  @$pb.TagNumber(1)
  void clearMsg() => clearField(1);
}

class Grant extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Grant', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'cosmos.authz.v1beta1'), createEmptyInstance: create)
    ..aOM<$3.Any>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'authorization', subBuilder: $3.Any.create)
    ..aOM<$4.Timestamp>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expiration', subBuilder: $4.Timestamp.create)
    ..hasRequiredFields = false
  ;

  Grant._() : super();
  factory Grant({
    $3.Any? authorization,
    $4.Timestamp? expiration,
  }) {
    final _result = create();
    if (authorization != null) {
      _result.authorization = authorization;
    }
    if (expiration != null) {
      _result.expiration = expiration;
    }
    return _result;
  }
  factory Grant.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Grant.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Grant clone() => Grant()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Grant copyWith(void Function(Grant) updates) => super.copyWith((message) => updates(message as Grant)) as Grant; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Grant create() => Grant._();
  Grant createEmptyInstance() => create();
  static $pb.PbList<Grant> createRepeated() => $pb.PbList<Grant>();
  @$core.pragma('dart2js:noInline')
  static Grant getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Grant>(create);
  static Grant? _defaultInstance;

  @$pb.TagNumber(1)
  $3.Any get authorization => $_getN(0);
  @$pb.TagNumber(1)
  set authorization($3.Any v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasAuthorization() => $_has(0);
  @$pb.TagNumber(1)
  void clearAuthorization() => clearField(1);
  @$pb.TagNumber(1)
  $3.Any ensureAuthorization() => $_ensure(0);

  @$pb.TagNumber(2)
  $4.Timestamp get expiration => $_getN(1);
  @$pb.TagNumber(2)
  set expiration($4.Timestamp v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasExpiration() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpiration() => clearField(2);
  @$pb.TagNumber(2)
  $4.Timestamp ensureExpiration() => $_ensure(1);
}

class GrantAuthorization extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GrantAuthorization', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'cosmos.authz.v1beta1'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'granter')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'grantee')
    ..aOM<$3.Any>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'authorization', subBuilder: $3.Any.create)
    ..aOM<$4.Timestamp>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expiration', subBuilder: $4.Timestamp.create)
    ..hasRequiredFields = false
  ;

  GrantAuthorization._() : super();
  factory GrantAuthorization({
    $core.String? granter,
    $core.String? grantee,
    $3.Any? authorization,
    $4.Timestamp? expiration,
  }) {
    final _result = create();
    if (granter != null) {
      _result.granter = granter;
    }
    if (grantee != null) {
      _result.grantee = grantee;
    }
    if (authorization != null) {
      _result.authorization = authorization;
    }
    if (expiration != null) {
      _result.expiration = expiration;
    }
    return _result;
  }
  factory GrantAuthorization.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GrantAuthorization.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GrantAuthorization clone() => GrantAuthorization()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GrantAuthorization copyWith(void Function(GrantAuthorization) updates) => super.copyWith((message) => updates(message as GrantAuthorization)) as GrantAuthorization; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GrantAuthorization create() => GrantAuthorization._();
  GrantAuthorization createEmptyInstance() => create();
  static $pb.PbList<GrantAuthorization> createRepeated() => $pb.PbList<GrantAuthorization>();
  @$core.pragma('dart2js:noInline')
  static GrantAuthorization getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GrantAuthorization>(create);
  static GrantAuthorization? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get granter => $_getSZ(0);
  @$pb.TagNumber(1)
  set granter($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGranter() => $_has(0);
  @$pb.TagNumber(1)
  void clearGranter() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get grantee => $_getSZ(1);
  @$pb.TagNumber(2)
  set grantee($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGrantee() => $_has(1);
  @$pb.TagNumber(2)
  void clearGrantee() => clearField(2);

  @$pb.TagNumber(3)
  $3.Any get authorization => $_getN(2);
  @$pb.TagNumber(3)
  set authorization($3.Any v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasAuthorization() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthorization() => clearField(3);
  @$pb.TagNumber(3)
  $3.Any ensureAuthorization() => $_ensure(2);

  @$pb.TagNumber(4)
  $4.Timestamp get expiration => $_getN(3);
  @$pb.TagNumber(4)
  set expiration($4.Timestamp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasExpiration() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpiration() => clearField(4);
  @$pb.TagNumber(4)
  $4.Timestamp ensureExpiration() => $_ensure(3);
}

