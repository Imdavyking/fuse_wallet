// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' hide Coin;

import '../extensions/big_int_ext.dart';
import '../service/wallet_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import '../interface/coin.dart';
import '../main.dart';
import '../utils/app_config.dart';
import 'package:cardano_wallet_sdk/cardano_wallet_sdk.dart' as cardano;

const cardanoDecimals = 6;
const int maxFeeGuessForCardano = 200000;
const _accountHardOffsetKey = 0x80000000;

class CardanoCoin extends Coin {
  String blockFrostKey;
  cardano.NetworkId cardano_network;
  String blockExplorer;
  String symbol;
  String default_;
  String image;
  String name;
  String geckoID;
  String rampID;
  String payScheme;
  CardanoCoin({
    required this.blockExplorer,
    required this.symbol,
    required this.default_,
    required this.image,
    required this.name,
    required this.blockFrostKey,
    required this.cardano_network,
    required this.geckoID,
    required this.rampID,
    required this.payScheme,
  });

  factory CardanoCoin.fromJson(Map<String, dynamic> json) {
    return CardanoCoin(
      blockFrostKey: json['blockFrostKey'],
      cardano_network: json['cardano_network'],
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
  Future<String> addressExplorer() async {
    final address = await getAddress();
    return blockExplorer
        .replaceFirst('/transaction/', '/address/')
        .replaceFirst(blockExplorerPlaceholder, address);
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cardano_network'] = cardano_network;
    data['blockFrostKey'] = blockFrostKey;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;
    data['image'] = image;
    data['geckoID'] = geckoID;
    data['rampID'] = rampID;
    data['payScheme'] = payScheme;

    return data;
  }

  @override
  Future<AccountData> fromMnemonic({required String mnemonic}) async {
    String saveKey =
        'cardanoDetail-${cardano_network.name}${walletImportType.name}';
    Map<String, dynamic> mnemonicMap = {};

    if (pref.containsKey(saveKey)) {
      mnemonicMap = Map<String, dynamic>.from(jsonDecode(pref.get(saveKey)));
      if (mnemonicMap.containsKey(mnemonic)) {
        return AccountData.fromJson(mnemonicMap[mnemonic]);
      }
    }

    final args = CardanoDeriveArgs(
      networkId: cardano_network,
      mnemonic: mnemonic,
    );

    final keys = await compute(calculateCardanoKey, args);

    mnemonicMap[mnemonic] = keys;

    await pref.put(saveKey, jsonEncode(mnemonicMap));

    return AccountData.fromJson(keys);
  }

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final address = await getAddress();
    final key = 'cardanoAddressBalance$address';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      final cardanoBlockfrostBaseUrl =
          'https://cardano-${cardano_network == cardano.NetworkId.mainnet ? 'mainnet' : 'preprod'}.blockfrost.io/api/v0/addresses/';
      final request = await get(
        Uri.parse('$cardanoBlockfrostBaseUrl$address'),
        headers: {'project_id': blockFrostKey},
      );

      if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
        throw Exception('Request failed');
      }
      Map decodedData = jsonDecode(request.body);
      final String balance = (decodedData['amount'] as List)
          .where((element) => element['unit'] == 'lovelace')
          .toList()[0]['quantity'];
      final base = BigInt.from(10);
      final bal = BigInt.parse(balance) / base.pow(decimals());

      await pref.put(key, bal);

      return bal;
    } catch (e) {
      return savedBalance;
    }
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
  Future<String?> transferToken(String amount, String to,
      {String? memo}) async {
    final data = WalletService.getActiveKey(walletImportType)!.data;
    final cardanoDetails = await importData(data);
    final walletBuilder = cardano.WalletBuilder()
      ..networkId = cardano_network
      ..mnemonic = data.split(' ');

    // TODO: coin selection not working well

    if (cardano_network == cardano.NetworkId.mainnet) {
      walletBuilder.mainnetAdapterKey = blockFrostKey;
    } else if (cardano_network == cardano.NetworkId.testnet) {
      walletBuilder.testnetAdapterKey = blockFrostKey;
    }
    final result = await walletBuilder.buildAndSync();
    if (result.isErr()) {
      if (kDebugMode) {
        print(result.err().unwrap());
      }
      throw Exception(result.err().unwrap());
    }
    final lovelace = amount.toBigIntDec(decimals());

    cardano.Wallet userWallet = result.unwrap();

    final coinSelection = await cardano.largestFirst(
      unspentInputsAvailable: userWallet.unspentTransactions,
      outputsRequested: [
        cardano.MultiAssetRequest.lovelace(
          lovelace.toInt() + maxFeeGuessForCardano,
        )
      ],
      ownedAddresses: userWallet.addresses.toSet(),
    );

    final builder = cardano.TransactionBuilder()
      ..wallet(userWallet)
      ..blockchainAdapter(userWallet.blockchainAdapter)
      ..toAddress(cardano.ShelleyAddress.fromBech32(to))
      ..inputs(coinSelection.unwrap().inputs)
      ..value(
        cardano.ShelleyValue(
          coin: lovelace.toInt(),
          multiAssets: [],
        ),
      )
      ..changeAddress(
        cardano.ShelleyAddress.fromBech32(cardanoDetails.address),
      );

    final txResult = await builder.buildAndSign();

    if (txResult.isErr()) {
      if (kDebugMode) {
        print(txResult.err().unwrap());
      }
      throw Exception(txResult.err().unwrap());
    }

    final submitTrx = await userWallet.blockchainAdapter.submitTransaction(
      txResult.unwrap().serialize,
    );

    if (submitTrx.isErr()) {
      if (kDebugMode) {
        print(submitTrx.err().unwrap());
      }
      throw Exception(submitTrx.err().unwrap());
    }

    final txHash = submitTrx.unwrap();
    return txHash.replaceAll('"', '');
  }

  @override
  validateAddress(String address) {
    cardano.ShelleyAddress.fromBech32(address);
  }

  @override
  int decimals() {
    return cardanoDecimals;
  }

  @override
  Future<double> getTransactionFee(String amount, String to) async {
    return maxFeeGuessForCardano / pow(10, cardanoDecimals);
  }

  @override
  String getGeckoId() => geckoID;

  @override
  String getPayScheme() => payScheme;

  @override
  String getRampID() => rampID;
}

List<CardanoCoin> getCardanoBlockChains() {
  List<CardanoCoin> blockChains = [];
  if (enableTestNet) {
    blockChains.add(
      CardanoCoin(
        name: 'Cardano(Prepod)',
        symbol: 'ADA',
        default_: 'ADA',
        blockExplorer:
            'https://preprod.cardanoscan.io/transaction/$blockExplorerPlaceholder',
        image: 'assets/cardano.png',
        cardano_network: cardano.NetworkId.testnet,
        blockFrostKey: 'preprodmpCaCFGCxLihVPPxXxqEvEnp7dyFmG6J',
        geckoID: 'cardano',
        payScheme: 'cardano',
        rampID: 'CARDANO_ADA',
      ),
    );
  } else {
    blockChains.addAll([
      CardanoCoin(
        name: 'Cardano',
        symbol: 'ADA',
        default_: 'ADA',
        blockExplorer:
            'https://cardanoscan.io/transaction/$blockExplorerPlaceholder',
        image: 'assets/cardano.png',
        cardano_network: cardano.NetworkId.mainnet,
        blockFrostKey: 'mainnetpgkQqXqQ4HjK6gzUKaHW6VU9jcmcKEbd',
        geckoID: 'cardano',
        payScheme: 'cardano',
        rampID: 'CARDANO_ADA',
      ),
    ]);
  }
  return blockChains;
}

class CardanoDeriveArgs {
  final NetworkId networkId;
  final String mnemonic;

  const CardanoDeriveArgs({
    required this.networkId,
    required this.mnemonic,
  });
}

Map calculateCardanoKey(CardanoDeriveArgs config) {
  final wallet = cardano.HdWallet.fromMnemonic(config.mnemonic);

  final bip32Pair = wallet.deriveUnusedBaseAddressKit(
    networkId: config.networkId,
    index: 0,
    account: _accountHardOffsetKey,
    role: 0,
    unusedCallback: (cardano.ShelleyAddress address) => true,
  );

  String userWalletAddress = bip32Pair.address.toString();

  return {
    'address': userWalletAddress,
  };
}
