import 'package:flutter/material.dart';

import '../../../models/table_model.dart';

/// Step 2: Descrizione semantica delle tabelle
class TableDescriptionStep extends StatefulWidget {
  final List<TableModel> tables;
  final ValueChanged<TableModel> onTableUpdated;

  const TableDescriptionStep({
    super.key,
    required this.tables,
    required this.onTableUpdated,
  });

  @override
  State<TableDescriptionStep> createState() => _TableDescriptionStepState();
}

class _TableDescriptionStepState extends State<TableDescriptionStep> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    for (final table in widget.tables) {
      _controllers[table.name] = TextEditingController(text: table.description);
      _focusNodes[table.name] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _updateDescription(TableModel table, String description) {
    final updatedTable = table.copyWith(description: description);
    widget.onTableUpdated(updatedTable);
  }

  String _generateSuggestion(TableModel table) {
    // Genera un suggerimento basato sul nome della tabella
    final name = table.name.toLowerCase();
    
    if (name.contains('user') || name.contains('utent')) {
      return 'Tabella che contiene i dati degli utenti registrati nel sistema';
    } else if (name.contains('order') || name.contains('ordin')) {
      return 'Tabella che contiene gli ordini effettuati dai clienti';
    } else if (name.contains('product') || name.contains('prodott')) {
      return 'Tabella che contiene il catalogo dei prodotti disponibili';
    } else if (name.contains('customer') || name.contains('client')) {
      return 'Tabella che contiene i dati anagrafici dei clienti';
    } else if (name.contains('invoice') || name.contains('fattur')) {
      return 'Tabella che contiene le fatture emesse';
    } else if (name.contains('payment') || name.contains('pagament')) {
      return 'Tabella che contiene i pagamenti ricevuti';
    } else if (name.contains('categor')) {
      return 'Tabella che contiene le categorie per la classificazione';
    } else if (name.contains('log')) {
      return 'Tabella di log che traccia le attività del sistema';
    } else if (name.contains('config') || name.contains('setting')) {
      return 'Tabella che contiene le configurazioni del sistema';
    }
    
    return 'Tabella ${table.name} che contiene ${table.columns.length} colonne';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Intestazione
          Text(
            'Descrivi le tabelle selezionate',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi una descrizione semantica per ogni tabella. '
            'Questo aiuterà l\'AI a comprendere meglio il contesto dei tuoi dati.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Lista tabelle con descrizioni
          Expanded(
            child: ListView.builder(
              itemCount: widget.tables.length,
              itemBuilder: (context, index) {
                final table = widget.tables[index];
                final controller = _controllers[table.name]!;
                final focusNode = _focusNodes[table.name]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header tabella
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.table_chart,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    table.name,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${table.columns.length} colonne',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            // Pulsante suggerimento
                            TextButton.icon(
                              onPressed: () {
                                final suggestion = _generateSuggestion(table);
                                controller.text = suggestion;
                                _updateDescription(table, suggestion);
                              },
                              icon: const Icon(Icons.auto_fix_high, size: 18),
                              label: const Text('Suggerisci'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Campo descrizione
                        TextField(
                          controller: controller,
                          focusNode: focusNode,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Descrizione',
                            hintText:
                                'Descrivi cosa rappresenta questa tabella...',
                            helperText:
                                'Es: Tabella che contiene i dati degli ordini con data, importo e stato',
                            border: const OutlineInputBorder(),
                            suffixIcon: controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.check_circle),
                                    color: Colors.green,
                                    onPressed: null,
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            _updateDescription(table, value);
                            setState(() {}); // Refresh per mostrare l'icona check
                          },
                        ),
                        const SizedBox(height: 12),

                        // Preview colonne
                        ExpansionTile(
                          title: const Text('Anteprima colonne'),
                          tilePadding: EdgeInsets.zero,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: table.columns.map((col) {
                                return Chip(
                                  avatar: Icon(
                                    _getColumnIcon(col.dataType),
                                    size: 16,
                                  ),
                                  label: Text(
                                    '${col.name} (${col.dataType})',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
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

  IconData _getColumnIcon(String dataType) {
    final type = dataType.toLowerCase();
    if (type.contains('int') || type.contains('decimal') || type.contains('float')) {
      return Icons.numbers;
    } else if (type.contains('varchar') || type.contains('text') || type.contains('char')) {
      return Icons.text_fields;
    } else if (type.contains('date') || type.contains('time')) {
      return Icons.calendar_today;
    } else if (type.contains('bool')) {
      return Icons.toggle_on;
    } else if (type.contains('blob') || type.contains('binary')) {
      return Icons.attachment;
    }
    return Icons.data_object;
  }
}
