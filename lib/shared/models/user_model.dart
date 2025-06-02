class User {
  final String id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final UserType userType;
  final String? birthDate;
  final String? sport;
  final String? goal;
  final bool isOnboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    required this.userType,
    this.birthDate,
    this.sport,
    this.goal,
    required this.isOnboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON 직렬화
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      userType: UserType.fromString(json['userType'] as String),
      birthDate: json['birthDate'] as String?,
      sport: json['sport'] as String?,
      goal: json['goal'] as String?,
      isOnboardingCompleted: json['isOnboardingCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'userType': userType.value,
      'birthDate': birthDate,
      'sport': sport,
      'goal': goal,
      'isOnboardingCompleted': isOnboardingCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // copyWith 메서드
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImageUrl,
    UserType? userType,
    String? birthDate,
    String? sport,
    String? goal,
    bool? isOnboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      userType: userType ?? this.userType,
      birthDate: birthDate ?? this.birthDate,
      sport: sport ?? this.sport,
      goal: goal ?? this.goal,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, userType: $userType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// 사용자 타입 enum
enum UserType {
  athlete('athlete', '선수'),
  general('general', '일반인'),
  guardian('guardian', '보호자'),
  coach('coach', '지도자');

  const UserType(this.value, this.displayName);

  final String value;
  final String displayName;

  static UserType fromString(String value) {
    return UserType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => UserType.general,
    );
  }

  @override
  String toString() => displayName;
}
