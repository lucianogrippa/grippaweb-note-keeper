class RegistrationData {

  late String name;
  late String lastname;
  late String username;
  late String email;
  late String password;
  late bool passwordConfirmed;
  late String masterPassword;
  late bool masterPasswordConfirmed;

   RegistrationData();

   factory RegistrationData.empty() => RegistrationData()
     ..name = ''
     ..lastname = ''
     ..username = ''
     ..email = ''
     ..password = ''
     ..passwordConfirmed = false
     ..masterPassword = ''
     ..masterPasswordConfirmed = false;

   factory RegistrationData.fromMap(Map<String, dynamic> map) => RegistrationData()
     ..name = map['name'] ?? ''
     ..lastname = map['lastname'] ?? ''
     ..username = map['username'] ?? ''
     ..email = map['email'] ?? ''
     ..password = map['password'] ?? ''
     ..passwordConfirmed = map['passwordConfirmed'] ?? false
     ..masterPassword = map['masterPassword'] ?? ''
     ..masterPasswordConfirmed = map['masterPasswordConfirmed'] ?? false;
}