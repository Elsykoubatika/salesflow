import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedDomain = 'Commerce';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Type de métier', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: _selectedDomain,
            onChanged: (val) =>
                setState(() => _selectedDomain = val ?? 'Commerce'),
            child: Column(
              children: ['Commerce', 'Technique', 'Libéral']
                  .map((domain) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: RadioListTile<String>(
                            title: Text(domain),
                            subtitle: Text(_getDescription(domain),
                                style: theme.textTheme.bodySmall),
                            value: domain,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _saveDomain, child: const Text('Enregistrer')),
        ],
      ),
    );
  }

  String _getDescription(String domain) => switch (domain) {
        'Commerce' => 'Vente de produits/marchandises',
        'Technique' => 'Services techniques (réparation, installation)',
        'Libéral' => 'Conseils/formation/prestations intellectuelles',
        _ => '',
      };

  void _saveDomain() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Domaine "$_selectedDomain" enregistré')),
    );
  }
}
