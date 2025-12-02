import 'package:flutter/material.dart';

import '../../../models/table_model.dart';

/// Step 4: Riepilogo della configurazione schema
class ReviewStep extends StatelessWidget {
  final List<TableModel> tables;

  const ReviewStep({
    super.key,
    required this.tables,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Statistiche
    final totalColumns = tables.fold<int>(
      0,
      (sum, table) => sum + table.columns.length,
    );
    final sensitiveColumns = tables.fold<int>(
      0,
      (sum, table) =>
          sum + table.columns.where((c) => c.isSensitive).length,
    );
    final describedColumns = tables.fold<int>(
      0,
      (sum, table) =>
          sum +
          table.columns
              .where((c) => c.description != null && c.description!.isNotEmpty)
              .length,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Intestazione
          Text(
            'Riepilogo Configurazione',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Verifica la configurazione prima di procedere alla chat',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Statistiche riepilogative
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.table_chart,
                  value: '${tables.length}',
                  label: 'Tabelle',
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.view_column,
                  value: '$totalColumns',
                  label: 'Colonne',
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.description,
                  value: '$describedColumns',
                  label: 'Descritte',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.security,
                  value: '$sensitiveColumns',
                  label: 'Sensibili',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Avvisi
          if (describedColumns < totalColumns)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${totalColumns - describedColumns} colonne non hanno una descrizione. '
                      'L\'AI potrebbe avere difficoltà a interpretarle correttamente.',
                      style: TextStyle(color: Colors.amber.shade800),
                    ),
                  ),
                ],
              ),
            ),

          if (sensitiveColumns > 0)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$sensitiveColumns colonne sono marcate come sensibili e verranno mascherate nelle risposte.',
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
            ),

          // Lista tabelle dettagliata
          Expanded(
            child: ListView.builder(
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                final sensitiveCols =
                    table.columns.where((c) => c.isSensitive).length;
                final describedCols = table.columns
                    .where((c) =>
                        c.description != null && c.description!.isNotEmpty)
                    .length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: Container(
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
                    title: Text(
                      table.name,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (table.description != null)
                          Text(
                            table.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _MiniStat(
                              icon: Icons.view_column,
                              value: '${table.columns.length}',
                            ),
                            const SizedBox(width: 12),
                            _MiniStat(
                              icon: Icons.description,
                              value: '$describedCols',
                              color: describedCols == table.columns.length
                                  ? Colors.green
                                  : null,
                            ),
                            if (sensitiveCols > 0) ...[
                              const SizedBox(width: 12),
                              _MiniStat(
                                icon: Icons.security,
                                value: '$sensitiveCols',
                                color: Colors.orange,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Colonne:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...table.columns.map((column) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getColumnIcon(column.dataType),
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        column.name,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        column.dataType,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        column.description ?? '(nessuna descrizione)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: column.description != null
                                              ? null
                                              : theme.colorScheme.outline,
                                          fontStyle: column.description == null
                                              ? FontStyle.italic
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (column.isSensitive)
                                      const Icon(
                                        Icons.security,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? color;

  const _MiniStat({
    required this.icon,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(fontSize: 12, color: effectiveColor),
        ),
      ],
    );
  }
}
