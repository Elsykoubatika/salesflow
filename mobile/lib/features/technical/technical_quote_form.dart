import 'package:flutter/material.dart';
import '../../theme.dart';

class TechnicalQuoteFormScreen extends StatefulWidget {
  const TechnicalQuoteFormScreen({super.key});

  @override
  State<TechnicalQuoteFormScreen> createState() => _TechnicalQuoteFormScreenState();
}

class _TechnicalQuoteFormScreenState extends State<TechnicalQuoteFormScreen> {
  String _selectedType = 'electrical';
  int bedrooms = 2, bathrooms = 1, kitchens = 1;
  double powerLoad = 5.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Devis Technique'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Type de travaux', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'electrical', label: Text('Électrique')),
                ButtonSegment(value: 'plumbing', label: Text('Plomberie')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (s) => setState(() => _selectedType = s.first),
            ),
            const SizedBox(height: 24),
            
            if (_selectedType == 'electrical') ...[
              _buildElectricalCalculators(theme),
            ] else ...[
              _buildPlumbingCalculators(theme),
            ],
            
            const SizedBox(height: 24),
            FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Devis créé'))), child: const Text('Créer Devis')),
          ],
        ),
      ),
    );
  }

  Widget _buildElectricalCalculators(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Prises électriques (NFC15-100)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text('Chambres: $bedrooms'),
        Slider(min: 0, max: 10, value: bedrooms.toDouble(), onChanged: (v) => setState(() => bedrooms = v.toInt()), divisions: 10),
        const SizedBox(height: 8),
        Text('S.d.b: $bathrooms'),
        Slider(min: 0, max: 5, value: bathrooms.toDouble(), onChanged: (v) => setState(() => bathrooms = v.toInt()), divisions: 5),
        const SizedBox(height: 8),
        Text('Cuisines: $kitchens'),
        Slider(min: 0, max: 3, value: kitchens.toDouble(), onChanged: (v) => setState(() => kitchens = v.toInt()), divisions: 3),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_calcOutlets()} prises nécessaires', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.forestGreen)),
                const SizedBox(height: 4),
                Text('à 3.500 XAF/prise = ${_calcOutletsCost()} XAF', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        Text('Disjoncteurs', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text('Charge: ${powerLoad.toStringAsFixed(1)} kW'),
        Slider(min: 1, max: 50, value: powerLoad, onChanged: (v) => setState(() => powerLoad = v), divisions: 49),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_calcBreakers()} disjoncteurs 10A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.forestGreen)),
                const SizedBox(height: 4),
                Text('à 12.000 XAF = ${_calcBreakersPrice()} XAF', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlumbingCalculators(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tuyauterie PVC', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text('Salles d\'eau: $bathrooms'),
        Slider(min: 0, max: 10, value: bathrooms.toDouble(), onChanged: (v) => setState(() => bathrooms = v.toInt()), divisions: 10),
        const SizedBox(height: 8),
        Text('Cuisines: $kitchens'),
        Slider(min: 0, max: 5, value: kitchens.toDouble(), onChanged: (v) => setState(() => kitchens = v.toInt()), divisions: 5),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_calcPipes()} mètres de tuyauterie', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.forestGreen)),
                const SizedBox(height: 4),
                Text('à 2.500 XAF/m = ${_calcPipesPrice()} XAF', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _calcOutlets() => (bedrooms * 3) + (bathrooms * 2) + (kitchens * 6) + 4;
  int _calcOutletsCost() => _calcOutlets() * 3500;
  int _calcBreakers() => ((powerLoad * 1000 / 230) / 10).ceil();
  int _calcBreakersPrice() => _calcBreakers() * 12000;
  int _calcPipes() => ((bathrooms * 15) + (kitchens * 12) + 20).toInt();
  int _calcPipesPrice() => _calcPipes() * 2500;
}
