// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User(
      apikey: json['apikey'] as String,
      name: json['name'] as String,
      password: json['password'] as String,
      admin: json['admin'] as bool,
      verified: json['verified'] as bool);
}

Map<String, dynamic> _$UserToJson(User instance) {
  var val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('apikey', instance.apikey);
  writeNotNull('name', instance.name);
  writeNotNull('password', instance.password);
  writeNotNull('admin', instance.admin);
  writeNotNull('verified', instance.verified);
  return val;
}
