import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../widgets/brand.dart';
import '../../api/api_client.dart';
import 'deal_api.dart';

/// Formulaire de création d'un Deal — supporte les 4 types de commission.
///
/// Décisions UX :
///   - 2 choix au sommet : produit existant vs campagne libre
///   - 4 types de commission visibles d'un coup, CPA pré-sélectionné
///   - Champ unique "Montant" qui s'adapte (XAF fixe ou % du prix)
///   - Dates de validité optionnelles
class DealCreationScreen extends StatefulWidget {
  const DealCreationScreen({super.key});

  @override
  State<DealCreationScreen> createState() => _DealCreationScreenState();
}

class _DealCreationScreenState extends State<DealCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  bool _useExistingProduct = false; // true = Produit, false = Campagne libre
  String _commissionType = 'CPA';
  bool _isPercentage = false; // pour CPA on peut choisir % ou fixe
  DateTime? _activeFrom;
  DateTime? _activeTo;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _conditionsCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DealFlowBrand.cream,
      appBar: AppBar(
        backgroundColor: DealFlowBrand.green900,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: const CloseButton(),
        title: const Text(
          'Nouveau deal',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1f9d6b),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 34),
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Publier',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'Type de deal'),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeChoice(
                            icon: Icons.inventory_2_outlined,
                            label: 'Produit existant',
                            selected: _useExistingProduct,
                            onTap: () =>
                                setState(() => _useExistingProduct = true),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _TypeChoice(
                            icon: Icons.campaign_outlined,
                            label: 'Campagne libre',
                            selected: !_useExistingProduct,
                            onTap: () =>
                                setState(() => _useExistingProduct = false),
                          ),
                        ),
                      ],
                    ),
                    if (_useExistingProduct) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Sélection du produit lors de l\'étape suivante (à venir).',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'Titre & description'),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Titre du deal *',
                        hintText: 'Ex : Ciment Simon — destockage',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Titre requis' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'Type de commission'),
                    const SizedBox(height: 7),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 2.5,
                      children: [
                        _CommissionTypeChoice(
                          code: 'CPC',
                          label: 'Par clic',
                          hint: 'audience large',
                          selected: _commissionType == 'CPC',
                          onTap: () => setState(() {
                            _commissionType = 'CPC';
                            _isPercentage = false;
                          }),
                        ),
                        _CommissionTypeChoice(
                          code: 'CPS',
                          label: 'Par partage',
                          hint: 'visibilité',
                          selected: _commissionType == 'CPS',
                          onTap: () => setState(() {
                            _commissionType = 'CPS';
                            _isPercentage = false;
                          }),
                        ),
                        _CommissionTypeChoice(
                          code: 'CPA',
                          label: 'Par vente',
                          hint: 'le plus juste',
                          selected: _commissionType == 'CPA',
                          onTap: () => setState(() => _commissionType = 'CPA'),
                        ),
                        _CommissionTypeChoice(
                          code: 'CPL',
                          label: 'Par lead',
                          hint: 'contact capté',
                          selected: _commissionType == 'CPL',
                          onTap: () => setState(() {
                            _commissionType = 'CPL';
                            _isPercentage = false;
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'Montant de la commission'),
                    const SizedBox(height: 7),
                    if (_commissionType == 'CPA') ...[
                      Row(
                        children: [
                          Expanded(
                            child: _ToggleChip(
                              label: 'Montant fixe (XAF)',
                              selected: !_isPercentage,
                              onTap: () =>
                                  setState(() => _isPercentage = false),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _ToggleChip(
                              label: '% du prix de vente',
                              selected: _isPercentage,
                              onTap: () => setState(() => _isPercentage = true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _isPercentage
                            ? 'Pourcentage *'
                            : 'Montant en XAF *',
                        suffixText: _isPercentage ? '%' : 'XAF',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Valeur requise';
                        }
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n <= 0) return 'Valeur invalide';
                        if (_isPercentage && n > 100) return 'Max 100%';
                        return null;
                      },
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _explainCommission(),
                      style: TextStyle(
                          fontSize: 10.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'Conditions & validité'),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: _conditionsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Conditions pour gagner (optionnel)',
                        hintText: 'Ex : vente complétée et payée',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock disponible (optionnel)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'Début',
                            date: _activeFrom,
                            onPick: (d) => setState(() => _activeFrom = d),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DateField(
                            label: 'Fin',
                            date: _activeTo,
                            onPick: (d) => setState(() => _activeTo = d),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _explainCommission() {
    switch (_commissionType) {
      case 'CPC':
        return 'L\'affilié gagne ce montant à chaque clic unique sur son lien.';
      case 'CPS':
        return 'L\'affilié gagne ce montant à chaque partage du deal.';
      case 'CPL':
        return 'L\'affilié gagne ce montant à chaque contact capté.';
      case 'CPA':
      default:
        return _isPercentage
            ? 'L\'affilié reçoit ce pourcentage de chaque vente finalisée.'
            : 'L\'affilié gagne ce montant fixe à chaque vente finalisée.';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
    final stock = int.tryParse(_stockCtrl.text);

    try {
      final api = DealApi(context.read<ApiClient>());
      await api.create(
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        commissionType: _commissionType,
        commissionAmount:
            _isPercentage && _commissionType == 'CPA' ? null : amount,
        commissionPercent:
            _isPercentage && _commissionType == 'CPA' ? amount : null,
        conditions: _conditionsCtrl.text.trim().isEmpty
            ? null
            : _conditionsCtrl.text.trim(),
        stockAvailable: stock,
        activeFrom: _activeFrom,
        activeTo: _activeTo,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true); // signale au parent : "créé"
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}

// ─── Sous-widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
          letterSpacing: 0.6,
        ),
      );
}

class _TypeChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE1F5EE) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? DealFlowBrand.green900 : Colors.grey.shade300,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 22,
                color:
                    selected ? DealFlowBrand.green900 : Colors.grey.shade600),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    selected ? const Color(0xFF04342C) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommissionTypeChoice extends StatelessWidget {
  final String code;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _CommissionTypeChoice({
    required this.code,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE1F5EE) : Colors.white,
          border: Border.all(
            color: selected ? DealFlowBrand.green900 : Colors.grey.shade300,
            width: selected ? 1.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? DealFlowBrand.green900 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? const Color(0xFF04342C)
                          : Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: selected
                          ? const Color(0xFF0F6E56)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: DealFlowBrand.green900, size: 15),
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? DealFlowBrand.green900 : Colors.white,
          border: Border.all(
            color: selected ? DealFlowBrand.green900 : Colors.grey.shade300,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;

  const _DateField(
      {required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'fr_FR');
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: now.subtract(const Duration(days: 1)),
          lastDate: now.add(const Duration(days: 365)),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFf3f1ea),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  Text(
                    date != null ? fmt.format(date!) : 'Sélectionner',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
