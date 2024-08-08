import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

import '../coins/near_coin.dart';
import '../service/mint_service.dart';
import 'package:cryptowallet/main.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../config/colors.dart';
import '../../config/styles.dart';
import '../components/loader.dart';
import '../utils/slide_up_panel.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class AI extends StatefulWidget {
  final String referralAddress;
  const AI({Key? key, this.referralAddress = zeroAddress}) : super(key: key);

  @override
  _AIState createState() => _AIState();
}

class _AIState extends State<AI> {
  bool isLoading = false;
  bool isClaiming = false;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late AppLocalizations localization;
  bool get disableBtn => MintService.getMint() == BigInt.zero || isClaiming;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    localization = AppLocalizations.of(context)!;
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(title: const Text('AI Earn')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 2));
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 30,
                      ),
                      SvgPicture.asset('assets/airdrop_big.svg'),
                      const SizedBox(
                        height: 50,
                      ),
                      Text(
                        localization.youWouldEarn,
                        style: s_agRegular_gray12,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ValueListenableBuilder(
                        valueListenable:
                            pref.listenable(keys: [MintService.mintAmtKey]),
                        builder: (context, box, _) {
                          final coin = MintService.getMintCoin();

                          final amount = MintService.getMint() /
                              BigInt.from(10).pow(coin.decimals());

                          return Text(
                            '${formatMoney(amount)} ${coin.getSymbol()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 50,
                      ),
                      Container(
                        color: Colors.transparent,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            // ()
                            backgroundColor: MaterialStateProperty.resolveWith(
                              (states) => disableBtn
                                  ? appBackgroundblue.withOpacity(0.3)
                                  : appBackgroundblue,
                            ),
                            shape: MaterialStateProperty.resolveWith(
                              (states) => RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          onPressed: disableBtn
                              ? null
                              : () async {
                                  if (isClaiming) return;
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  setState(() {
                                    isClaiming = true;
                                  });

                                  NearCoin coin = nearChains[0];

                                  try {
                                    if (!await coin.mintToken()) {
                                      throw Exception(
                                        'claiming failed, try funding your NEAR wallet or check your internet.',
                                      );
                                    }
                                  } catch (e) {
                                    if (kDebugMode) {
                                      print(e);
                                    }
                                    setState(() {
                                      isClaiming = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red,
                                        content: Text(
                                          e.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  await slideUpPanel(context,
                                      StatefulBuilder(builder: (ctx, setState) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/successIcon.png',
                                            scale: 10,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(30),
                                            child: Text(
                                              localization.airdropSuccess,
                                              style: title1,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }));

                                  setState(() {
                                    isClaiming = false;
                                  });
                                },
                          child: isClaiming
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Loader(color: black),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Text(
                                    localization.claim,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        localization.airdropClaimedOnceOnly,
                        style: s_agRegular_gray12,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
