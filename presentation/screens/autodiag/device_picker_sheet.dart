import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/diagnostics_provider.dart';

Future<void> showDevicePicker(BuildContext context) async {
  final diag = context.read<DiagnosticsProvider>();
  await diag.startDiscovery();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Consumer<DiagnosticsProvider>(
        builder: (context, d, _) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(d.scanning ? 'Поиск…' : 'Устройства Bluetooth'),
                  trailing: IconButton(
                    onPressed: () => d.startDiscovery(),
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                SizedBox(
                  height: 360,
                  child: ListView.builder(
                    itemCount: d.discovered.length,
                    itemBuilder: (_, i) {
                      final dev = d.discovered[i];
                      return ListTile(
                        title: Text(dev.name ?? 'Без имени'),
                        subtitle: Text(dev.address),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await d.connectTo(dev.address);
                        },
                      );
                    },
                  ),
                ),
                if (d.discovered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Нет сопряжённых устройств — сопрягите ELM327 в настройках Android'),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

// Fix typo const_icon -> const Icon