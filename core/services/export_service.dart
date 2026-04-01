// export_service.dart (полный код с исправлениями)

import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/autodiag_repository.dart';
import '../../data/models/autodiag_models.dart';

class ExportService {
  ExportService(this._repo);
  final AutodiagRepository _repo;
  static pw.Font? _font;
  static bool _fontLoadedFromAsset = false;

  Future<pw.Font> _getFont() async {
    if (_font != null && _fontLoadedFromAsset) return _font!;

    try {
      final byteData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
      _font = pw.Font.ttf(byteData);
      _fontLoadedFromAsset = true;
      return _font!;
    } catch (_) {
      try {
        _font = pw.Font.helvetica();
        _fontLoadedFromAsset = false;
        return _font!;
      } catch (_) {
        _font = pw.Font.courier();
        _fontLoadedFromAsset = false;
        return _font!;
      }
    }
  }

  Future<Map<String, _ParamStats>> _computeStats(List<SessionParamRow> history) async {
    final stats = <String, _ParamStats>{};
    final grouped = <String, List<SessionParamRow>>{};
    for (final p in history) {
      grouped.putIfAbsent(p.pidCode, () => []).add(p);
    }
    for (final entry in grouped.entries) {
      final values = entry.value.map((p) => p.value).toList();
      if (values.isNotEmpty) {
        final min = values.reduce((a, b) => a < b ? a : b);
        final max = values.reduce((a, b) => a > b ? a : b);
        final avg = values.reduce((a, b) => a + b) / values.length;
        final last = values.last;
        stats[entry.key] = _ParamStats(min: min, max: max, avg: avg, last: last);
      }
    }
    return stats;
  }

  Future<File> sessionToPdf({
    required int sessionId,
    required DateTime sessionTime,
    required List<SessionDtcRow> dtcs,
    required List<SessionParamRow> params,
    required String notes,
    required String carLabel,
  }) async {
    final doc = pw.Document();
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final font = await _getFont();
    final baseTextStyle = pw.TextStyle(font: font, fontSize: 10);
    final headerTextStyle = pw.TextStyle(
      font: font,
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );
    final boldTextStyle = pw.TextStyle(
      font: font,
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );

    final recs = await _repo.sessionRecommendations(sessionId);
    final history = await _repo.sessionParamsHistory(sessionId);
    final stats = await _computeStats(history);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('AutoDiag — отчёт о диагностике', style: headerTextStyle),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text('Автомобиль: $carLabel', style: baseTextStyle),
                    ),
                    pw.Expanded(
                      child: pw.Text('Дата: ${df.format(sessionTime)}', style: baseTextStyle),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          if (dtcs.isNotEmpty) ...[
            _buildDtcTable(dtcs, baseTextStyle, boldTextStyle, headerTextStyle),
            pw.SizedBox(height: 20),
          ] else ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.green100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Row(
                children: [
                  pw.Text('✓', style: boldTextStyle.copyWith(color: PdfColors.green)),
                  pw.SizedBox(width: 10),
                  pw.Text('Ошибки не обнаружены', style: boldTextStyle.copyWith(color: PdfColors.green)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          if (params.isNotEmpty) ...[
            _buildParamsTable(params, baseTextStyle, boldTextStyle, headerTextStyle),
            pw.SizedBox(height: 20),
          ],

          if (stats.isNotEmpty) ...[
            _buildStatsTable(stats, params, baseTextStyle, boldTextStyle, headerTextStyle),
            pw.SizedBox(height: 20),
          ],

          if (recs.isNotEmpty) ...[
            _buildRecommendationsSection(recs, baseTextStyle, boldTextStyle, headerTextStyle),
            pw.SizedBox(height: 20),
          ],

          if (notes.isNotEmpty) ...[
            _buildNotesSection(notes, baseTextStyle, boldTextStyle, headerTextStyle),
          ],

          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              'Сгенерировано AutoDiag v1.0',
              style: baseTextStyle.copyWith(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'autodiag_session_$sessionId.pdf'));
    await file.writeAsBytes(await doc.save());
    return file;
  }

  pw.Widget _buildDtcTable(
      List<SessionDtcRow> dtcs,
      pw.TextStyle baseStyle,
      pw.TextStyle boldStyle,
      pw.TextStyle headerStyle,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Обнаруженные ошибки (DTC)', style: headerStyle),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(80),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FixedColumnWidth(60),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Код', boldStyle, isHeader: true),
                _buildTableCell('Описание', boldStyle, isHeader: true),
                _buildTableCell('Тип', boldStyle, isHeader: true),
              ],
            ),
            ...dtcs.map((dtc) => pw.TableRow(
              children: [
                _buildTableCell(dtc.code, baseStyle),
                _buildTableCell(dtc.description, baseStyle),
                _buildTableCell(
                  dtc.type == 'current' ? 'Активная' : 'Отложенная',
                  baseStyle.copyWith(
                    color: dtc.type == 'current' ? PdfColors.red : PdfColors.orange,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildParamsTable(
      List<SessionParamRow> params,
      pw.TextStyle baseStyle,
      pw.TextStyle boldStyle,
      pw.TextStyle headerStyle,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Параметры двигателя (последние значения)', style: headerStyle),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(60),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FixedColumnWidth(80),
            3: const pw.FixedColumnWidth(40),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('PID', boldStyle, isHeader: true),
                _buildTableCell('Параметр', boldStyle, isHeader: true),
                _buildTableCell('Значение', boldStyle, isHeader: true),
                _buildTableCell('Ед.', boldStyle, isHeader: true),
              ],
            ),
            ...params.map((param) => pw.TableRow(
              children: [
                _buildTableCell(param.pidCode, baseStyle),
                _buildTableCell(param.name, baseStyle),
                _buildTableCell(param.value.toStringAsFixed(1), baseStyle),
                _buildTableCell(param.unit ?? '', baseStyle),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildStatsTable(
      Map<String, _ParamStats> stats,
      List<SessionParamRow> params,
      pw.TextStyle baseStyle,
      pw.TextStyle boldStyle,
      pw.TextStyle headerStyle,
      ) {
    final paramInfo = <String, (String, String?)>{};
    for (final p in params) {
      paramInfo[p.pidCode] = (p.name, p.unit);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Сводная статистика параметров', style: headerStyle),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(60),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FixedColumnWidth(80),
            3: const pw.FixedColumnWidth(80),
            4: const pw.FixedColumnWidth(80),
            5: const pw.FixedColumnWidth(80),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('PID', boldStyle, isHeader: true),
                _buildTableCell('Параметр', boldStyle, isHeader: true),
                _buildTableCell('Мин.', boldStyle, isHeader: true),
                _buildTableCell('Макс.', boldStyle, isHeader: true),
                _buildTableCell('Среднее', boldStyle, isHeader: true),
                _buildTableCell('Последнее', boldStyle, isHeader: true),
              ],
            ),
            ...stats.entries.map((entry) {
              final pid = entry.key;
              final stat = entry.value;
              final info = paramInfo[pid] ?? (pid, null);
              final name = info.$1;
              final unit = info.$2 ?? '';
              return pw.TableRow(
                children: [
                  _buildTableCell(pid, baseStyle),
                  _buildTableCell(name, baseStyle),
                  _buildTableCell(stat.min.toStringAsFixed(1), baseStyle),
                  _buildTableCell(stat.max.toStringAsFixed(1), baseStyle),
                  _buildTableCell(stat.avg.toStringAsFixed(1), baseStyle),
                  _buildTableCell(stat.last.toStringAsFixed(1), baseStyle),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildRecommendationsSection(
      List<Map<String, dynamic>> recs,
      pw.TextStyle baseStyle,
      pw.TextStyle boldStyle,
      pw.TextStyle headerStyle,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Рекомендации', style: headerStyle),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            border: pw.Border.all(color: PdfColors.blue200),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: recs.map((rec) {
              final text = (rec['text'] as String?) ?? '';
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: boldStyle.copyWith(color: PdfColors.blue)),
                    pw.Expanded(
                      child: pw.Text(text, style: baseStyle),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildNotesSection(
      String notes,
      pw.TextStyle baseStyle,
      pw.TextStyle boldStyle,
      pw.TextStyle headerStyle,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Заметки', style: headerStyle),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            border: pw.Border.all(color: PdfColors.grey200),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Text(notes, style: baseStyle),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, pw.TextStyle style, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: isHeader ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(text, style: style),
    );
  }

  Future<void> sharePdf(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Отчёт AutoDiag');
  }

  Future<File> exportHistoryAndMaintenanceCsv() async {
    final sessions = await _repo.exportSessionsFlat();
    final maint = await _repo.exportMaintenanceFlat();
    final buf = StringBuffer();
    buf.writeln('# SESSIONS');
    buf.writeln('id,date_time,brand,model,notes');
    for (final r in sessions) {
      buf.writeln(
          '${r['id']},${r['date_time']},${r['brand']},${r['model']},"${(r['notes'] ?? '').toString().replaceAll('"', "'")}"');
    }
    buf.writeln('# MAINTENANCE');
    buf.writeln('id,title,type,interval,next_mileage,next_date_ms,car');
    for (final r in maint) {
      buf.writeln(
          '${r['id']},${r['title']},${r['interval_type']},${r['interval_value']},${r['next_due_mileage']},${r['next_due_date']},${r['car']}');
    }
    final dir = await getTemporaryDirectory();
    final file = File(
        p.join(dir.path, 'autodiag_export_${DateTime.now().millisecondsSinceEpoch}.csv'));
    await file.writeAsString(buf.toString(), encoding: utf8);
    return file;
  }

  Future<void> shareCsv(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'CSV AutoDiag');
  }

  Future<File> copyDatabaseBackup() async {
    final dbPath = p.join(await getDatabasesPath(), 'autodiag.db');
    final dir = await getTemporaryDirectory();
    final out = File(
        p.join(dir.path, 'autodiag_backup_${DateTime.now().millisecondsSinceEpoch}.db'));
    await File(dbPath).copy(out.path);
    return out;
  }

  Future<void> shareDb(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Резервная копия БД AutoDiag');
  }
}

class _ParamStats {
  final double min;
  final double max;
  final double avg;
  final double last;
  _ParamStats({required this.min, required this.max, required this.avg, required this.last});
}