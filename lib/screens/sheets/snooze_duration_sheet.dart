import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/customization_provider.dart';

class SnoozeDurationSheet extends ConsumerStatefulWidget {
  const SnoozeDurationSheet({super.key});

  @override
  ConsumerState<SnoozeDurationSheet> createState() => _SnoozeDurationSheetState();
}

class _SnoozeDurationSheetState extends ConsumerState<SnoozeDurationSheet> {
  final Map<String, int> _options = {
    '15 mins': 15,
    '30 mins': 30,
    '45 mins': 45,
    '1 hr': 60,
    '4 hrs': 240,
    '12 hrs': 720,
    '1 day': 1440,
  };

  void _showCustomTimeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: TriplTheme.obsidianBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: TriplTheme.borderGreen, width: 1),
          ),
          title: Text('Custom Snooze Time', style: TextStyle(color: TriplTheme.textLight)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: TriplTheme.textLight),
            decoration: InputDecoration(
              hintText: 'Enter duration in minutes',
              hintStyle: TextStyle(color: TriplTheme.textGray),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriplTheme.borderGreen)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriplTheme.primaryMint)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: TriplTheme.textGray)),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(controller.text);
                if (val != null && val > 0) {
                  ref.read(snoozeDurationProvider.notifier).setDuration(val);
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Close the sheet as well
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: TriplTheme.primaryMint, foregroundColor: TriplTheme.obsidianBg),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDuration = ref.watch(snoozeDurationProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TriplTheme.obsidianBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TriplTheme.borderGreen, width: 0.5),
                ),
                child: Icon(Icons.snooze_rounded, color: TriplTheme.primaryMint, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remind Later Duration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TriplTheme.textLight,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Select how long to snooze notifications',
                      style: TextStyle(fontSize: 12, color: TriplTheme.textGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._options.entries.map((entry) {
            final isSelected = currentDuration == entry.value;
            return ListTile(
              title: Text(entry.key, style: TextStyle(color: isSelected ? TriplTheme.primaryMint : TriplTheme.textLight)),
              trailing: isSelected ? Icon(Icons.check, color: TriplTheme.primaryMint) : null,
              onTap: () {
                ref.read(snoozeDurationProvider.notifier).setDuration(entry.value);
                Navigator.pop(context);
              },
            );
          }),
          Divider(color: TriplTheme.borderGreen),
          ListTile(
            title: Text('Custom Time...', style: TextStyle(color: TriplTheme.textLight)),
            trailing: Icon(Icons.keyboard_arrow_right, color: TriplTheme.textGray),
            onTap: _showCustomTimeDialog,
          ),
        ],
      ),
    ),
  );
}
}
