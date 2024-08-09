// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';
import '../service/wallet_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:fuse_wallet_sdk/fuse_wallet_sdk.dart' hide Client;
import '../interface/coin.dart';
import '../main.dart';
import '../model/seed_phrase_root.dart';
import '../utils/alt_ens.dart';
import '../utils/app_config.dart';
import '../utils/rpc_urls.dart';
import '../extensions/big_int_ext.dart';
import "package:http/http.dart";

const etherDecimals = 18;

class FuseCoin extends Coin {
  int coinType;
  int chainId;
  String rpc;
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;
  String geckoID;
  String rampID;
  String payScheme;

  FuseCoin({
    required this.blockExplorer,
    required this.symbol,
    required this.default_,
    required this.image,
    required this.coinType,
    required this.rpc,
    required this.chainId,
    required this.name,
    required this.geckoID,
    required this.rampID,
    required this.payScheme,
  });

  @override
  bool get supportKeystore => true;
  @override
  bool get supportPrivateKey => true;

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

  Future<String> stakeToken(String amount, String to) async {
    final fuseSDK = await getSdk();

    final res = await fuseSDK.stakeToken(
      StakeRequestBody(
        accountAddress: fuseSDK.wallet.getSender(),
        tokenAmount: amount,
        tokenAddress: Variables.NATIVE_TOKEN_ADDRESS,
      ),
    );
    return res.userOpHash;
  }

  @override
  String getName() {
    return name;
  }

  @override
  String getSymbol() {
    return symbol;
  }

  factory FuseCoin.fromJson(Map<String, dynamic> json) {
    return FuseCoin(
      chainId: json['chainId'],
      rpc: json['rpc'],
      coinType: json['coinType'],
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
    data['chainId'] = chainId;
    data['rpc'] = rpc;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;
    data['coinType'] = coinType;
    data['image'] = image;
    data['geckoID'] = geckoID;
    data['rampID'] = rampID;
    data['payScheme'] = payScheme;

    return data;
  }

  @override
  Future<AccountData> fromPrivateKey(String privateKey) async {
    String saveKey =
        'ethereumDetailsPrivate4337$coinType${walletImportType.name}';
    Map<String, dynamic> privateKeyMap = {};

    if (pref.containsKey(saveKey)) {
      privateKeyMap = Map<String, dynamic>.from(jsonDecode(pref.get(saveKey)));
      if (privateKeyMap.containsKey(privateKey)) {
        return AccountData.fromJson(privateKeyMap[privateKey]);
      }
    }

    final address = await etherPrivateKeyToAddress(privateKey);

    final keys = AccountData(
      address: address,
      privateKey: privateKey,
    ).toJson();

    privateKeyMap[privateKey] = keys;

    await pref.put(saveKey, jsonEncode(privateKeyMap));

    return AccountData.fromJson(keys);
  }

  @override
  Future<AccountData> fromMnemonic({required String mnemonic}) async {
    String saveKey = 'ethereumDetails4337$coinType${walletImportType.name}';
    Map<String, dynamic> mnemonicMap = {};

    if (pref.containsKey(saveKey)) {
      mnemonicMap = Map<String, dynamic>.from(jsonDecode(pref.get(saveKey)));
      if (mnemonicMap.containsKey(mnemonic)) {
        return AccountData.fromJson(mnemonicMap[mnemonic]);
      }
    }

    final args = EthereumDeriveArgs(
      seedRoot: seedPhraseRoot,
      coinType: coinType,
    );

    final keys = await compute(calculateEthereumKey, args);

    mnemonicMap[mnemonic] = keys;

    await pref.put(saveKey, jsonEncode(mnemonicMap));

    return AccountData.fromJson(keys);
  }

  @override
  Future<String> addressExplorer() async {
    final address = await getAddress();
    return blockExplorer
        .replaceFirst('/tx/', '/address/')
        .replaceFirst(blockExplorerPlaceholder, address);
  }

  @override
  Future<String?> resolveAddress(String address) async {
    Map resolver = await ensToAddr(
      domainName: address,
    );

    if (resolver['success']) {
      return resolver['msg'];
    }

    resolver = await udResolver(
      domainName: address,
      currency: getDefault(),
    );

    if (resolver['success']) {
      return resolver['msg'];
    }
    return null;
  }

  Future<FuseSDK> getSdk() async {
    final data = WalletService.getActiveKey(walletImportType)!.data;
    final response = await importData(data);
    final credentials = EthPrivateKey.fromHex(response.privateKey!);
    const publicApiKey = 'pk_E0S4XB9wT5ycd-WmIWBeb3is';
    return await FuseSDK.init(
      publicApiKey,
      credentials,
    );
  }

  @override
  Future<String> getAddress() async {
    final data = WalletService.getActiveKey(walletImportType)!.data;
    final details = await importData(data);

    final addressKey = '$rpc/address${details.address}';
    final storedAddress = pref.get(addressKey);

    if (storedAddress != null) return storedAddress;
    final FuseSDK fuseSDK = await getSdk();
    final smartAddress = fuseSDK.wallet.getSender();
    await pref.put(addressKey, smartAddress);
    return smartAddress;
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    String address = roninAddrToEth(await getAddress());

    final tokenKey = '$rpc$address/balance4337';
    final storedBalance = pref.get(tokenKey);

    double savedBalance = 0;

    if (storedBalance != null) savedBalance = storedBalance;

    if (skipNetworkRequest) return savedBalance;

    try {
      final fuseSdk = await getSdk();
      print(address);
      final userTokens = await fuseSdk.balancesModule.getTokenList(address);
      print("errrror");
      print(userTokens.error);
      for (TokenDetails action in userTokens.data?.result ?? []) {
        if (action.address == Variables.NATIVE_TOKEN_ADDRESS) {
          print("baa");
          // await pref.put(tokenKey, action);
          // return action.amount;
          return savedBalance;
        }
      }
      return savedBalance;
    } catch (e) {
      print(e);
      return savedBalance;
    }
  }

  @override
  String savedTransKey() {
    return '$default_$rpc Details';
  }

  @override
  Future<String?> transferToken(String amount, String to,
      {String? memo}) async {
    final fuseSdk = await getSdk();
    final wei = amount.toBigIntDec(decimals());
    final res = await fuseSdk.transferToken(
      EthereumAddress.fromHex(
        Variables.NATIVE_TOKEN_ADDRESS,
      ),
      EthereumAddress.fromHex(
        to,
      ),
      wei,
    );
    return res.userOpHash;
  }

  @override
  validateAddress(String address) {
    EthereumAddress.fromHex(address);
  }

  @override
  int decimals() {
    return etherDecimals;
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    final data = WalletService.getActiveKey(walletImportType)!.data;
    final response = await importData(data);
    final transactionFee = await getEtherTransactionFee(
      rpc,
      null,
      EthereumAddress.fromHex(roninAddrToEth(response.address)),
      EthereumAddress.fromHex(roninAddrToEth(to)),
    );

    return transactionFee / pow(10, decimals());
  }

  @override
  String getGeckoId() => geckoID;

  @override
  String getPayScheme() => payScheme;

  @override
  String getRampID() => rampID;
}

List<FuseCoin> getFUSEBlockchains() {
  List<FuseCoin> blockChains = [];

  if (enableTestNet) {
    blockChains.addAll([
      FuseCoin(
        name: 'Fuse(4337)',
        rpc: 'https://rpc.fuse.io',
        chainId: 122,
        blockExplorer: 'https://explorer.fuse.io/tx/$blockExplorerPlaceholder',
        symbol: 'FUSE',
        default_: 'FUSE',
        image: 'assets/fuse.png',
        coinType: 60,
        geckoID: "fuse-network-token",
        payScheme: 'fuse',
        rampID: '',
      ),
    ]);
  } else {
    blockChains.addAll([
      FuseCoin(
        name: 'Fuse',
        rpc: 'https://rpc.fuse.io',
        chainId: 122,
        blockExplorer: 'https://explorer.fuse.io/tx/$blockExplorerPlaceholder',
        symbol: 'FUSE',
        default_: 'FUSE',
        image: 'assets/fuse.png',
        coinType: 60,
        geckoID: "fuse-network-token",
        payScheme: 'fuse',
        rampID: '',
      ),
    ]);
  }

  final prefCoin = pref.get(newEVMChainKey);
  if (prefCoin != null && WalletService.isPharseKey()) {
    final tokenList =
        Map.from(jsonDecode(prefCoin)).values.map((e) => FuseCoin.fromJson(e));

    blockChains.addAll([...tokenList]);
  }

  return blockChains;
}

Future<double> getEtherTransactionFee(
  String rpc,
  Uint8List? data,
  EthereumAddress sender,
  EthereumAddress? to, {
  double? value,
  EtherAmount? gasPrice,
}) async {
  final client = Web3Client(
    rpc,
    Client(),
  );

  final etherValue = value != null
      ? EtherAmount.inWei(
          BigInt.from(value),
        )
      : null;

  if (gasPrice == null || gasPrice.getInWei == BigInt.from(0)) {
    gasPrice = await client.getGasPrice();
  }

  BigInt? gasUnit;

  try {
    gasUnit = await client.estimateGas(
      sender: sender,
      to: to,
      data: data,
      value: etherValue,
    );
  } catch (_) {}

  if (gasUnit == null) {
    try {
      gasUnit = await client.estimateGas(
        sender: EthereumAddress.fromHex(zeroAddress),
        to: to,
        data: data,
        value: etherValue,
      );
    } catch (_) {}
  }

  if (gasUnit == null) {
    try {
      gasUnit = await client.estimateGas(
        sender: EthereumAddress.fromHex(deadAddress),
        to: to,
        data: data,
        value: etherValue,
      );
    } catch (e) {
      gasUnit = BigInt.from(0);
    }
  }

  return gasPrice.getInWei.toDouble() * gasUnit.toDouble();
}

class EthereumDeriveArgs {
  final SeedPhraseRoot seedRoot;
  final int coinType;

  const EthereumDeriveArgs({
    required this.seedRoot,
    required this.coinType,
  });
}

Future<Map> calculateEthereumKey(EthereumDeriveArgs config) async {
  SeedPhraseRoot seedRoot_ = config.seedRoot;
  final path = "m/44'/${config.coinType}'/0'/0/0";
  final node = seedRoot_.root.derivePath(path);
  final privateKey = HEX.encode(node.privateKey!);
  final privatekeyStr = "0x$privateKey";
  final address = await etherPrivateKeyToAddress(privatekeyStr);

  return {
    'address': address,
    'privateKey': privatekeyStr,
  };
}

Future<String> etherPrivateKeyToAddress(String privateKey) async {
  EthPrivateKey ethereumPrivateKey = EthPrivateKey.fromHex(privateKey);
  final uncheckedAddr = ethereumPrivateKey.address;
  return EthereumAddress.fromHex('$uncheckedAddr').hexEip55;
}

String roninAddrToEth(String address) {
  return address.replaceFirst('ronin:', '0x');
}

String ethAddrToRonin(String address) {
  return address.replaceFirst('0x', 'ronin:');
}
