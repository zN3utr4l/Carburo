import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/fill_up.dart';
import '../../providers.dart';
import '../dashboard/dashboard_providers.dart';
import '../expenses/expense_form_screen.dart';
import '../expenses/expense_providers.dart';
import '../fillups/fill_up_form_screen.dart';
import '../fillups/fillup_providers.dart';
import '../vehicles/widgets/empty_vehicle_prompt.dart';

enum _Filter { all, fuel, expense }

class MovimentiScreen extends ConsumerStatefulWidget {
  const MovimentiScreen({super.key});

  @override
  ConsumerState<MovimentiScreen> createState() => _MovimentiScreenState();
}

class _MovimentiScreenState extends ConsumerState<MovimentiScreen> {
  _Filter _filter = _Filter.all;
  final _query = TextEditingController();

  /// Multi-select state. Keys are `'f:<id>'` (fill-up) or `'e:<id>'` (expense).
  bool _selecting = false;
  final Set<String> _selected = {};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _exitSelection() => setState(() {
    _selecting = false;
    _selected.clear();
  });

  void _toggle(_Row r) => setState(() {
    if (!_selected.remove(r.key)) _selected.add(r.key);
    if (_selected.isEmpty) _selecting = false;
  });

  void _enterSelection(_Row r) => setState(() {
    _selecting = true;
    _selected.add(r.key);
  });

  Future<void> _confirmDelete({
    required String title,
    required Future<void> Function() delete,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text('Operazione non reversibile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await delete();
  }

  Future<void> _deleteSelected(int vehicleId) async {
    final fuelIds = <int>[];
    final expenseIds = <int>[];
    for (final key in _selected) {
      final id = int.parse(key.substring(2));
      (key.startsWith('f:') ? fuelIds : expenseIds).add(id);
    }
    final count = fuelIds.length + expenseIds.length;
    if (count == 0) return;

    final messenger = ScaffoldMessenger.of(context);
    await _confirmDelete(
      title: count == 1
          ? 'Eliminare il movimento selezionato?'
          : 'Eliminare $count movimenti selezionati?',
      delete: () async {
        await ref.read(fillUpRepositoryProvider).deleteMany(fuelIds);
        await ref.read(expenseRepositoryProvider).deleteMany(expenseIds);
        ref.invalidate(fillUpsProvider(vehicleId));
        ref.invalidate(expensesForVehicleProvider(vehicleId));
        if (!mounted) return;
        setState(() {
          _selecting = false;
          _selected.clear();
        });
        messenger.showSnackBar(
          SnackBar(content: Text('$count movimenti eliminati')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleAsync = ref.watch(dashboardVehicleProvider);
    return vehicleAsync.when(
      loading: () => _scaffold(body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => _scaffold(body: Center(child: Text('Errore: $e'))),
      data: (vehicle) {
        if (vehicle == null) {
          return _scaffold(body: const EmptyVehiclePrompt());
        }
        final fills = ref.watch(fillUpsProvider(vehicle.id));
        final expenses = ref.watch(expensesForVehicleProvider(vehicle.id));
        final cats = ref.watch(allCategoriesProvider);
        final filtered = _filteredRows(
          vehicle.id,
          fills.asData?.value ?? const [],
          expenses.asData?.value ?? const [],
          {for (final c in cats.asData?.value ?? const []) c.id: c.name},
        );
        return _scaffold(
          vehicleId: vehicle.id,
          filtered: filtered,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    SegmentedButton<_Filter>(
                      segments: const [
                        ButtonSegment(value: _Filter.all, label: Text('Tutti')),
                        ButtonSegment(
                          value: _Filter.fuel,
                          label: Text('Carburante'),
                        ),
                        ButtonSegment(
                          value: _Filter.expense,
                          label: Text('Spese'),
                        ),
                      ],
                      selected: {_filter},
                      // Switching the type filter changes what "all" means, so
                      // clear any selection to avoid deleting now-hidden rows.
                      onSelectionChanged: (s) => setState(() {
                        _filter = s.first;
                        _selecting = false;
                        _selected.clear();
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _query,
                      decoration: const InputDecoration(
                        labelText: 'Cerca',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: (fills.isLoading || expenses.isLoading)
                    ? const Center(child: CircularProgressIndicator())
                    : _listView(filtered),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the screen scaffold; the app bar becomes a contextual selection bar
  /// while [_selecting]. [vehicleId]/[filtered] are only needed in that mode.
  Widget _scaffold({required Widget body, int? vehicleId, List<_Row> filtered = const []}) {
    final allSelected =
        filtered.isNotEmpty && filtered.every((r) => _selected.contains(r.key));
    return Scaffold(
      appBar: _selecting
          ? AppBar(
              leading: IconButton(
                tooltip: 'Annulla selezione',
                icon: const Icon(Icons.close),
                onPressed: _exitSelection,
              ),
              title: Text('${_selected.length} selezionati'),
              actions: [
                IconButton(
                  tooltip: allSelected ? 'Deseleziona tutto' : 'Seleziona tutto',
                  icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
                  onPressed: filtered.isEmpty
                      ? null
                      : () => setState(() {
                          if (allSelected) {
                            _selected.clear();
                            _selecting = false;
                          } else {
                            _selected
                              ..clear()
                              ..addAll(filtered.map((r) => r.key));
                          }
                        }),
                ),
                IconButton(
                  tooltip: 'Elimina selezionati',
                  icon: const Icon(Icons.delete),
                  onPressed: (_selected.isEmpty || vehicleId == null)
                      ? null
                      : () => _deleteSelected(vehicleId),
                ),
              ],
            )
          : AppBar(title: const Text('Movimenti')),
      body: body,
    );
  }

  List<_Row> _filteredRows(
    int vehicleId,
    List<FillUp> fills,
    List<Expense> expenses,
    Map<int, String> catName,
  ) {
    final rows = <_Row>[
      if (_filter != _Filter.expense)
        for (final f in fills)
          _Row(
            isFuel: true,
            id: f.id,
            date: f.date,
            icon: Icons.local_gas_station,
            color: Colors.teal,
            title: 'Rifornimento',
            subtitle: f.liters == null ? null : fmtLiters(f.liters!),
            amount: f.amount,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    FillUpFormScreen(vehicleId: vehicleId, initial: f),
              ),
            ),
            onDelete: () => _confirmDelete(
              title: 'Eliminare il rifornimento?',
              delete: () async {
                await ref.read(fillUpRepositoryProvider).delete(f.id);
                ref.invalidate(fillUpsProvider(vehicleId));
              },
            ),
          ),
      if (_filter != _Filter.fuel)
        for (final e in expenses)
          _Row(
            isFuel: false,
            id: e.id,
            date: e.date,
            icon: Icons.payments,
            color: Colors.amber.shade800,
            title: catName[e.categoryId] ?? 'Spesa',
            subtitle: e.description,
            amount: e.amount,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ExpenseFormScreen(vehicleId: vehicleId, initial: e),
              ),
            ),
            onDelete: () => _confirmDelete(
              title: 'Eliminare la spesa?',
              delete: () async {
                await ref.read(expenseRepositoryProvider).delete(e.id);
                ref.invalidate(expensesForVehicleProvider(vehicleId));
              },
            ),
          ),
    ]..sort((a, b) => b.date.compareTo(a.date));
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where(
          (r) =>
              r.title.toLowerCase().contains(q) ||
              (r.subtitle?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  Widget _listView(List<_Row> filtered) {
    if (filtered.isEmpty) {
      return const Center(child: Text('Nessun movimento.'));
    }
    return ListView(
      children: [
        for (final r in filtered)
          _movimentoTile(r),
      ],
    );
  }

  Widget _movimentoTile(_Row r) {
    final selected = _selected.contains(r.key);
    return ListTile(
      selected: selected,
      leading: _selecting
          ? Checkbox(value: selected, onChanged: (_) => _toggle(r))
          : Icon(r.icon, color: r.color),
      title: Text(r.title),
      subtitle: Text(
        [
          fmtDate(r.date),
          if (r.subtitle != null) r.subtitle!,
        ].join(' · '),
      ),
      trailing: _selecting
          ? Text(
              fmtEuro(r.amount),
              style: Theme.of(context).textTheme.titleMedium,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fmtEuro(r.amount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  tooltip: 'Elimina',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: r.onDelete,
                ),
              ],
            ),
      onTap: _selecting ? () => _toggle(r) : r.onTap,
      onLongPress: _selecting ? null : () => _enterSelection(r),
    );
  }
}

class _Row {
  _Row({
    required this.isFuel,
    required this.id,
    required this.date,
    required this.icon,
    required this.color,
    required this.title,
    required this.amount,
    required this.onTap,
    required this.onDelete,
    this.subtitle,
  });
  final bool isFuel;
  final int id;
  final DateTime date;
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final double amount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String get key => '${isFuel ? 'f' : 'e'}:$id';
}
