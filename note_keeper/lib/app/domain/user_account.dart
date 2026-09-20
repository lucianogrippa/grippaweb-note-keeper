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

  const Account(this.token, this.login, this.expireDate,
      {required super.name, required super.lastname, required super.username, required super.email});

  factory Account.empty() =>
      Account('', DateTime.now(), DateTime.now(), name: '',
          lastname: '',
          username: '',
          email: '');

  factory Account.mokAdmin() =>
      Account('token', DateTime.now(), DateTime.now().add(Duration(days: 5)),
          name: 'Admin',
          lastname: 'User',
          username: 'admin',
          email: 'admin@prova');

  bool isNotEmptyAccount() {
    return token != '' && name != '' && lastname != '' &&
        email != '' && username != '';
  }
}