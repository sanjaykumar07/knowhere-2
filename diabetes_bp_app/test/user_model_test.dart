import 'package:flutter_test/flutter_test.dart';
import 'package:diabetes_bp_app/models/user_model.dart';

/// A minimal profile map with the given emergency-contact-related overrides.
Map<String, dynamic> _base(Map<String, dynamic> extra) => {
      'uid': 'u1',
      'name': 'Alex',
      'email': 'alex@example.com',
      'phone': '555',
      'dateOfBirth': '1990-01-01',
      'gender': 'Other',
      'height': 170,
      'weight': 70,
      'diabetesType': 'Type 2',
      'hypertension': false,
      'allergies': '',
      ...extra,
    };

void main() {
  group('UserModel emergency contacts', () {
    test('parses a new emergencyContacts list', () {
      final user = UserModel.fromMap(_base({
        'emergencyContacts': [
          {'name': 'Jane', 'number': '111'},
          {'name': 'Sam', 'number': '222'},
        ],
      }));

      expect(user.emergencyContacts.length, 2);
      expect(user.emergencyContacts.first.name, 'Jane');
      expect(user.emergencyContacts.first.number, '111');
      expect(user.emergencyContacts[1].name, 'Sam');
    });

    test('migrates the legacy emergencyContact string to one name-only contact',
        () {
      final user = UserModel.fromMap(_base({
        'emergencyContact': 'Jane 555-1234',
      }));

      expect(user.emergencyContacts.length, 1);
      expect(user.emergencyContacts.first.name, 'Jane 555-1234');
      expect(user.emergencyContacts.first.number, '');
    });

    test('yields an empty list when neither field is present', () {
      final user = UserModel.fromMap(_base({}));
      expect(user.emergencyContacts, isEmpty);
    });

    test('empty legacy string yields an empty list', () {
      final user = UserModel.fromMap(_base({'emergencyContact': '   '}));
      expect(user.emergencyContacts, isEmpty);
    });

    test('round-trips through toMap/fromMap', () {
      final original = UserModel(
        uid: 'u1',
        name: 'Alex',
        email: 'alex@example.com',
        phone: '555',
        dateOfBirth: '1990-01-01',
        gender: 'Other',
        height: 170,
        weight: 70,
        diabetesType: 'Type 2',
        hypertension: false,
        allergies: '',
        emergencyContacts: const [
          EmergencyContact(name: 'Jane', number: '111'),
        ],
      );

      final map = original.toMap();
      expect(map.containsKey('emergencyContact'), isFalse);
      expect(map['emergencyContacts'], [
        {'name': 'Jane', 'number': '111'},
      ]);

      final restored = UserModel.fromMap(map);
      expect(restored.emergencyContacts.length, 1);
      expect(restored.emergencyContacts.first.name, 'Jane');
      expect(restored.emergencyContacts.first.number, '111');
    });
  });
}
