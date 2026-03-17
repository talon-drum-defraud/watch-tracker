import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/watch_provider.dart';

class AddWatchScreen extends StatefulWidget {
  final String? editWatchId; // if set, we're editing
  const AddWatchScreen({super.key, this.editWatchId});

  @override
  State<AddWatchScreen> createState() => _AddWatchScreenState();
}

class _AddWatchScreenState extends State<AddWatchScreen> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _movementCtrl = TextEditingController();
  bool _saving = false;

  bool get _isEditing => widget.editWatchId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final watch = context
          .read<WatchProvider>()
          .watches
          .firstWhere((w) => w.id == widget.editWatchId);
      _nameCtrl.text = watch.name;
      _brandCtrl.text = watch.brand;
      _movementCtrl.text = watch.movement;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _movementCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Watch' : 'Add Watch'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Field(
              controller: _nameCtrl,
              label: 'Watch Name / Label',
              hint: 'e.g. Submariner, SKX007',
              icon: Icons.label_outline,
            ),
            const SizedBox(height: 16),
            _Field(
              controller: _brandCtrl,
              label: 'Brand',
              hint: 'e.g. Rolex, Seiko, Omega',
              icon: Icons.business_outlined,
            ),
            const SizedBox(height: 16),
            _Field(
              controller: _movementCtrl,
              label: 'Movement',
              hint: 'e.g. ETA 2824-2, 4R36, Cal. 3135',
              icon: Icons.settings_outlined,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Save Changes' : 'Add Watch'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final brand = _brandCtrl.text.trim();
    final movement = _movementCtrl.text.trim();

    if (name.isEmpty || brand.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and brand are required.')),
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<WatchProvider>();

    if (_isEditing) {
      final existing =
          provider.watches.firstWhere((w) => w.id == widget.editWatchId);
      await provider.updateWatch(
        existing.copyWith(name: name, brand: brand, movement: movement),
      );
    } else {
      await provider.addWatch(name: name, brand: brand, movement: movement);
    }

    if (mounted) Navigator.pop(context);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}
