///
//  Generated code. Do not modify.
//  source: cosmos/slashing/v1beta1/slashing.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use validatorSigningInfoDescriptor instead')
const ValidatorSigningInfo$json = const {
  '1': 'ValidatorSigningInfo',
  '2': const [
    const {'1': 'address', '3': 1, '4': 1, '5': 9, '10': 'address'},
    const {'1': 'start_height', '3': 2, '4': 1, '5': 3, '8': const {}, '10': 'startHeight'},
    const {'1': 'index_offset', '3': 3, '4': 1, '5': 3, '8': const {}, '10': 'indexOffset'},
    const {'1': 'jailed_until', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '8': const {}, '10': 'jailedUntil'},
    const {'1': 'tombstoned', '3': 5, '4': 1, '5': 8, '10': 'tombstoned'},
    const {'1': 'missed_blocks_counter', '3': 6, '4': 1, '5': 3, '8': const {}, '10': 'missedBlocksCounter'},
  ],
  '7': const {},
};

/// Descriptor for `ValidatorSigningInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List validatorSigningInfoDescriptor = $convert.base64Decode('ChRWYWxpZGF0b3JTaWduaW5nSW5mbxIYCgdhZGRyZXNzGAEgASgJUgdhZGRyZXNzEjoKDHN0YXJ0X2hlaWdodBgCIAEoA0IX8t4fE3lhbWw6InN0YXJ0X2hlaWdodCJSC3N0YXJ0SGVpZ2h0EjoKDGluZGV4X29mZnNldBgDIAEoA0IX8t4fE3lhbWw6ImluZGV4X29mZnNldCJSC2luZGV4T2Zmc2V0El4KDGphaWxlZF91bnRpbBgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCH8jeHwDy3h8TeWFtbDoiamFpbGVkX3VudGlsIpDfHwFSC2phaWxlZFVudGlsEh4KCnRvbWJzdG9uZWQYBSABKAhSCnRvbWJzdG9uZWQSVAoVbWlzc2VkX2Jsb2Nrc19jb3VudGVyGAYgASgDQiDy3h8ceWFtbDoibWlzc2VkX2Jsb2Nrc19jb3VudGVyIlITbWlzc2VkQmxvY2tzQ291bnRlcjoImKAfAOigHwE=');
@$core.Deprecated('Use paramsDescriptor instead')
const Params$json = const {
  '1': 'Params',
  '2': const [
    const {'1': 'signed_blocks_window', '3': 1, '4': 1, '5': 3, '8': const {}, '10': 'signedBlocksWindow'},
    const {'1': 'min_signed_per_window', '3': 2, '4': 1, '5': 12, '8': const {}, '10': 'minSignedPerWindow'},
    const {'1': 'downtime_jail_duration', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '8': const {}, '10': 'downtimeJailDuration'},
    const {'1': 'slash_fraction_double_sign', '3': 4, '4': 1, '5': 12, '8': const {}, '10': 'slashFractionDoubleSign'},
    const {'1': 'slash_fraction_downtime', '3': 5, '4': 1, '5': 12, '8': const {}, '10': 'slashFractionDowntime'},
  ],
};

/// Descriptor for `Params`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List paramsDescriptor = $convert.base64Decode('CgZQYXJhbXMSUQoUc2lnbmVkX2Jsb2Nrc193aW5kb3cYASABKANCH/LeHxt5YW1sOiJzaWduZWRfYmxvY2tzX3dpbmRvdyJSEnNpZ25lZEJsb2Nrc1dpbmRvdxKBAQoVbWluX3NpZ25lZF9wZXJfd2luZG93GAIgASgMQk7I3h8A2t4fJmdpdGh1Yi5jb20vY29zbW9zL2Nvc21vcy1zZGsvdHlwZXMuRGVj8t4fHHlhbWw6Im1pbl9zaWduZWRfcGVyX3dpbmRvdyJSEm1pblNpZ25lZFBlcldpbmRvdxJ6ChZkb3dudGltZV9qYWlsX2R1cmF0aW9uGAMgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uQinI3h8A8t4fHXlhbWw6ImRvd250aW1lX2phaWxfZHVyYXRpb24imN8fAVIUZG93bnRpbWVKYWlsRHVyYXRpb24SkAEKGnNsYXNoX2ZyYWN0aW9uX2RvdWJsZV9zaWduGAQgASgMQlPI3h8A2t4fJmdpdGh1Yi5jb20vY29zbW9zL2Nvc21vcy1zZGsvdHlwZXMuRGVj8t4fIXlhbWw6InNsYXNoX2ZyYWN0aW9uX2RvdWJsZV9zaWduIlIXc2xhc2hGcmFjdGlvbkRvdWJsZVNpZ24SiAEKF3NsYXNoX2ZyYWN0aW9uX2Rvd250aW1lGAUgASgMQlDI3h8A2t4fJmdpdGh1Yi5jb20vY29zbW9zL2Nvc21vcy1zZGsvdHlwZXMuRGVj8t4fHnlhbWw6InNsYXNoX2ZyYWN0aW9uX2Rvd250aW1lIlIVc2xhc2hGcmFjdGlvbkRvd250aW1l');
