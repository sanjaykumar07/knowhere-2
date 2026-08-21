/// A single emergency contact (name + phone number).
/// Stored inside the user profile's `emergencyContacts` array.
class EmergencyContact {
  final String name;
  final String number;

  const EmergencyContact({required this.name, required this.number});

  Map<String, dynamic> toMap() => {'name': name, 'number': number};

  factory EmergencyContact.fromMap(Map<String, dynamic> m) =>
      EmergencyContact(name: m['name'] ?? '', number: m['number'] ?? '');
}

/// Represents the patient's profile, stored at users/{uid}
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String dateOfBirth; // stored as yyyy-MM-dd string
  final String gender;
  final double height; // cm
  final double weight; // kg
  final String diabetesType; // "Type 1", "Type 2", "Other", "Not diagnosed"
  final bool hypertension;
  final String? dateDiagnosed;
  final String allergies;
  final List<EmergencyContact> emergencyContacts;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    required this.height,
    required this.weight,
    required this.diabetesType,
    required this.hypertension,
    this.dateDiagnosed,
    required this.allergies,
    this.emergencyContacts = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'height': height,
      'weight': weight,
      'diabetesType': diabetesType,
      'hypertension': hypertension,
      'dateDiagnosed': dateDiagnosed,
      'allergies': allergies,
      'emergencyContacts': emergencyContacts.map((c) => c.toMap()).toList(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      gender: map['gender'] ?? '',
      height: (map['height'] ?? 0).toDouble(),
      weight: (map['weight'] ?? 0).toDouble(),
      diabetesType: map['diabetesType'] ?? 'Not diagnosed',
      hypertension: map['hypertension'] ?? false,
      dateDiagnosed: map['dateDiagnosed'],
      allergies: map['allergies'] ?? '',
      emergencyContacts: _parseContacts(map),
    );
  }

  /// Reads `emergencyContacts` as a list; falls back to wrapping the legacy
  /// single-string `emergencyContact` field into one name-only contact so
  /// profiles created before the multi-contact change keep working.
  static List<EmergencyContact> _parseContacts(Map<String, dynamic> map) {
    final raw = map['emergencyContacts'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => EmergencyContact.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }
    final legacy = (map['emergencyContact'] ?? '').toString().trim();
    return legacy.isEmpty
        ? const []
        : [EmergencyContact(name: legacy, number: '')];
  }
}
