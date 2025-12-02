import 'package:flutter/material.dart';

import '../../../models/table_model.dart';
import '../../../models/column_model.dart';

/// Step 3: Descrizione semantica delle colonne
class ColumnDescriptionStep extends StatefulWidget {
  final TableModel table;
  final ValueChanged<TableModel> onTableUpdated;

  const ColumnDescriptionStep({
    super.key,
    required this.table,
    required this.onTableUpdated,
  });

  @override
  State<ColumnDescriptionStep> createState() => _ColumnDescriptionStepState();
}

class _ColumnDescriptionStepState extends State<ColumnDescriptionStep> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _isSensitive = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (final column in widget.table.columns) {
      _controllers[column.name] =
          TextEditingController(text: column.description);
      _isSensitive[column.name] = column.isSensitive;
    }
  }

  @override
  void didUpdateWidget(ColumnDescriptionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.table.name != widget.table.name) {
      // Pulisci i controller precedenti
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
      _isSensitive.clear();
      _initControllers();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateColumn(ColumnModel column, {String? description, bool? sensitive}) {
    final updatedColumn = column.copyWith(
      description: description ?? column.description,
      isSensitive: sensitive ?? column.isSensitive,
    );

    final updatedColumns = widget.table.columns.map((c) {
      return c.name == column.name ? updatedColumn : c;
    }).toList();

    final updatedTable = widget.table.copyWith(columns: updatedColumns);
    widget.onTableUpdated(updatedTable);
  }

  void _autoDescribeAll() {
    final updatedColumns = widget.table.columns.map((column) {
      final suggestion = _generateColumnSuggestion(column);
      _controllers[column.name]?.text = suggestion;
      return column.copyWith(description: suggestion);
    }).toList();

    final updatedTable = widget.table.copyWith(columns: updatedColumns);
    widget.onTableUpdated(updatedTable);
    setState(() {});
  }

  String _generateColumnSuggestion(ColumnModel column) {
    final name = column.name.toLowerCase();
    final type = column.dataType.toLowerCase();

    // Pattern comuni
    if (name == 'id' || name.endsWith('_id')) {
      return 'Identificativo univoco${name.endsWith('_id') ? ' di riferimento' : ''}';
    }
    if (name.contains('email')) {
      return 'Indirizzo email';
    }
    if (name.contains('phone') || name.contains('telefon')) {
      return 'Numero di telefono';
    }
    if (name.contains('name') || name.contains('nome')) {
      return 'Nome';
    }
    if (name.contains('surname') || name.contains('cognome')) {
      return 'Cognome';
    }
    if (name.contains('address') || name.contains('indirizzo')) {
      return 'Indirizzo';
    }
    if (name.contains('city') || name.contains('citta')) {
      return 'Città';
    }
    if (name.contains('country') || name.contains('paese')) {
      return 'Paese';
    }
    if (name.contains('zip') || name.contains('cap')) {
      return 'Codice postale';
    }
    if (name.contains('price') || name.contains('prezzo')) {
      return 'Prezzo';
    }
    if (name.contains('quantity') || name.contains('quantit')) {
      return 'Quantità';
    }
    if (name.contains('total') || name.contains('totale')) {
      return 'Totale';
    }
    if (name.contains('date') || name.contains('data')) {
      return 'Data';
    }
    if (name.contains('created') || name.contains('creat')) {
      return 'Data di creazione';
    }
    if (name.contains('updated') || name.contains('modificat')) {
      return 'Data di modifica';
    }
    if (name.contains('status') || name.contains('stato')) {
      return 'Stato';
    }
    if (name.contains('active') || name.contains('attivo')) {
      return 'Flag attivo/disattivo';
    }
    if (name.contains('description') || name.contains('descrizion')) {
      return 'Descrizione';
    }
    if (name.contains('note') || name.contains('notes')) {
      return 'Note aggiuntive';
    }
    if (name.contains('password')) {
      return 'Password (dato sensibile)';
    }

    // Suggerimento basato sul tipo
    if (type.contains('int')) {
      return 'Valore numerico intero';
    }
    if (type.contains('decimal') || type.contains('float') || type.contains('double')) {
      return 'Valore numerico decimale';
    }
    if (type.contains('varchar') || type.contains('text')) {
      return 'Campo testuale';
    }
    if (type.contains('date')) {
      return 'Data';
    }
    if (type.contains('time')) {
      return 'Orario';
    }
    if (type.contains('bool')) {
      return 'Valore booleano (sì/no)';
    }

    return 'Colonna ${column.name}';
  }

  bool _detectSensitiveColumn(ColumnModel column) {
    final name = column.name.toLowerCase();
    final sensitivePatterns = [
      'password',
      'pwd',
      'secret',
      'token',
      'api_key',
      'apikey',
      'ssn',
      'social_security',
      'credit_card',
      'card_number',
      'cvv',
      'pin',
      'fiscal_code',
      'codice_fiscale',
      'cf',
    ];

    return sensitivePatterns.any((pattern) => name.contains(pattern));
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descrivi le colonne di "${widget.table.name}"',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aggiungi descrizioni e marca le colonne sensibili che devono essere mascherate',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _autoDescribeAll,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Auto-descrivi tutto'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lista colonne
          Expanded(
            child: ListView.builder(
              itemCount: widget.table.columns.length,
              itemBuilder: (context, index) {
                final column = widget.table.columns[index];
                final controller = _controllers[column.name]!;
                final isSensitive = _isSensitive[column.name] ?? false;
                final isAutoDetectedSensitive = _detectSensitiveColumn(column);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isSensitive
                      ? theme.colorScheme.errorContainer.withOpacity(0.3)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header colonna
                        Row(
                          children: [
                            Icon(
                              _getColumnIcon(column.dataType),
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    column.name,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          column.dataType,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (column.isPrimaryKey)
                                        const _ColumnBadge(
                                          icon: Icons.key,
                                          label: 'PK',
                                          color: Colors.amber,
                                        ),
                                      if (column.isForeignKey)
                                        const _ColumnBadge(
                                          icon: Icons.link,
                                          label: 'FK',
                                          color: Colors.blue,
                                        ),
                                      if (!column.isNullable)
                                        const _ColumnBadge(
                                          icon: Icons.warning_amber,
                                          label: 'NOT NULL',
                                          color: Colors.orange,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Switch dato sensibile
                            Column(
                              children: [
                                Switch(
                                  value: isSensitive,
                                  onChanged: (value) {
                                    setState(() {
                                      _isSensitive[column.name] = value;
                                    });
                                    _updateColumn(column, sensitive: value);
                                  },
                                ),
                                Text(
                                  'Sensibile',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Avviso auto-detected
                        if (isAutoDetectedSensitive && !isSensitive)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Questa colonna potrebbe contenere dati sensibili',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isSensitive[column.name] = true;
                                    });
                                    _updateColumn(column, sensitive: true);
                                  },
                                  child: const Text('Marca come sensibile'),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Campo descrizione
                        TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Descrizione',
                            hintText: 'Descrivi questa colonna...',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.auto_fix_high, size: 18),
                              onPressed: () {
                                final suggestion =
                                    _generateColumnSuggestion(column);
                                controller.text = suggestion;
                                _updateColumn(column, description: suggestion);
                              },
                              tooltip: 'Suggerisci descrizione',
                            ),
                          ),
                          onChanged: (value) {
                            _updateColumn(column, description: value);
                          },
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
    if (type.contains('int') ||
        type.contains('decimal') ||
        type.contains('float')) {
      return Icons.numbers;
    } else if (type.contains('varchar') ||
        type.contains('text') ||
        type.contains('char')) {
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

class _ColumnBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ColumnBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}
