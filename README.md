A local database using dart:io file system components

## Getting started

In the `pubspec.yaml` of your flutter project, add the following dependency:

```yaml
dependencies:
  ...
  local_database: ^1.0.1+4
```

In your library add the following import:

```dart
import "package:local_database/local_database.dart";
```

For help getting started with Flutter, view the online [documentation](https://flutter.io/).


## Using

This plugin comes with three main operations, get, put, and remove.

To use the database, simply instantiate it with the constructor 
`Database database = new Database(/*File System Path to database*/);`

Next, call the built in methods for database.

To put into the database, use the []= operator (note that only JSON encodable types can be used). The parameter of this operator is the path in the database to put to delimited by forward slashes ("/").
```dart
database["dir1"] = {
	"b":[1,2,3]
};
database["dir1/b/0"] = 100;
```

To read from the database, use the [] operator. The parameter of this operator is the path in the database to read from delimited by forward slashes ("/").

```dart
print(database["dir1"]);
print(database["dir1/b/0"]);
```

To remove from the database, use the .remove(String path) method. The parameter of this operator is the path in the database to put to delimited by forward slashes ("/").

```dart
database.remove("dir1");
```

The following is an example use of the package:

```dart
Database database = new Database(Directory.current.path+"/data");
Map<String,dynamic> userData;
if(database["userData"]==null){
	String userId = "";
	Random r = new Random();
	for(int i = 0; i<8;i++){
		userId+=r.nextInt(10).toString();
	}
	database["userData"] = {
		"created": (new DateTime.now()).millisecondsSinceEpoch,
		"id":userId,
		"numLikes":0
	};
}
userData = database["userData"];
```