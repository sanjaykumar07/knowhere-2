import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/medication.dart';
import '../main_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _MedDraft {
  final nameCtrl = TextEditingController();
  final doseCtrl = TextEditingController();
  String frequency = 'Once daily';
  final timeCtrl = TextEditingController();
  String instructions = 'None';
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  // Account
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Health profile
  final _dobCtrl = TextEditingController();
  String _gender = 'Female';
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _diabetesType = 'Type 2';
  bool _hypertension = false;
  final _dateDiagnosedCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _emergencyContactCtrl = TextEditingController();

  // Medication
  bool _takesMedication = false;
  final List<_MedDraft> _medications = [_MedDraft()];

  bool _loading = false;
  String? _error;

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Create the Firebase Auth account -> unique UID
      final uid = await _authService.signUp(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );

      // 2. Save the profile under users/{uid}
      final user = UserModel(
        uid: uid,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        dateOfBirth: _dobCtrl.text.trim(),
        gender: _gender,
        height: double.tryParse(_heightCtrl.text) ?? 0,
        weight: double.tryParse(_weightCtrl.text) ?? 0,
        diabetesType: _diabetesType,
        hypertension: _hypertension,
        dateDiagnosed: _dateDiagnosedCtrl.text.trim().isEmpty ? null : _dateDiagnosedCtrl.text.trim(),
        allergies: _allergiesCtrl.text.trim(),
        emergencyContact: _emergencyContactCtrl.text.trim(),
      );
      await _firestoreService.createUserProfile(user);

      // 3. Save medications, if any
      if (_takesMedication) {
        const uuid = Uuid();
        for (final draft in _medications) {
          if (draft.nameCtrl.text.trim().isEmpty) continue;
          final med = Medication(
            id: uuid.v4(),
            name: draft.nameCtrl.text.trim(),
            dose: draft.doseCtrl.text.trim(),
            frequency: draft.frequency,
            time: draft.timeCtrl.text.trim(),
            instructions: draft.instructions,
          );
          await _firestoreService.addMedication(uid, med);
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      setState(() => _error = _authService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up for Free')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle('Account information'),
            const SizedBox(height: 12),
            TextFormField(
                controller: _nameCtrl,
                decoration: _dec('Full name'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec('Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: _dec('Password'),
                validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: _dec('Confirm password'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _dec('Phone number'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),

            const SizedBox(height: 28),
            _sectionTitle('Health profile'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dobCtrl,
              readOnly: true,
              onTap: _pickDob,
              decoration: _dec('Date of birth').copyWith(suffixIcon: const Icon(Icons.calendar_today)),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: _dec('Gender'),
              items: ['Female', 'Male', 'Other', 'Prefer not to say']
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
              items: ['Type 1', 'Type 2', 'Other', 'Not diagnosed']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _diabetesType = v!),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyContactCtrl,
              decoration: _dec('Emergency contact (name & phone)'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),

            const SizedBox(height: 28),
            _sectionTitle('Medication setup'),
            const SizedBox(height: 8),
            const Text('Do you currently take medication for diabetes or hypertension?'),
            RadioGroup<bool>(
              groupValue: _takesMedication,
              onChanged: (v) => setState(() => _takesMedication = v!),
              child: const Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Yes'),
                      value: true,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('No'),
                      value: false,
                    ),
                  ),
                ],
              ),
            ),
            if (_takesMedication) ...[
              const SizedBox(height: 8),
              ..._medications.asMap().entries.map((entry) {
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
                            Text('Medication ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (_medications.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => setState(() => _medications.removeAt(i)),
                              ),
                          ],
                        ),
                        TextFormField(controller: draft.nameCtrl, decoration: _dec('Medication name')),
                        const SizedBox(height: 8),
                        TextFormField(controller: draft.doseCtrl, decoration: _dec('Dose (e.g. 500 mg)')),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: draft.frequency,
                          decoration: _dec('Frequency'),
                          items: ['Once daily', 'Twice daily', 'Three times daily', 'As needed']
                              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                              .toList(),
                          onChanged: (v) => setState(() => draft.frequency = v!),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(controller: draft.timeCtrl, decoration: _dec('Time (e.g. 8:00 AM)')),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: draft.instructions,
                          decoration: _dec('Before/after food'),
                          items: ['None', 'Before food', 'After food']
                              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                              .toList(),
                          onChanged: (v) => setState(() => draft.instructions = v!),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _medications.add(_MedDraft())),
                icon: const Icon(Icons.add),
                label: const Text('Add another medication'),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _signUp,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create account'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) =>
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
}
