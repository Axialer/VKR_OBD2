import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/cars_provider.dart';
import '../../providers/history_provider.dart';
import 'session_detail_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hist = context.watch<HistoryProvider>();
    final cars = context.watch<CarsProvider>();
    final df = DateFormat('dd.MM.yyyy HH:mm');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Поиск по дате или авто',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: hist.setQuery,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonFormField<int?>(
            value: hist.filterCarId,
            decoration: const InputDecoration(
              labelText: 'Автомобиль',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Все')),
              ...cars.cars.map(
                (c) => DropdownMenuItem<int?>(
                  value: c.id,
                  child: Text(c.displayName),
                ),
              ),
            ],
            onChanged: (v) {
              hist.setFilterCar(v);
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: hist.filtered.length,
            itemBuilder: (ctx, i) {
              final s = hist.filtered[i];
              return ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(s.carLabel),
                subtitle: Text(
                  '${df.format(s.dateTime)} · DTC: ${s.dtcCount}',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionDetailScreen(sessionId: s.id),
                    ),
                  ).then((_) => hist.refresh());
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
