// ignore_for_file: constant_identifier_names

import 'package:cryptowallet/coins/fuse_4337_coin.dart';

import '../../interface/ft_explorer.dart';
import 'package:cryptowallet/utils/app_config.dart';

class FuseFungibleCoin extends FuseCoin implements FTExplorer {
  int mintDecimals;
  FuseFungibleCoin(
      {required String blockExplorer,
      required String symbol,
      required String default_,
      required String image,
      required int coinType,
      required String rpc,
      required int chainId,
      required String name,
      required String geckoID,
      required String rampID,
      required String contractAddress,
      required this.mintDecimals,
      required String payScheme})
      : super(
          blockExplorer: blockExplorer,
          symbol: symbol,
          default_: default_,
          image: image,
          coinType: coinType,
          rpc: rpc,
          chainId: chainId,
          name: name,
          geckoID: geckoID,
          rampID: rampID,
          contractAddress: contractAddress,
          payScheme: payScheme,
        );
  @override
  String tokenAddress() => contractAddress;

  @override
  int decimals() => mintDecimals;

  @override
  String get badgeImage => getFUSEBlockchains().first.image;
  @override
  String contractExplorer() {
    return getExplorer().replaceFirst(
      '/tx/$blockExplorerPlaceholder',
      '/token/${tokenAddress()}',
    );
  }

  @override
  Future<String?> stakeToken(String amount) async {
    return null;
  }

  @override
  Future<String?> unstakeToken(String amount) async {
    return null;
  }
}

List<FuseFungibleCoin> getFUSEFTBlockchains() {
  List<FuseFungibleCoin> blockChains = [];

  if (enableTestNet) {
    blockChains.addAll([
      FuseFungibleCoin(
        name: 'sFUSE',
        rpc: 'https://rpc.fuse.io',
        chainId: 122,
        blockExplorer: 'https://explorer.fuse.io/tx/$blockExplorerPlaceholder',
        symbol: 'sFUSE',
        default_: 'sFUSE',
        image: 'assets/sfuse.png',
        coinType: 60,
        geckoID: "liquid-staked-fuse",
        payScheme: 'fuse',
        rampID: '',
        contractAddress: '0xb1DD0B683d9A56525cC096fbF5eec6E60FE79871',
        mintDecimals: 10,
      ),
    ]);
  } else {
    blockChains.addAll([
      FuseFungibleCoin(
        name: 'sFUSE',
        rpc: 'https://rpc.fuse.io',
        chainId: 122,
        blockExplorer: 'https://explorer.fuse.io/tx/$blockExplorerPlaceholder',
        symbol: 'sFUSE',
        default_: 'sFUSE',
        image: 'assets/sfuse.png',
        coinType: 60,
        geckoID: "liquid-staked-fuse",
        payScheme: 'fuse',
        rampID: '',
        contractAddress: '0xb1DD0B683d9A56525cC096fbF5eec6E60FE79871',
        mintDecimals: 10,
      ),
    ]);
  }

  return blockChains;
}
