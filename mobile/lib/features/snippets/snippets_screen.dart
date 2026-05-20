import 'package:flutter/material.dart';

class Snippet {
  final String title;
  final String content;
  Snippet({required this.title, required this.content});
}

class SnippetsScreen extends StatefulWidget {
  const SnippetsScreen({super.key});

  @override
  State<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends State<SnippetsScreen> {
  final _snippets = [
    Snippet(title: 'Relance paiement', content: 'Bonjour, êtes-vous en mesure de nous rembourser la commande SF-2026-0001 ? Merci!'),
    Snippet(title: 'Nouveau produit', content: 'Découvrez notre nouveau produit ! Qualité garantie, prix spécial cette semaine.'),
    Snippet(title: 'Remerciement', content: 'Merci pour votre confiance ! Nous apprécions votre collaboration.'),
    Snippet(title: 'Promotion', content: 'Offre limitée : achetez 3, obtenez 1 gratuit ! Valide cette semaine seulement.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réponses Scriptées'), centerTitle: false),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _snippets.length,
        itemBuilder: (context, i) {
          final snippet = _snippets[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(snippet.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(snippet.content, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copié: "${snippet.title}"')));
                },
              ),
              onTap: () => _showDetail(context, snippet),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSnippet(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDetail(BuildContext context, Snippet snippet) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(snippet.title),
        content: Text(snippet.content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copié!')));
              Navigator.pop(context);
            },
            child: const Text('Copier'),
          ),
        ],
      ),
    );
  }

  void _addSnippet() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajout en v2')));
  }
}
