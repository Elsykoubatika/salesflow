import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../widgets/brand.dart';
import '../api/api_client.dart';
import '../features/guest_cart/guest_cart_cubit.dart';
import '../features/public_catalog/public_catalog_api.dart';
import '../features/public_catalog/public_catalog_model.dart';

/// Écran de finalisation de commande pour un visiteur SANS compte.
///
/// Récolte : nom, téléphone, adresse de livraison (+ optionnel région).
/// À la validation, crée auto un compte léger côté backend et la commande.
class GuestCheckoutScreen extends StatefulWidget {
  const GuestCheckoutScreen({super.key});

  @override
  State<GuestCheckoutScreen> createState() => _GuestCheckoutScreenState();
}

class _GuestCheckoutScreenState extends State<GuestCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DealFlowBrand.cream,
      appBar: AppBar(
        backgroundColor: DealFlowBrand.green900,
        foregroundColor: Colors.white,
        title: const Text(
          'Finaliser la commande',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: BlocBuilder<GuestCartCubit, GuestCartState>(
        builder: (context, cart) {
          if (cart.isEmpty) {
            return const Center(
              child: Text('Votre panier est vide'),
            );
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CartSummary(cart: cart),
                        Container(
                          color: Colors.white,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Vos coordonnées',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Un compte sera créé automatiquement pour suivre votre commande.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Nom complet *',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Nom requis'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Téléphone *',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                  hintText: '+242 06 123 45 67',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Téléphone requis';
                                  }
                                  final digits =
                                      v.replaceAll(RegExp(r'\D'), '');
                                  if (digits.length < 9) {
                                    return 'Numéro trop court';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _addressCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Adresse de livraison *',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                  hintText: 'Quartier, rue, repère…',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Adresse requise'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _regionCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Ville (optionnel)',
                                  prefixIcon: Icon(Icons.map_outlined),
                                  hintText: 'Brazzaville, Pointe-Noire…',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _CheckoutBar(
                total: cart.total,
                currency: cart.currency,
                submitting: _submitting,
                onSubmit: () => _submit(cart),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(GuestCartState cart) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      final api = PublicCatalogApi(context.read<ApiClient>());
      final result = await api.placeGuestOrder(
        fullName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        deliveryAddress: _addressCtrl.text.trim(),
        region: _regionCtrl.text.trim().isEmpty
            ? null
            : _regionCtrl.text.trim(),
        items: cart.items
            .map((i) => (productId: i.product.id, quantity: i.quantity))
            .toList(),
      );
      if (!mounted) return;
      context.read<GuestCartCubit>().clear();
      _showSuccessDialog(result);
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

  void _showSuccessDialog(GuestOrderResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: DealFlowBrand.green500.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: DealFlowBrand.green700),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Commande confirmée')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Numéro de commande',
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            Text(
              result.orderCode,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: DealFlowBrand.green900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              result.message,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: DealFlowBrand.green900),
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pop(); // checkout → retour catalogue
            },
            child: const Text('Retour au catalogue'),
          ),
        ],
      ),
    );
  }
}

// ─── Résumé du panier ────────────────────────────────────────────────────────
class _CartSummary extends StatelessWidget {
  final GuestCartState cart;
  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mon panier',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                '${cart.itemCount} article${cart.itemCount > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.product.sellerName,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _QuantityStepper(item: item),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: Text(
                      _formatMoney(item.subtotal, item.product.currency),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final GuestCartItem item;
  const _QuantityStepper({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () =>
                context.read<GuestCartCubit>().decrement(item.product.id),
            child: const SizedBox(
              width: 28,
              height: 28,
              child: Icon(Icons.remove, size: 14),
            ),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          InkWell(
            onTap: () =>
                context.read<GuestCartCubit>().increment(item.product.id),
            child: const SizedBox(
              width: 28,
              height: 28,
              child: Icon(Icons.add, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final double total;
  final String currency;
  final bool submitting;
  final VoidCallback onSubmit;

  const _CheckoutBar({
    required this.total,
    required this.currency,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total à payer',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatMoney(total, currency),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: DealFlowBrand.green900,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: DealFlowBrand.green900,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: submitting ? null : onSubmit,
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Confirmer',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatMoney(double v, String currency) {
  final f = NumberFormat.decimalPattern('fr_FR');
  return '${f.format(v.round())} $currency';
}
