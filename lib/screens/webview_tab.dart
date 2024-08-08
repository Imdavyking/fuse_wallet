import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';
import 'package:cryptowallet/coins/near_coin.dart';
import 'package:hex/hex.dart';
import 'package:sui/utils/sha.dart';

import '../model/near_message_borsh.dart';
import '../model/near_trx_obj.dart';
import '../service/wallet_connect_service.dart';
import '../service/wallet_service.dart';
import 'dart:ui';
import 'package:bs58check/bs58check.dart';
import 'package:cryptowallet/api/notification_api.dart';
import 'package:cryptowallet/model/solana_web3_res.dart' hide Instruction;
import 'package:pinput/pinput.dart';
import 'package:solana/solana.dart' hide signTransaction;
import 'package:cryptowallet/coins/multiversx_coin.dart';
import 'package:cryptowallet/coins/solana_coin.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:multiversx_sdk/multiversx.dart' as multiversx;
import 'package:solana/solana.dart' as solana;
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import '../coins/ethereum_coin.dart';
import '../main.dart';
import '../model/multix_sign_model.dart' hide Transaction;
import '../utils/app_config.dart';
import '../utils/json_model_callback.dart';
import '../utils/web_notifications.dart';

class WebViewTab extends StatefulWidget {
  final String? url;
  final int? windowId;
  final String provider;
  final String init;
  final String? data;
  final String webNotifier;

  final Function() onStateUpdated;
  final Function(CreateWindowAction createWindowAction) onCreateTabRequested;
  final Function() onCloseTabRequested;

  String? get currentUrl {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    return state?._url;
  }

  bool? get isSecure {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    return state?._isSecure;
  }

  InAppWebViewController? get controller {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    return state?._controller;
  }

  TextEditingController? get browserController {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    return state?._browserController;
  }

  Uint8List? get screenshot {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;

    return state?._screenshot;
  }

  String? get title {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    return state?._title;
  }

  Favicon? get favicon {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    return state?._favicon;
  }

  const WebViewTab(
      {GlobalKey? key,
      required this.url,
      required this.onStateUpdated,
      required this.onCloseTabRequested,
      required this.onCreateTabRequested,
      required this.data,
      required this.provider,
      required this.webNotifier,
      required this.init,
      this.windowId})
      : super(key: key);

  @override
  State<WebViewTab> createState() => _WebViewTabState();

  Future<void> updateScreenshot() async {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    await state?.updateScreenshot();
  }

  Future<void> pause() async {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    await state?.pause();
  }

  Future<void> resume() async {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    await state?.resume();
  }

  Future<bool> canGoBack() async {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    return await state?.canGoBack() ?? false;
  }

  Future<void> goBack() async {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    await state?.goBack();
  }

  Future<bool> canGoForward() async {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    return await state?.canGoForward() ?? false;
  }

  Future<void> goForward() async {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    await state?.goForward();
  }

  Future<void> readloadWeb3_() async {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    await state?.reloadWeb3_();
  }

  Future<void> switchWeb3(int chainId, String rpc) async {
    final state = (key as GlobalKey).currentState as _WebViewTabState?;
    await state?.switchWeb3_(chainId, rpc);
  }
}

class _WebViewTabState extends State<WebViewTab> with WidgetsBindingObserver {
  InAppWebViewController? _controller;
  final _browserController = TextEditingController();
  Uint8List? _screenshot;
  String _url = '';
  bool _isSecure = false;
  String _title = '';
  Favicon? _favicon;
  final ValueNotifier<double> _progress = ValueNotifier(0);
  String initJs = '';
  final jsonNotification =
      jsonEncode(WebNotificationPermissionDb.getPermissions());
  WebNotificationController? webNotificationController;
  late List<UserScript> webNotification;

  final ReceivePort _port = ReceivePort();
  final TextEditingController _httpAuthUsernameController =
      TextEditingController();
  final TextEditingController _httpAuthPasswordController =
      TextEditingController();
  late PullToRefreshController _pullToRefreshController;
  final FindInteractionController _findInteractionController =
      FindInteractionController();
  InAppWebViewSettings inappViewSettings = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    isFraudulentWebsiteWarningEnabled: true,
    safeBrowsingEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    useOnDownloadStart: true,
    useHybridComposition: true,
    resourceCustomSchemes: ["wc"],
  );

  @override
  void initState() {
    super.initState();
    initJs = widget.init;

    webNotification = [
      UserScript(
          source: widget.webNotifier,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
      UserScript(source: """
    (function(window) {
      var notificationPermissionDb = $jsonNotification;
      if (notificationPermissionDb[window.location.host] === 'granted') {
        Notification._permission = 'granted';
      } 
    })(window);
    """, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START)
    ];
    WidgetsBinding.instance.addObserver(this);
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      if (kDebugMode) {
        print("Download progress: $progress%");
      }
      if (status == DownloadTaskStatus.complete) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Download $id completed!"),
        ));
      }
    });
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.blue),
      onRefresh: () async {
        reloadWeb3_();
      },
    );
    FlutterDownloader.registerCallback(downloadCallback);
    _url = widget.url ?? '';
  }

  @pragma('vm:entry-point')
  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  @override
  void dispose() {
    _controller = null;
    WidgetsBinding.instance.removeObserver(this);
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    _httpAuthUsernameController.dispose();
    _httpAuthPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb) {
      if (state == AppLifecycleState.resumed) {
        resume();
        _controller?.resumeTimers();
      } else {
        pause();
        _controller?.pauseTimers();
      }
    }
  }

  Future<HttpAuthResponseAction> createHttpAuthDialog(
      URLAuthenticationChallenge challenge) async {
    HttpAuthResponseAction action = HttpAuthResponseAction.CANCEL;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Login"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(challenge.protectionSpace.host),
              TextField(
                decoration: const InputDecoration(labelText: "Username"),
                controller: _httpAuthUsernameController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Password"),
                controller: _httpAuthPasswordController,
                obscureText: true,
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text("Cancel"),
              onPressed: () {
                action = HttpAuthResponseAction.CANCEL;
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text("Ok"),
              onPressed: () {
                action = HttpAuthResponseAction.PROCEED;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    return action;
  }

  String _addChain(EthereumCoin switchChain, String sendingAddress) {
    String source = '''
        window.ethereum.setConfig({
          ethereum:{
            chainId: ${switchChain.chainId},
            rpcUrl: "${switchChain.rpc}",
            address: "$sendingAddress"
            }
          }
        )
        ''';
    return source;
  }

  Future<void> _sendError(String network, String message, int methodId) {
    String script = "window.$network.sendError($methodId, \"$message\")";
    return _controller!.evaluateJavascript(source: script);
  }

  Future _setSolanaAddress(id, sendingAddress) async {
    final setAddress = "trustwallet.solana.setAddress(\"$sendingAddress\");";

    String callback =
        "trustwallet.solana.sendResponse($id, [\"$sendingAddress\"])";

    await _sendCustomResponse(setAddress);

    await _sendCustomResponse(callback);
  }

  Future<void> _sendNearError(String message, int methodId) {
    String script = "window.nightly.near.sendError($methodId, \"$message\")";
    debugPrint(script);
    return _controller!
        .evaluateJavascript(source: script)
        .then((value) => debugPrint(value))
        .onError((error, stackTrace) {debugPrint(error.toString());});
  }

  Future<void> _sendNearResult(String message, int methodId) {
    String script = "window.nightly.near.sendResponse($methodId, '$message')";
    debugPrint(script);
    return _controller!
        .evaluateJavascript(source: script)
        .then((value) => debugPrint(value))
        .onError((error, stackTrace) {debugPrint(error.toString());});
  }

  Future _sendCosmosMessageSign(id, List signature) async {
    final signatureData = jsonEncode(signature);
    String script = "window.keplr.sendResponse($id, '$signatureData')";

    debugPrint(script);
    return _controller!
        .evaluateJavascript(source: script)
        .then((value) => debugPrint(value))
        .onError((error, stackTrace) {debugPrint(error.toString());});
  }

  Future _sendCosmosDirectTxSign(id, List signature) async {
    final signatureData = jsonEncode(signature);
    String script = "window.keplr.sendResponse($id, '$signatureData')";

    debugPrint(script);
    return _controller!
        .evaluateJavascript(source: script)
        .then((value) => debugPrint(value))
        .onError((error, stackTrace) {debugPrint(error.toString());});
  }

  Future _setCosmosAddress(id, sendingAddress, [String? pubKey]) async {
    final addressData = jsonEncode(
      {'address': sendingAddress, 'pubKey': pubKey},
    );
    String script = "window.keplr.sendResponse($id, '$addressData')";

    debugPrint(script);
    return _controller!
        .evaluateJavascript(source: script)
        .then((value) => debugPrint(value))
        .onError((error, stackTrace) {debugPrint(error.toString());});
  }

  Future _setEthereumAddress(id, sendingAddress) async {
    final setAddress = "window.ethereum.setAddress(\"$sendingAddress\");";

    String callback =
        "window.ethereum.sendResponse($id, [\"$sendingAddress\"])";

    await _sendCustomResponse(setAddress);

    await _sendCustomResponse(callback);
  }

  String localStorageKey({required String network, required String address}) =>
      'walletName-$network-$address';

  Future<void> _saveWeb3Address(String network, String address) {
    final key = localStorageKey(network: network, address: address);
    return _controller!
        .evaluateJavascript(
            source: "localStorage.setItem('$key','$walletName')")
        .then((value) => debugPrint(value))
        .onError((error, stackTrace) {debugPrint(error.toString());});
  }

  Future _getWeb3Address(String network, String address) {
    final key = localStorageKey(network: network, address: address);
    return _controller!
        .evaluateJavascript(source: "localStorage.getItem('$key')");
  }

  Future _removeWeb3Address(String network, String address) {
    final key = localStorageKey(network: network, address: address);
    return _controller!
        .evaluateJavascript(source: "localStorage.removeItem('$key')");
  }

  Future<void> _sendResult(String network, String message, int methodId) {
    String script = "window.$network.sendResponse($methodId, \"$message\")";
    debugPrint(script);
    return _controller!
        .evaluateJavascript(source: script)
        .then((value) => debugPrint(value))
        .onError((error, stackTrace) {debugPrint(error.toString());});
  }

  Future _switchWeb3ChainRequest({
    required EthereumCoin currentChain,
    required EthereumCoin switchChain,
    required String initString,
    required JsCallbackModel jsData,
    bool haveNotExecuted = true,
  }) async {
    switchEthereumChain(
      context: context,
      currentChain: currentChain,
      switchChain: switchChain,
      onConfirm: () async {
        initJs = await returnInitEvm(
          switchChain.chainId,
          switchChain.rpc,
        );
        await _sendCustomResponse(initString);
        await _emitChange(switchChain.chainId);
        await _sendNull(
          "ethereum",
          jsData.id ?? 0,
        );

        Navigator.pop(context);
      },
      onReject: () async {
        if (haveNotExecuted) {
          _sendError("ethereum", 'canceled', jsData.id ?? 0);
        }

        Navigator.pop(context);
      },
    );
  }

  Future _emitChange(int chainId) {
    final chain16 = "0x${chainId.toRadixString(16)}";
    String script = "trustwallet.ethereum.emitChainChanged(\"$chain16\");";
    return _controller!
        .evaluateJavascript(source: script)
        .then((value) => debugPrint(value))
        .onError((error, stackTrace) => debugPrint(error.toString()));
  }

  Future<void> _sendNull(String network, int methodId) {
    String script = "window.$network.sendResponse($methodId, null)";
    debugPrint(script);
    return _controller!
        .evaluateJavascript(source: script)
        .then((value) => debugPrint(value))
        .onError((error, stackTrace) => debugPrint(error.toString()));
  }

  Future<void> _blockAds(bool blockAds) async {
    if (!blockAds) return;
    final adUrlFilters = [
      ".*.doubleclick.net/.*",
      ".*.ads.pubmatic.com/.*",
      ".*.googlesyndication.com/.*",
      ".*.google-analytics.com/.*",
      ".*.adservice.google.*/.*",
      ".*.adbrite.com/.*",
      ".*.exponential.com/.*",
      ".*.quantserve.com/.*",
      ".*.scorecardresearch.com/.*",
      ".*.zedo.com/.*",
      ".*.adsafeprotected.com/.*",
      ".*.teads.tv/.*",
      ".*.outbrain.com/.*"
    ];

    for (final adUrlFilter in adUrlFilters) {
      contentBlockers.add(
        ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: adUrlFilter,
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          ),
        ),
      );
    }

    contentBlockers.add(
      ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: ".*",
        ),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.CSS_DISPLAY_NONE,
          selector: ".banner, .banners, .ads, .ad, .advert",
        ),
      ),
    );

    await _controller?.setSettings(
      settings: inappViewSettings..contentBlockers = contentBlockers,
    );
  }

  Future<void> _sendCustomResponse(String response) {
    return _controller!
        .evaluateJavascript(source: response)
        .then((value) => debugPrint(value))
        .onError((error, stackTrace) => debugPrint(error.toString()));
  }

  Future<void> _changeUserAgent() async {
    final defaultUserAgent = await InAppWebViewController.getDefaultUserAgent();
    if (kDebugMode) {
      print("Default User Agent: $defaultUserAgent");
    }

    String? newUserAgent;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Remove "wv" from the Android WebView default user agent
        // https://developer.chrome.com/docs/multidevice/user-agent/#webview-on-android
        newUserAgent = defaultUserAgent.replaceFirst("; wv)", ")");
        break;
      case TargetPlatform.iOS:
        // Add Safari/604.1 at the end of the iOS WKWebView default user agent
        newUserAgent = "$defaultUserAgent Safari/604.1";
        break;
      default:
        newUserAgent = null;
    }

    await _controller?.setSettings(
      settings: inappViewSettings..userAgent = newUserAgent,
    );
  }

  final List<ContentBlocker> contentBlockers = [];

  @override
  Widget build(BuildContext context) {
    inappViewSettings.forceDark =
        Theme.of(context).brightness == Brightness.dark
            ? ForceDark.ON
            : ForceDark.OFF;
    return Column(children: <Widget>[
      Expanded(
        child: Stack(
          children: [
            Container(
              color: Colors.white,
            ),
            InAppWebView(
              findInteractionController: _findInteractionController,
              pullToRefreshController: _pullToRefreshController,
              initialUrlRequest:
                  URLRequest(url: WebUri(widget.data ?? walletURL)),
              initialSettings: inappViewSettings,
              onPermissionRequest: (controller, request) async {
                final resources = <PermissionResourceType>[];
                if (request.resources.contains(PermissionResourceType.CAMERA)) {
                  final cameraStatus = await Permission.camera.request();
                  if (!cameraStatus.isDenied) {
                    resources.add(PermissionResourceType.CAMERA);
                  }
                }
                if (request.resources
                    .contains(PermissionResourceType.MICROPHONE)) {
                  final microphoneStatus =
                      await Permission.microphone.request();
                  if (!microphoneStatus.isDenied) {
                    resources.add(PermissionResourceType.MICROPHONE);
                  }
                }
                // only for iOS and macOS
                if (request.resources
                    .contains(PermissionResourceType.CAMERA_AND_MICROPHONE)) {
                  final cameraStatus = await Permission.camera.request();
                  final microphoneStatus =
                      await Permission.microphone.request();
                  if (!cameraStatus.isDenied && !microphoneStatus.isDenied) {
                    resources.add(PermissionResourceType.CAMERA_AND_MICROPHONE);
                  }
                }

                return PermissionResponse(
                  resources: resources,
                  action: resources.isEmpty
                      ? PermissionResponseAction.DENY
                      : PermissionResponseAction.GRANT,
                );
              },
              onUpdateVisitedHistory: (controller, url, isReload) {
                if (url != null) {
                  _url = url.toString();

                  _browserController.setText(_url);
                  widget.onStateUpdated.call();
                }
              },
              onDownloadStartRequest: (
                InAppWebViewController contrl,
                DownloadStartRequest downReq,
              ) async {
                _tryDownloadFile(
                  '${downReq.url}',
                  downReq.suggestedFilename,
                );
              },
              shouldOverrideUrlLoading: (
                InAppWebViewController controller,
                NavigationAction shouldOverrideUrl,
              ) async {
                Uri url = shouldOverrideUrl.request.url!;
                String url_ = url.toString();

                if (url_.contains('wc?uri=')) {
                  final wcUri = Uri.parse(
                    Uri.decodeFull(
                      Uri.parse(url_).queryParameters['uri']!,
                    ),
                  );

                  await WCService.qrScanHandler(wcUri.toString());

                  return NavigationActionPolicy.CANCEL;
                } else if (url_.startsWith('wc:')) {
                  await WCService.qrScanHandler(url_);

                  return NavigationActionPolicy.CANCEL;
                }
                List<String> allowedAction = [
                  "http",
                  "https",
                  "file",
                  "chrome",
                  "data",
                  "javascript",
                  "about"
                ];

                if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
                  final shouldPerformDownload =
                      shouldOverrideUrl.shouldPerformDownload ?? false;
                  final url = shouldOverrideUrl.request.url;
                  if (shouldPerformDownload && url != null) {
                    _tryDownloadFile('$url');
                    return NavigationActionPolicy.DOWNLOAD;
                  }
                }

                if (!allowedAction.contains(url.scheme)) {
                  try {
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  } catch (_) {}
                  return NavigationActionPolicy.CANCEL;
                }

                return NavigationActionPolicy.ALLOW;
              },
              onWebViewCreated: (controller) async {
                _controller = controller;
                await _changeUserAgent();
                await _blockAds(false);
                final data = WalletService.getActiveKey(walletImportType)!.data;

                webNotificationController =
                    WebNotificationController(controller);
                _controller!.addJavaScriptHandler(
                  handlerName: 'Notification.requestPermission',
                  callback: (arguments) async {
                    final permission = await onNotificationRequestPermission();
                    return permission.name.toLowerCase();
                  },
                );

                _controller!.addJavaScriptHandler(
                  handlerName: 'Notification.show',
                  callback: (arguments) {
                    final notification =
                        WebNotification.fromJson(arguments[0], _controller!);
                    onShowNotification(notification);
                  },
                );

                _controller!.addJavaScriptHandler(
                  handlerName: 'Notification.close',
                  callback: (arguments) {
                    final notificationId = arguments[0];
                    onCloseNotification(notificationId);
                  },
                );

                _controller!.addJavaScriptHandler(
                  handlerName: 'Multiversx',
                  callback: (callback) async {
                    Map reponse = json.decode(
                      callback[0],
                    );

                    final coin = getEGLBBlockchains().first;

                    final multiversxRes = await coin.importData(data);
                    multiversx.UserSecretKey signer = multiversx.UserSecretKey(
                      HEX.decode(multiversxRes.privateKey!),
                    );
                    multiversx.Wallet keys = multiversx.Wallet(signer);

                    switch (reponse['type']) {
                      case "logout":
                        {
                          var t = json.encode({
                            'target': "erdw-contentScript",
                            'type': '',
                            'data': true
                          });

                          await _controller!.evaluateJavascript(
                            source: "window.postMessage($t, window.origin)",
                          );
                          break;
                        }
                      case "signMessage":
                        {
                          String message = reponse['data']['message'];

                          await signMessage(
                            context: context,
                            messageType: '',
                            data: message,
                            networkIcon: null,
                            name: null,
                            onReject: () async {
                              Navigator.pop(context);
                            },
                            onConfirm: () async {
                              try {
                                Uint8List serialized =
                                    MultiversxCoin.serializeForSigning(
                                  message,
                                );
                                multiversx.UserSigner signer =
                                    keys.signer as multiversx.UserSigner;
                                final signature =
                                    await compute(MultiversxCoin.signMessage, {
                                  'signer': signer.secretKey,
                                  'message': serialized,
                                });

                                var t = json.encode(
                                  {
                                    "target": "erdw-contentScript",
                                    "type": "",
                                    "data": {
                                      "message": message,
                                      "signature": bytesToHex(signature),
                                    }
                                  },
                                );

                                await _controller!.evaluateJavascript(
                                  source:
                                      "window.postMessage($t, window.origin)",
                                );
                              } catch (_) {
                              } finally {
                                Navigator.pop(context);
                              }
                            },
                          );

                          break;
                        }
                      case "signTransactions":
                        {
                          final jsData = MultiversXSignTransModel.fromJson(
                            reponse['data'],
                          );

                          var allTrans = jsData.transactions!;

                          for (int i = 0; i < allTrans.length; i++) {
                            var e = allTrans[i];
                            List<int> data = [];
                            try {
                              data = base64.decode(e.data!);
                            } catch (err) {
                              data = txDataToUintList(e.data!);
                            }

                            await signMultiversXTransaction(
                              gasPrice: '${e.gasPrice}',
                              to: e.receiver,
                              from: jsData.from,
                              txData: e.data ?? '',
                              value_: e.value,
                              networkIcon: null,
                              context: context,
                              gasLimit: '${e.gasLimit}',
                              symbol: 'EGLD',
                              chainId: e.chainId,
                              name: '',
                              onConfirm: () async {
                                try {
                                  await keys.synchronize(coin.getProxy());

                                  final networkConfig = await coin
                                      .getProxy()
                                      .getNetworkConfiguration();

                                  int nonce =
                                      e.nonce ?? keys.account.nonce.value;

                                  int gasPrice = e.gasPrice ??
                                      networkConfig.minGasPrice.value;

                                  int gasLimit = e.gasLimit ??
                                      networkConfig.minGasLimit.value;

                                  int transVersion = e.version ??
                                      networkConfig.minTransactionVersion.value;

                                  String balance = e.value ?? '0';

                                  final trans = multiversx.Transaction(
                                    nonce: multiversx.Nonce(nonce),
                                    chainId: multiversx.ChainId(e.chainId),
                                    sender: multiversx.Address.fromBech32(
                                      jsData.from,
                                    ),
                                    receiver: multiversx.Address.fromBech32(
                                      e.receiver,
                                    ),
                                    gasPrice: multiversx.GasPrice(gasPrice),
                                    gasLimit: multiversx.GasLimit(gasLimit),
                                    transactionVersion:
                                        multiversx.TransactionVersion(
                                      transVersion,
                                    ),
                                    balance: multiversx.Balance(
                                      BigInt.parse(balance),
                                    ),
                                    data: multiversx.TransactionPayload(data),
                                  );

                                  var signTrans = await compute(
                                      MultiversxCoin.signTransaction, {
                                    'signer': keys.signer,
                                    'transaction': trans,
                                  });

                                  multiversx.Transaction txHash = signTrans;
                                  allTrans[i].signature = txHash.signature.hex;

                                  var t = json.encode({
                                    'target': "erdw-contentScript",
                                    'type': '',
                                    'data': allTrans.toList(),
                                  });

                                  await _controller!.evaluateJavascript(
                                    source:
                                        "window.postMessage($t, window.origin)",
                                  );
                                } catch (e, sk) {
                                  if (kDebugMode) {
                                    print(e);
                                    print(sk);
                                  }
                                } finally {
                                  Navigator.pop(context);
                                }
                              },
                              onReject: () async {
                                var t = json.encode(
                                  {
                                    "target": "erdw-contentScript",
                                    "type": "",
                                    "data": {"name": "CanceledError"}
                                  },
                                );
                                await _controller!.evaluateJavascript(
                                  source:
                                      "window.postMessage($t, window.origin)",
                                );

                                Navigator.pop(context);
                              },
                            );
                          }

                          break;
                        }

                      case "connect":
                        {
                          await connectWalletModal(
                            context: context,
                            url: reponse['url'],
                            authToken: reponse['data'],
                            onConfirm: () async {
                              try {
                                final String authToken = reponse['data'];
                                List<int> signature = [];

                                final hasToken = authToken.trim() != '';

                                if (hasToken) {
                                  String message =
                                      '${multiversxRes.address}$authToken{}';

                                  Uint8List serialized =
                                      MultiversxCoin.serializeForSigning(
                                          message);

                                  multiversx.UserSigner signer =
                                      keys.signer as multiversx.UserSigner;

                                  signature = await compute(
                                      MultiversxCoin.signMessage, {
                                    'signer': signer.secretKey,
                                    'message': serialized,
                                  });
                                }

                                final data = {
                                  'address': multiversxRes.address,
                                  'name': 'Main',
                                };

                                if (hasToken) {
                                  data['signature'] = bytesToHex(signature);
                                }
                                var t = json.encode(
                                  {
                                    'target': "erdw-contentScript",
                                    'type': 'connectResponse',
                                    'data': data
                                  },
                                );

                                await _controller!.evaluateJavascript(
                                  source:
                                      "window.postMessage($t, window.origin)",
                                );
                              } catch (_) {
                              } finally {
                                Navigator.pop(context);
                              }
                            },
                            onReject: () async {
                              var t = json.encode(
                                {
                                  "target": "erdw-contentScript",
                                  "type": "connectResponse",
                                  "data": {"name": "CanceledError"}
                                },
                              );
                              await _controller!.evaluateJavascript(
                                source: "window.postMessage($t, window.origin)",
                              );
                              Navigator.pop(context);
                            },
                          );

                          break;
                        }
                    }
                  },
                );

                _controller!.addJavaScriptHandler(
                  handlerName: 'NightyHandler',
                  callback: (callback) async {
                    final jsData =
                        JsCallbackModel.fromJson(json.decode(callback[0]));
                    final coin = getNearBlockChains().first;

                    final accountDetail = await coin.importData(data);

                    final sendingAddress = accountDetail.address;

                    switch (jsData.name) {
                      case "disconnect":
                        _removeWeb3Address('near', sendingAddress);
                        break;
                      case "signTransaction":
                        {
                          final trxObj = NearDappTrx.fromJson(jsData.object!);

                          await signNearTransaction(
                            from: sendingAddress,
                            txData: trxObj,
                            networkIcon: null,
                            context: context,
                            coin: coin,
                            symbol: coin.symbol,
                            name: '',
                            onConfirm: () async {
                              try {
                                final nearTrx = await coin.signDappTrx(trxObj);

                                final sigData = jsonEncode({
                                  'signature': nearTrx.signature,
                                });

                                await _sendNearResult(sigData, jsData.id!);
                              } catch (e, sk) {
                                final error =
                                    e.toString().replaceAll('"', '\'');

                                _sendNearError(error, jsData.id ?? 0);
                                if (kDebugMode) {
                                  print(e);
                                  print(sk);
                                }
                              } finally {
                                Navigator.pop(context);
                              }
                            },
                            onReject: () async {
                              _sendNearError(
                                'user rejected msg',
                                jsData.id ?? 0,
                              );
                              Navigator.pop(context);
                            },
                          );

                          break;
                        }
                      case "signMessage":
                        {
                          final data = JsNearMessageObject.fromJson(
                            jsData.object ?? {},
                          );

                          await signMessage(
                            context: context,
                            messageType: '',
                            data: data.message,
                            networkIcon: null,
                            name: null,
                            onReject: () async {
                              _sendNearError(
                                'user rejected msg',
                                jsData.id ?? 0,
                              );
                              Navigator.pop(context);
                            },
                            onConfirm: () async {
                              try {
                                final params = NearMessageBorsh(
                                  message: data.message,
                                  recipient: data.recipient,
                                  nonce: data.nonce.data,
                                  callbackUrl: data.callbackUrl,
                                );

                                final msg = await coin
                                    .signMessage(sha256(params.serialize()));

                                final signedMsg = jsonEncode(
                                  {
                                    'accountId': sendingAddress,
                                    'publicKey': base58.encode(
                                      HEX.decode(sendingAddress) as Uint8List,
                                    ),
                                    'signature': base64.encode(msg),
                                    'state': data.state,
                                  },
                                );

                                await _sendNearResult(signedMsg, jsData.id!);
                              } catch (e) {
                                final error =
                                    e.toString().replaceAll('"', '\'');

                                _sendNearError(error, jsData.id ?? 0);
                              } finally {
                                Navigator.pop(context);
                              }
                            },
                          );

                          break;
                        }
                      case "connect":
                        {
                          final addressData = jsonEncode(
                            {
                              'accountId': sendingAddress,
                              'publicKey': base58.encode(
                                HEX.decode(sendingAddress) as Uint8List,
                              ),
                            },
                          );
                          final request = await _getWeb3Address(
                            'near',
                            sendingAddress,
                          );

                          if (request != null) {
                            await _sendNearResult(addressData, jsData.id!);

                            return;
                          }
                          await connectWalletModal(
                            context: context,
                            url: jsData.url,
                            onConfirm: () async {
                              try {
                                await _sendNearResult(addressData, jsData.id!);

                                await _saveWeb3Address(
                                  'near',
                                  sendingAddress,
                                );
                              } catch (e) {
                                final error =
                                    e.toString().replaceAll('"', '\'');

                                _sendNearError(error, jsData.id ?? 0);
                              } finally {
                                Navigator.pop(context);
                              }
                            },
                            onReject: () async {
                              _sendNearError(
                                'user rejected connection',
                                jsData.id ?? 0,
                              );
                              Navigator.pop(context);
                            },
                          );

                          break;
                        }
                    }
                  },
                );
                _controller!.addJavaScriptHandler(
                  handlerName: 'CryptoHandler',
                  callback: (callback) async {
                    final jsData =
                        JsCallbackModel.fromJson(json.decode(callback[0]));

                    if (jsData.network == 'solana') {
                      final coin = getSolanaBlockChains().first;

                      final accountDetail = await coin.importData(data);

                      final privateKeyBytes =
                          HEX.decode(accountDetail.privateKey!);

                      final solanaKeyPair =
                          await solana.Ed25519HDKeyPair.fromPrivateKeyBytes(
                        privateKey: privateKeyBytes,
                      );

                      final sendingAddress = accountDetail.address;

                      switch (jsData.name) {
                        case "requestAccounts":
                          {
                            final request = await _getWeb3Address(
                              'solana',
                              sendingAddress,
                            );

                            if (request != null) {
                              await _setSolanaAddress(
                                jsData.id,
                                sendingAddress,
                              );
                              return;
                            }
                            await connectWalletModal(
                              context: context,
                              url: jsData.url,
                              onConfirm: () async {
                                try {
                                  await _setSolanaAddress(
                                    jsData.id,
                                    sendingAddress,
                                  );

                                  await _saveWeb3Address(
                                    'solana',
                                    sendingAddress,
                                  );
                                } catch (e) {
                                  final error =
                                      e.toString().replaceAll('"', '\'');
                                  _sendError("solana", error, jsData.id ?? 0);
                                } finally {
                                  Navigator.pop(context);
                                }
                              },
                              onReject: () async {
                                _sendError(
                                  "solana",
                                  'user rejected connection',
                                  jsData.id ?? 0,
                                );
                                Navigator.pop(context);
                              },
                            );

                            break;
                          }
                        case "signMessage":
                          {
                            try {
                              final data = JsSolanaMessageObject.fromJson(
                                jsData.object ?? {},
                              );

                              await signMessage(
                                context: context,
                                messageType: personalSignKey,
                                data: data.data,
                                networkIcon: null,
                                name: null,
                                onConfirm: () async {
                                  try {
                                    final signature = await solanaKeyPair.sign(
                                      txDataToUintList(data.data),
                                    );

                                    _sendResult(
                                      "solana",
                                      base58.encode(
                                        signature.bytes as Uint8List,
                                      ),
                                      jsData.id ?? 0,
                                    );
                                  } catch (e) {
                                    final error =
                                        e.toString().replaceAll('"', '\'');
                                    _sendError("solana", error, jsData.id ?? 0);
                                  } finally {
                                    Navigator.pop(context);
                                  }
                                },
                                onReject: () {
                                  _sendError(
                                      "solana",
                                      'user rejected signature',
                                      jsData.id ?? 0);
                                  Navigator.pop(context);
                                },
                              );
                            } catch (e) {
                              final error = e.toString().replaceAll('"', '\'');
                              _sendError("solana", error, jsData.id ?? 0);
                            }
                            break;
                          }
                        case "signRawTransaction":
                          {
                            final data = JsSolanaTransactionObject.fromJson(
                              jsData.object ?? {},
                            );

                            final SolanaWeb3Res solanaWeb3Res =
                                SolanaWeb3Res.fromJson(
                              json.decode(data.data),
                            );

                            final from = solana.Ed25519HDPublicKey.fromBase58(
                              solanaWeb3Res.feePayer,
                            );

                            await signSolanaTransaction(
                              to: '',
                              from: from.toBase58(),
                              txData: data.raw,
                              networkIcon: null,
                              context: context,
                              symbol: 'SOL',
                              solanaWeb3Res: solanaWeb3Res,
                              solanaKeyPair: solanaKeyPair,
                              name: '',
                              coin: coin,
                              onConfirm: () async {
                                try {
                                  if (solanaWeb3Res.feePayer !=
                                      sendingAddress) {
                                    throw Exception('Invalid fee payer');
                                  }

                                  final signature = await solanaKeyPair.sign(
                                    base58.decode(data.raw),
                                  );

                                  _sendResult(
                                    "solana",
                                    signature.toBase58(),
                                    jsData.id ?? 0,
                                  );
                                } catch (e, sk) {
                                  if (kDebugMode) {
                                    print(sk);
                                  }
                                  final error =
                                      e.toString().replaceAll('"', '\'');
                                  _sendError("solana", error, jsData.id ?? 0);
                                } finally {
                                  Navigator.pop(context);
                                }
                              },
                              onReject: () async {
                                _sendError(
                                  "solana",
                                  'user rejected transaction',
                                  jsData.id ?? 0,
                                );
                                Navigator.pop(context);
                              },
                            );

                            break;
                          }
                      }
                    
                    } else if (jsData.network == 'ethereum') {
                      int chainId = pref.get(dappChainIdKey);

                      final coin = evmFromChainId(chainId)!;
                      final web3Response = await coin.importData(data);

                      final privateKey = web3Response.privateKey!;
                      final credentials = EthPrivateKey.fromHex(privateKey);

                      final sendingAddress = web3Response.address;

                      switch (jsData.name) {
                        case "signTransaction":
                          {
                            final data = JsTransactionObject.fromJson(
                                jsData.object ?? {});
                            await signTransaction(
                              gasPriceInWei_: null,
                              to: data.to,
                              from: sendingAddress,
                              txData: data.data,
                              valueInWei_: data.value,
                              gasInWei_: null,
                              networkIcon: null,
                              context: context,
                              symbol: coin.symbol,
                              name: '',
                              onConfirm: () async {
                                try {
                                  final client = Web3Client(
                                    coin.rpc,
                                    Client(),
                                  );

                                  final signedTransaction =
                                      await client.signTransaction(
                                    credentials,
                                    Transaction(
                                      to: data.to != null
                                          ? EthereumAddress.fromHex(data.to!)
                                          : null,
                                      value: data.value != null
                                          ? EtherAmount.inWei(
                                              BigInt.parse(data.value!),
                                            )
                                          : null,
                                      nonce: data.nonce != null
                                          ? int.parse(data.nonce!)
                                          : null,
                                      data: data.data == null
                                          ? null
                                          : txDataToUintList(data.data!),
                                      gasPrice: data.gasPrice != null
                                          ? EtherAmount.inWei(
                                              BigInt.parse(
                                                data.gasPrice!,
                                              ),
                                            )
                                          : null,
                                    ),
                                    chainId: chainId,
                                  );

                                  final response = await client
                                      .sendRawTransaction(signedTransaction);

                                  _sendResult(
                                    "ethereum",
                                    response,
                                    jsData.id ?? 0,
                                  );
                                } catch (e, sk) {
                                  if (kDebugMode) {
                                    print(sk);
                                  }

                                  final error =
                                      e.toString().replaceAll('"', '\'');
                                  _sendError("ethereum", error, jsData.id ?? 0);
                                } finally {
                                  Navigator.pop(context);
                                }
                              },
                              onReject: () async {
                                _sendError(
                                  "ethereum",
                                  'user rejected transaction',
                                  jsData.id ?? 0,
                                );
                                Navigator.pop(context);
                              },
                              title: 'Sign Transaction',
                              chainId: chainId,
                            );

                            break;
                          }
                        case "signPersonalMessage":
                          {
                            final data =
                                JsDataModel.fromJson(jsData.object ?? {});

                            await signMessage(
                              context: context,
                              messageType: personalSignKey,
                              data: data.data,
                              networkIcon: null,
                              name: null,
                              onConfirm: () async {
                                try {
                                  final signedData =
                                      await credentials.signPersonalMessage(
                                    txDataToUintList(data.data),
                                  );

                                  _sendResult(
                                    "ethereum",
                                    bytesToHex(signedData, include0x: true),
                                    jsData.id ?? 0,
                                  );
                                } catch (e) {
                                  final error =
                                      e.toString().replaceAll('"', '\'');
                                  _sendError("ethereum", error, jsData.id ?? 0);
                                } finally {
                                  Navigator.pop(context);
                                }
                              },
                              onReject: () {
                                _sendError("ethereum",
                                    'user rejected signature', jsData.id ?? 0);
                                Navigator.pop(context);
                              },
                            );
                            break;
                          }
                        case "signMessage":
                          {
                            try {
                              final data =
                                  JsDataModel.fromJson(jsData.object ?? {});

                              String signedDataHex;

                              await signMessage(
                                context: context,
                                messageType: normalSignKey,
                                data: data.data,
                                networkIcon: null,
                                name: null,
                                onConfirm: () async {
                                  try {
                                    try {
                                      signedDataHex = EthSigUtil.signMessage(
                                        privateKey: privateKey,
                                        message: txDataToUintList(data.data),
                                      );
                                    } catch (e) {
                                      Uint8List signedData =
                                          await credentials.signPersonalMessage(
                                        txDataToUintList(data.data),
                                      );
                                      signedDataHex = bytesToHex(
                                        signedData,
                                        include0x: true,
                                      );
                                    }
                                    _sendResult("ethereum", signedDataHex,
                                        jsData.id ?? 0);
                                  } catch (e) {
                                    final error =
                                        e.toString().replaceAll('"', '\'');
                                    _sendError(
                                        "ethereum", error, jsData.id ?? 0);
                                  } finally {
                                    Navigator.pop(context);
                                  }
                                },
                                onReject: () {
                                  _sendError(
                                      "ethereum",
                                      'user rejected signature',
                                      jsData.id ?? 0);
                                  Navigator.pop(context);
                                },
                              );
                            } catch (e) {
                              final error = e.toString().replaceAll('"', '\'');
                              _sendError("ethereum", error, jsData.id ?? 0);
                            }
                            break;
                          }
                        case "signTypedMessage":
                          {
                            final data = JsEthSignTypedData.fromJson(
                              jsData.object ?? {},
                            );

                            final typedChainId = data.domain.chainId;

                            if (typedChainId != chainId) {
                              _sendError(
                                "ethereum",
                                "Provided chainId $typedChainId must match the active chainId $chainId",
                                jsData.id ?? 0,
                              );
                              return;
                            }

                            await signMessage(
                              context: context,
                              messageType: typedMessageSignKey,
                              data: data.raw,
                              networkIcon: null,
                              name: null,
                              onConfirm: () async {
                                try {
                                  String signedDataHex =
                                      EthSigUtil.signTypedData(
                                    privateKey: privateKey,
                                    jsonData: data.raw,
                                    version: TypedDataVersion.V4,
                                  );
                                  _sendResult("ethereum", signedDataHex,
                                      jsData.id ?? 0);
                                } catch (e) {
                                  final error =
                                      e.toString().replaceAll('"', '\'');
                                  _sendError("ethereum", error, jsData.id ?? 0);
                                } finally {
                                  Navigator.pop(context);
                                }
                              },
                              onReject: () {
                                _sendError("ethereum",
                                    'user rejected signature', jsData.id ?? 0);
                                Navigator.pop(context);
                              },
                            );

                            break;
                          }
                        case "ecRecover":
                          {
                            final data =
                                JsEcRecoverObject.fromJson(jsData.object ?? {});

                            try {
                              final signature =
                                  EthSigUtil.recoverPersonalSignature(
                                message: txDataToUintList(data.message),
                                signature: data.signature,
                              );
                              _sendResult(
                                "ethereum",
                                signature,
                                jsData.id ?? 0,
                              );
                            } catch (e) {
                              final error = e.toString().replaceAll('"', '\'');
                              _sendError("ethereum", error, jsData.id ?? 0);
                            }
                            break;
                          }
                        case "requestAccounts":
                          {
                            final request = await _getWeb3Address(
                              'ethereum',
                              sendingAddress,
                            );
                            if (request != null) {
                              await _setEthereumAddress(
                                jsData.id,
                                sendingAddress,
                              );
                              return;
                            }
                            await connectWalletModal(
                                context: context,
                                url: jsData.url,
                                onConfirm: () async {
                                  try {
                                    await _setEthereumAddress(
                                      jsData.id,
                                      sendingAddress,
                                    );

                                    await _saveWeb3Address(
                                      'ethereum',
                                      sendingAddress,
                                    );
                                  } catch (e) {
                                    final error =
                                        e.toString().replaceAll('"', '\'');
                                    _sendError(
                                        "ethereum", error, jsData.id ?? 0);
                                  } finally {
                                    Navigator.pop(context);
                                  }
                                },
                                onReject: () async {
                                  _sendError(
                                    "ethereum",
                                    'user rejected connection',
                                    jsData.id ?? 0,
                                  );
                                  Navigator.pop(context);
                                });

                            break;
                          }
                        case "watchAsset":
                          {
                            final data =
                                JsWatchAsset.fromJson(jsData.object ?? {});

                            try {
                              if (data.decimals == null) {
                                throw Exception(
                                  'invalid asset decimals',
                                );
                              }
                              if (data.symbol == null) {
                                throw Exception(
                                  'invalid asset symbol',
                                );
                              }
                              coin.validateAddress(data.contract);

                              final assetDetails = {
                                'name': data.symbol,
                                'symbol': data.symbol,
                                'decimals': data.decimals.toString(),
                                'contractAddress': data.contract,
                                'network': coin.name,
                                'rpc': coin.rpc,
                                'chainId': coin.chainId,
                                'coinType': coin.coinType,
                                'blockExplorer': coin.blockExplorer,
                              };
                              if (kDebugMode) {
                                print(assetDetails);
                              }
                              throw Exception('not Implemented');
                              // _sendResult("ethereum", '', jsData.id ?? 0);
                            } catch (e) {
                              final error = e.toString().replaceAll('"', '\'');
                              _sendError("ethereum", error, jsData.id ?? 0);
                            }
                            break;
                          }
                        case "addEthereumChain":
                          {
                            final data = JsAddEthereumChain.fromJson(
                              jsData.object ?? {},
                            );

                            try {
                              final switchChainId =
                                  BigInt.parse(data.chainId).toInt();

                              final currentChain = evmFromChainId(chainId)!;

                              EthereumCoin? switchChain =
                                  evmFromChainId(switchChainId);

                              if (chainId == switchChainId) {
                                _sendNull(
                                  "ethereum",
                                  jsData.id ?? 0,
                                );
                                return;
                              }

                              bool switchNetwork = true;
                              bool haveNotExecuted = true;

                              if (switchChain == null) {
                                switchNetwork = false;
                                haveNotExecuted = false;
                                List blockExplorers = data.blockExplorerUrls;
                                String blockExplorer = '';
                                if (blockExplorers.isNotEmpty) {
                                  blockExplorer = blockExplorers[0];
                                  if (blockExplorer.endsWith('/')) {
                                    blockExplorer = blockExplorer.substring(
                                        0, blockExplorer.length - 1);
                                  }
                                }
                                List rpcUrl = data.rpcUrls;

                                Map addBlockChain = {};
                                if (pref.get(newEVMChainKey) != null) {
                                  addBlockChain = Map.from(
                                      jsonDecode(pref.get(newEVMChainKey)));
                                }

                                if (data.symbol == null) {
                                  _sendError(
                                    "ethereum",
                                    'no symbol set',
                                    jsData.id ?? 0,
                                  );
                                  return;
                                }
                                if (data.symbol!.isEmpty) {
                                  _sendError(
                                    "ethereum",
                                    'no symbol set',
                                    jsData.id ?? 0,
                                  );
                                  return;
                                }
                                if (data.name!.isEmpty) {
                                  _sendError(
                                    "ethereum",
                                    'no name set',
                                    jsData.id ?? 0,
                                  );
                                  return;
                                }
                                if (rpcUrl.isEmpty) {
                                  _sendError(
                                    "ethereum",
                                    'not rpc url set',
                                    jsData.id ?? 0,
                                  );
                                  return;
                                }
                                if (blockExplorers.isEmpty) {
                                  _sendError(
                                    "ethereum",
                                    'not explorers url set',
                                    jsData.id ?? 0,
                                  );
                                  return;
                                }

                                switchChain = EthereumCoin(
                                  rpc: rpcUrl.isNotEmpty ? rpcUrl[0] : null,
                                  chainId: switchChainId,
                                  blockExplorer:
                                      '$blockExplorer/tx/$blockExplorerPlaceholder',
                                  symbol: data.symbol!,
                                  default_: data.symbol!,
                                  image: 'assets/ethereum-2.png',
                                  coinType: 60,
                                  name: data.chainName,
                                  geckoID: '',
                                  rampID: '',
                                  payScheme: '',
                                );

                                final switchJson = switchChain.toJson();

                                Map details = {
                                  data.chainName: switchJson,
                                };
                                addBlockChain.addAll(details);

                                await addEthereumChain(
                                  context: context,
                                  jsonObj: json.encode(
                                    Map.from({
                                      'name': data.chainName,
                                    })
                                      ..addAll(switchJson)
                                      ..remove('image')
                                      ..remove('coinType'),
                                  ),
                                  onConfirm: () async {
                                    try {
                                      const id = 83;
                                      final response = await post(
                                        Uri.parse(
                                          switchChain!.rpc,
                                        ),
                                        body: json.encode(
                                          {
                                            "jsonrpc": "2.0",
                                            "method": "eth_chainId",
                                            "params": [],
                                            "id": id
                                          },
                                        ),
                                        headers: {
                                          "Content-Type": "application/json"
                                        },
                                      );
                                      String responseBody = response.body;
                                      if (response.statusCode ~/ 100 == 4 ||
                                          response.statusCode ~/ 100 == 5) {
                                        if (kDebugMode) {
                                          print(responseBody);
                                        }
                                        throw Exception(responseBody);
                                      }

                                      final jsonResponse =
                                          json.decode(responseBody);

                                      final chainIdResponse =
                                          BigInt.parse(jsonResponse['result'])
                                              .toInt();

                                      if (jsonResponse['id'] != id) {
                                        throw Exception('invalid id returned');
                                      } else if (chainIdResponse !=
                                          switchChainId) {
                                        throw Exception(
                                          'chain Id different with eth_chainId',
                                        );
                                      }

                                      await pref.put(
                                        newEVMChainKey,
                                        jsonEncode(addBlockChain),
                                      );

                                      getAllBlockchains.add(switchChain);

                                      switchNetwork = true;
                                      Navigator.pop(context);
                                    } catch (e) {
                                      final error =
                                          e.toString().replaceAll('"', '\'');
                                      _sendError(
                                          "ethereum", error, jsData.id ?? 0);
                                      Navigator.pop(context);
                                    }
                                  },
                                  onReject: () async {
                                    _sendError(
                                        "ethereum", 'canceled', jsData.id ?? 0);

                                    Navigator.pop(context);
                                  },
                                );
                              }
                              if (switchNetwork) {
                                final initString =
                                    _addChain(switchChain, sendingAddress);
                                await _switchWeb3ChainRequest(
                                  currentChain: currentChain,
                                  switchChain: switchChain,
                                  initString: initString,
                                  jsData: jsData,
                                  haveNotExecuted: haveNotExecuted,
                                );
                              }
                            } catch (e) {
                              final error = e.toString().replaceAll('"', '\'');
                              _sendError("ethereum", error, jsData.id ?? 0);
                            }
                            break;
                          }
                        case "switchEthereumChain":
                          {
                            try {
                              final data = JsSwitchEthereumChain.fromJson(
                                jsData.object ?? {},
                              );
                              final switchChainId =
                                  BigInt.parse(data.chainId).toInt();

                              final currentChain = evmFromChainId(chainId)!;

                              final switchChain = evmFromChainId(switchChainId);

                              if (chainId == switchChainId) {
                                _sendNull(
                                  "ethereum",
                                  jsData.id ?? 0,
                                );

                                return;
                              }

                              if (switchChain == null) {
                                _sendError(
                                  "ethereum",
                                  'unknown chain id',
                                  jsData.id ?? 0,
                                );
                              } else {
                                final initString =
                                    _addChain(switchChain, sendingAddress);
                                await _switchWeb3ChainRequest(
                                  currentChain: currentChain,
                                  switchChain: switchChain,
                                  initString: initString,
                                  jsData: jsData,
                                );
                              }
                            } catch (e) {
                              final error = e.toString().replaceAll('"', '\'');
                              _sendError("ethereum", error, jsData.id ?? 0);
                            }
                            break;
                          }
                        default:
                          {
                            _sendError(jsData.network.toString(),
                                "Operation not supported", jsData.id ?? 0);
                            break;
                          }
                      }
                    }
                  },
                );
              },
              onLoadResourceWithCustomScheme: (
                InAppWebViewController contrl,
                WebResourceRequest req,
              ) async {
                if (req.url.scheme == "wc") {
                  await contrl.stopLoading();
                  await WCService.qrScanHandler('${req.url}');
                  return null;
                }
                return null;
              },
              initialUserScripts: UnmodifiableListView([
                UserScript(
                  source: widget.provider + initJs,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                ),
                ...webNotification
              ]),
              onLoadStart: (InAppWebViewController controller, Uri? url) async {
                _browserController.setText(url.toString());

                final documentTitle = await controller.getTitle();

                List history = [
                  {
                    'url': url.toString(),
                    'title': documentTitle,
                  }
                ];
                final savedHistory = pref.get(historyKey);
                if (savedHistory != null) {
                  history.addAll(jsonDecode(savedHistory) as List);
                }
                history.length = maximumBrowserHistoryToSave;

                _favicon = null;
                _title = '';
                _url = url.toString();
                _isSecure = urlIsSecure(url!);
                widget.onStateUpdated.call();
                await pref.put(
                  historyKey,
                  jsonEncode(history),
                );
              },
              onTitleChanged: (controller, title) {
                _title = title ?? '';
                widget.onStateUpdated.call();
              },
              onProgressChanged: (controller, progress) {
                if (mounted) {
                  _progress.value = progress / 100;
                  if (progress == 100) {
                    _pullToRefreshController.endRefreshing();
                  }
                }
              },
              onLoadStop: (controller, url) async {
                updateScreenshot();
                _pullToRefreshController.endRefreshing();
                if (url != null) {
                  final sslCertificate = await controller.getCertificate();
                  _url = url.toString();
                  _isSecure = sslCertificate != null || urlIsSecure(url);
                }

                try {
                  final favicons = await _controller?.getFavicons();
                  if (favicons != null && favicons.isNotEmpty) {
                    for (final favicon in favicons) {
                      if (_favicon == null) {
                        _favicon = favicon;
                      } else if (favicon.width != null &&
                          (favicon.width ?? 0) > (_favicon?.width ?? 0)) {
                        _favicon = favicon;
                      }
                    }
                  }
                } catch (_) {}

                if (mounted) {
                  widget.onStateUpdated.call();
                }
              },
              onConsoleMessage:
                  (InAppWebViewController controller, ConsoleMessage message) {
                if (kDebugMode) {
                  print(message.toString());
                }
              },
              onReceivedHttpAuthRequest: (controller, challenge) async {
                var action = await createHttpAuthDialog(challenge);
                return HttpAuthResponse(
                    username: _httpAuthUsernameController.text.trim(),
                    password: _httpAuthPasswordController.text,
                    action: action,
                    permanentPersistence: true);
              },
            ),
            ValueListenableBuilder(
              valueListenable: _progress,
              builder: (context, value, child) {
                return _progress.value < 1.0
                    ? LinearProgressIndicator(
                        value: _progress.value,
                      )
                    : Container();
              },
            ),
          ],
        ),
      ),
    ]);
  }

  Future<WebNotificationPermission> onNotificationRequestPermission() async {
    final url = await _controller!.getUrl();

    if (url != null) {
      final savedPermission =
          WebNotificationPermissionDb.getPermission(url.host);
      if (savedPermission != null) {
        return savedPermission;
      }
    }

    final permission = await showDialog<WebNotificationPermission>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('${url?.host} wants to show notifications'),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop<WebNotificationPermission>(
                          context, WebNotificationPermission.DENIED);
                    },
                    child: const Text('Deny')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop<WebNotificationPermission>(
                          context, WebNotificationPermission.GRANTED);
                    },
                    child: const Text('Grant'))
              ],
            );
          },
        ) ??
        WebNotificationPermission.DENIED;

    if (url != null) {
      await WebNotificationPermissionDb.savePermission(url.host, permission);
    }

    return permission;
  }

  void onShowNotification(WebNotification notification) async {
    webNotificationController?.notifications[notification.id] = notification;
    Uri? iconUrl = notification.icon.trim().isNotEmpty
        ? Uri.tryParse(notification.icon)
        : null;
    if (!iconUrl!.hasScheme) {
      iconUrl = Uri.tryParse(
          (await _controller?.getUrl()).toString() + iconUrl.toString());
    }

    await NotificationApi.showNotification(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      imageUrl: iconUrl?.toString(),
      onclick: (payload) async {
        await notification.dispatchClick();
      },
      onclose: () async {
        await notification.close();
      },
    );

    final vibrate = notification.vibrate;
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator && vibrate.isNotEmpty) {
      if (vibrate.length % 2 != 0) {
        vibrate.add(0);
      }
      final intensities = <int>[];
      for (int i = 0; i < vibrate.length; i++) {
        if (i % 2 == 0 && vibrate[i] > 0) {
          intensities.add(255);
        } else {
          intensities.add(0);
        }
      }
      await Vibration.vibrate(pattern: vibrate, intensities: intensities);
    }
  }

  resetNotificationPermission() async {
    await WebNotificationPermissionDb.clear();
    await webNotificationController?.resetPermission();
  }

  void onCloseNotification(int id) async {
    final notification = webNotificationController?.notifications[id];
    await NotificationApi.closeNotification(id: id);
    if (notification != null) {
      await NotificationApi.closeNotification(id: id);
      webNotificationController?.notifications.remove(id);
    }
  }

  Future<void> updateScreenshot() async {
    final scshot = await _controller!
        .takeScreenshot(
          screenshotConfiguration: ScreenshotConfiguration(
            compressFormat: CompressFormat.JPEG,
            quality: 20,
          ),
        )
        .timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () => null,
        );
    _screenshot = scshot;
  }

  Future<void> pause() async {
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _controller?.setAllMediaPlaybackSuspended(suspended: true);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await _controller?.pause();
      }
    }
  }

  Future<void> resume() async {
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _controller?.setAllMediaPlaybackSuspended(suspended: false);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await _controller?.resume();
      }
    }
  }

  Future<bool> canGoBack() async {
    return await _controller?.canGoBack() ?? false;
  }

  Future<void> goBack() async {
    if (await canGoBack()) {
      await _controller?.goBack();
    }
  }

  Future<bool> canGoForward() async {
    return await _controller?.canGoForward() ?? false;
  }

  Future<void> goForward() async {
    if (await canGoForward()) {
      await _controller?.goForward();
    }
  }

  switchWeb3_(int chainId, String rpc) async {
    initJs = await returnInitEvm(chainId, rpc);
    await reloadWeb3_();
  }

  reloadWeb3_() async {
    await _controller!.removeAllUserScripts();
    await _controller!.addUserScripts(userScripts: [
      UserScript(
        source: widget.provider + initJs,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
      ...webNotification
    ]);
    await _controller!.reload();
  }

  void _tryDownloadFile(String url, [String? filename]) {
    final snack = ScaffoldMessenger.of(context);
    snack.clearSnackBars();
    SnackBar snackBar = SnackBar(
      content: Text(
        'Allow download $url?',
      ),
      action: SnackBarAction(
        label: 'Ok',
        onPressed: () async {
          await downloadFile(
            url,
            filename,
          );
        },
      ),
    );
    snack.showSnackBar(snackBar);
  }
}
