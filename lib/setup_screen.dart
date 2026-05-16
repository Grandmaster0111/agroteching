import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shown on first launch when Firebase config has not been entered yet.
/// Collects the Firebase project values and persists them in SharedPreferences.
class SetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;
  const SetupScreen({super.key, required this.onSetupComplete});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyCtrl         = TextEditingController();
  final _appIdCtrl          = TextEditingController();
  final _senderIdCtrl       = TextEditingController();
  final _projectIdCtrl      = TextEditingController();
  final _storageBucketCtrl  = TextEditingController();
  final _databaseUrlCtrl    = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _appIdCtrl.dispose();
    _senderIdCtrl.dispose();
    _projectIdCtrl.dispose();
    _storageBucketCtrl.dispose();
    _databaseUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebase_api_key',        _apiKeyCtrl.text.trim());
    await prefs.setString('firebase_app_id',         _appIdCtrl.text.trim());
    await prefs.setString('firebase_sender_id',      _senderIdCtrl.text.trim());
    await prefs.setString('firebase_project_id',     _projectIdCtrl.text.trim());
    await prefs.setString('firebase_storage_bucket', _storageBucketCtrl.text.trim());
    await prefs.setString('firebase_database_url',   _databaseUrlCtrl.text.trim());
    setState(() => _saving = false);
    widget.onSetupComplete();
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool required = true, String hint = ''}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your Firebase project credentials',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find these values in:\n'
                  'Firebase Console → Project Settings → General → Your apps',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                _field('API Key',         _apiKeyCtrl,        hint: 'AIzaSy...'),
                _field('App ID',          _appIdCtrl,         hint: '1:123456:android:abc...'),
                _field('Sender ID',       _senderIdCtrl,      hint: '123456789'),
                _field('Project ID',      _projectIdCtrl,     hint: 'my-project-id'),
                _field('Storage Bucket',  _storageBucketCtrl, hint: 'my-project.appspot.com'),
                _field('Realtime DB URL', _databaseUrlCtrl,   required: false,
                       hint: 'https://my-project-default-rtdb.firebaseio.com'),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const CircularProgressIndicator()
                        : const Text('Save & Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
