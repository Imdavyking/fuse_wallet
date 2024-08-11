// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:cryptowallet/extensions/big_int_ext.dart';
import 'package:hex/hex.dart';
import 'package:ton_dart/ton_dart.dart';
import '../../interface/ft_explorer.dart';
import '../../main.dart';
import '../../service/wallet_service.dart';
import '../../utils/app_config.dart';
import '../ton_coin.dart';

class TonFungibleCoin extends TonCoin implements FTExplorer {
  String tokenID;

  int mintDecimals;

  TonFungibleCoin({
    required String blockExplorer,
    required String symbol,
    required String default_,
    required String image,
    required String name,
    required String api,
    required this.mintDecimals,
    required this.tokenID,
    required String geckoID,
  }) : super(
          rampID: '',
          payScheme: '',
          blockExplorer: blockExplorer,
          symbol: symbol,
          default_: default_,
          image: image,
          api: api,
          name: name,
          geckoID: geckoID,
        );

  factory TonFungibleCoin.fromJson(Map<String, dynamic> json) {
    return TonFungibleCoin(
      api: json['api'],
      blockExplorer: json['blockExplorer'],
      default_: json['default'],
      symbol: json['symbol'],
      image: json['image'],
      name: json['name'],
      mintDecimals: json['mintDecimals'],
      tokenID: json['tokenID'],
      geckoID: json['geckoID'],
    );
  }

  @override
  String get badgeImage => tonChains.first.image;
  @override
  String savedTransKey() => '$tokenID$api FTDetails';

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['api'] = api;
    data['default'] = default_;
    data['symbol'] = symbol;
    data['name'] = name;
    data['blockExplorer'] = blockExplorer;
    data['image'] = image;
    data['mintDecimals'] = mintDecimals;
    data['tokenID'] = tokenID;
    data['geckoID'] = geckoID;
    return data;
  }

  @override
  int decimals() => mintDecimals;

  @override
  String contractExplorer() {
    return getExplorer().replaceFirst(
      '/tx/$blockExplorerPlaceholder',
      '/jetton/${tokenAddress()}',
    );
  }

  @override
  String tokenAddress() => tokenID;

  @override
  Future<double> getBalance(bool skipNetworkRequest) async {
    final data = WalletService.getActiveKey(walletImportType)!.data;
    final details = await importData(data);

    final address = details.address;
    final key = 'tonFTAddressBalance$api$address$tokenID';

    final storedBalance = pref.get(key);

    double savedBalance = 0;

    if (storedBalance != null) {
      savedBalance = storedBalance;
    }

    if (skipNetworkRequest) return savedBalance;

    try {
      final ownerWallet = WalletV4.create(
        workChain: 0,
        publicKey: HEX.decode(details.publicKey!),
        bounceableAddress: true,
      );

      final minter = JettonMinter(
        owner: ownerWallet,
        address: TonAddress(
          tokenID,
        ),
      );

      final jettonWalletAddress = await minter.getWalletAddress(
        rpc: getRpc(),
        owner: ownerWallet.address,
      );

      final jettonWallet = JettonWallet.fromAddress(
        jettonWalletAddress: jettonWalletAddress,
        owner: ownerWallet,
      );
      final balance = await jettonWallet.getBalance(getRpc());
      double balTon = balance / BigInt.from(10).pow(decimals());
      await pref.put(key, balTon);
      return balTon;
    } catch (_) {
      return savedBalance;
    }
  }

  // ignore: unused_element
  _mintTokens() async {
    final data = WalletService.getActiveKey(walletImportType)!.data;
    final tonDetails = await importData(data);
    final privateKey = TonPrivateKey.fromBytes(
      HEX.decode(tonDetails.privateKey!),
    );
    final ownerWallet = WalletV4.create(
      workChain: 0,
      publicKey: HEX.decode(tonDetails.publicKey!),
      bounceableAddress: true,
    );

    /// Create JettonMinter with owner and content
    final minter = JettonMinter.create(
      owner: ownerWallet,
      metadata: JettonOnChainMetadata.snakeFormat(
        name: "PRIME",
        symbol: "PRM",
        decimals: 9,
      ),
    );

    /// Define the address to which tokens will be minted
    final addressToMint = TonAddress(
      tonDetails.address,
      forceWorkchain: 0,
    );

    /// Define amounts
    final amount = TonHelper.toNano("0.5");
    final forwardAmount = TonHelper.toNano("0.3");
    final totalAmount = TonHelper.toNano("0.4");
    final jettonAmountForMint = BigInt.parse("1${"0" * 15}");

    /// Mint tokens
    await minter.mint(
      privateKey: privateKey,
      rpc: getRpc(),
      jettonAmout: jettonAmountForMint,
      forwardTonAmount: forwardAmount,
      totalTonAmount: totalAmount,
      amount: amount + totalAmount,
      to: addressToMint,
      bounce: false,
    );
  }

  @override
  Future<String?> transferToken(
    String amount,
    String to, {
    String? memo,
  }) async {
    final data = WalletService.getActiveKey(walletImportType)!.data;
    final tonDetails = await importData(data);
    final ownerWallet = WalletV4.create(
      workChain: 0,
      publicKey: HEX.decode(tonDetails.publicKey!),
      bounceableAddress: true,
    );

    final minter = JettonMinter(
      owner: ownerWallet,
      address: TonAddress(
        tokenID,
      ),
    );

    final jettonWalletAddress = await minter.getWalletAddress(
      rpc: getRpc(),
      owner: ownerWallet.address,
    );

    final jettonWallet = JettonWallet.fromAddress(
      jettonWalletAddress: jettonWalletAddress,
      owner: ownerWallet,
    );

    final forwardTonAmount = TonHelper.toNano("0.1");
    final transferAmount = amount.toBigIntDec(decimals());
    final BigInt feeAmount = TonHelper.toNano("0.3");
    final privateKey = TonPrivateKey.fromBytes(
      HEX.decode(tonDetails.privateKey!),
    );
    final tx = await jettonWallet.transfer(
      privateKey: privateKey,
      rpc: getRpc(),
      destination: TonAddress(to),
      forwardTonAmount: forwardTonAmount,
      jettonAmount: transferAmount,
      amount: feeAmount + forwardTonAmount,
      bounce: false,
      forwardPayload:
          memo == null ? null : TransactioUtils.buildMessageBody(memo),
    );
    return tx;
  }

  @override
  String getGeckoId() => geckoID;
}

List<TonFungibleCoin> getTonFungibleCoins() {
  List<TonFungibleCoin> blockChains = [];

  if (enableTestNet) {
    blockChains.addAll([
      TonFungibleCoin(
        blockExplorer:
            'https://testnet.tonscan.org/tx/$blockExplorerPlaceholder',
        name: 'AIOTX (Testnet)',
        symbol: 'AIOTX',
        default_: 'TON',
        image: 'assets/logo.png',
        api: 'https://testnet.toncenter.com/api/v2/jsonRPC',
        geckoID: '',
        mintDecimals: 9,
        tokenID: 'EQAiboDEv_qRrcEdrYdwbVLNOXBHwShFbtKGbQVJ2OKxY0to',
      ),
    ]);
  } else {
    blockChains.addAll([
      TonFungibleCoin(
        blockExplorer: 'https://tonscan.org/tx/$blockExplorerPlaceholder',
        symbol: 'NOT',
        name: 'Notcoin',
        default_: 'TON',
        image: 'assets/notcoin.webp',
        api: 'https://toncenter.com/api/v2/jsonRPC',
        geckoID: 'notcoin',
        mintDecimals: 9,
        tokenID: 'EQAvlWFDxGF2lXm67y4yzC17wYKD9A0guwPkMs1gOsM__NOT',
      ),
      TonFungibleCoin(
        blockExplorer: 'https://tonscan.org/tx/$blockExplorerPlaceholder',
        name: 'Tether USD',
        symbol: 'USDT',
        default_: 'TON',
        image: 'assets/usdt.png',
        api: 'https://toncenter.com/api/v2/jsonRPC',
        geckoID: 'tether',
        mintDecimals: 6,
        tokenID: 'EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs',
      ),
    ]);
  }

  return blockChains;
}
