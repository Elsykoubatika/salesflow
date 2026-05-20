import 'package:flutter/material.dart';
import '../../theme.dart';

class _Invoice {
  final String number;
  final String client;
  final String date;
  final String dueDate;
  final double hours;
  final int hourlyRate;
  final int materials;
  final int advance;
  final int total;
  final int paid;
  final String status;
  final int daysOverdue;
  final String paymentMethod;
  final String mobileRef;

  const _Invoice({
    required this.number,
    required this.client,
    required this.date,
    required this.dueDate,
    required this.hours,
    required this.hourlyRate,
    required this.materials,
    required this.advance,
    required this.total,
    required this.paid,
    required this.status,
    required this.daysOverdue,
    required this.paymentMethod,
    required this.mobileRef,
  });
}

class TechnicalInvoiceScreen extends StatefulWidget {
  const TechnicalInvoiceScreen({super.key});

  @override
  State<TechnicalInvoiceScreen> createState() => _TechnicalInvoiceScreenState();
}

class _TechnicalInvoiceScreenState extends State<TechnicalInvoiceScreen> {
  static const List<_Invoice> _invoices = [
    _Invoice(
      number: 'FT-2024-001',
      client: 'ECAB Sarl',
      date: '15/05/2024',
      dueDate: '20/06/2024',
      hours: 8.5,
      hourlyRate: 35000,
      materials: 145000,
      advance: 50000,
      total: 295500,
      paid: 0,
      status: 'Overdue',
      daysOverdue: 12,
      paymentMethod: 'MobileMoney',
      mobileRef: 'MTN-2024-001',
    ),
    _Invoice(
      number: 'FT-2024-002',
      client: 'Impact Group',
      date: '12/05/2024',
      dueDate: '10/06/2024',
      hours: 5.0,
      hourlyRate: 40000,
      materials: 75000,
      advance: 100000,
      total: 275000,
      paid: 175000,
      status: 'PartiallyPaid',
      daysOverdue: 0,
      paymentMethod: 'MobileMoney',
      mobileRef: 'AIRTEL-2024-003',
    ),
    _Invoice(
      number: 'FT-2024-003',
      client: 'TradeHub Congo',
      date: '18/05/2024',
      dueDate: '18/06/2024',
      hours: 12.0,
      hourlyRate: 30000,
      materials: 250000,
      advance: 200000,
      total: 610000,
      paid: 610000,
      status: 'Paid',
      daysOverdue: 0,
      paymentMethod: 'Bank',
      mobileRef: 'BANK-2024-005',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdueCount = _invoices.where((inv) => inv.status == 'Overdue').length;
    final totalFacture = _invoices.fold<int>(0, (sum, inv) => sum + inv.total);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factures Techniques'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Total facturé',
                    value: '${totalFacture ~/ 1000}k',
                    color: AppTheme.forestGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Impayés',
                    value: overdueCount.toString(),
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Factures (${_invoices.length})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._invoices.map((inv) => _InvoiceCard(invoice: inv)),
          ],
        ),
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
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final _Invoice invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(invoice.status);
    final remaining = invoice.total - invoice.paid;
    final laborCost = (invoice.hours * invoice.hourlyRate).toInt();
    final subtotal = laborCost + invoice.materials;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.number,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    invoice.client,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                invoice.status == 'Overdue' ? 'EN RETARD' : invoice.status,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${invoice.total ~/ 1000}k XAF',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: statusColor,
            fontSize: 13,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BreakdownRow(
                  'Durée',
                  '${invoice.hours} h @ ${invoice.hourlyRate ~/ 1000}k/h',
                  laborCost,
                ),
                _BreakdownRow('Matériaux', '', invoice.materials),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppTheme.textMuted, height: 1),
                ),
                _BreakdownRow('Sous-total', '', subtotal),
                _BreakdownRow(
                  'Acompte',
                  '- ${invoice.advance} XAF',
                  -invoice.advance,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL DÛ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${invoice.total ~/ 1000}k XAF',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Payment progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Paiement',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${invoice.paid * 100 ~/ invoice.total}% complété',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: invoice.paid.toDouble() / invoice.total,
                        minHeight: 8,
                        backgroundColor:
                            AppTheme.forestGreen.withValues(alpha: 0.2),
                        color: AppTheme.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payé: ${invoice.paid ~/ 1000}k',
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          'Restant: ${remaining ~/ 1000}k',
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Overdue reminder
                if (invoice.status == 'Overdue')
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'EN RETARD depuis ${invoice.daysOverdue} jours',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rappel envoyé via Email',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Payment method
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.forestGreen.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Méthode paiement',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        invoice.paymentMethod,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (invoice.paymentMethod == 'MobileMoney') ...[
                        const SizedBox(height: 4),
                        Text(
                          'Réf: ${invoice.mobileRef}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(
                              const SnackBar(content: Text('PDF généré')),
                            ),
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                        label: const Text('PDF'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(
                              const SnackBar(
                                content: Text('Marquer comme payée'),
                              ),
                            ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Paiement'),
                      ),
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

  Color _getStatusColor(String status) => switch (status) {
        'Paid' => Colors.green.shade700,
        'PartiallyPaid' => Colors.amber.shade700,
        'Overdue' => Colors.red.shade700,
        _ => AppTheme.textMuted,
      };
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String detail;
  final int amount;

  const _BreakdownRow(this.label, this.detail, this.amount);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              if (detail.isNotEmpty)
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
            ],
          ),
          Text(
            '${amount ~/ 1000}k XAF',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
