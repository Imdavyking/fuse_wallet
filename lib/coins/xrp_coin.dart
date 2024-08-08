// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';
import '../extensions/big_int_ext.dart';
import '../service/wallet_service.dart';
import 'package:base_x/base_x.dart';
import 'package:flutter/foundation.dart';
import 'package:hash/hash.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:crypto/crypto.dart';

import '../interface/coin.dart';
import '../main.dart';
import '../model/seed_phrase_root.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';
import '../xrp_transaction/xrp_transaction.dart';

const xrpDecimals = 6;

class XRPCoin extends Coin {
  String api;
  String geckoID;

  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;
  String rampID;
  String payScheme;

  XRPCoin({
    required this.blockExplorer,
    required this.symbol,
    required this.default_,
    required this.image,
    required this.name,
    required this.api,
    required this.geckoID,
    required this.rampID,
    required this.payScheme,
  });

  @override
  String getExplorer() {
    return blockExplorer;
  }

  @override
  String getDefault() {
    return default_;
  }

  @override
  String getImage() {
    return image;
  }

  @override
  String getName() {
    return name;
  }

  @override
  bool requireMemo() => true;

  @override
  String getSymbol() {
    return symbol;
  }

  factory XRPCoin.fromJson(Map<String, dynamic> json) {
    return XRPCoin(
      api: json['api'],
      blockExplorer: json['blockExplorer'],
      default_: json['default'],
      symbol: json['symbol'],
      image: json['image'],
      name: json['name'],
      geckoID: json['geckoID'],
      rampID: json['rampID'],
      payScheme: json['payScheme'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['api'] = api;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;
    data['geckoID'] = geckoID;
    data['rampID'] = rampID;
    data['image'] = image;
    data['payScheme'] = payScheme;
    return data;
  }

  @override
  Future<AccountData> fromMnemonic({required String mnemonic}) async {
    String saveKey = 'xrpDetails${walletImportType.name}';
    Map<String, dynamic> mnemonicMap = {};

    if (pref.containsKey(saveKey)) {
      mnemonicMap = Map<String, dynamic>.from(jsonDecode(pref.get(saveKey)));
      if (mnemonicMap.containsKey(mnemonic)) {
        return AccountData.fromJson(mnemonicMap[mnemonic]);
      }
    }

    final args = XRPArgs(seedRoot: seedPhraseRoot);

    final keys = await compute(calculateRippleKey, args);

    mnemonicMap[mnemonic] = keys;

    await pref.put(saveKey, jsonEncode(mnemonicMap));

    return AccountData.fromJson(keys);
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await getAddress();
    final key = 'xrpAddressBalance$address$api';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;
    try {
      final httpFromWs = Uri.parse(api);
      final request = await post(
        httpFromWs,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "method": "account_info",
          "params": [
            {"account": address}
          ]
        }),
      );

      if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
        throw Exception(request.body);
      }

      Map accountInfo = json.decode(request.body);

      if (accountInfo['result']['account_data'] == null) {
        throw Exception('Account not found');
      }

      final balance = accountInfo['result']['account_data']['Balance'];

      final base = BigInt.from(10);

      double userBalance = BigInt.parse(balance) / base.pow(decimals());
      await pref.put(key, userBalance);

      return userBalance;
    } catch (e) {
      return savedBalance;
    }
  }

  @override
  Future<String?> transferToken(
    String amount,
    String to, {
    String? memo,
  }) async {
    final data = WalletService.getActiveKey(walletImportType)!.data;
    final getXRPDetails = await importData(data);

    final amountInDrop = amount.toBigIntDec(xrpDecimals);

    Map xrpJson = {
      "Account": getXRPDetails.address,
      "Fee": "10",
      "Sequence": 0,
      "TransactionType": "Payment",
      "SigningPubKey": getXRPDetails.publicKey,
      "Amount": "$amountInDrop",
      "Destination": to,
    };

    if (memo != null) {
      xrpJson['DestinationTag'] = int.parse(memo);
    }

    if (getXRPDetails.address == to) {
      throw Exception(
        'An XRP payment transaction cannot have the same sender and destination',
      );
    }

    Map? ledgers = await getXrpLedgerSequence(getXRPDetails.address, api);

    Map? fee = await getXrpFee(api);

    if (ledgers != null) {
      xrpJson = {...xrpJson, ...ledgers};
    }
    if (fee != null) {
      xrpJson = {...xrpJson, ...fee};
    }

    Map xrpTransaction = signXrpTransaction(getXRPDetails.privateKey!, xrpJson);

    final httpFromWs = Uri.parse(api);
    final request = await post(
      httpFromWs,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "method": "submit",
        "params": [
          {
            "tx_blob": encodeXrpJson(xrpTransaction).substring(8),
          }
        ]
      }),
    );

    if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
      throw Exception(request.body);
    }

    Map txInfo = json.decode(request.body);

    final hash = txInfo['result']["tx_json"]['hash'];

    return hash;
  }

  @override
  String savedTransKey() {
    return '$default_$api Details';
  }

  @override
  validateAddress(String address) {
    final bytes = xrpBaseCodec.decode(address);

    final computedCheckSum = sha256
        .convert(sha256.convert(bytes.sublist(0, bytes.length - 4)).bytes)
        .bytes
        .sublist(0, 4);
    final expectedCheckSum = bytes.sublist(bytes.length - 4);

    if (!seqEqual(computedCheckSum as Uint8List, expectedCheckSum)) {
      throw Exception('Invalid XRP address');
    }
  }

  @override
  int decimals() {
    return xrpDecimals;
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    final fee = await getXrpFee(api);
    return double.parse(fee!['Fee']) / pow(10, xrpDecimals);
  }

  @override
  Future<String> addressExplorer() async {
    final address = await getAddress();
    return blockExplorer
        .replaceFirst('/transactions/', '/accounts/')
        .replaceFirst(blockExplorerPlaceholder, address);
  }

  @override
  String getGeckoId() => geckoID;

  @override
  String getPayScheme() => payScheme;

  @override
  String getRampID() => rampID;
}

List<XRPCoin> getXRPBlockChains() {
  List<XRPCoin> blockChains = [];
  if (enableTestNet) {
    blockChains.add(
      XRPCoin(
        name: 'XRP(Testnet)',
        symbol: 'XRP',
        default_: 'XRP',
        blockExplorer:
            'https://testnet.xrpl.org/transactions/$blockExplorerPlaceholder',
        image: 'assets/ripple.png',
        api: 'https://s.altnet.rippletest.net:51234/',
        geckoID: 'ripple',
        payScheme: 'ripple',
        rampID: "XRP_XRP",
      ),
    );
  } else {
    blockChains.addAll([
      XRPCoin(
        name: 'XRP',
        symbol: 'XRP',
        default_: 'XRP',
        blockExplorer:
            'https://livenet.xrpl.org/transactions/$blockExplorerPlaceholder',
        image: 'assets/ripple.png',
        api: 'https://s1.ripple.com:51234/',
        geckoID: 'ripple',
        payScheme: 'ripple',
        rampID: "XRP_XRP",
      ),
    ]);
  }
  return blockChains;
}

Future<Map?> getXrpLedgerSequence(
  String address,
  String ws,
) async {
  try {
    final httpFromWs = Uri.parse(ws);
    final request = await post(
      httpFromWs,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "method": "account_info",
        "params": [
          {
            "account": address,
            "ledger_index": "current",
          }
        ]
      }),
    );

    if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
      throw Exception(request.body);
    }

    Map accountInfo = json.decode(request.body);

    final accountData = accountInfo['result']['account_data'];
    if (accountData == null) {
      throw Exception('Account not found');
    }

    return {
      'Sequence': accountData['Sequence'],
      'Flags': accountData['Flags'],
    };
  } catch (e) {
    return null;
  }
}

Future<Map?> getXrpFee(String ws) async {
  try {
    final httpFromWs = Uri.parse(ws);
    final request = await post(
      httpFromWs,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'method': 'fee',
        'params': [{}]
      }),
    );

    if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
      throw Exception(request.body);
    }

    Map feeInfo = json.decode(request.body);

    return {
      'Fee': feeInfo['result']['drops']['base_fee'],
    };
  } catch (e) {
    return null;
  }
}

Future<bool> fundRippleTestnet(String address) async {
  try {
    const ws = 'https://faucet.altnet.rippletest.net/accounts';
    final httpFromWs = Uri.parse(ws);
    final request = await post(
      httpFromWs,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({"destination": address}),
    );

    if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
      throw Exception(request.body);
    }
    return true;
  } catch (e) {
    return false;
  }
}

final xrpBaseCodec =
    BaseXCodec('rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz');

class XRPArgs {
  final SeedPhraseRoot seedRoot;

  const XRPArgs({
    required this.seedRoot,
  });
}

Map<String, String> calculateRippleKey(XRPArgs config) {
  SeedPhraseRoot seedRoot_ = config.seedRoot;
  final node = seedRoot_.root.derivePath("m/44'/144'/0'/0/0");

  final pubKeyHash = computePublicKeyHash(node.publicKey);

  final t = sha256
      .convert(sha256.convert([0, ...pubKeyHash]).bytes)
      .bytes
      .sublist(0, 4);

  String address =
      xrpBaseCodec.encode(Uint8List.fromList([0, ...pubKeyHash, ...t]));
  return {
    'address': address,
    'publicKey': HEX.encode(node.publicKey),
    'privateKey': HEX.encode(node.privateKey!),
  };
}

Uint8List computePublicKeyHash(Uint8List publicKeyBytes) {
  final hash256 = sha256.convert(publicKeyBytes).bytes;
  final hash160 = RIPEMD160().update(hash256).digest();

  return Uint8List.fromList(hash160);
}
