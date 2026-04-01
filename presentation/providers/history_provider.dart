import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../data/autodiag_repository.dart';
import '../../data/models/autodiag_models.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._repo);
  final AutodiagRepository _repo;

  List<DiagnosticSessionRow> sessions = [];
  List<DiagnosticSessionRow> filtered = [];
  int? filterCarId;
  String query = '';

  Future<void> refresh() async {
    sessions = await _repo.listSessions(carIdFilter: filterCarId);
    _applyQuery();
    notifyListeners();
  }

  void _applyQuery() {
    if (query.trim().isEmpty) {
      filtered = List.of(sessions);
      return;
    }
    final q = query.trim().toLowerCase();
    final df = DateFormat('yyyy-MM-dd HH:mm');
    filtered = sessions.where((s) {
      return df.format(s.dateTime).toLowerCase().contains(q) ||
          s.carLabel.toLowerCase().contains(q);
    }).toList();
  }

  void setFilterCar(int? id) {
    filterCarId = id;
    refresh();
  }

  void setQuery(String q) {
    query = q;
    _applyQuery();
    notifyListeners();
  }
}
