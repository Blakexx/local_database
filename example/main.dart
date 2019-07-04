import "dart:io";
import "package:local_database/local_database.dart";

void main() async {
  String home = "";
  Map<String, String> envVars = Platform.environment;
  if (Platform.isMacOS) {
    home = envVars["HOME"];
  } else if (Platform.isLinux) {
    home = envVars["HOME"];
  } else if (Platform.isWindows) {
    home = envVars["UserProfile"];
  } else {
    throw new Exception("Unknown platform");
  }
  Database database = new Database(home + "/data");
  //Put a complex map into path /dir1
  database["dir1"] = {
    "a": [1, 2, 3],
    "b": {"c": 5},
    "d": [
      1,
      2,
      {"e": 5}
    ]
  };
  //Put a single string into path /dir2/f
  database["dir2/f"] = "Data";
  //Read from /dir1
  print(await database["dir1"]);
  //Read from /dir1/a/0
  print(await database["dir1/a/0"]);
  //Read the entire database
  print(await database["/"]);
  //Read a nonexistent element
  print(await database["nonexistant"]);
  //Remove from the database
  database.remove("dir1");
  print(await database["dir1"]);
  new Directory(home + "/data")..deleteSync(recursive: true);
}
