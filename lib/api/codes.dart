import 'dart:convert';

const Unknown = -1;
const Ok = 0;
const Invalid = 1;
const NameShort = 2;
const PasswordShort = 3;
const PasswordInvalid = 4;
const NameInvalid = 5;
const AddUserFailed = 6;
const UserAlreadyExists = 7;
const InvalidPassword = 8;
const PasswordLong = 9;
const NameLong = 10;
const YoutubeFetchFailure = 11;
const YoutubeSearchFailure = 12;
const YoutubeGetFailure = 13;
const YoutubeGetInfoFailure = 14;
const YoutubeGetChartsFailure = 15;
const PlaylistIdAlreadyExists = 16;
const AddHistoryFailed = 17;

int getStatusCode(String data) {
  Map<String, dynamic> parsed = json.decode(data);
  if (parsed != null) {
    return parsed["statuscode"];
  }
  return null;
}
