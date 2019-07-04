import "package:flutter_test/flutter_test.dart";
import "dart:io";
import "package:local_database/local_database.dart";

void main() {
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
  test("Put to, read from, and remove from the database", () async {
    Database database = new Database(home + "/data");
    database["dir1"] = {
      "a": [1, 2, 3],
      "b": {"c": 5},
      "d": [
        1,
        2,
        {"e": 5}
      ]
    };
    database["dir2/f"] = "Data";
    expect((await database["dir1"]).toString(),
        "{a: [1, 2, 3], d: [1, 2, {e: 5}], b: {c: 5}}");
    expect(await database["dir1/a/0"], 1);
    expect((await database["/"]).toString(),
        "{dir2: {f: Data}, dir1: {a: [1, 2, 3], d: [1, 2, {e: 5}], b: {c: 5}}}");
    expect(await database["nonexistant"], null);
    database.remove("dir1");
    expect((await database["dir1"]).toString(), "null");
    new Directory(home + "/data")..deleteSync(recursive: true);
  });
}
