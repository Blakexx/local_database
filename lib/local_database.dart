library local_database;

import "dart:io";
import "dart:convert";

///A dart:io based Database
class Database {
  Directory _base;

  ///Create a Database with path b
  Database(String b) {
    assert(b != null);
    _base = new Directory(b)..createSync(recursive: true);
  }

  ///Return the Database's path
  String get path => _base.path;

  String _delim = Platform.pathSeparator;

  ///Put into the Database
  operator []=(String path, dynamic data) {
    assert(path != null);
    path = _fixPath(path);
    String s;
    try {
      s = json.encode(data);
    } catch (e) {
      throw new Exception("Invalid data (not json encodable)");
    }
    remove(path);
    if (data is List) {
      List l = data;
      data = new Map<String, dynamic>();
      l.asMap().forEach((i, d) => data[i.toString()] = d);
    }
    if (data is Map) {
      data.forEach((k, v) => this[path == _delim ? path + k : "$path/$k"] = v);
    } else {
      if (data == null || data == "") {
        remove(path);
      } else {
        if (path == _delim) {
          throw new Exception("Invalid Path (cannot write to root)");
        }
        new File(_base.path + path)
          ..createSync(recursive: true)
          ..writeAsStringSync(s);
      }
    }
  }

  ///Get from the Database
  operator [](String path) {
    assert(path != null);
    path = _fixPath(path);
    dynamic f = new File(_base.path + path);
    if (!f.existsSync()) {
      f = new Directory(_base.path + path);
    }
    if (!f.existsSync()) {
      return null;
    } else {
      if (f is Directory) {
        Map<String, dynamic> map = new Map<String, dynamic>();
        List<dynamic> files = f.listSync(recursive: true);
        files.forEach((d) {
          if (d is Directory) {
            return;
          }
          String path = d.path;
          path = path.substring(f.path.length);
          path = _fixPath(path);
          if (Platform.isMacOS && path.split(_delim).last == ".DS_Store") {
            return;
          }
          List<String> paths = path.split(_delim);
          paths.removeAt(0);
          String last = paths.removeLast();
          Map<String, dynamic> temp = map;
          paths.forEach((s) {
            if (temp[s] != null) {
              temp = temp[s];
            } else {
              temp[s] = new Map<String, dynamic>();
              temp = temp[s];
            }
          });
          temp[last] = json.decode(d.readAsStringSync());
        });
        _convertAllLists(map, null, null);
        if (_isList(map)) {
          return _mapToList(map);
        }
        return map;
      } else {
        String data = f.readAsStringSync();
        return json.decode(data);
      }
    }
  }

  ///Remove from the database
  dynamic remove(String path) {
    assert(path != null);
    path = _fixPath(path);
    dynamic data = this[path];
    dynamic f = new File(_base.path + path);
    if (f.existsSync()) {
      Directory parent = f.parent;
      f.deleteSync(recursive: true);
      while (parent.path != _base.path && parent.listSync().length == 0) {
        parent.deleteSync(recursive: true);
        parent = parent.parent;
      }
    } else {
      f = new Directory(_base.path + path);
      if (f.existsSync()) {
        Directory parent = f.parent;
        f.deleteSync(recursive: true);
        while (parent.path != _base.path && parent.listSync().length == 0) {
          parent.deleteSync(recursive: true);
          parent = parent.parent;
        }
      }
    }
    if (path == _delim) {
      _base.createSync();
    }
    return data;
  }

  ///Convert a Map to a List
  List<dynamic> _mapToList(Map<String, dynamic> map) {
    List<dynamic> list = new List<dynamic>();
    list.length = map.length;
    for (int i = 0; i < list.length; i++) {
      list[i] = map[i.toString()];
    }
    return list;
  }

  //Recursively convert all potential Maps into Lists
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
    bool allInts = keys.every((s) => new RegExp("\\d+").hasMatch(s));
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
    return path;
  }
}
