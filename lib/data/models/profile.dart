class Profile {
  const Profile({
    required this.name,
    required this.age,
    required this.email,
    this.clinicName,
    this.clinicCode,
    this.clinicianName,
  });

  final String name;
  final int age;
  final String email;
  final String? clinicName;
  final String? clinicCode;
  final String? clinicianName;

  Profile copyWith({
    String? name,
    int? age,
    String? email,
    String? clinicName,
    String? clinicCode,
    String? clinicianName,
  }) => Profile(
    name: name ?? this.name,
    age: age ?? this.age,
    email: email ?? this.email,
    clinicName: clinicName ?? this.clinicName,
    clinicCode: clinicCode ?? this.clinicCode,
    clinicianName: clinicianName ?? this.clinicianName,
  );
}
