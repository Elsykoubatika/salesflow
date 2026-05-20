import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../catalog/format_money.dart';
import 'proof_detail_screen.dart';
import 'proof_model.dart';
import 'proof_status_visual.dart';
import 'proof_upload_screen.dart';
import 'proofs_cubit.dart';

class ProofsListScreen extends StatelessWidget {
  const ProofsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProofsCubit()..load(),
      child: const _ProofsListView(),
    );
  }
}

class _ProofsListView extends StatelessWidget {
  const _ProofsListView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffre-Fort'),
      ),
      body: BlocBuilder<ProofsCubit, ProofsState>(
        builder: (context, state) {
          if (state is ProofsInitial || state is ProofsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProofsError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<ProofsCubit>().load(),
            );
          }

          final loaded = state as ProofsLoaded;
          return RefreshIndicator(
            onRefresh: () => context.read<ProofsCubit>().refresh(),
            child: CustomScrollView(
              slivers: [
                if (loaded.pendingCount > 0)
                  SliverToBoxAdapter(child: _PendingBanner(count: loaded.pendingCount)),
                SliverToBoxAdapter(
                  child: _FilterChips(activeFilter: loaded.statusFilter),
                ),
                if (loaded.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyView(theme: theme, hasFilter: loaded.statusFilter != null),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    sliver: SliverList.separated(
                      itemCount: loaded.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ProofCard(proof: loaded.items[i]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _AddFab(),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final int count;
  const _PendingBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count preuve${count > 1 ? 's' : ''} en attente de validation',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => context.read<ProofsCubit>().changeFilter(ProofStatus.pending),
            child: const Text('Voir'),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final ProofStatus? activeFilter;
  const _FilterChips({this.activeFilter});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _chip(context, label: 'Toutes', selected: activeFilter == null, status: null),
          const SizedBox(width: 8),
          _chip(context, label: 'En attente', selected: activeFilter == ProofStatus.pending, status: ProofStatus.pending),
          const SizedBox(width: 8),
          _chip(context, label: 'Validées', selected: activeFilter == ProofStatus.validated, status: ProofStatus.validated),
          const SizedBox(width: 8),
          _chip(context, label: 'Erreurs', selected: activeFilter == ProofStatus.error, status: ProofStatus.error),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, {required String label, required bool selected, required ProofStatus? status}) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => context.read<ProofsCubit>().changeFilter(status),
    );
  }
}

class _ProofCard extends StatelessWidget {
  final Proof proof;
  const _ProofCard({required this.proof});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ProofStatusVisual.color(proof.status, theme.colorScheme);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => ProofDetailScreen(proofId: proof.id)),
          );
          if (result == true && context.mounted) {
            context.read<ProofsCubit>().refresh();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Vignette : icône avec bordure colorée par statut
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                ),
                child: Icon(Icons.receipt_long, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            proof.amount != null
                                ? formatMoney(proof.amount!, proof.currency)
                                : 'Montant non renseigné',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ProofStatusBadge(status: proof.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        OperatorChip(operator: proof.operator),
                        if (proof.transactionReference != null) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              proof.transactionReference!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          dateFmt.format(proof.transactionDate ?? proof.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        if (proof.orderNumber != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.link, size: 12, color: theme.colorScheme.primary),
                          const SizedBox(width: 2),
                          Text(
                            proof.orderNumber!,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showSourceSheet(context),
      icon: const Icon(Icons.add_a_photo),
      label: const Text('Ajouter'),
    );
  }

  Future<void> _showSourceSheet(BuildContext context) async {
    final cubit = context.read<ProofsCubit>();

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Source de l\'image', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _pickAndUpload(context, cubit, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _pickAndUpload(context, cubit, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, ProofsCubit cubit, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        imageQuality: 85, // Compression légère pour rester sous 5 MB
        maxWidth: 2400,
      );
      if (file == null || !context.mounted) return;

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => ProofUploadScreen(imagePath: file.path)),
      );

      if (result == true) cubit.refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur image : $e')),
        );
      }
    }
  }
}

class _EmptyView extends StatelessWidget {
  final ThemeData theme;
  final bool hasFilter;
  const _EmptyView({required this.theme, required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'Aucune preuve dans ce filtre' : 'Aucune preuve',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Changez le filtre ou ajoutez une nouvelle preuve.'
                  : 'Photographiez vos SMS de paiement Mobile Money\npour les archiver en sécurité.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
