///
//  Generated code. Do not modify.
//  source: cosmos/staking/v1beta1/genesis.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use genesisStateDescriptor instead')
const GenesisState$json = const {
  '1': 'GenesisState',
  '2': const [
    const {'1': 'params', '3': 1, '4': 1, '5': 11, '6': '.cosmos.staking.v1beta1.Params', '8': const {}, '10': 'params'},
    const {'1': 'last_total_power', '3': 2, '4': 1, '5': 12, '8': const {}, '10': 'lastTotalPower'},
    const {'1': 'last_validator_powers', '3': 3, '4': 3, '5': 11, '6': '.cosmos.staking.v1beta1.LastValidatorPower', '8': const {}, '10': 'lastValidatorPowers'},
    const {'1': 'validators', '3': 4, '4': 3, '5': 11, '6': '.cosmos.staking.v1beta1.Validator', '8': const {}, '10': 'validators'},
    const {'1': 'delegations', '3': 5, '4': 3, '5': 11, '6': '.cosmos.staking.v1beta1.Delegation', '8': const {}, '10': 'delegations'},
    const {'1': 'unbonding_delegations', '3': 6, '4': 3, '5': 11, '6': '.cosmos.staking.v1beta1.UnbondingDelegation', '8': const {}, '10': 'unbondingDelegations'},
    const {'1': 'redelegations', '3': 7, '4': 3, '5': 11, '6': '.cosmos.staking.v1beta1.Redelegation', '8': const {}, '10': 'redelegations'},
    const {'1': 'exported', '3': 8, '4': 1, '5': 8, '10': 'exported'},
  ],
};

/// Descriptor for `GenesisState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List genesisStateDescriptor = $convert.base64Decode('CgxHZW5lc2lzU3RhdGUSPAoGcGFyYW1zGAEgASgLMh4uY29zbW9zLnN0YWtpbmcudjFiZXRhMS5QYXJhbXNCBMjeHwBSBnBhcmFtcxJzChBsYXN0X3RvdGFsX3Bvd2VyGAIgASgMQknI3h8A2t4fJmdpdGh1Yi5jb20vY29zbW9zL2Nvc21vcy1zZGsvdHlwZXMuSW508t4fF3lhbWw6Imxhc3RfdG90YWxfcG93ZXIiUg5sYXN0VG90YWxQb3dlchKEAQoVbGFzdF92YWxpZGF0b3JfcG93ZXJzGAMgAygLMiouY29zbW9zLnN0YWtpbmcudjFiZXRhMS5MYXN0VmFsaWRhdG9yUG93ZXJCJMjeHwDy3h8ceWFtbDoibGFzdF92YWxpZGF0b3JfcG93ZXJzIlITbGFzdFZhbGlkYXRvclBvd2VycxJHCgp2YWxpZGF0b3JzGAQgAygLMiEuY29zbW9zLnN0YWtpbmcudjFiZXRhMS5WYWxpZGF0b3JCBMjeHwBSCnZhbGlkYXRvcnMSSgoLZGVsZWdhdGlvbnMYBSADKAsyIi5jb3Ntb3Muc3Rha2luZy52MWJldGExLkRlbGVnYXRpb25CBMjeHwBSC2RlbGVnYXRpb25zEoYBChV1bmJvbmRpbmdfZGVsZWdhdGlvbnMYBiADKAsyKy5jb3Ntb3Muc3Rha2luZy52MWJldGExLlVuYm9uZGluZ0RlbGVnYXRpb25CJMjeHwDy3h8ceWFtbDoidW5ib25kaW5nX2RlbGVnYXRpb25zIlIUdW5ib25kaW5nRGVsZWdhdGlvbnMSUAoNcmVkZWxlZ2F0aW9ucxgHIAMoCzIkLmNvc21vcy5zdGFraW5nLnYxYmV0YTEuUmVkZWxlZ2F0aW9uQgTI3h8AUg1yZWRlbGVnYXRpb25zEhoKCGV4cG9ydGVkGAggASgIUghleHBvcnRlZA==');
@$core.Deprecated('Use lastValidatorPowerDescriptor instead')
const LastValidatorPower$json = const {
  '1': 'LastValidatorPower',
  '2': const [
    const {'1': 'address', '3': 1, '4': 1, '5': 9, '10': 'address'},
    const {'1': 'power', '3': 2, '4': 1, '5': 3, '10': 'power'},
  ],
  '7': const {},
};

/// Descriptor for `LastValidatorPower`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lastValidatorPowerDescriptor = $convert.base64Decode('ChJMYXN0VmFsaWRhdG9yUG93ZXISGAoHYWRkcmVzcxgBIAEoCVIHYWRkcmVzcxIUCgVwb3dlchgCIAEoA1IFcG93ZXI6CIigHwDooB8A');
