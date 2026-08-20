import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final firestore = FirestoreService();
    final uid = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: StreamBuilder<UserModel?>(
        stream: firestore.streamUserProfile(uid),
        builder: (context, snap) {
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
                child: Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
              if (user.dateDiagnosed != null) _infoTile('Date diagnosed', user.dateDiagnosed!),
              _infoTile('Allergies', user.allergies.isEmpty ? 'None reported' : user.allergies),
              _infoTile('Emergency contact', user.emergencyContact),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
