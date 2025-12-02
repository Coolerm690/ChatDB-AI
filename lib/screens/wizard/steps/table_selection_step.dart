import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/table_model.dart';
import '../../../providers/schema_provider.dart';

/// Step 1: Selezione delle tabelle da modellare
class TableSelectionStep extends ConsumerStatefulWidget {
  final List<TableModel> selectedTables;
  final ValueChanged<List<TableModel>> onTablesChanged;

  const TableSelectionStep({
    super.key,
    required this.selectedTables,
    required this.onTablesChanged,
  });

  @override
  ConsumerState<TableSelectionStep> createState() => _TableSelectionStepState();
}

class _TableSelectionStepState extends ConsumerState<TableSelectionStep> {
  String _searchQuery = '';
  Set<String> _selectedTableNames = {};

  @override
  void initState() {
    super.initState();
    _selectedTableNames = widget.selectedTables.map((t) => t.name).toSet();
  }

  void _toggleTable(TableModel table) {
    setState(() {
      if (_selectedTableNames.contains(table.name)) {
        _selectedTableNames.remove(table.name);
      } else {
        _selectedTableNames.add(table.name);
      }
    });

    // Aggiorna la lista delle tabelle selezionate
    final allTables = ref.read(schemaProvider).tables;
    final selected = allTables
        .where((t) => _selectedTableNames.contains(t.name))
        .toList();
    widget.onTablesChanged(selected);
  }

  void _selectAll(List<TableModel> tables) {
    setState(() {
      _selectedTableNames = tables.map((t) => t.name).toSet();
    });
    widget.onTablesChanged(tables);
  }

  void _deselectAll() {
    setState(() {
      _selectedTableNames.clear();
    });
    widget.onTablesChanged([]);
  }

  @override
  Widget build(BuildContext context) {
    final schemaState = ref.watch(schemaProvider);
    final theme = Theme.of(context);

    // Filtra le tabelle in base alla ricerca
    final filteredTables = schemaState.tables.where((table) {
      return table.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Intestazione
          Text(
            'Seleziona le tabelle da modellare',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Scegli le tabelle che vuoi rendere disponibili per le query in linguaggio naturale',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Barra di ricerca e azioni
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cerca tabelle...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => _selectAll(filteredTables),
                child: const Text('Seleziona tutto'),
              ),
              TextButton(
                onPressed: _deselectAll,
                child: const Text('Deseleziona tutto'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contatore
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_selectedTableNames.length} tabelle selezionate su ${schemaState.tables.length}',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 16),

          // Lista tabelle
          Expanded(
            child: schemaState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : schemaState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Errore caricamento schema',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(schemaState.error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(schemaProvider.notifier).loadSchema();
                              },
                              child: const Text('Riprova'),
                            ),
                          ],
                        ),
                      )
                    : filteredTables.isEmpty
                        ? const Center(
                            child: Text('Nessuna tabella trovata'),
                          )
                        : ListView.builder(
                            itemCount: filteredTables.length,
                            itemBuilder: (context, index) {
                              final table = filteredTables[index];
                              final isSelected =
                                  _selectedTableNames.contains(table.name);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (_) => _toggleTable(table),
                                  title: Text(
                                    table.name,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${table.columns.length} colonne',
                                  ),
                                  secondary: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.table_chart,
                                      color: theme.colorScheme.onSecondaryContainer,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
