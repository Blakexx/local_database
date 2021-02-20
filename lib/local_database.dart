library local_database;

import "dart:io";
import "dart:convert";
import "dart:async";
import "package:queue/queue.dart";

///A dart:io based Database
class Database {
  Directory _base;
  Queue _queue;

  ///Create a Database with path b
  Database(String b) {
    assert(b != null);
    _base = Directory(b)..create(recursive: true);
    _queue = Queue();
  }

  ///Return the Database's path
  String get path => _base.path;

  String _delim = Platform.pathSeparator;

  Future<void> _set(String path, dynamic data) async {
    path = _fixPath(path);
    String s;
    try {
      s = json.encode(data);
    } catch (e) {
      throw Exception("Invalid data (not json encodable)");
    }
    if (data is List) {
      List l = data;
      data = Map<String, dynamic>();
      l.asMap().forEach((i, d) => data[i.toString()] = d);
    }
    if (data is Map) {
      await Future.wait(data.keys
          .map((k) => Future<void>(() async {
                await _set(path == _delim ? path + k : "$path/$k", data[k]);
              }))
          .toList()
          .cast<Future<void>>());
    } else {
      if (data != null && data != "") {
        if (path == _delim) {
          throw Exception("Invalid Path (cannot write to root)");
        }
        File f = File(_base.path + path);
        await f.create(recursive: true);
        await f.writeAsString(s);
      }
    }
  }

  ///Put into the Database
  void operator []=(String path, dynamic data) {
    assert(path != null);
    _queue.add(() async {
      await _remove(path);
      await _set(path, data);
    });
  }

  ///Get from the Database
  Future<dynamic> operator [](String path) async {
    assert(path != null);
    return await _queue.add(() async {
      path = _fixPath(path);
      dynamic f = File(_base.path + path);
      if (!f.existsSync()) {
        f = Directory(_base.path + path);
      }
      if (!(await f.exists())) {
        return null;
      } else {
        if (f is Directory) {
          Map<String, dynamic> map = Map<String, dynamic>();
          dynamic files = await f.list(recursive: true);
          files = await files.toList();
          await Future.wait(files
              .map((d) => Future<void>(() async {
                    if (d is Directory) {
                      return;
                    }
                    String path = d.path;
                    path = path.substring(f.path.length);
                    path = _fixPath(path);
                    if (Platform.isMacOS &&
                        path.split(_delim).last == ".DS_Store") {
                      return;
                    }
                    List<String> paths = path.split(_delim);
                    paths.removeAt(0);
                    String last = paths.removeLast();
                    Map<String, dynamic> temp = map;
                    paths.forEach((s) {
                      if (temp[s] == null) {
                        temp[s] = Map<String, dynamic>();
                      }
                      temp = temp[s];
                    });
                    temp[last] = json.decode(await d.readAsString());
                  }))
              .toList()
              .cast<Future<dynamic>>());
          _convertAllLists(map, null, null);
          if (_isList(map)) {
            return _mapToList(map);
          }
          return map;
        } else {
          return json.decode(await f.readAsString());
        }
      }
    });
  }

  Future<void> _remove(String path) async {
    path = _fixPath(path);
    dynamic f = File(_base.path + path);
    if (f.existsSync()) {
      Directory parent = f.parent;
      f.deleteSync(recursive: true);
      while (parent.path != _base.path && parent.listSync().length == 0) {
        await parent.delete(recursive: true);
        parent = parent.parent;
      }
    } else {
      f = Directory(_base.path + path);
      if (f.existsSync()) {
        Directory parent = f.parent;
        await f.delete(recursive: true);
        while (parent.path != _base.path && parent.listSync().length == 0) {
          await parent.delete(recursive: true);
          parent = parent.parent;
        }
      }
    }
    if (path == _delim) {
      await _base.create();
    }
  }

  ///Remove from the database
  Future<void> remove(String path) async {
    assert(path != null);
    await _queue.add(() async {
      await _remove(path);
    });
  }

  ///Convert a Map to a List
  List<dynamic> _mapToList(Map<String, dynamic> map) {
    List<dynamic> list = [];
    list.length = map.length;
    for (int i = 0; i < list.length; i++) {
      list[i] = map[i.toString()];
    }
    return list;
  }

  ///Recursively convert all potential Maps into Lists
  void _convertAllLists(Map map, dynamic parentMap, dynamic key) {
    if (_isList(map)) {
      if (parentMap != null) {
        parentMap[key] = _mapToList(map);
        List l = parentMap[key];
        for (int i = 0; i < l.length; i++) {
          if (l[i] is Map) {
            _convertAllLists(l[i], parentMap[key], i);
          }
        }
      } else {
        List l = _mapToList(map);
        for (int i = 0; i < map.keys.length; i++) {
          if (l[i] is Map) {
            _convertAllLists(map[i.toString()], map, i.toString());
          }
        }
      }
      return;
    }
    map.forEach((k, v) {
      if (v is Map) {
        _convertAllLists(v, map, k);
      }
    });
  }

  ///Check if a Map is a List
  bool _isList(Map map) {
    dynamic keys = map.keys;
    bool allInts = keys.every((s) => RegExp("\\d+").hasMatch(s));
    bool sequential = true;
    for (int i = 0; i < keys.length; i++) {
      if (!keys.contains("$i")) {
        sequential = false;
        break;
      }
    }
    return map.keys.length > 0 && allInts && sequential;
  }

  ///Fix the provided paths
  String _fixPath(String path) {
    path = path.replaceAll("/", _delim).replaceAll("\\", _delim);
    if (path.length == 0 || path.substring(0, 1) != _delim) {
      path = _delim + path;
    }
    if (path.length > 2 && path.endsWith(_delim)) {
      path = path.substring(0, path.length - 1);
    }
    if (RegExp(r"/{2,}").allMatches(path).length > 0) {
      throw Exception("Invalid path");
    }
    return path;
  }
}
