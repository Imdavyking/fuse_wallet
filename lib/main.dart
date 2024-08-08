// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'package:cryptowallet/coins/fungible_tokens/erc_fungible_coin.dart';
import 'package:cryptowallet/coins/fuse_4337_coin.dart';
import 'package:cryptowallet/wordlist.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../service/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:cryptowallet/screens/navigator_service.dart';
import 'package:cryptowallet/screens/open_app_pin_failed.dart';
import 'package:cryptowallet/screens/security.dart';
import 'package:cryptowallet/screens/wallet.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:cryptowallet/utils/web_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:pointycastle/pointycastle.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'coins/fungible_tokens/esdt_coin.dart';
import 'coins/fungible_tokens/ton_fungible_coins.dart';
import 'coins/harmony_coin.dart';
import 'coins/icp_coin.dart';
import 'coins/iotex_coin.dart';
import 'coins/multiversx_coin.dart';
import 'coins/fungible_tokens/near_fungible_coin.dart';
import 'coins/ronin_coin.dart';
import 'coins/fungible_tokens/spl_token_coin.dart';
import 'coins/sui_coin.dart';
import 'coins/ton_coin.dart';
import 'coins/zilliqa_coin.dart';
import 'data_structures/trie.dart';
import 'interface/coin.dart';
import 'screens/main_screen.dart';
import '../coins/ethereum_coin.dart';
import '../coins/near_coin.dart';
import '../coins/solana_coin.dart';
import '../coins/stellar_coin.dart';
import '../coins/tezos_coin.dart';

List<Coin> getAllBlockchains = [];

late String currencyJson;
late String currencyJsonSearch;
late String provider;
late String nightly;
late String webNotifer;
late String abiJs;
List<EthereumCoin> evmChains = [
  ...getEVMBlockchains(),
];

List<NearCoin> nearChains = [
  ...getNearBlockChains(),
];
List<SolanaCoin> solanaChains = [
  ...getSolanaBlockChains(),
];
List<MultiversxCoin> multiversXchains = [
  ...getEGLBBlockchains(),
];

List<TonCoin> tonChains = [
  ...getTonBlockChains(),
];
// ---- FT ----

List<ERCFungibleCoin> erc20Coins = [
  ...getERC20Coins(),
];

Future<List<Coin>> getAllBlockchains_fun() async {
  List<Coin> blockchains = [
    ...getESDTCoins(),
    ...getTonFungibleCoins(),
    ...tonChains,
    ...evmChains,
    ...nearChains,
    ...solanaChains,
    ...multiversXchains,
    ...getNearFungibles(),
    ...getFUSEBlockchains(),
    ...getZilliqaBlockChains(),
    ...getTezosBlockchains(),
    ...getHarmonyBlockChains(),
    ...getIOTEXBlockChains(),
    ...getStellarBlockChains(),
    ...getICPBlockchains(),
    ...getSuiBlockChains(),
    ...getRoninBlockchains(),
    ...getSplTokens(),
    ...erc20Coins,
  ]..sort((a, b) => a.getSymbol().compareTo(b.getSymbol()));
  // List<Future<MapEntry<Coin, double>>> futures = blockchains.map((coin) async {
  //   double balance = await coin.getBalance(true);
  //   return MapEntry(coin, balance);
  // }).toList();

  // List<MapEntry<Coin, double>> coinBalances = await Future.wait(futures);

  // coinBalances.sort((a, b) => b.value.compareTo(a.value));

  // List<Coin> sortedBlockchains =
  //     coinBalances.map((entry) => entry.key).toList();

  // return sortedBlockchains;

  return blockchains;
}

late Box pref;
final phraseAutoComplete = Trie();
late WalletType walletImportType;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize();
  await Hive.initFlutter();
  FocusManager.instance.primaryFocus?.unfocus();
  // make app always in portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kReleaseMode) {
      return Container();
    }
    return Container(
      color: Colors.red,
      child: Center(
        child: Text(
          details.exceptionAsString(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  };
  const _secureEncryptionKey = 'b6f71-9b6df9-0abc-4463-a623-43eaf2';

  const FlutterSecureStorage secureStorage = FlutterSecureStorage();
  var containsEncryptionKey =
      await secureStorage.containsKey(key: _secureEncryptionKey);

  if (!containsEncryptionKey) {
    var key = Hive.generateSecureKey();
    await secureStorage.write(
      key: _secureEncryptionKey,
      value: base64UrlEncode(key),
    );
  }

  final result = await secureStorage.read(key: _secureEncryptionKey);

  var encryptionKey = base64Url.decode(result!);
  pref = await Hive.openBox(
    secureStorageKey,
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  walletImportType = WalletService.getType();

  provider = await rootBundle.loadString('js/trust.min.js');
  nightly = await rootBundle.loadString('js/nightly.min.js');
  webNotifer = await rootBundle.loadString('js/web_notification.js');
  currencyJson = await rootBundle.loadString('json/currency_symbol.json');
  currencyJsonSearch = await rootBundle.loadString('json/currencies.json');
  abiJs = await rootBundle.loadString('js/abi-decoder.js');
  await WebNotificationPermissionDb.loadSavedPermissions();
  if (WalletService.isPharseKey()) {
    await reInstianteSeedRoot();
  }
  getAllBlockchains = await getAllBlockchains_fun();

  for (int i = 0; i < wordList.length; i++) {
    phraseAutoComplete.insert(wordList[i]);
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  runApp(ProviderScope(
    child: MyApp(
      userDarkMode: pref.get(darkModekey, defaultValue: true),
      locale: Locale.fromSubtags(
        languageCode: pref.get(languageKey, defaultValue: 'en'),
      ),
    ),
  ));
}

int uint8ListToNumber(Uint8List bytes, {Endian endian = Endian.little}) {
  if (endian == Endian.big) {
    return bytes.fold(0, (result, byte) => (result << 8) + byte);
  } else {
    return bytes.reversed.fold(0, (result, byte) => (result << 8) + byte);
  }
}

class MyApp extends StatefulWidget {
  static ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  static bool getCoinGeckoData = true;
  static DateTime lastcoinGeckoData = DateTime.now();

  final bool userDarkMode;
  final Locale locale;

  const MyApp({Key? key, required this.userDarkMode, required this.locale})
      : super(key: key);
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  initState() {
    super.initState();
    _locale = widget.locale;
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    MyApp.themeNotifier.value =
        widget.userDarkMode ? ThemeMode.dark : ThemeMode.light;

    return ValueListenableBuilder(
      valueListenable: MyApp.themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarBrightness: currentMode == ThemeMode.light
                ? Brightness.light
                : Brightness.dark,
            statusBarColor: Colors.black,
          ),
        );
        return MaterialApp(
          navigatorKey: NavigationService.navigatorKey, // set property
          debugShowCheckedModeBanner: false,
          locale: _locale,
          theme: lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          darkTheme: darkTheme,
          themeMode: currentMode,
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSplashScreen.withScreenFunction(
        curve: Curves.linear,
        splashIconSize: 100,
        backgroundColor: Theme.of(context).colorScheme.background,
        disableNavigation: true,
        splash: 'assets/logo.png',
        screenFunction: () async {
          final bool hasWallet =
              WalletService.getActiveKey(walletImportType) != null;

          final bool hasPasscode = pref.get(userUnlockPasscodeKey) != null;
          final int hasUnlockTime = pref.get(appUnlockTime, defaultValue: 1);
          bool isAuthenticated = false;

          if (hasUnlockTime > 1) {
            return OpenAppPinFailed(remainSec: hasUnlockTime);
          }

          if (hasWallet) {
            isAuthenticated = await authenticate(context);
          }

          if (hasWallet && !isAuthenticated) return const OpenAppPinFailed();

          if (hasWallet) return const Wallet();

          if (hasPasscode) return const MainScreen();

          return const Security();
        },
        pageTransitionType: PageTransitionType.rightToLeft,
      ),
    );
  }
}
