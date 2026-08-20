import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Minimal clinician-facing screen. In this prototype every patient
/// document lives at users/{uid}, so a clinician view simply lists
/// patient profiles.
///
/// NOTE: this screen is a starting point only. A real deployment
/// needs a "role" field on the user (patient/clinician) plus
/// Firestore security rules that check that role before granting
/// read access to other users' health data. That role-based access
/// control is out of scope for this prototype and is listed as
/// future work.
class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinician Dashboard')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No patients yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(data['name'] ?? 'Unknown patient'),
                  subtitle: Text(
                      '${data['diabetesType'] ?? '-'} · Hypertension: ${data['hypertension'] == true ? 'Yes' : 'No'}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
