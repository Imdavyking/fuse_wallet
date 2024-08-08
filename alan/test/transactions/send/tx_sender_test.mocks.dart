// Mocks generated by Mockito 5.2.0 from annotations
// in alan/test/transactions/send/tx_sender_test.dart.
// Do not manually edit this file.

import 'dart:async' as _i6;

import 'package:alan/proto/cosmos/tx/v1beta1/service.pb.dart' as _i5;
import 'package:alan/proto/cosmos/tx/v1beta1/service.pbgrpc.dart' as _i4;
import 'package:grpc/service_api.dart' as _i2;
import 'package:grpc/src/client/call.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types

class _FakeResponseFuture_0<R> extends _i1.Fake
    implements _i2.ResponseFuture<R> {}

class _FakeClientCall_1<Q, R> extends _i1.Fake
    implements _i3.ClientCall<Q, R> {}

class _FakeResponseStream_2<R> extends _i1.Fake
    implements _i2.ResponseStream<R> {}

/// A class which mocks [ServiceClient].
///
/// See the documentation for Mockito's code generation for more information.
class MockServiceClient extends _i1.Mock implements _i4.ServiceClient {
  MockServiceClient() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.ResponseFuture<_i5.SimulateResponse> simulate(
          _i5.SimulateRequest? request,
          {_i2.CallOptions? options}) =>
      (super.noSuchMethod(
              Invocation.method(#simulate, [request], {#options: options}),
              returnValue: _FakeResponseFuture_0<_i5.SimulateResponse>())
          as _i2.ResponseFuture<_i5.SimulateResponse>);
  @override
  _i2.ResponseFuture<_i5.GetTxResponse> getTx(_i5.GetTxRequest? request,
          {_i2.CallOptions? options}) =>
      (super.noSuchMethod(
              Invocation.method(#getTx, [request], {#options: options}),
              returnValue: _FakeResponseFuture_0<_i5.GetTxResponse>())
          as _i2.ResponseFuture<_i5.GetTxResponse>);
  @override
  _i2.ResponseFuture<_i5.BroadcastTxResponse> broadcastTx(
          _i5.BroadcastTxRequest? request,
          {_i2.CallOptions? options}) =>
      (super.noSuchMethod(
              Invocation.method(#broadcastTx, [request], {#options: options}),
              returnValue: _FakeResponseFuture_0<_i5.BroadcastTxResponse>())
          as _i2.ResponseFuture<_i5.BroadcastTxResponse>);
  @override
  _i2.ResponseFuture<_i5.GetTxsEventResponse> getTxsEvent(
          _i5.GetTxsEventRequest? request,
          {_i2.CallOptions? options}) =>
      (super.noSuchMethod(
              Invocation.method(#getTxsEvent, [request], {#options: options}),
              returnValue: _FakeResponseFuture_0<_i5.GetTxsEventResponse>())
          as _i2.ResponseFuture<_i5.GetTxsEventResponse>);
  @override
  _i2.ResponseFuture<_i5.GetBlockWithTxsResponse> getBlockWithTxs(
          _i5.GetBlockWithTxsRequest? request,
          {_i2.CallOptions? options}) =>
      (super.noSuchMethod(
          Invocation.method(#getBlockWithTxs, [request], {#options: options}),
          returnValue:
              _FakeResponseFuture_0<_i5.GetBlockWithTxsResponse>()) as _i2
          .ResponseFuture<_i5.GetBlockWithTxsResponse>);
  @override
  _i3.ClientCall<Q, R> $createCall<Q, R>(
          _i2.ClientMethod<Q, R>? method, _i6.Stream<Q>? requests,
          {_i2.CallOptions? options}) =>
      (super.noSuchMethod(
          Invocation.method(
              #$createCall, [method, requests], {#options: options}),
          returnValue: _FakeClientCall_1<Q, R>()) as _i3.ClientCall<Q, R>);
  @override
  _i2.ResponseFuture<R> $createUnaryCall<Q, R>(
          _i2.ClientMethod<Q, R>? method, Q? request,
          {_i2.CallOptions? options}) =>
      (super.noSuchMethod(
          Invocation.method(
              #$createUnaryCall, [method, request], {#options: options}),
          returnValue: _FakeResponseFuture_0<R>()) as _i2.ResponseFuture<R>);
  @override
  _i2.ResponseStream<R> $createStreamingCall<Q, R>(
          _i2.ClientMethod<Q, R>? method, _i6.Stream<Q>? requests,
          {_i2.CallOptions? options}) =>
      (super.noSuchMethod(
          Invocation.method(
              #$createStreamingCall, [method, requests], {#options: options}),
          returnValue: _FakeResponseStream_2<R>()) as _i2.ResponseStream<R>);
}
