
import 'package:cryptowallet/screens/dapp_ui.dart';
import 'package:cryptowallet/screens/settings.dart';
import 'package:cryptowallet/screens/ai_and_earn.dart';
import 'package:cryptowallet/screens/wallet_main_body.dart';
import 'package:cryptowallet/service/wallet_service.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class Wallet extends StatefulWidget {
  const Wallet({Key? key}) : super(key: key);

  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  PageController pageController = PageController(initialPage: 0);
  int currentIndex_ = 0;

  @override
  void initState() {
    super.initState();
    enableScreenShot();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  _onTapped(int index) {
    setState(() {
      currentIndex_ = index;
    });
    // remove keyboard focus
    FocusManager.instance.primaryFocus?.unfocus();
    pageController.animateToPage(index,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex_ = index;
      // remove focus
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  final pages = [
    const WalletMainBody(),
    if (!WalletService.isViewKey()) const DappUI(),
    const AI(),
    const Settings(),
  ];

  late AppLocalizations localization;
  @override
  Widget build(BuildContext context) {
    localization = AppLocalizations.of(context)!;
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex_,
        elevation: 0,
        onTap: _onTapped,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              FontAwesomeIcons.wallet,
              size: 25,
              color: currentIndex_ == 0
                  ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                  : Theme.of(context)
                      .bottomNavigationBarTheme
                      .unselectedItemColor,
            ),
            label: localization.wallet,
          ),
          if (!WalletService.isViewKey())
            BottomNavigationBarItem(
              icon: Icon(
                FontAwesomeIcons.cubes,
                size: 25,
                color: currentIndex_ == 1
                    ? Theme.of(context)
                        .bottomNavigationBarTheme
                        .selectedItemColor
                    : Theme.of(context)
                        .bottomNavigationBarTheme
                        .unselectedItemColor,
              ),
              label: "Dapp",
            ),
          BottomNavigationBarItem(
            icon: Icon(
              FontAwesomeIcons.piggyBank,
              size: 25,
              color: currentIndex_ == (!WalletService.isViewKey() ? 2 : 1)
                  ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                  : Theme.of(context)
                      .bottomNavigationBarTheme
                      .unselectedItemColor,
            ),
            label: "Earn",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              FontAwesomeIcons.cog,
              size: 25,
              color: currentIndex_ == (!WalletService.isViewKey() ? 3 : 2)
                  ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                  : Theme.of(context)
                      .bottomNavigationBarTheme
                      .unselectedItemColor,
            ),
            label: localization.settings,
          )
        ],
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: onPageChanged,
        children: pages,
      ),
    );
  }
}
