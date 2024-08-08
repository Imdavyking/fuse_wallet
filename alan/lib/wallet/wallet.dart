import 'dart:typed_data';

import 'package:alan/alan.dart';
import 'package:alan/wallet/bech32_encoder.dart';
import 'package:equatable/equatable.dart';
import 'package:hex/hex.dart';
import 'package:pointycastle/export.dart';

/// Represents a wallet which contains the hex private key, the hex public key
/// and the hex address.
/// In order to create one properly, the [Wallet.derive] method should always
/// be used.
/// The associated [networkInfo] will be used when computing the [bech32Address]
/// associated with the wallet.
class Wallet extends Equatable {
  static const derivationPath = "m/44'/118'/0'/0/0";

  final Uint8List address;
  final Uint8List privateKey;
  final Uint8List publicKey;

  final NetworkInfo networkInfo;

  Wallet({
    required this.networkInfo,
    required this.address,
    required this.privateKey,
    required this.publicKey,
  });

  static bool isEthSecp256(String derivationPath) {
    return derivationPath.split('/')[2].trim() == "60'";
  }

  static Uint8List compressPublicKey(Uint8List uncompressedKey) {
    if (uncompressedKey.length != 65 || uncompressedKey[0] != 0x04) {
      throw ArgumentError('Invalid uncompressed public key');
    }

    final x = uncompressedKey.sublist(1, 33);
    final y = uncompressedKey.sublist(33, 65);

    // Determine the prefix based on the parity of the Y-coordinate
    final prefix = (y.last % 2 == 0) ? 0x02 : 0x03;

    final compressedKey = Uint8List(33)
      ..[0] = prefix
      ..setRange(1, 33, x);

    return compressedKey;
  }

  /// Derives the private key from the given [mnemonic] using the specified
  /// [networkInfo].
  factory Wallet.derive(
    List<String> mnemonic,
    NetworkInfo networkInfo, {
    String derivationPath = derivationPath,
  }) {
    // Validate the mnemonic
    if (!Bip39.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic');
    }

    // Convert the mnemonic to a BIP32 instance
    final seed = Bip39.mnemonicToSeed(mnemonic);
    final root = Bip32.fromSeed(seed);

    // Get the node from the derivation path
    final derivedNode = root.derivePath(derivationPath);

    // Get the curve data
    final secp256k1 = ECCurve_secp256k1();
    final point = secp256k1.G;

    // Compute the curve point associated to the private key
    final bigInt = BigInt.parse(HEX.encode(derivedNode.privateKey!), radix: 16);
    final curvePoint = point * bigInt;

    Uint8List publicKeyBytes;
    Uint8List address;

    if (isEthSecp256(derivationPath)) {
      publicKeyBytes = curvePoint!.getEncoded(false);
      final keccakAddress = KeccakDigest(256)
          .process(publicKeyBytes.sublist(1, publicKeyBytes.length));
      address = keccakAddress.sublist(
          keccakAddress.length - 20, keccakAddress.length);
    } else {
      publicKeyBytes = curvePoint!.getEncoded();
      final sha256Digest = SHA256Digest().process(publicKeyBytes);
      address = RIPEMD160Digest().process(sha256Digest);
    }

    if (publicKeyBytes.length == 65) {
      publicKeyBytes = compressPublicKey(publicKeyBytes);
    }

    // Return the key bytes
    return Wallet(
      address: address,
      publicKey: publicKeyBytes,
      privateKey: derivedNode.privateKey!,
      networkInfo: networkInfo,
    );
  }

  /// Generated a new random [Wallet] using the specified [networkInfo]
  /// and the optional [derivationPath].
  factory Wallet.random(
    NetworkInfo networkInfo, {
    String derivationPath = derivationPath,
  }) {
    return Wallet.derive(
      Bip39.generateMnemonic(strength: 256),
      networkInfo,
      derivationPath: derivationPath,
    );
  }

  /// Creates a new [Wallet] instance based on the existent [wallet] for
  /// the given [networkInfo].
  factory Wallet.convert(
    Wallet wallet,
    NetworkInfo networkInfo,
  ) {
    return Wallet(
      networkInfo: networkInfo,
      address: wallet.address,
      privateKey: wallet.privateKey,
      publicKey: wallet.publicKey,
    );
  }

  /// Creates a new [Wallet] instance from the given [json] and [privateKey].
  factory Wallet.fromJson(
    Map<String, dynamic> json,
    Uint8List privateKey,
  ) {
    return Wallet(
      address: Uint8List.fromList(HEX.decode(json['hex_address'] as String)),
      publicKey: Uint8List.fromList(HEX.decode(json['public_key'] as String)),
      privateKey: privateKey,
      networkInfo: NetworkInfo.fromJson(
        json['network_info'] as Map<String, dynamic>,
      ),
    );
  }

  /// Creates a new [Wallet] instance from [privateKey].
  factory Wallet.import(
    NetworkInfo networkInfo,
    Uint8List privateKey,
  ) {
    final secp256k1 = ECCurve_secp256k1();
    final point = secp256k1.G;
    // Compute the curve point associated to the private key
    final bigInt = BigInt.parse(HEX.encode(privateKey), radix: 16);
    final curvePoint = point * bigInt;

    Uint8List publicKeyBytes;
    Uint8List address;

    if (isEthSecp256(derivationPath)) {
      publicKeyBytes = curvePoint!.getEncoded(false);
      final keccakAddress = KeccakDigest(256)
          .process(publicKeyBytes.sublist(1, publicKeyBytes.length));
      address = keccakAddress.sublist(
          keccakAddress.length - 20, keccakAddress.length);
    } else {
      publicKeyBytes = curvePoint!.getEncoded();
      final sha256Digest = SHA256Digest().process(publicKeyBytes);
      address = RIPEMD160Digest().process(sha256Digest);
    }

    if (publicKeyBytes.length == 65) {
      publicKeyBytes = compressPublicKey(publicKeyBytes);
    }

    return Wallet(
      address: address,
      publicKey: publicKeyBytes,
      privateKey: privateKey,
      networkInfo: networkInfo,
    );
  }

  /// Returns the associated [address] as a Bech32 string.
  String get bech32Address {
    return Bech32Encoder.encode(networkInfo.bech32Hrp, address);
  }

  /// Returns the associated [privateKey] as an [ECPrivateKey] instance.
  ECPrivateKey get _ecPrivateKey {
    final privateKeyInt = BigInt.parse(HEX.encode(privateKey), radix: 16);
    return ECPrivateKey(privateKeyInt, ECCurve_secp256k1());
  }

  /// Returns the associated [publicKey] as an [ECPublicKey] instance.
  ECPublicKey get ecPublicKey {
    final secp256k1 = ECCurve_secp256k1();
    final point = secp256k1.G;
    final curvePoint = point * _ecPrivateKey.d;
    return ECPublicKey(curvePoint, ECCurve_secp256k1());
  }

  /// Normalizes the given [signature] using the provided [curveParams].
  /// This is used to create signatures that are always in the lower-S form, to
  /// make sure that they cannot be tamped with the alternative S value.
  /// More info can be found here: https://tinyurl.com/2yfurry7
  ECSignature _normalizeECSignature(
    ECSignature signature,
    ECDomainParameters curveParams,
  ) {
    var normalizedS = signature.s;
    if (normalizedS.compareTo(curveParams.n >> 1) > 0) {
      normalizedS = curveParams.n - normalizedS;
    }
    return ECSignature(signature.r, normalizedS);
  }

  /// Hashes the given [data] with SHA-256, and then sign the hash using the
  /// private key associated with this wallet, returning the signature
  /// encoded as a 64 bytes array.
  Uint8List sign(Uint8List data, [isSlipp44 = false]) {
    // Select the appropriate hash function based on isSlipp44 flag
    Digest hashFunction = isSlipp44 ? KeccakDigest(256) : SHA256Digest();
    // Hash the data
    Uint8List hash = hashFunction.process(data);

    final ecdsaSigner = ECDSASigner(null, HMac(hashFunction, 64))
      ..init(true, PrivateKeyParameter(_ecPrivateKey));

    final ecSignature = ecdsaSigner.generateSignature(hash) as ECSignature;
    final normalized = _normalizeECSignature(ecSignature, ECCurve_secp256k1());
    final rBytes = normalized.r.toUin8List();
    final sBytes = normalized.s.toUin8List();

    var sigBytes = Uint8List(64);
    copy(rBytes, 32 - rBytes.length, 32, sigBytes);
    copy(sBytes, 64 - sBytes.length, 64, sigBytes);
    return sigBytes;
  }

  /// Converts the current [Wallet] instance into a JSON object.
  /// Note that the private key is not serialized for safety reasons.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'hex_address': HEX.encode(address),
      'bech32_address': bech32Address,
      'public_key': HEX.encode(publicKey),
      'network_info': networkInfo.toJson(),
    };
  }

  @override
  List<Object> get props {
    return [
      networkInfo,
      address,
      privateKey,
      publicKey,
    ];
  }

  @override
  String toString() {
    return '{ '
        'networkInfo: $networkInfo, '
        'address: $address, '
        'publicKey: $publicKey '
        '}';
  }
}
