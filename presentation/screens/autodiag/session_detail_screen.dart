import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/export_service.dart';
import '../../../data/autodiag_repository.dart';
import '../../../data/models/autodiag_models.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  Future<_SessionBundle>? _future;
  final _notes = TextEditingController();
  bool _dirty = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _fetch();
  }

  Future<_SessionBundle> _fetch() async {
    final repo = context.read<AutodiagRepository>();
    final sessions = await repo.listSessions();
    final head = sessions.where((e) => e.id == widget.sessionId).toList();
    if (head.isEmpty) {
      throw StateError('Сеанс #${widget.sessionId} не найден в базе');
    }
    final dtcs = await repo.sessionDtcs(widget.sessionId);
    final params = await repo.sessionParams(widget.sessionId);
    final recs = await repo.sessionRecommendations(widget.sessionId);
    _notes.text = head.first.notes ?? '';
    return _SessionBundle(
      head: head.first,
      dtcs: dtcs,
      params: params,
      recs: recs,
    );
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final export = context.read<ExportService>();
    return FutureBuilder<_SessionBundle>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Ошибка загрузки сеанса: ${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        if (snap.connectionState != ConnectionState.done || !snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final b = snap.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(df.format(b.head.dateTime)),
            actions: [
              IconButton(
                onPressed: () async {
                  try {
                    final file = await export.sessionToPdf(
                      sessionId: b.head.id,
                      sessionTime: b.head.dateTime,
                      dtcs: b.dtcs,
                      params: b.params,
                      notes: _notes.text,
                      carLabel: b.head.carLabel,
                      mileageAtSession: b.head.mileageAtSession,
                      obdDistanceWithMilKm: b.head.obdDistanceWithMilKm,
                    );
                    await export.sharePdf(file);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PDF сформирован')),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка PDF: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Экспорт PDF',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Авто: ${b.head.carLabel}'),
              if (b.head.mileageAtSession != null)
                Text('Пробег на момент сеанса: ${b.head.mileageAtSession} км'),
              if (b.head.obdDistanceWithMilKm != null)
                Text('OBD PID 21 (дистанция с MIL): ${b.head.obdDistanceWithMilKm} км'),
              const SizedBox(height: 16),
              const Text('Ошибки', style: TextStyle(fontWeight: FontWeight.bold)),
              if (b.dtcs.isEmpty)
                const Text('—')
              else
                ...b.dtcs.map(
                  (e) => ListTile(
                    dense: true,
                    title: Text(e.code),
                    subtitle: Text(e.description),
                    trailing: Text(e.type),
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Рекомендации', style: TextStyle(fontWeight: FontWeight.bold)),
              if (b.recs.isEmpty)
                const Text('—')
              else
                ...b.recs.map(
                  (r) => ListTile(
                    dense: true,
                    title: Text(r['text'] as String),
                    subtitle: Text('важность: ${r['severity']}'),
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Параметры', style: TextStyle(fontWeight: FontWeight.bold)),
              if (b.params.isEmpty)
                const Text('—')
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('PID')),
                      DataColumn(label: Text('Название')),
                      DataColumn(label: Text('Значение')),
                    ],
                    rows: b.params
                        .map(
                          (p) => DataRow(
                            cells: [
                              DataCell(Text(p.pidCode)),
                              DataCell(Text(p.name)),
                              DataCell(
                                Text(
                                    '${p.value.toStringAsFixed(1)} ${p.unit ?? ''}'),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Заметки'),
              TextField(
                controller: _notes,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (_) => _dirty = true,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: !_dirty
                    ? null
                    : () async {
                        await context.read<AutodiagRepository>().updateSessionNotes(
                              widget.sessionId,
                              _notes.text,
                            );
                        if (context.mounted) {
                          setState(() => _dirty = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Заметки сохранены')),
                          );
                        }
                      },
                child: const Text('Сохранить заметки'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionBundle {
  _SessionBundle({
    required this.head,
    required this.dtcs,
    required this.params,
    required this.recs,
  });
  final DiagnosticSessionRow head;
  final List<SessionDtcRow> dtcs;
  final List<SessionParamRow> params;
  final List<Map<String, Object?>> recs;
}
