import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../api/api_client.dart';
import '../features/deals/deal_api.dart';
import '../features/deals/deal_cubit.dart';
import '../features/deals/deals_list_screen.dart';

/// Onglet « Deals » du shell principal — version Lot 3.
///
/// Injecte le DealCubit dans le contexte et délègue l'affichage à
/// DealsListScreen qui gère les 3 onglets internes.
class DealsTabScreen extends StatelessWidget {
  const DealsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DealCubit(DealApi(context.read<ApiClient>())),
      child: const DealsListScreen(),
    );
  }
}
