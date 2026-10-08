import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'notion_style.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String role;
  final String email;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.role,
    required this.email,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _role;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name);
    _role = TextEditingController(text: widget.role);
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context)
        .pop({'name': _name.text.trim(), 'role': _role.text.trim()});
  }

  InputDecoration _decoration() => InputDecoration(
    filled: true,
    fillColor: AppColors.of(context).surfaceMuted,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: AppColors.of(context).border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: AppColors.of(context).border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: AppColors.of(context).accent, width: 1.5),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: NotionText.section.copyWith(
        color: AppColors.of(context).textSecondary,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: notionAppBar(context, title: 'Edit Profile'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: c.grayBg,
                  child: Text(
                    _name.text.isEmpty ? '?' : _name.text[0].toUpperCase(),
                    style: TextStyle(fontSize: 32, color: c.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {}, // TODO: image picker
                  child: Text('Add a photo', style: TextStyle(color: c.accent)),
                ),
              ),
              const SizedBox(height: 16),
              _label('Preferred name'),
              TextFormField(
                controller: _name,
                decoration: _decoration(),
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),
              _label('Role'),
              TextFormField(controller: _role, decoration: _decoration()),
              const SizedBox(height: 20),
              _label('Email'),
              TextFormField(
                initialValue: widget.email,
                enabled: false,
                decoration: _decoration(),
                style: TextStyle(color: c.textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.canvas,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
