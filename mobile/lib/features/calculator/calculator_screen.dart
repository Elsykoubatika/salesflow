import 'package:flutter/material.dart';
import '../../theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _materialCtrl = TextEditingController();
  final _laborCtrl = TextEditingController();
  final _marginCtrl = TextEditingController(text: '30');
  num _costPrice = 0;
  num _salePrice = 0;

  @override
  void dispose() {
    _materialCtrl.dispose();
    _laborCtrl.dispose();
    _marginCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final material = num.tryParse(_materialCtrl.text) ?? 0;
    final labor = num.tryParse(_laborCtrl.text) ?? 0;
    final margin = num.tryParse(_marginCtrl.text) ?? 30;
    final totalCost = material + labor;
    setState(() {
      _costPrice = totalCost;
      _salePrice = totalCost * (1 + margin / 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Calculateur prix de revient'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Coûts', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _materialCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Coût matière (XAF)', prefixIcon: Icon(Icons.shopping_cart_outlined)),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _laborCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Coût main-d\'œuvre (XAF)', prefixIcon: Icon(Icons.person_outline)),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 24),
            Text('Marge', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _marginCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Marge (%)', prefixIcon: Icon(Icons.percent)),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.xafGold.withValues(alpha: 0.1), AppTheme.xafGold.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.xafGold.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Coût de revient', style: theme.textTheme.bodyLarge),
                    Text('${_costPrice.toStringAsFixed(0)} XAF', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Prix de vente', style: theme.textTheme.bodyLarge),
                    Text('${_salePrice.toStringAsFixed(0)} XAF', style: theme.textTheme.displaySmall?.copyWith(color: AppTheme.forestGreen, fontSize: 28, fontWeight: FontWeight.w800)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Gain: ${(_salePrice - _costPrice).toStringAsFixed(0)} XAF', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
