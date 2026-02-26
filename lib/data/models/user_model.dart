class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? image;
  final String? token;
  final String? refreshToken;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.image,
    this.token,
    this.refreshToken,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l'.isEmpty ? username[0].toUpperCase() : '$f$l';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      image: json['image'] as String?,
      token: json['accessToken'] as String? ?? json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'image': image,
        'accessToken': token,
        'refreshToken': refreshToken,
      };

  UserModel copyWith({
    String? token,
    String? refreshToken,
  }) {
    return UserModel(
      id: id,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      image: image,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}
