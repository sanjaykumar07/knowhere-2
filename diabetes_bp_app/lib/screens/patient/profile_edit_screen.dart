import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

/// Editable form for the patient profile. Seeded from the [UserModel] passed
/// in and saved back via [FirestoreService.updateUserProfile]. Email is shown
/// read-only because it is the Firebase Auth login identity.
class ProfileEditScreen extends StatefulWidget {
  final UserModel user;

  const ProfileEditScreen({super.key, required this.user});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

/// A single editable emergency-contact row.
class _ContactDraft {
  final TextEditingController nameCtrl;
  final TextEditingController numberCtrl;

  _ContactDraft({String name = '', String number = ''})
      : nameCtrl = TextEditingController(text: name),
        numberCtrl = TextEditingController(text: number);

  void dispose() {
    nameCtrl.dispose();
    numberCtrl.dispose();
  }
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();

  static const _genderOptions = ['Female', 'Male', 'Other', 'Prefer not to say'];
  static const _diabetesOptions = ['Type 1', 'Type 2', 'Other', 'Not diagnosed'];

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _allergiesCtrl;
  late final TextEditingController _dateDiagnosedCtrl;

  late String _gender;
  late String _diabetesType;
  late bool _hypertension;
  late List<_ContactDraft> _contacts;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u.name);
    _phoneCtrl = TextEditingController(text: u.phone);
    _dobCtrl = TextEditingController(text: u.dateOfBirth);
    _heightCtrl =
        TextEditingController(text: u.height > 0 ? u.height.toStringAsFixed(0) : '');
    _weightCtrl =
        TextEditingController(text: u.weight > 0 ? u.weight.toStringAsFixed(0) : '');
    _allergiesCtrl = TextEditingController(text: u.allergies);
    _dateDiagnosedCtrl = TextEditingController(text: u.dateDiagnosed ?? '');

    _gender = _genderOptions.contains(u.gender) ? u.gender : _genderOptions.last;
    _diabetesType =
        _diabetesOptions.contains(u.diabetesType) ? u.diabetesType : 'Not diagnosed';
    _hypertension = u.hypertension;
    _contacts = u.emergencyContacts.isEmpty
        ? [_ContactDraft()]
        : u.emergencyContacts
            .map((c) => _ContactDraft(name: c.name, number: c.number))
            .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _allergiesCtrl.dispose();
    _dateDiagnosedCtrl.dispose();
    for (final c in _contacts) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDob() async {
    final initial = DateTime.tryParse(_dobCtrl.text) ?? DateTime(1990, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final u = widget.user;
    final contacts = <EmergencyContact>[];
    for (final draft in _contacts) {
      final name = draft.nameCtrl.text.trim();
      final number = draft.numberCtrl.text.trim();
      if (name.isEmpty && number.isEmpty) continue;
      contacts.add(EmergencyContact(name: name, number: number));
    }

    final updated = UserModel(
      uid: u.uid,
      name: _nameCtrl.text.trim(),
      email: u.email, // read-only: login identity
      phone: _phoneCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
      gender: _gender,
      height: double.tryParse(_heightCtrl.text) ?? u.height,
      weight: double.tryParse(_weightCtrl.text) ?? u.weight,
      diabetesType: _diabetesType,
      hypertension: _hypertension,
      dateDiagnosed: _hypertension && _dateDiagnosedCtrl.text.trim().isNotEmpty
          ? _dateDiagnosedCtrl.text.trim()
          : null,
      allergies: _allergiesCtrl.text.trim(),
      emergencyContacts: contacts,
    );

    try {
      await _firestore.updateUserProfile(updated);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save profile. Please try again.')),
      );
    }
  }

  InputDecoration _dec(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: _dec('Full name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.user.email,
              readOnly: true,
              enabled: false,
              decoration: _dec('Email').copyWith(
                suffixIcon: const Icon(Icons.lock_outline, size: 18),
                helperText: 'Email is your login and can\'t be changed here.',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _dec('Phone number'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dobCtrl,
              readOnly: true,
              onTap: _pickDob,
              decoration: _dec('Date of birth')
                  .copyWith(suffixIcon: const Icon(Icons.calendar_today)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: _dec('Gender'),
              items: _genderOptions
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Height (cm)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Weight (kg)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _diabetesType,
              decoration: _dec('Diabetes type'),
              items: _diabetesOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _diabetesType = v!),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hypertension'),
              value: _hypertension,
              onChanged: (v) => setState(() => _hypertension = v),
            ),
            if (_hypertension) ...[
              const SizedBox(height: 4),
              TextFormField(
                controller: _dateDiagnosedCtrl,
                decoration: _dec('Date diagnosed (optional)'),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _allergiesCtrl,
              decoration: _dec('Allergies (optional)'),
            ),
            const SizedBox(height: 24),
            const Text('Emergency contacts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._contacts.asMap().entries.map((entry) {
              final i = entry.key;
              final draft = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Contact ${i + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Remove contact',
                            onPressed: () => setState(() {
                              _contacts.removeAt(i).dispose();
                            }),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: draft.nameCtrl,
                        decoration: _dec('Contact name'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: draft.numberCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _dec('Phone number'),
                      ),
                    ],
                  ),
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => _contacts.add(_ContactDraft())),
              icon: const Icon(Icons.add),
              label: const Text('Add contact'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save changes'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
