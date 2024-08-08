///
//  Generated code. Do not modify.
//  source: ethermint/evm/v1/tx.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'tx.pb.dart' as $0;
export 'tx.pb.dart';

class MsgClient extends $grpc.Client {
  static final _$ethereumTx =
      $grpc.ClientMethod<$0.MsgEthereumTx, $0.MsgEthereumTxResponse>(
          '/ethermint.evm.v1.Msg/EthereumTx',
          ($0.MsgEthereumTx value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.MsgEthereumTxResponse.fromBuffer(value));

  MsgClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.MsgEthereumTxResponse> ethereumTx(
      $0.MsgEthereumTx request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$ethereumTx, request, options: options);
  }
}

abstract class MsgServiceBase extends $grpc.Service {
  $core.String get $name => 'ethermint.evm.v1.Msg';

  MsgServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.MsgEthereumTx, $0.MsgEthereumTxResponse>(
        'EthereumTx',
        ethereumTx_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.MsgEthereumTx.fromBuffer(value),
        ($0.MsgEthereumTxResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.MsgEthereumTxResponse> ethereumTx_Pre(
      $grpc.ServiceCall call, $async.Future<$0.MsgEthereumTx> request) async {
    return ethereumTx(call, await request);
  }

  $async.Future<$0.MsgEthereumTxResponse> ethereumTx(
      $grpc.ServiceCall call, $0.MsgEthereumTx request);
}
