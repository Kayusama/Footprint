class HolderTracker {
  String uid;
  String username;
  String email;
  String key;
  String profilePicture;
  String campus;
  String position;
  String firstname;
  String lastname;
  String address;
  String number;
  DateTime birthday;

  // Constructor
HolderTracker({
  required this.uid,
  required this.username,
  required this.email,
  required this.key,
  this.profilePicture = '',
  this.campus = '',
  this.position = '',
  required this.firstname,
  required this.lastname,
  this.address = '',
  this.number = '',
  required DateTime birthday,
}) : birthday = birthday;

  // Named empty constructor
  HolderTracker.empty()
      : uid = '',
        username = '',
        email = '',
        key = '',
        profilePicture = '',
        campus = '',
        position = '',
        firstname = '',
        lastname = '',
        address = '',
        number = '',
        birthday = DateTime(1970);

  // Factory method to create a HolderTracker object from JSON
  factory HolderTracker.fromJson(Map<String, dynamic> data) {
    return HolderTracker(
      uid: data['uid'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      key: data['key'] ?? '',
      profilePicture: data['profilePicture'] ?? '',
      campus: data['campus'] ?? '',
      position: data['position'] ?? '',
      firstname: data['firstname'] ?? '',
      lastname: data['lastname'] ?? '',
      address: data['address'] ?? '',
      number: data['number'] ?? '',
      birthday: data['birthday'] != null
          ? DateTime.tryParse(data['birthday']) ?? DateTime(1970)
          : DateTime(1970),
    );
  }

  // Method to convert a HolderTracker object to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'key': key,
      'profilePicture': profilePicture,
      'campus': campus,
      'position': position,
      'firstname': firstname,
      'lastname': lastname,
      'address': address,
      'number': number,
      'birthday': birthday.toIso8601String(),
    };
  }

  // Setters
  set setUid(String value) => uid = value;
  set setUsername(String value) => username = value;
  set setEmail(String value) => email = value;
  set setKey(String value) => key = value;
  set setProfilePicture(String value) => profilePicture = value;
  set setCampus(String value) => campus = value;
  set setPosition(String value) => position = value;
  set setFirstname(String value) => firstname = value;
  set setLastname(String value) => lastname = value;
  set setAddress(String value) => address = value;
  set setNumber(String value) => number = value;
  set setBirthday(DateTime value) => birthday = value;

  // Getter for full name
  String get fullName => '$firstname $lastname';
}
