import 'dart:convert';
import 'dart:typed_data';
import 'package:bs58/bs58.dart';
import 'package:crypto/crypto.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:near_api_flutter/src/models/action_types.dart';
import 'package:near_api_flutter/src/models/keys/public_key.dart';
import '../models/actions/action_function_call.dart';
import '../models/actions/action_transfer.dart';
import '../models/transaction_dto.dart';
import '../models/signature/signature.dart';
import '../models/signed_transactions/signed_transaction_function_call.dart';
import '../models/signed_transactions/signed_transaction_transfer.dart';
import '../models/transactions/transaction_function_call.dart';
import '../models/transactions/transaction_transfer.dart';
import '../utils.dart';

// The dart method for key generation and transaction signing
class TransactionManager {
  static Uint8List serializeTransferTransaction(Transaction transaction) {
    return TransferTransaction(
            transferActions: [
          TransferAction(
              actionNumber: ActionType.transfer.value,
              transferActionArgs: TransferActionArgs(
                  deposit: Utils.decodeNearDeposit(transaction.nearAmount)))
        ],
            blockHash: base58.decode(transaction.accessKey.blockHash),
            nonce: BigInt.from(transaction.accessKey.nonce),
            publicKey: PublicKey(
                data: base58.decode(transaction.publicKey), keyType: 0),
            receiverId: transaction.receiver,
            signerId: transaction.signer)
        .toBorsh();
  }

  static Uint8List serializeSignedTransferTransaction(
      Transaction transaction, signature) {
    return SignedTransferTransaction(
            transferTransaction: TransferTransaction(
                transferActions: [
                  TransferAction(
                      actionNumber: ActionType.transfer.value,
                      transferActionArgs: TransferActionArgs(
                          deposit:
                              Utils.decodeNearDeposit(transaction.nearAmount)))
                ],
                blockHash: base58.decode(transaction.accessKey.blockHash),
                nonce: BigInt.from(transaction.accessKey.nonce),
                publicKey: PublicKey(
                    data: base58.decode(transaction.publicKey), keyType: 0),
                receiverId: transaction.receiver,
                signerId: transaction.signer),
            signature: Signature(keyType: 0, data: signature))
        .toBorsh();
  }

  static Uint8List serializeFunctionCallTransaction(Transaction transaction) {
    return FunctionCallTransaction(
            functionCallActions: [
          FunctionCallAction(
              actionNumber: ActionType.functionCall.value,
              functionCallActionArgs: FunctionCallActionArgs(
                  methodName: transaction.methodName,
                  args: transaction.methodArgs,
                  gas: BigInt.from(transaction.gasFees),
                  deposit: Utils.decodeNearDeposit(transaction.nearAmount)))
        ],
            blockHash: base58.decode(transaction.accessKey.blockHash),
            nonce: BigInt.from(transaction.accessKey.nonce),
            publicKey: PublicKey(
                data: base58.decode(transaction.publicKey), keyType: 0),
            receiverId: transaction.receiver,
            signerId: transaction.signer)
        .toBorsh();
  }

  static Uint8List serializeSignedFunctionCallTransaction(
      Transaction transaction, signature) {
    return SignedFunctionCallTransaction(
            functionCallTransaction: FunctionCallTransaction(
                functionCallActions: [
                  FunctionCallAction(
                      actionNumber: ActionType.functionCall.value,
                      functionCallActionArgs: FunctionCallActionArgs(
                          methodName: transaction.methodName,
                          args: transaction.methodArgs,
                          gas: BigInt.from(transaction.gasFees),
                          deposit:
                              Utils.decodeNearDeposit(transaction.nearAmount)))
                ],
                blockHash: base58.decode(transaction.accessKey.blockHash),
                nonce: BigInt.from(transaction.accessKey.nonce),
                publicKey: PublicKey(
                    data: base58.decode(transaction.publicKey), keyType: 0),
                receiverId: transaction.receiver,
                signerId: transaction.signer),
            signature: Signature(keyType: 0, data: signature))
        .toBorsh();
  }

  //signTransaction by user's private key using ed library
  static Uint8List signTransaction(
      ed.PrivateKey privateKey, Uint8List hashedSerializedTx) {
    Uint8List signature = ed.sign(privateKey, hashedSerializedTx);
    return signature;
  }

  static encodeSerialization(Uint8List serialization) {
    return base64Encode(serialization);
  }

  static Uint8List toSHA256(Uint8List serializedTransaction) {
    return Uint8List.fromList(sha256.convert(serializedTransaction).bytes);
  }
}
