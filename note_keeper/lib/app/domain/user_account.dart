class User {

  final String name;
  final String lastname;
  final String username;
  final String  email;

  const User({required this.name, required this.lastname, required this.username, required this.email});
}

class Account extends User {
  final String token;
  final DateTime login;
  final DateTime expireDate;

  Account(this.token, this.login, this.expireDate,
      {required super.name, required super.lastname, required super.username, required super.email});
}