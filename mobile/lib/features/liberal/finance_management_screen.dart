import 'package:flutter/material.dart';
import '../../theme.dart';

class FinanceManagementScreen extends StatefulWidget {
  const FinanceManagementScreen({super.key});

  @override
  State<FinanceManagementScreen> createState() => _FinanceManagementScreenState();
}

class _FinanceManagementScreenState extends State<FinanceManagementScreen> {
  final _accounts = [
    {'name': 'Personnel', 'type': 'Personal', 'balance': 2500000, 'transactions': 45},
    {'name': 'Famille', 'type': 'Family', 'balance': 5800000, 'transactions': 127},
    {'name': 'Affaires', 'type': 'Business', 'balance': 15300000, 'transactions': 203},
  ];

  final _monthlyTransactions = [
    {'category': 'Revenus', 'amount': 8500000, 'type': 'Income', 'date': 'Aujourd\'hui'},
    {'category': 'Électricité', 'amount': -450000, 'type': 'Expense', 'date': 'Hier'},
    {'category': 'Nourriture', 'amount': -280000, 'type': 'Expense', 'date': 'Il y a 2j'},
    {'category': 'Transport', 'amount': -120000, 'type': 'Expense', 'date': 'Il y a 3j'},
    {'category': 'Bonus', 'amount': 1200000, 'type': 'Income', 'date': 'Il y a 4j'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Finances'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mes Comptes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _accounts.length,
                itemBuilder: (ctx, i) {
                  final acc = _accounts[i];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.forestGreen, AppTheme.forestGreen.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(acc['name'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        const Spacer(),
                        Text('${(acc['balance']).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} XAF', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        Text('${acc['transactions']} transactions', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            Text('Budgets ce mois', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...[
              {'category': 'Nourriture', 'budget': 800000, 'spent': 620000, 'color': AppTheme.xafGold},
              {'category': 'Transport', 'budget': 400000, 'spent': 280000, 'color': Colors.blue.shade700},
              {'category': 'Santé', 'budget': 300000, 'spent': 150000, 'color': Colors.red.shade700},
            ].map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(b['category'].toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('${(((b['spent'] as int) / (b['budget'] as int)) * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ((b['spent'] as int) / (b['budget'] as int)),
                      minHeight: 6,
                      backgroundColor: (b['color'] as Color).withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(b['color'] as Color),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${(b['spent']).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} / ${(b['budget']).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} XAF', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            )),
            const SizedBox(height: 24),

            Text('Transactions récentes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._monthlyTransactions.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: t['type'] == 'Income' ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(t['type'] == 'Income' ? Icons.arrow_downward : Icons.arrow_upward, 
                      color: t['type'] == 'Income' ? Colors.green.shade700 : Colors.red.shade700, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['category'].toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(t['date'].toString(), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  Text('${t['type'] == 'Income' ? '+' : '-'} ${((t['amount'] as int).abs()).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} XAF',
                    style: TextStyle(fontWeight: FontWeight.w600, color: t['type'] == 'Income' ? Colors.green.shade700 : Colors.red.shade700, fontSize: 13)),
                ],
              ),
            )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajouter transaction'))),
        child: const Icon(Icons.add),
      ),
    );
  }
}
