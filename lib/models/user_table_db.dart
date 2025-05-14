//models/user_table_db.dart
final String tableUsers = 'users';

class UserFields {
  static final String id = 'id';
  static final String first_name = 'first_name';
  static final String last_name = 'last_name';
  static final String username = 'username';
  static final String email = 'email';
  static final String password = 'password';
  static final String phone_num = 'phone_num';
  static final String address = 'address';
  static final String profile_picture = 'profile_picture';
  static final String isPrivate = 'isPrivate';
  static final String themePreference = 'themePreference';
  static final String notificationSettings = 'notificationSettings';
  static final String isEmailVerified = 'isEmailVerified';
}

class Users {
  final String id;
  final String? first_name;
  final String? last_name;
  final String? username;
  final String? email;
  final String? password;
  final int? phone_num;
  final String? address;
  final String profile_picture;
  final bool isPrivate;
  final String themePreference;
  final Map<String, bool> notificationSettings;
  final bool isEmailVerified;

  const Users({
    required this.id,
    this.first_name,
    this.last_name,
    this.username,
    this.email,
    this.password,
    this.phone_num,
    this.address,
    this.profile_picture = 'assets/default_profile.png',
    this.isPrivate = false,
    this.themePreference = 'light',
    this.notificationSettings = const {
      'likes': true,
      'comments': true,
      'follows': true,
      'messages': true,
      'mentions': true,
    },
    this.isEmailVerified = false,
  });

  Users copy({
    String? id,
    String? first_name,
    String? last_name,
    String? username,
    String? email,
    String? password,
    int? phone_num,
    String? address,
    String? profile_picture,
    bool? isPrivate,
    String? themePreference,
    Map<String, bool>? notificationSettings,
    bool? isEmailVerified,
  }) =>
      Users(
        id: id ?? this.id,
        first_name: first_name ?? this.first_name,
        last_name: last_name ?? this.last_name,
        username: username ?? this.username,
        email: email ?? this.email,
        password: password ?? this.password,
        phone_num: phone_num ?? this.phone_num,
        address: address ?? this.address,
        profile_picture: profile_picture ?? this.profile_picture,
        isPrivate: isPrivate ?? this.isPrivate,
        themePreference: themePreference ?? this.themePreference,
        notificationSettings: notificationSettings ?? this.notificationSettings,
        isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      );

  Map<String, Object?> toJson() => {
    UserFields.id: id,
    UserFields.first_name: first_name,
    UserFields.last_name: last_name,
    UserFields.username: username,
    UserFields.email: email,
    UserFields.password: password,
    UserFields.phone_num: phone_num,
    UserFields.address: address,
    UserFields.profile_picture: profile_picture,
    UserFields.isPrivate: isPrivate,
    UserFields.themePreference: themePreference,
    UserFields.notificationSettings: notificationSettings,
    UserFields.isEmailVerified: isEmailVerified,
  };

  static Users fromJson(Map<String, dynamic> json) => Users(
    id: json[UserFields.id] as String,
    first_name: json[UserFields.first_name] as String?,
    last_name: json[UserFields.last_name] as String?,
    username: json[UserFields.username] as String? ?? 'Unknown',
    email: json[UserFields.email] as String?,
    password: json[UserFields.password] as String?,
    phone_num: json[UserFields.phone_num] as int?,
    address: json[UserFields.address] as String?,
    profile_picture: json[UserFields.profile_picture] as String? ?? 'assets/default_profile.png',
    isPrivate: json[UserFields.isPrivate] as bool? ?? false,
    themePreference: json[UserFields.themePreference] as String? ?? 'light',
    notificationSettings:
    (json[UserFields.notificationSettings] as Map<String, dynamic>?)?.cast<String, bool>() ??
        {
          'likes': true,
          'comments': true,
          'follows': true,
          'messages': true,
          'mentions': true,
        },
    isEmailVerified: json[UserFields.isEmailVerified] as bool? ?? false,
  );

  // Method to print user data
  void printUserData() {
    print('User ID: $id');
    print('First Name: $first_name');
    print('Last Name: $last_name');
    print('Username: $username');
    print('Email: $email');
    print('Phone Number: $phone_num');
    print('Address: $address');
    print('Profile Picture: $profile_picture');
    print('Is Private: $isPrivate');
    print('Theme Preference: $themePreference');
    print('Notification Settings: $notificationSettings');
    print('Is Email Verified: $isEmailVerified');
  }
}