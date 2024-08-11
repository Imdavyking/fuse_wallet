import 'package:cryptowallet/coins/fuse_4337_coin.dart';
import 'package:cryptowallet/components/loader.dart';
import 'package:cryptowallet/utils/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:pinput/pinput.dart';
import 'package:web3dart/web3dart.dart';

class CreateGoal extends StatefulWidget {
  final FuseCoin coin;

  const CreateGoal({Key? key, required this.coin}) : super(key: key);

  @override
  State<CreateGoal> createState() => _CreateGoalState();
}

class _CreateGoalState extends State<CreateGoal> {
  final TextEditingController _goalNameController = TextEditingController();

  final TextEditingController _AmountController = TextEditingController();

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  AppLocalizations? localization;

  @override
  Widget build(BuildContext context) {
    localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Token Goal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              enabled: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              controller: _goalNameController,
              decoration: InputDecoration(
                suffixIconConstraints: const BoxConstraints(minWidth: 100),

                hintText: localization!.goalName,

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
            const SizedBox(height: 16.0),
            TextFormField(
              enabled: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.trim() == '') {
                  return localization!.amountIsRequired;
                } else {
                  return null;
                }
              },
              controller: _AmountController,
              decoration: InputDecoration(
                suffixIconConstraints: const BoxConstraints(minWidth: 100),
                // suffixIcon: IconButton(
                //   alignment: Alignment.centerRight,
                //   icon: Text(
                //     localization!.max,
                //     textAlign: TextAlign.end,
                //   ),
                //   onPressed: () async {
                //     final maxTransfer = await coin.getMaxTransfer();
                //     _AmountController.setText(maxTransfer.toString());
                //   },
                // ),
                hintText: localization!.amount,

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
            const SizedBox(height: 32.0),
            ValueListenableBuilder(
              valueListenable: isLoading,
              builder: (context, value, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => appBackgroundblue),
                      shape: WidgetStateProperty.resolveWith(
                        (states) => RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      textStyle: WidgetStateProperty.resolveWith(
                        (states) => const TextStyle(color: Colors.white),
                      ),
                    ),
                    child: isLoading.value
                        ? const Loader()
                        : Text(
                            localization!.continue_,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                    onPressed: () async {
                      try {
                        final goalName = _goalNameController.text;
                        final tokenAddress = _AmountController.text;
                        EthereumAddress.fromHex(tokenAddress);
                        isLoading.value = true;
                        await widget.coin.saveTokens(goalName, tokenAddress);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text(
                              'Goal created',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      } catch (e) {
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
                      } finally {
                        isLoading.value = false;
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
