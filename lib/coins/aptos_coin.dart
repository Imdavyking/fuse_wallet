// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';
import '../extensions/big_int_ext.dart';
import '../service/wallet_service.dart';
import 'package:aptos/aptos.dart';
import 'package:aptos/coin_client.dart';
import 'package:aptos/constants.dart';
import 'package:aptos/faucet_client.dart';
import 'package:flutter/foundation.dart';

import '../interface/coin.dart';
import '../main.dart';
import '../utils/app_config.dart';

const aptosDecimals = 8;

class AptosCoin extends Coin {
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;
  String rpc;
  String geckoID;
  String rampID;
  String payScheme;

  @override
  Future<String> addressExplorer() async {
    final address = await getAddress();
    return blockExplorer
        .replaceFirst('/txn/', '/account/')
        .replaceFirst(blockExplorerPlaceholder, address);
  }

  @override
  String getExplorer() => blockExplorer;

  @override
  String getDefault() => default_;

  @override
  String getImage() => image;

  @override
  String getName() => name;

  @override
  String getSymbol() => symbol;

  AptosCoin({
    required this.blockExplorer,
    required this.symbol,
    required this.default_,
    required this.image,
    required this.name,
    required this.rpc,
    required this.geckoID,
    required this.payScheme,
    required this.rampID,
  });

  factory AptosCoin.fromJson(Map<String, dynamic> json) {
    return AptosCoin(
      blockExplorer: json['blockExplorer'],
      default_: json['default'],
      symbol: json['symbol'],
      image: json['image'],
      name: json['name'],
      rpc: json['rpc'],
      geckoID: json['geckoID'],
      payScheme: json['payScheme'],
      rampID: json['rampID'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['rpc'] = rpc;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;
    data['image'] = image;
    data['payScheme'] = payScheme;
    data['rampID'] = rampID;
    data['geckoID'] = geckoID;
    

    return data;
  }

  @override
  bool get supportKeystore => true;
  @override
  bool get supportPrivateKey => true;
  @override
  Future<AccountData> fromPrivateKey(String privateKey) async {
    String saveKey = 'aptosDetailPrivate${walletImportType.name}';
    Map<String, dynamic> privateKeyMap = {};

    if (pref.containsKey(saveKey)) {
      privateKeyMap = Map<String, dynamic>.from(jsonDecode(pref.get(saveKey)));
      if (privateKeyMap.containsKey(privateKey)) {
        return AccountData.fromJson(privateKeyMap[privateKey]);
      }
    }

    final keyPair = AptosAccount.fromPrivateKey(privateKey);

    final keys = AccountData(
      address: keyPair.address,
      privateKey: privateKey,
    ).toJson();

    privateKeyMap[privateKey] = keys;

    await pref.put(saveKey, jsonEncode(privateKeyMap));

    return AccountData.fromJson(keys);
  }

  @override
  Future<AccountData> fromMnemonic({required String mnemonic}) async {
    String saveKey = 'aptosCoinDetail${walletImportType.name}';
    Map<String, dynamic> mnemonicMap = {};

    if (pref.containsKey(saveKey)) {
      mnemonicMap = Map<String, dynamic>.from(jsonDecode(pref.get(saveKey)));
      if (mnemonicMap.containsKey(mnemonic)) {
        return AccountData.fromJson(mnemonicMap[mnemonic]);
      }
    }

    final args = AptosDeriveArgs(
      mnemonic: mnemonic,
    );

    final keys = await compute(calculateAptosKey, args);

    mnemonicMap[mnemonic] = keys;

    await pref.put(saveKey, jsonEncode(mnemonicMap));

    return AccountData.fromJson(keys);
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await getAddress();

    final key = 'aptosAddressBalance$address$rpc';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      final aptosClient = AptosClient(rpc, enableDebugLog: kDebugMode);
      final coinClient = CoinClient(aptosClient);

      final resp = await coinClient.checkBalance(address);
      final base = BigInt.from(10);
      final balance = resp / base.pow(decimals());

      await pref.put(key, balance);

      return balance;
    } catch (_) {
      return savedBalance;
    }
  }

  @override
  Future<String?> transferToken(String amount, String to,
      {String? memo}) async {
    final miniAptos = amount.toBigIntDec(decimals());
    final data = WalletService.getActiveKey(walletImportType)!.data;
    final response = await importData(data);
    final keyPair = AptosAccount.fromPrivateKey(response.privateKey!);

    final aptosClient = AptosClient(rpc, enableDebugLog: kDebugMode);
    final coinClient = CoinClient(aptosClient);

    final hash = await coinClient.transfer(
      keyPair,
      to,
      miniAptos,
      createReceiverIfMissing: true,
    );

    return hash;
  }

  @override
  validateAddress(String address) {
    if (!RegExp(r"^0x[A-Fa-f0-9]{64}$").hasMatch(address)) {
      throw Exception('Invalid $symbol address');
    }
  }

  @override
  int decimals() {
    return aptosDecimals;
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    final aptosClient = AptosClient(rpc, enableDebugLog: kDebugMode);
    final coinClient = CoinClient(aptosClient);

    bool accountExists = false;
    try {
      accountExists = await coinClient.aptosClient.accountExist(to);
    } catch (_) {}

    switch (rpc) {
      case Constants.devnetAPI:
        if (accountExists) {
          return 0.000005;
        } else {
          return 0.001009;
        }
      case Constants.mainnetAPI:
        if (accountExists) {
          return 0.00160416;
        } else {
          return 0.00532224;
        }

      case Constants.testnetAPI:
        if (accountExists) {
          return 0.0000075;
        } else {
          return 0.0010185;
        }

      default:
        return 0.0;
    }
  }

  @override
  String getGeckoId() => geckoID;

  @override
  String getPayScheme() => payScheme;

  @override
  String getRampID() => rampID;
}

Future<bool> getFaucetToken(String address) async {
  try {
    final faucet = FaucetClient(Constants.faucetDevAPI);
    final amountToFund = 10 * pow(10, aptosDecimals);
    await faucet.fundAccount(address, amountToFund.toString());
    return true;
  } catch (_) {
    return false;
  }
}

List<AptosCoin> getAptosBlockchain() {
  List<AptosCoin> blockChains = [];
  if (enableTestNet) {
    blockChains.add(
      AptosCoin(
        name: 'Aptos(Testnet)',
        symbol: 'APT',
        default_: 'APT',
        blockExplorer:
            'https://explorer.aptoslabs.com/txn/$blockExplorerPlaceholder?network=devnet',
        image: 'assets/aptos.png',
        rpc: Constants.devnetAPI,
        geckoID: "aptos",
        payScheme: 'aptos',
        rampID: '',
      ),
    );
  } else {
    blockChains.addAll([
      AptosCoin(
        name: 'Aptos',
        symbol: 'APT',
        default_: 'APT',
        blockExplorer:
            'https://explorer.aptoslabs.com/txn/$blockExplorerPlaceholder?network=mainnet',
        image: 'assets/aptos.png',
        rpc: Constants.mainnetAPI,
        geckoID: "aptos",
        payScheme: 'aptos',
        rampID: '',
      ),
    ]);
  }

  return blockChains;
}

class AptosDeriveArgs {
  final String mnemonic;

  const AptosDeriveArgs({
    required this.mnemonic,
  });
}

Future calculateAptosKey(AptosDeriveArgs config) async {
  final account = AptosAccount.generateAccount(
    config.mnemonic,
  );

  return {
    'address': account.address,
    'privateKey': HEX.encode(account.signingKey.privateKey.bytes)
  };
}
