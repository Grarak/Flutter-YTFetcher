// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Youtube _$YoutubeFromJson(Map<String, dynamic> json) {
  return Youtube(
      apikey: json['apikey'] as String,
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

  writeNotNull('apikey', instance.apikey);
  writeNotNull('searchquery', instance.searchquery);
  writeNotNull('id', instance.id);
  writeNotNull('addhistory', instance.addhistory);
  return val;
}

YoutubeResult _$YoutubeResultFromJson(Map<String, dynamic> json) {
  return YoutubeResult(
      title: json['title'] as String,
      id: json['id'] as String,
      thumbnail: json['thumbnail'] as String,
      duration: json['duration'] as String);
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
