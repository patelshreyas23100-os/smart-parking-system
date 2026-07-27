class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String licenceNo;
  final double walletBalance;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.licenceNo,
    required this.walletBalance,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'] ?? '',
      licenceNo: json['licence_no'] ?? '',
      walletBalance: (json['wallet_balance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'licence_no': licenceNo,
      'wallet_balance': walletBalance,
    };
  }
}
