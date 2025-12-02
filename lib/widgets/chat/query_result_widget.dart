import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget per visualizzare i risultati delle query SQL
class QueryResultWidget extends StatelessWidget {
  final List<Map<String, dynamic>> results;

  const QueryResultWidget({
    super.key,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Estrai colonne dal primo risultato
    final columns = results.isNotEmpty 
        ? results.first.keys.toList() 
        : <String>[];
    final rowCount = results.length;

    if (results.isEmpty) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Nessun risultato trovato'),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.table_rows,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$rowCount risultati',
                  style: theme.textTheme.labelLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyToClipboard(context, results, columns),
                  tooltip: 'Copia come CSV',
                ),
              ],
            ),
          ),

          // Tabella dati
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 400),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  theme.colorScheme.surfaceContainerLow,
                ),
                columnSpacing: 24,
                horizontalMargin: 16,
                columns: columns.map((col) {
                  return DataColumn(
                    label: Text(
                      col,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                rows: results.take(100).map((row) {
                  return DataRow(
                    cells: columns.map((col) {
                      final value = row[col];
                      return DataCell(
                        _buildCellContent(value, theme),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),

          // Footer con avviso se troncato
          if (results.length > 100)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Visualizzati 100 di ${results.length} risultati',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCellContent(dynamic value, ThemeData theme) {
    if (value == null) {
      return Text(
        'NULL',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.outline,
        ),
      );
    }

    final stringValue = value.toString();

    // Verifica se è un valore mascherato
    if (stringValue.contains('***')) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_off,
            size: 14,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            stringValue,
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ],
      );
    }

    // Formatta in base al tipo
    if (value is num) {
      return Text(
        _formatNumber(value),
        style: const TextStyle(fontFamily: 'monospace'),
      );
    }

    if (value is DateTime) {
      return Text(_formatDateTime(value));
    }

    if (value is bool) {
      return Icon(
        value ? Icons.check_circle : Icons.cancel,
        size: 18,
        color: value ? Colors.green : Colors.red,
      );
    }

    // Testo lungo: mostra con tooltip
    if (stringValue.length > 50) {
      return Tooltip(
        message: stringValue,
        child: Text(
          '${stringValue.substring(0, 47)}...',
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Text(stringValue);
  }

  String _formatNumber(num value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(
    BuildContext context,
    List<Map<String, dynamic>> rows,
    List<String> columns,
  ) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(columns.join(','));

    // Righe
    for (final row in rows) {
      final values = columns.map((col) {
        final value = row[col];
        if (value == null) return '';
        final str = value.toString();
        // Escape virgole e virgolette
        if (str.contains(',') || str.contains('"')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).toList();
      buffer.writeln(values.join(','));
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dati copiati come CSV'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
