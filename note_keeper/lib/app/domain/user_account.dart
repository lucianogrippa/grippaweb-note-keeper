class User {

  final String id;
  final String name;
  final String lastname;
  final String username;
  final String email;

  const User({required this.id, required this.name, required this.lastname, required this.username, required this.email});
}

class Account extends User {
   DateTime login;
   DateTime expireDate;

  Account(this.login, this.expireDate,
      {required super.id, required super.name, required super.lastname, required super.username, required super.email});

  factory Account.empty() =>
      Account(DateTime.now(), DateTime.now(), id: '', name: '',
          lastname: '',
          username: '',
          email: '');

  factory Account.fromUser({required User user, DateTime? expiredDate}) =>
      Account(
          DateTime.now(),
          expiredDate ?? DateTime.now().add(Duration(days: 5)),
          id: user.id,
          name: user.name,
          lastname: user.lastname,
          username: user.username,
          email: user.email);

  bool isNotEmptyAccount() {
    return name != '' && lastname != '' &&
        email != '' && username != '';
  }
}