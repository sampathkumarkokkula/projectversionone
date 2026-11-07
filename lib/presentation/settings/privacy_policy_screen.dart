import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows the bundled privacy policy (PRIVACY_POLICY.md at the repo root).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('PRIVACY_POLICY.md'),
        builder: (context, snapshot) {
          final text = snapshot.data;
          if (text == null) return const Center(child: CircularProgressIndicator());
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(text.replaceAll('**', '').replaceAll('# ', '')),
          );
        },
      ),
    );
  }
}
