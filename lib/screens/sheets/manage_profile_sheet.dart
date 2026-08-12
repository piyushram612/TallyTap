import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/profile_provider.dart';

class ManageProfileSheet extends ConsumerStatefulWidget {
  const ManageProfileSheet({super.key});

  @override
  ConsumerState<ManageProfileSheet> createState() => _ManageProfileSheetState();
}

class _ManageProfileSheetState extends ConsumerState<ManageProfileSheet> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentName = ref.read(usernameProvider);
      setState(() {
        _nameController.text = currentName;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customize Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: TriplTheme.primaryMint,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: TriplTheme.textGray),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'USERNAME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: TriplTheme.textGray,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: TriplTheme.textLight, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Enter your name (e.g. Alex)',
              hintStyle: TextStyle(color: TriplTheme.textGray),
              filled: true,
              fillColor: TriplTheme.obsidianCard,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: TriplTheme.borderGreen),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: TriplTheme.primaryMint, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final newName = _nameController.text;
              if (newName.trim().isNotEmpty) {
                ref.read(usernameProvider.notifier).setUsername(newName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Username updated to "${newName.trim()}"!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: TriplTheme.obsidianBg),
                    ),
                    backgroundColor: TriplTheme.primaryMint,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TriplTheme.primaryMint,
              foregroundColor: TriplTheme.obsidianBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            child: const Text(
              'SAVE PROFILE NAME',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
