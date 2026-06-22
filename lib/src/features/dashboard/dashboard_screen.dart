import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import 'dashboard_providers.dart';
import 'widgets/stat_card.dart';
import '../fillups/fill_up_form_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(dashboardVehicleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tanko')),
      body: vehicleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (vehicle) {
          if (vehicle == null) {
            return const Center(child: Text('Aggiungi un veicolo per iniziare.'));
          }
          final statsAsync = ref.watch(vehicleStatsProvider(vehicle.id));
          return statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Errore: $e')),
            data: (s) => GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(12),
              childAspectRatio: 1.6,
              children: [
                StatCard(label: 'Spesa totale', value: fmtEuro(s.totalSpend)),
                StatCard(
                  label: 'Prezzo medio',
                  value: s.avgPricePerLiter == null
                      ? '—'
                      : '${fmtEuro(s.avgPricePerLiter!)}/L',
                ),
                StatCard(
                  label: 'Consumo medio',
                  value: s.avgConsumption == null
                      ? '—'
                      : fmtConsumption(s.avgConsumption!),
                ),
                StatCard(label: 'Km totali', value: fmtKm(s.totalKm)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: vehicleAsync.maybeWhen(
        data: (v) => v == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FillUpFormScreen(vehicleId: v.id),
                  ),
                ),
                icon: const Icon(Icons.local_gas_station),
                label: const Text('Rifornimento'),
              ),
        orElse: () => null,
      ),
    );
  }
}
