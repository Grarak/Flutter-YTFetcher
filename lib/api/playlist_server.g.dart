// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Playlist _$PlaylistFromJson(Map<String, dynamic> json) {
  return Playlist(
      apikey: json['apikey'] as String,
      name: json['name'] as String,
      public: json['public'] as bool);
}

Map<String, dynamic> _$PlaylistToJson(Playlist instance) {
  var val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('apikey', instance.apikey);
  writeNotNull('name', instance.name);
  writeNotNull('public', instance.public);
  return val;
}
