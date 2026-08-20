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
  final String emergencyContact;

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
    required this.emergencyContact,
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
      'emergencyContact': emergencyContact,
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
      emergencyContact: map['emergencyContact'] ?? '',
    );
  }
}
