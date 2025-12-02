import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/routes.dart';
import '../../models/table_model.dart';
import '../../providers/schema_provider.dart';
import 'steps/table_selection_step.dart';
import 'steps/table_description_step.dart';
import 'steps/column_description_step.dart';
import 'steps/review_step.dart';

/// Wizard per la modellazione dello schema database
class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key});

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  int _currentStep = 0;
  List<TableModel> _selectedTables = [];
  int _currentTableIndex = 0;

  final List<String> _stepTitles = [
    'Selezione Tabelle',
    'Descrizione Tabelle',
    'Descrizione Colonne',
    'Riepilogo',
  ];

  @override
  void initState() {
    super.initState();
    // Carica lo schema dal database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schemaProvider.notifier).loadSchema();
    });
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeWizard();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _onTablesSelected(List<TableModel> tables) {
    setState(() {
      _selectedTables = tables;
    });
  }

  void _onTableUpdated(TableModel table) {
    final index = _selectedTables.indexWhere((t) => t.name == table.name);
    if (index != -1) {
      setState(() {
        _selectedTables[index] = table;
      });
    }
  }

  void _nextTable() {
    if (_currentTableIndex < _selectedTables.length - 1) {
      setState(() {
        _currentTableIndex++;
      });
    }
  }

  void _previousTable() {
    if (_currentTableIndex > 0) {
      setState(() {
        _currentTableIndex--;
      });
    }
  }

  Future<void> _completeWizard() async {
    try {
      await ref.read(schemaProvider.notifier).saveSchema(_selectedTables);
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.chat);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore salvataggio schema: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schemaState = ref.watch(schemaProvider);

    // Mostra loading durante il caricamento
    if (schemaState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Wizard Modellazione Schema'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Caricamento tabelle...'),
            ],
          ),
        ),
      );
    }

    // Mostra errore se presente
    if (schemaState.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Wizard Modellazione Schema'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(schemaState.error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(schemaProvider.notifier).loadSchema(),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wizard Modellazione Schema'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed(AppRoutes.settings);
            },
            icon: const Icon(Icons.settings),
            label: const Text('Impostazioni'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stepper indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(4, (index) {
                final isCompleted = index < _currentStep;
                final isCurrent = index == _currentStep;

                return Expanded(
                  child: Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                      _buildStepIndicator(
                        index + 1,
                        _stepTitles[index],
                        isCompleted: isCompleted,
                        isCurrent: isCurrent,
                      ),
                      if (index < 3)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Step content
          Expanded(
            child: _buildStepContent(),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pulsante Indietro
                if (_currentStep > 0)
                  OutlinedButton.icon(
                    onPressed: _previousStep,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Indietro'),
                  )
                else
                  const SizedBox.shrink(),

                // Indicatore tabella corrente (solo nello step 2)
                if (_currentStep == 2 && _selectedTables.isNotEmpty)
                  Row(
                    children: [
                      IconButton(
                        onPressed:
                            _currentTableIndex > 0 ? _previousTable : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        'Tabella ${_currentTableIndex + 1} di ${_selectedTables.length}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      IconButton(
                        onPressed: _currentTableIndex <
                                _selectedTables.length - 1
                            ? _nextTable
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),

                // Pulsante Avanti/Completa
                ElevatedButton.icon(
                  onPressed: _canProceed() ? _nextStep : null,
                  icon: Icon(
                    _currentStep == 3 ? Icons.check : Icons.arrow_forward,
                  ),
                  label: Text(_currentStep == 3 ? 'Completa' : 'Avanti'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
    int number,
    String title, {
    required bool isCompleted,
    required bool isCurrent,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isCurrent
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isCurrent
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return TableSelectionStep(
          selectedTables: _selectedTables,
          onTablesChanged: _onTablesSelected,
        );
      case 1:
        return TableDescriptionStep(
          tables: _selectedTables,
          onTableUpdated: _onTableUpdated,
        );
      case 2:
        if (_selectedTables.isEmpty) {
          return const Center(
            child: Text('Nessuna tabella selezionata'),
          );
        }
        return ColumnDescriptionStep(
          table: _selectedTables[_currentTableIndex],
          onTableUpdated: _onTableUpdated,
        );
      case 3:
        return ReviewStep(tables: _selectedTables);
      default:
        return const SizedBox.shrink();
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedTables.isNotEmpty;
      case 1:
        return _selectedTables.every(
          (t) => t.description != null && t.description!.isNotEmpty,
        );
      case 2:
        return true; // Le descrizioni colonne sono opzionali
      case 3:
        return true;
      default:
        return false;
    }
  }
}
