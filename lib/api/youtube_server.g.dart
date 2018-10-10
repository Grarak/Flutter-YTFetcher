// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Youtube _$YoutubeFromJson(Map<String, dynamic> json) {
  return Youtube(
      apiKey: json['apiKey'] as String,
      searchquery: json['searchquery'] as String,
      id: json['id'] as String,
      addhistory: json['addhistory'] as bool);
}

Map<String, dynamic> _$YoutubeToJson(Youtube instance) {
  var val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('apiKey', instance.apiKey);
  writeNotNull('searchquery', instance.searchquery);
  writeNotNull('id', instance.id);
  writeNotNull('addhistory', instance.addhistory);
  return val;
}

YoutubeResult _$YoutubeResultFromJson(Map<String, dynamic> json) {
  return YoutubeResult(json['title'] as String, json['id'] as String,
      json['thumbnail'] as String, json['duration'] as String);
}

Map<String, dynamic> _$YoutubeResultToJson(YoutubeResult instance) {
  var val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('title', instance.title);
  writeNotNull('id', instance.id);
  writeNotNull('thumbnail', instance.thumbnail);
  writeNotNull('duration', instance.duration);
  return val;
}
