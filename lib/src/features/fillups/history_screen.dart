import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../providers.dart';
import 'fillup_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, required this.vehicleId});
  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fillUpsProvider(vehicleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Storico')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (fills) {
          final sorted = [...fills]..sort((a, b) => b.date.compareTo(a.date));
          if (sorted.isEmpty) {
            return const Center(child: Text('Nessun rifornimento.'));
          }
          return ListView(
            children: [
              for (final f in sorted)
                Dismissible(
                  key: ValueKey(f.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await ref.read(fillUpRepositoryProvider).delete(f.id);
                    ref.invalidate(fillUpsProvider(vehicleId));
                  },
                  child: ListTile(
                    title: Text('${fmtDate(f.date)} · ${fmtEuro(f.amount)}'),
                    subtitle: Text(
                      f.liters == null
                          ? '—'
                          : '${fmtLiters(f.liters!)} · ${fmtEuro(f.amount / f.liters!)}/L',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
