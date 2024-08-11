import 'package:flutter/material.dart';

class EIP4337Education extends StatelessWidget {
  const EIP4337Education({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Educational Steps')),
      body: const StepperExample(),
    );
  }
}

class StepperExample extends StatefulWidget {
  const StepperExample({Key? key}) : super(key: key);

  @override
  State<StepperExample> createState() => _StepperExampleState();
}

class _StepperExampleState extends State<StepperExample> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Stepper(
      currentStep: _index,
      onStepCancel: () {
        if (_index > 0) {
          setState(() {
            _index -= 1;
          });
        }
      },
      onStepContinue: () {
        if (_index < 3) {
          // Updated to reflect the new step count
          setState(() {
            _index += 1;
          });
        }
      },
      onStepTapped: (int index) {
        setState(() {
          _index = index;
        });
      },
      steps: <Step>[
        Step(
          title: const Text('Introduction to Financial Principles'),
          content: Container(
            alignment: Alignment.centerLeft,
            child: const Text(
              'Financial principles form the foundation of personal and business finance. Here are key concepts:\n\n'
              '1. **Saving**: Setting aside a portion of your income regularly helps in building a financial cushion. This is important for emergencies and future expenses.\n'
              '2. **Budgeting**: Creating a budget helps you track your income and expenses, ensuring that you live within your means and avoid unnecessary debt.\n'
              '3. **Managing Debt**: Understanding the difference between good debt (like a mortgage) and bad debt (like high-interest credit card debt) is crucial. Aim to pay off bad debt quickly and manage good debt responsibly.\n'
              '4. **Compound Interest**: This is the interest on a loan or deposit calculated based on both the initial principal and the accumulated interest from previous periods. It’s a powerful tool for growing wealth over time.',
            ),
          ),
        ),
        Step(
          title: const Text('Understanding Blockchain Technology'),
          content: Container(
            alignment: Alignment.centerLeft,
            child: const Text(
              'Blockchain is a revolutionary technology that underpins cryptocurrencies like Bitcoin and Ethereum. Key concepts include:\n\n'
              '1. **Decentralization**: Unlike traditional financial systems, blockchain operates without a central authority. This means that no single entity, like a bank or government, controls the blockchain.\n'
              '2. **Consensus Mechanisms**: These are protocols that help all participants in the blockchain network agree on the validity of transactions. Examples include Proof of Work (PoW) and Proof of Stake (PoS).\n'
              '3. **Smart Contracts**: These are self-executing contracts with the terms of the agreement directly written into code. They automatically execute actions when predefined conditions are met, removing the need for intermediaries.\n'
              '4. **Immutable Ledger**: Once data is recorded on the blockchain, it cannot be altered. This ensures transparency and trust, as all transactions are permanently logged and accessible to all network participants.',
            ),
          ),
        ),
        Step(
          title: const Text('Investment Strategies'),
          content: Container(
            alignment: Alignment.centerLeft,
            child: const Text(
              'Investing is about growing your wealth over time. Here are some strategies to consider:\n\n'
              '1. **Risk Management**: Understand your risk tolerance before investing. Higher returns usually come with higher risks, so it’s important to balance your investments according to your comfort level.\n'
              '2. **Diversification**: Don’t put all your eggs in one basket. Spread your investments across different asset classes (stocks, bonds, real estate, cryptocurrencies) to reduce risk.\n'
              '3. **Long-Term vs. Short-Term Investing**: Long-term investing often involves buying assets with the intention of holding them for several years, benefiting from compound growth. Short-term investing, on the other hand, focuses on quick profits and often involves more risk.\n'
              '4. **Dollar-Cost Averaging**: This strategy involves regularly investing a fixed amount of money, regardless of the market’s condition. It helps reduce the impact of market volatility on your investments.\n'
              '5. **Rebalancing**: Periodically review and adjust your portfolio to maintain your desired asset allocation, ensuring that you’re not overexposed to any single asset class.',
            ),
          ),
        ),
        Step(
          title: const Text('EIP-4337: Account Abstraction for Smart Wallets'),
          content: Container(
            alignment: Alignment.centerLeft,
            child: const Text(
              'EIP-4337 is a proposed Ethereum Improvement Proposal that introduces account abstraction, which allows for more flexible and powerful smart wallets. Here’s what it entails:\n\n'
              '1. **Account Abstraction**: Traditionally, Ethereum accounts are either externally owned (controlled by a private key) or contract-based (controlled by code). EIP-4337 abstracts these differences, enabling more advanced functionalities in smart wallets.\n'
              '2. **Benefits for Users**: With EIP-4337, users can enjoy features like multi-signature wallets, social recovery (in case you lose your private key), and more intuitive user experiences without compromising security.\n'
              '3. **Advanced Use Cases**: EIP-4337 enables new possibilities such as gasless transactions (where transaction fees are paid by a third party), batched transactions (executing multiple operations in one transaction), and customizable security models.\n'
              '4. **Implementation**: EIP-4337 is designed to be implemented at the application layer, meaning it does not require changes to Ethereum’s core protocol, making it easier to adopt without hard forks or network upgrades.',
            ),
          ),
        ),
      ],
    );
  }
}
