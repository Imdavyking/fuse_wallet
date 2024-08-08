// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:algorand_dart/algorand_dart.dart' as algo_rand;
import '../extensions/big_int_ext.dart';
import '../interface/coin.dart';
import '../main.dart';
import '../model/seed_phrase_root.dart';
import '../service/wallet_service.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';

const algorandDecimals = 6;

class AlgorandCoin extends Coin {
  String api;
  String indexer;
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;
  String geckoID;
  String rampID;
  String payScheme;

  AlgorandCoin({
    required this.blockExplorer,
    required this.symbol,
    required this.default_,
    required this.image,
    required this.name,
    required this.api,
    required this.indexer,
    required this.geckoID,
    required this.payScheme,
    required this.rampID,
  });

  factory AlgorandCoin.fromJson(Map<String, dynamic> json) {
    return AlgorandCoin(
      api: json['api'],
      indexer: json['indexer'],
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
  bool requireMemo() => true;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['api'] = api;
    data['indexer'] = indexer;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;
    data['image'] = image;
    data['geckoID'] = geckoID;
    data['payScheme'] = payScheme;
    data['rampID'] = rampID;

    return data;
  }

  @override
  Future<AccountData> fromMnemonic({required String mnemonic}) async {
    String saveKey = 'algorandDetails${walletImportType.name}$api';
    Map<String, dynamic> mnemonicMap = {};

    if (pref.containsKey(saveKey)) {
      mnemonicMap = Map<String, dynamic>.from(jsonDecode(pref.get(saveKey)));
      if (mnemonicMap.containsKey(mnemonic)) {
        return AccountData.fromJson(mnemonicMap[mnemonic]);
      }
    }

    final args = AlgorandDeriveArgs(
      seedRoot: seedPhraseRoot,
    );

    final keys = await compute(calculateAlgorandKey, args);

    mnemonicMap[mnemonic] = keys;

    await pref.put(saveKey, jsonEncode(mnemonicMap));
    return AccountData.fromJson(keys);
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await getAddress();
    final key = 'algorandAddressBalance$address$api';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      final algoMicro = await _getAlgorandClient().getBalance(address);
      final base = BigInt.from(10);
      final userBalance = BigInt.from(algoMicro) / base.pow(decimals());
      await pref.put(key, userBalance);

      return userBalance;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return savedBalance;
    }
  }

  @override
  bool get supportPrivateKey => true;

  @override
  Future<AccountData> fromPrivateKey(String privateKey) async {
    String saveKey = 'algorandDetailsPrivate${walletImportType.name}$api';
    Map<String, dynamic> privateKeyMap = {};

    if (pref.containsKey(saveKey)) {
      privateKeyMap = Map<String, dynamic>.from(jsonDecode(pref.get(saveKey)));
      if (privateKeyMap.containsKey(privateKey)) {
        return AccountData.fromJson(privateKeyMap[privateKey]);
      }
    }

    final keyPair = await algo_rand.Account.fromPrivateKey(privateKey);

    final address = keyPair.address.toString();

    final keys = AccountData(
      address: address,
      privateKey: privateKey,
    ).toJson();

    privateKeyMap[privateKey] = keys;

    await pref.put(saveKey, jsonEncode(privateKeyMap));

    return AccountData.fromJson(keys);
  }

  @override
  Future<String?> transferToken(String amount, String to,
      {String? memo}) async {
    final data = WalletService.getActiveKey(walletImportType)!.data;
    final response = await importData(data);

    final microAlgos = amount.toBigIntDec(decimals());

    final keyPair =
        await algo_rand.Account.fromPrivateKey(response.privateKey!);

    String signature = await _getAlgorandClient().sendPayment(
      note: memo,
      account: keyPair,
      recipient: algo_rand.Address.fromAlgorandAddress(
        address: to,
      ),
      amount: microAlgos.toInt(),
    );
    return signature;
  }

  @override
  validateAddress(String address) {
    algo_rand.Address.fromAlgorandAddress(
      address: address,
    );
  }

  @override
  int decimals() {
    return algorandDecimals;
  }

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
  String getSymbol() {
    return symbol;
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    return 0.001;
  }

  @override
  Future<String> addressExplorer() async {
    final address = await getAddress();
    return blockExplorer
        .replaceFirst('/tx/', '/address/')
        .replaceFirst(blockExplorerPlaceholder, address);
  }

  algo_rand.Algorand _getAlgorandClient() {
    final _algodClient = algo_rand.AlgodClient(
      apiUrl: api,
      apiKey: pureStakeApiKey,
      tokenKey: algo_rand.PureStake.API_TOKEN_HEADER,
    );

    final _indexerClient = algo_rand.IndexerClient(
      apiUrl: indexer,
      apiKey: pureStakeApiKey,
      tokenKey: algo_rand.PureStake.API_TOKEN_HEADER,
    );

    final _kmdClient = algo_rand.KmdClient(
      apiUrl: '127.0.0.1',
      apiKey: pureStakeApiKey,
    );

    return algo_rand.Algorand(
      algodClient: _algodClient,
      indexerClient: _indexerClient,
      kmdClient: _kmdClient,
    );
  }

  @override
  String getGeckoId() => geckoID;

  @override
  String getPayScheme() => payScheme;

  @override
  String getRampID() => rampID;
}

List<AlgorandCoin> getAlgorandBlockchains() {
  List<AlgorandCoin> blockChains = [];

  if (enableTestNet) {
    blockChains.add(
      AlgorandCoin(
        blockExplorer:
            'https://testnet.explorer.perawallet.app/tx/$blockExplorerPlaceholder',
        symbol: 'ALGO',
        name: 'Algorand(Testnet)',
        default_: 'ALGO',
        image: 'assets/algorand.png',
        api: 'https://testnet-api.algonode.cloud',
        indexer: 'https://testnet-idx.algonode.cloud',
        geckoID: "algorand",
        payScheme: 'algorand',
        rampID: '',
      ),
    );
  } else {
    blockChains.addAll([
      AlgorandCoin(
        blockExplorer:
            'https://explorer.perawallet.app/tx/$blockExplorerPlaceholder',
        symbol: 'ALGO',
        name: 'Algorand',
        default_: 'ALGO',
        image: 'assets/algorand.png',
        api: 'https://mainnet-api.algonode.cloud',
        indexer: 'https://mainnet-idx.algonode.cloud',
        geckoID: "algorand",
        payScheme: 'algorand',
        rampID: '',
      ),
    ]);
  }
  return blockChains;
}

class AlgorandDeriveArgs {
  final SeedPhraseRoot seedRoot;

  const AlgorandDeriveArgs({
    required this.seedRoot,
  });
}

Future<Map> calculateAlgorandKey(AlgorandDeriveArgs config) async {
  SeedPhraseRoot seedRoot_ = config.seedRoot;
  KeyData masterKey =
      await ED25519_HD_KEY.derivePath("m/44'/283'/0'/0'/0'", seedRoot_.seed);

  final privateKey = HEX.encode(masterKey.key);

  final account = await algo_rand.Account.fromPrivateKey(privateKey);

  return {
    'address': account.publicAddress,
    'privateKey': privateKey,
  };
}
