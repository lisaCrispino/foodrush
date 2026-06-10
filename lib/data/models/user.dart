class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String address;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.address,
  });

  AppUser copyWith({
    String? name,
    String? phone,
    String? address,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'address': address,
      };
}
