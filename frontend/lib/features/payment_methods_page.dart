import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      appBar: AppBar(
        title: const Text('Payment methods'),
        backgroundColor: const Color(0xFFF6F9F8),
        foregroundColor: GuzoColors.ink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/user'),
          tooltip: 'Back to account',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: GuzoColors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.credit_card_rounded,
                    color: GuzoColors.green,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Payment methods aren’t available yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GuzoColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You’ll be able to manage cards and wallets when booking '
                  'checkout is available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GuzoColors.muted.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
