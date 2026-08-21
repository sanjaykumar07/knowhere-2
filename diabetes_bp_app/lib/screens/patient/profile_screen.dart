import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final firestore = FirestoreService();
    final uid = auth.currentUser!.uid;

    return StreamBuilder<UserModel?>(
      stream: firestore.streamUserProfile(uid),
      builder: (context, snap) {
        final user = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit profile',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProfileEditScreen(user: user)),
                  ),
                ),
            ],
          ),
          body: _buildBody(snap),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<UserModel?> snap) {
    if (snap.hasError) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            "Couldn't load your profile.\nPlease check your connection and try again.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    final user = snap.data;
    if (user == null) return const Center(child: Text('Profile not found'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        _infoTile('Email', user.email),
        _infoTile('Phone', user.phone),
        _infoTile('Date of birth', user.dateOfBirth),
        _infoTile('Gender', user.gender),
        _infoTile('Height', '${user.height.toStringAsFixed(0)} cm'),
        _infoTile('Weight', '${user.weight.toStringAsFixed(0)} kg'),
        _infoTile('Diabetes type', user.diabetesType),
        _infoTile('Hypertension', user.hypertension ? 'Yes' : 'No'),
        if (user.dateDiagnosed != null)
          _infoTile('Date diagnosed', user.dateDiagnosed!),
        _infoTile('Allergies',
            user.allergies.isEmpty ? 'None reported' : user.allergies),
        _contactsTile(user.emergencyContacts),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 140,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _contactsTile(List<EmergencyContact> contacts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
              width: 140,
              child: Text('Emergency contacts',
                  style: TextStyle(color: Colors.grey))),
          Expanded(
            child: contacts.isEmpty
                ? const Text('None reported',
                    style: TextStyle(fontWeight: FontWeight.w500))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: contacts
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(_contactLabel(c),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _contactLabel(EmergencyContact c) {
    if (c.name.isNotEmpty && c.number.isNotEmpty) return '${c.name} — ${c.number}';
    return c.name.isNotEmpty ? c.name : c.number;
  }
}
