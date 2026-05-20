import 'package:flutter/material.dart';
import '../../theme.dart';

class LiberalPipelineScreen extends StatefulWidget {
  const LiberalPipelineScreen({super.key});

  @override
  State<LiberalPipelineScreen> createState() => _LiberalPipelineScreenState();
}

class _LiberalPipelineScreenState extends State<LiberalPipelineScreen> {
  String _selectedStage = 'All';

  final _prospects = [
    {
      'company': 'ECAB Consulting',
      'contact': 'Jean Durand',
      'stage': 'Proposal',
      'value': 2500000,
      'probability': 75,
      'lastContact': 'Il y a 2j',
      'nextFollowUp': 'Demain',
      'events': ['Appel initial (15/05)', 'Réunion (18/05)', 'Proposition envoyée (20/05)'],
    },
    {
      'company': 'Impact Group',
      'contact': 'Marie Okolo',
      'stage': 'Negotiation',
      'value': 1800000,
      'probability': 60,
      'lastContact': 'Aujourd\'hui',
      'nextFollowUp': 'Dans 3j',
      'events': ['Premier contact (10/05)', 'Discution détails (17/05)'],
    },
    {
      'company': 'TradeHub Congo',
      'contact': 'Paul Mfuamba',
      'stage': 'Signed',
      'value': 3200000,
      'probability': 100,
      'lastContact': 'Il y a 1j',
      'nextFollowUp': 'Renouvellement: 20/06',
      'events': ['Contact initial (01/05)', 'Contrat signé (22/05)'],
    },
    {
      'company': 'Innovate SARL',
      'contact': 'Sophie Nkulu',
      'stage': 'Discussion',
      'value': 1200000,
      'probability': 40,
      'lastContact': 'Il y a 5j',
      'nextFollowUp': 'Prévu 28/05',
      'events': ['Primo contact (15/05)'],
    },
    {
      'company': 'BizFlow Solutions',
      'contact': 'Robert Kasongo',
      'stage': 'Prospect',
      'value': 950000,
      'probability': 20,
      'lastContact': 'Il y a 1 semaine',
      'nextFollowUp': 'À relancer',
      'events': [],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredProspects = _selectedStage == 'All'
        ? _prospects
        : _prospects.where((p) => p['stage'] == _selectedStage).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Pipeline Clients'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stage selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StageButton(
                    label: 'Tous',
                    isSelected: _selectedStage == 'All',
                    onTap: () => setState(() => _selectedStage = 'All'),
                  ),
                  ...[
                    ('Prospect', Colors.grey.shade700),
                    ('Discussion', Colors.orange.shade700),
                    ('Proposal', Colors.blue.shade700),
                    ('Negotiation', Colors.amber.shade700),
                    ('Signed', Colors.green.shade700),
                  ].map((item) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _StageButton(
                      label: item.$1,
                      color: item.$2,
                      isSelected: _selectedStage == item.$1,
                      onTap: () => setState(() => _selectedStage = item.$1),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pipeline Value Summary
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'CA potentiel',
                    value: '${(filteredProspects.fold<int>(0, (sum, p) => sum + (p['value'] as int)) / 1000000).toStringAsFixed(1)}M',
                    color: AppTheme.forestGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Prob. moyenne',
                    value: '${(filteredProspects.isEmpty ? 0 : (filteredProspects.fold<int>(0, (sum, p) => sum + (p['probability'] as int)) / filteredProspects.length)).toStringAsFixed(0)}%',
                    color: AppTheme.xafGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Prospects list
            Text('${filteredProspects.length} prospect(s)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            ...filteredProspects.map((prospect) => _ProspectCard(prospect: prospect)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajouter prospect'))),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StageButton extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StageButton({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: color?.withValues(alpha: 0.1),
      selectedColor: color ?? AppTheme.forestGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (color ?? AppTheme.forestGreen),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _ProspectCard extends StatelessWidget {
  final Map<String, dynamic> prospect;

  const _ProspectCard({required this.prospect});

  @override
  Widget build(BuildContext context) {
    final stage = prospect['stage'] as String;
    final stageColor = _getStageColor(stage);
    final events = (prospect['events'] as List<String>? ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prospect['company'].toString(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            Text(
              prospect['contact'].toString(),
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: stageColor, borderRadius: BorderRadius.circular(4)),
              child: Text(stage, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Text('${prospect['probability']}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.forestGreen)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Value & Probability
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Valeur estimée', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    Text('${(prospect['value'] as int) ~/ 1000} k XAF', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),

                // Timeline
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Derniers contacts', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text('Dernier: ${prospect['lastContact']}', style: const TextStyle(fontSize: 12)),
                    Text('Suivi: ${prospect['nextFollowUp']}', style: const TextStyle(fontSize: 12, color: AppTheme.forestGreen, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),

                // Events
                if (events.isNotEmpty) ...[
                  Text('Historique:', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ...events.map((event) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: AppTheme.forestGreen),
                        const SizedBox(width: 6),
                        Expanded(child: Text(event, style: const TextStyle(fontSize: 11))),
                      ],
                    ),
                  )),
                ],
                const SizedBox(height: 12),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appeler'))),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Appeler'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposer contrat'))),
                      icon: const Icon(Icons.description, size: 16),
                      label: const Text('Contrat'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStageColor(String stage) => switch (stage) {
    'Prospect' => Colors.grey.shade700,
    'Discussion' => Colors.orange.shade700,
    'Proposal' => Colors.blue.shade700,
    'Negotiation' => Colors.amber.shade700,
    'Signed' => Colors.green.shade700,
    _ => Colors.grey,
  };
}
