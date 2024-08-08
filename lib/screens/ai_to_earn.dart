import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:pinput/pinput.dart';

import '../components/loader.dart';
import '../config/colors.dart';
import '../service/mint_service.dart';
import '../utils/app_config.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

import '../utils/qr_scan_view.dart';

class AIToEarn extends StatefulWidget {
  const AIToEarn({Key? key}) : super(key: key);

  @override
  State<AIToEarn> createState() => _AIToEarnState();
}

class ApiResponse {
  bool isSafe;
  ApiResponse({required this.isSafe});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      isSafe: json['isSafe'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isSafe'] = isSafe;

    return data;
  }
}

class _AIToEarnState extends State<AIToEarn> {
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<String> safeBuy = ValueNotifier('');
  final contrAddrCntrl = TextEditingController();
  late AppLocalizations localization;

  _checkContract() async {
    final conAddr = contrAddrCntrl.text.trim();
    if (conAddr.isEmpty) return;
    try {
      isLoading.value = true;
      final request = await get(
        Uri.parse(
            'https://ninth-matter-407315.wn.r.appspot.com/predict/?contract_addr=$conAddr'),
      );

      if (request.statusCode ~/ 100 == 4 || request.statusCode ~/ 100 == 5) {
        throw Exception('Request failed');
      }

      ApiResponse data = ApiResponse.fromJson(jsonDecode(request.body));

      await MintService.saveMint(success: data.isSafe);

      safeBuy.value = data.isSafe ? '$conAddr safe' : '$conAddr not so sure';

      final amount = MintService.getAmountSuccess(success: data.isSafe);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: green,
          content: Text(
            '${localization.youWouldEarn} $amount ${MintService.getMintCoin().symbol}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e, sk) {
      if (kDebugMode) {
        print(e);
        print(sk);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    localization = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI To Earn ',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: contrAddrCntrl,
                    decoration: InputDecoration(
                      suffixIcon: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.qr_code_scanner,
                            ),
                            onPressed: () async {
                              String? addr = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => const QRScanView(),
                                ),
                              );
                              if (addr == null) return;
                              contrAddrCntrl.setText(addr);
                            },
                          ),
                          InkWell(
                            onTap: () async {
                              ClipboardData? cdata =
                                  await Clipboard.getData(Clipboard.kTextPlain);
                              if (cdata == null) return;
                              if (cdata.text == null) return;
                              contrAddrCntrl.setText(cdata.text!);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                localization.paste,
                              ),
                            ),
                          ),
                        ],
                      ),

                      hintText: localization.address,
                      focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide.none),
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide.none),
                      enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide.none), // you
                      filled: true,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: safeBuy,
                    builder: (context, value, child) {
                      if (safeBuy.value.isNotEmpty) {
                        return Text(
                          value,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        );
                      }
                      return Container();
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      color: Colors.red[100],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            localization.enterContractAddress,
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            localization.willAwardIfSafe,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: isLoading,
                    builder: (context, value, child) {
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith(
                              (states) => appBackgroundblue,
                            ),
                            shape: MaterialStateProperty.resolveWith(
                              (states) => RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            textStyle: MaterialStateProperty.resolveWith(
                              (states) => const TextStyle(color: Colors.white),
                            ),
                          ),
                          child: value
                              ? Container(
                                  color: Colors.transparent,
                                  width: 20,
                                  height: 20,
                                  child: const Loader(color: black),
                                )
                              : Text(
                                  localization.continue_,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                          onPressed: _checkContract,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
