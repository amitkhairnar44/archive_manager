import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:archive_manager/show_directory_contents.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

List<String> archiveFiles = [];
Map<String, ArchiveFile> filesMap = Map();
String rootPath;

void decode(DecodeParam param) {
  archiveFiles.clear();
  List<int> bytes = new File(param.file).readAsBytesSync();
  //print('Current extension: ${param.fileExtension}');
  // Decode the Zip file
  Archive archive;

  if (param.fileExtension == 'zip') {
    archive = new ZipDecoder().decodeBytes(bytes);
  }
  if (param.fileExtension == 'tar') {
    archive = new TarDecoder().decodeBytes(bytes);
  }
//  TODO Extract GZip archive straight away without displaying content
//  if(param.fileExtension == 'gz'){
//    archive = new GZipDecoder().decodeBytes(bytes);
//  }

  // Extract the contents of the Zip archive to disk.
  for (ArchiveFile file in archive) {
    String filename = file.name;
    filesMap[filename] = file;
    archiveFiles.add(filename);
    //print('$archiveFiles $filename');
//    if (file.isFile) {
//      List<int> data = file.content;
//      print(file.content);
//       new File('$rootPath/out/' + filename)
//         ..createSync(recursive: true)
//         ..writeAsBytes(data);
//    } else {
//       new Directory('$rootPath/' + filename)
//         ..create(recursive: true);
//    }
  }

  //param.sendPort.send(archiveFiles);
  param.sendPort.send(filesMap);
}

class DecodeParam {
  final String file;
  final String fileExtension;
  final SendPort sendPort;
  DecodeParam(this.file, this.sendPort, this.fileExtension);
}

class DecompressedArchiveDetails extends StatefulWidget {
  final String path;
  final String fileExtension;

  const DecompressedArchiveDetails({Key key, this.path, this.fileExtension})
      : super(key: key);

  @override
  _DecompressedArchiveDetailsState createState() =>
      _DecompressedArchiveDetailsState();
}

class _DecompressedArchiveDetailsState
    extends State<DecompressedArchiveDetails> {
  String title;

  Component _sortedMap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0.0,
        backgroundColor: Colors.white,
        brightness: Brightness.light,
        title: Text(
          'Archive',
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.unarchive),
              onPressed: () {
                _showExtractDialog();
              })
        ],
      ),
      body: _sortedMap != null && _sortedMap.files.length != 0
          ? ListView.builder(
              shrinkWrap: true,
              itemCount: _sortedMap.files.length,
              itemBuilder: (BuildContext context, int index) {
                //String key = filesMap.keys.elementAt(index);
                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 24.0, right: 8.0),
                  leading: Icon(
                    !_sortedMap.files[index].isDir
                        ? Icons.insert_drive_file
                        : Icons.folder_open,
                    color: Colors.grey[700],
                  ),
                  title: Text(_sortedMap.files[index].componentName),
//                  subtitle: filesMap[key].size < 1000
//                      ? Text('${filesMap[key].size} Bytes')
//                      : (filesMap[key].size > 1000 &&
//                      filesMap[key].size < 1000000)
//                      ? Text('${(filesMap[key].size / 1024).round()} KB')
//                      : Text(
//                      '${(filesMap[key].size / 1048576).round()} MB'),
                  trailing: PopupMenuButton(
                    itemBuilder: (BuildContext context) {
                      return [
                        new PopupMenuItem<String>(
                            child: new Text('Extract'), value: 'Extract'),
                        new PopupMenuItem<String>(
                            child: new Text('Info'), value: 'Info'),
                      ];
                    },
                    icon: Icon(Icons.more_vert),
//                    onSelected: (value) {
//                      //print(value);
//                      if (value == 'Info') {
//                        _showFileInfoDialog(filesMap[key]);
//                      }
//                      if (value == 'Extract') {
//                        if (filesMap[key].isFile) {
//                          List<int> data = filesMap[key].content;
//                          new File('$rootPath/out/' + filesMap[key].name)
//                            ..createSync(recursive: true)
//                            ..writeAsBytes(data);
//                        } else {
//                          new Directory('$rootPath/out/' + filesMap[key].name)
//                            ..create(recursive: true);
//                        }
//                      }
//                    },
                  ),
                  onTap: () {
                    //_showFileInfoDialog(filesMap[key]);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => DirectoryContents(
                              sortedMap: _sortedMap.files[index],
                              title: _sortedMap.files[index].componentName,
                            )));
                  },
                );
//                return ListTile(
//                  contentPadding: const EdgeInsets.only(left: 24.0, right: 8.0),
//                  leading: Icon(
//                    filesMap[key].isFile
//                        ? Icons.insert_drive_file
//                        : Icons.folder_open,
//                    color: Colors.grey[700],
//                  ),
//                  title: Text(key),
//                  subtitle: filesMap[key].size < 1000
//                      ? Text('${filesMap[key].size} Bytes')
//                      : (filesMap[key].size > 1000 &&
//                              filesMap[key].size < 1000000)
//                          ? Text('${(filesMap[key].size / 1024).round()} KB')
//                          : Text(
//                              '${(filesMap[key].size / 1048576).round()} MB'),
//                  trailing: PopupMenuButton(
//                    itemBuilder: (BuildContext context) {
//                      return [
//                        new PopupMenuItem<String>(
//                            child: new Text('Extract'), value: 'Extract'),
//                        new PopupMenuItem<String>(
//                            child: new Text('Info'), value: 'Info'),
//                      ];
//                    },
//                    icon: Icon(Icons.more_vert),
//                    onSelected: (value) {
//                      //print(value);
//                      if (value == 'Info') {
//                        _showFileInfoDialog(filesMap[key]);
//                      }
//                      if (value == 'Extract') {
//                        if (filesMap[key].isFile) {
//                          List<int> data = filesMap[key].content;
//                          new File('$rootPath/out/' + filesMap[key].name)
//                            ..createSync(recursive: true)
//                            ..writeAsBytes(data);
//                        } else {
//                          new Directory('$rootPath/out/' + filesMap[key].name)
//                            ..create(recursive: true);
//                        }
//                      }
//                    },
//                  ),
//                  onTap: () {
//                    _showFileInfoDialog(filesMap[key]);
//                  },
//                );
              },
            )
          : Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                    ),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0)),
                  Text(
                    'Please wait',
                    style: TextStyle(fontSize: 18.0),
                  )
                ],
              ),
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getRootPath();
    var split = widget.path.split('/');

    title = split[split.length - 1];
    //print(title);
    //_decodeArchive(widget.path);
    archiveFiles.clear();
    _decode();
    new Directory('$rootPath/Extracted')
      ..create(recursive: false).then((dir) {
        //print('Path of dir: ${dir.path}');
      }, onError: (error) {
        //print(error.message);
      });
  }

  showLoading({@required String message}) {
    return showDialog<Null>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: ListTile(
              leading: SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                ),
              ),
              title: Text(
                '$message',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
          );
        });
  }

  Future _goDeep(Component parent, List<String> paths) async {
    //print(paths);
    //print("parent name: ${parent.componentName} $paths");
    if (paths.length > 1) {
//      for (int i = 0; i < paths.length - 1; i++) {
//        Component def = Component(paths[i], true);
//        print(
//            "parent: ${parent.componentName}, child: ${def.componentName}, paths: ${paths.sublist(i + 1)}");
//        await _goDeep(def, paths.sublist(i + 1));
//        if (!parent.files
//            .any((file) => file.componentName == def.componentName)) {
//          parent.files.add(def);
//          print(
//              "Adding files to ${parent.componentName} : ${def.componentName}");
//        } else {
//          print("here");
//          parent.files
//              .singleWhere((file) => file.componentName == def.componentName)
//              .files
//              .addAll(def.files);
//        }
//      }
      Component def = Component(paths.first, true);
      print(
          "parent: ${parent.componentName}, child: ${def.componentName}, original: ${paths.first}, paths: ${paths.sublist(paths.length - (paths.length - 1))}");
      await _goDeep(def, paths.sublist(paths.length - (paths.length - 1)));
      if (parent.files.any((file) => file.componentName == def.componentName)) {
        print(
            "Adding files to ${parent.files.singleWhere((file) => file.componentName == def.componentName).componentName} : ${def.componentName} ${parent.files.any((file) => file.componentName == def.componentName)}");
        print("Files: ${def.files.map((i) => i.componentName)}");

        if (parent.files
            .singleWhere((file) => file.componentName == def.componentName)
            .files
            .any((file) => def.files
                .any((kFile) => kFile.componentName == file.componentName))) {
          print("Whatever!");
        } else {
          parent.files
              .singleWhere((file) => file.componentName == def.componentName)
              .files
              .addAll(def.files);
        }
      } else {
        parent.files.add(def);
      }
    } else {
      //print("Error: ${paths.first}");
      parent.files.add(Component(paths.first, false));
    }
  }

  _decode() async {
    ReceivePort receivePort = new ReceivePort();

    await Isolate.spawn(
        decode,
        new DecodeParam(
            widget.path, receivePort.sendPort, widget.fileExtension));

    // Get the processed image from the isolate.
    var data = await receivePort.first;
    setState(() {
      //archiveFiles = image;
      filesMap = data;
    });
    filesMap.forEach((name, file) async {
      if (_sortedMap == null) {
        _sortedMap = Component('root', true);
      }

      if (file.isFile) {
        var splitPath = name.split('/');
        await _goDeep(_sortedMap, splitPath);
        print(_sortedMap.files);
        //setState(() {});
//        if (splitPath.length > 1) {
//          Component _root;
//          Component _curr;
//          Component _prev;
//          for (int i = 0; i < splitPath.length - 1; i++) {
//            if (_curr == null) {
//              //print("${splitPath[i]} ${i == splitPath.length - 1} ");
//              _curr = Component(splitPath[i], !(i == splitPath.length - 1));
//              _root = _curr;
//              print("${_curr.componentName} : ${_curr.isDir}");
//            }
//            if (i >= 1) {
//              print("Object: ${splitPath[i]}");
//              _prev = Component(splitPath[i - 1], true);
//              _curr = Component(splitPath[i], true);
//              if (!_prev.files
//                  .any((comp) => comp.componentName == _curr.componentName)) {
//                print(
//                    "Curr: ${_curr.componentName}, Prev: ${_prev.componentName}");
//                _prev.files.add(_curr);
//              } else {
//                _prev.files
//                    .singleWhere(
//                        (comp) => comp.componentName == _curr.componentName)
//                    .files
//                    .addAll(_curr.files);
//              }
//
//              if (_root.files
//                  .any((file) => file.componentName == _prev.componentName)) {
//                _root.files
//                    .singleWhere(
//                        (file) => file.componentName == _prev.componentName)
//                    .files
//                    .add(_curr);
//              } else {
//                _root.files.add(_curr);
//              }
//              if (!_sortedMap.files
//                  .any((file) => file.componentName == _root.componentName)) {
//                _sortedMap.files.add(_root);
//              } else {
//                print(_root.files);
//                _sortedMap.files
//                    .singleWhere(
//                        (file) => file.componentName == _root.componentName)
//                    .files
//                    .addAll(_root.files);
//              }
//              _prev = _curr;
//            }
////            if (!_sortedMap.files
////                .any((file) => file.componentName == splitPath[i])) {
////              if (i == splitPath.length - 1) {
////                _sortedMap.files.add(Component(splitPath[i], false));
////              } else {
////                _sortedMap.files.add(Component(splitPath[i], true));
////              }
////            } else {
//////              _sortedMap.files
//////                  .singleWhere((file) => file.componentName == splitPath[i])
//////                  .files
//////                  .add(Component(splitPath[i], true));
////            }
//          }
////          if (!_sortedMap.files
////              .any((comp) => comp.componentName == _curr.componentName)) {
////            _sortedMap.files.add(_curr);
////          } else {
////            _sortedMap.files
////                .singleWhere(
////                    (comp) => comp.componentName == _curr.componentName)
////                .files
////                .addAll(_curr.files);
////          }
//        } else {
//          print("WTF : ${splitPath.first}");
//          _sortedMap.files.add(Component(splitPath.first, false));
//        }
      }

      //split
//      if (file.isFile) {
//        var splitPath = name.split('/');
//        print(name + "$splitPath");
//        if (splitPath.length > 1) {
//          Component _curr;
//          Component _prev;
//          for (int i = splitPath.length - 1; i >= 0; i--) {
//            if (_curr == null) {
//              print("${splitPath[i]} ${i == splitPath.length - 1} ");
//              _curr = Component(splitPath[i], !(i == splitPath.length - 1));
//              print("${_curr.componentName} : ${_curr.isDir}");
//            }
//            if (i >= 1) {
//              //print("i>=1 : ${splitPath[i - 1]}");
//              _prev = Component(splitPath[i - 1], true);
////              print(
////                  "Component exists? ${_prev.files.any((comp) => comp.componentName == _curr.componentName)}");
//              if (!_prev.files
//                  .any((comp) => comp.componentName == _curr.componentName)) {
//                //print(_curr.componentName);
//                _prev.files.add(_curr);
//              } else {
//                _prev.files
//                    .singleWhere(
//                        (comp) => comp.componentName == _curr.componentName)
//                    .files
//                    .addAll(_curr.files);
//              }
//              _curr = _prev;
//            }
//          }
//          if (!_sortedMap.files
//              .any((comp) => comp.componentName == _curr.componentName)) {
//            _sortedMap.files.add(_curr);
//          } else {
//            _sortedMap.files
//                .singleWhere(
//                    (comp) => comp.componentName == _curr.componentName)
//                .files
//                .addAll(_curr.files);
//          }
//        } else {
//          _sortedMap.files.add(Component(splitPath.first, false));
//        }
//      }
      //Split

//      if (file.isFile) {
//        var splitPath = name.split('/');
//        //print(splitPath);
//        Component _cmp = Component(splitPath[0], true);
//        for (int i = 0; i < splitPath.length; i++) {
//          if (i == 0 &&
//              _sortedMap.files
//                  .any((comp) => comp.componentName != splitPath[i])) {
//            _sortedMap.files.add(Component(splitPath[i], true));
//          }
//        }
//        if (splitPath.length > 1) {
////          if (_sortedMap == null) {
////            _sortedMap = Dir(splitPath.first);
////          }
//          for (int i = 0; i < splitPath.length; i++) {
//            if (i == splitPath.length - 1) {
////              print('$splitPath' + '$i');
////              print(_sortedMap.files
////                  .where((component) =>
////                      component.componentName == splitPath[i - 1])
////                  .map((comp) => comp.componentName));
//              //_sortedMap.files.forEach((comp) => print(comp.componentName));
//              //print(splitPath[i - 1]);
//              _sortedMap.files
//                  .singleWhere((component) =>
//                      component.componentName == splitPath[i - 1])
//                  .files
//                  .add(Component(splitPath[i], false));
//              //_sortedMap.files[i].files.add(Component(splitPath[i], false));
//            } else {
//              //_sortedMap.files.add(Dir(splitPath[i]));
//              //print("object");
//              //print('$splitPath' + '$i');
//              if (i > 0 &&
//                  _sortedMap.files.any((comp) =>
//                      comp.componentName == splitPath[i - 1] && comp.isDir)) {
//                if (!_sortedMap.files.any(
//                    (component) => component.componentName == splitPath[i])) {
//                  //print('Top');
//                  _sortedMap.files
//                      .singleWhere((comp) =>
//                          comp.componentName == splitPath[i - 1] && comp.isDir)
//                      .files
//                      .add(Component(splitPath[i], true));
//                }
//              } else {
//                if (!_sortedMap.files.any(
//                    (component) => component.componentName == splitPath[i])) {
//                  //print('bottom');
//                  _sortedMap.files.add(Component(splitPath[i], true));
//                }
//              }
//            }
////            _sortedMap.files.forEach((component) {
////              print(component.componentName +
////                  " ${component.isDir} " +
////                  'Files: ${component.files.map((comp) => comp.componentName)}');
////            });
//          }
//        } else {
//          _sortedMap.files.add(Component(splitPath.first, false));
//        }
//      }
    });

    //print(_sortedMap.componentName);
    _sortedMap.files.forEach((component) {
      var newMap =
          groupBy(component.files, (Component obj) => obj.componentName);
      //print(newMap);
      component.files.clear();
      component.files.addAll(newMap.keys.map((a) {
        List<Component> files = [];
        newMap[a].forEach((compo) {
          files.addAll(compo.files);
        });
//        Component comp = Component(a, true);
//        comp.files = files.toList();
        return Component(a, component.files.isEmpty ? false : true)
          ..files.addAll(files);
      }));
    });
    _sortedMap.files.forEach((component) {
      print(component.componentName +
          " ${component.isDir} " +
          'Files: ${component.files.map((comp) => comp.isDir ? '${comp.componentName} ${component.isDir} files: ${comp.files.map((cp) => cp.componentName)} ' : comp.componentName)}');
    });
  }

//  _decodeArchive(String filePath) {
//    archiveFiles.clear();
//    List<int> bytes = new File(filePath).readAsBytesSync();
//
//    // Decode the Zip file
//    Archive archive = new ZipDecoder().decodeBytes(bytes);
//
//    // Extract the contents of the Zip archive to disk.
//    for (ArchiveFile file in archive) {
//      String filename = file.name;
//      setState(() {
//        archiveFiles.add(filename);
//      });
//      print(filename);
//      if (file.isFile) {
//        List<int> data = file.content;
//        // new File('out/' + filename)
//        //   ..createSync(recursive: true)
//        //   ..writeAsBytesSync(data);
//      } else {
////         new Directory('out/' + filename)
////           ..create(recursive: true);
//      }
//    }
//  }

  _getRootPath() async {
    Directory appDocDir;

    if (Platform.isIOS) {
      appDocDir = await getApplicationDocumentsDirectory();
    } else {
      appDocDir = await getExternalStorageDirectory();
    }
    String appDocPath = appDocDir.path;
    //print('Root path: $rootPath');
    setState(() {
      rootPath = appDocPath;
    });
  }

  _showExtractDialog() {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            titlePadding: const EdgeInsets.only(left: 24.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            title: ListTile(
              title: Text(
                'Extract',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20.0),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.cancel,
                  color: Colors.grey[700],
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              contentPadding: const EdgeInsets.all(0.0),
            ),
            content: Text(
                'The archive will be extracted to \'Extracted\' folder in storage',
                style: TextStyle(fontWeight: FontWeight.w500)),
            actions: <Widget>[
              FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showLoading(message: 'Wait');
                    var split = title.split('.');
                    String dirName = split[0];
                    new Directory('$rootPath/Extracted/$dirName')
                      ..create(recursive: false).then((dir) {
                        //print('Path of dir: ${dir.path}');
                      }, onError: (error) {
                        //print(error.message);
                      });
                    var counter = 0;

                    filesMap.forEach((name, archiveFile) {
                      counter++;
                      if (archiveFile.isFile) {
                        List<int> data = archiveFile.content;
                        new File(
                            '$rootPath/Extracted/$dirName/' + archiveFile.name)
                          ..createSync(recursive: true)
                          ..writeAsBytes(data);
                      } else {
                        new Directory(
                            '$rootPath/Extracted/$dirName/' + archiveFile.name)
                          ..create(recursive: true);
                      }
                      if (counter == filesMap.length) {
                        //print('Equal $counter');
                        Navigator.of(context).pop();
                      }
                    });
                    //print(counter);
                  },
                  child: Text('Extract',
                      style: TextStyle(fontWeight: FontWeight.bold)))
            ],
          );
        });
  }

  _showFileInfoDialog(ArchiveFile file) {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            titlePadding: const EdgeInsets.only(left: 24.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            title: ListTile(
              title: Text(
                'Properties',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20.0),
              ),
              trailing: IconButton(
                icon: Icon(Icons.cancel),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              contentPadding: const EdgeInsets.all(0.0),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  title: Text(
                    'Name',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(file.name),
                  contentPadding: const EdgeInsets.all(0.0),
                ),
                ListTile(
                  title: Text(
                    'Size',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: file.size < 1000
                      ? Text('${file.size} Bytes')
                      : (file.size > 1000 && file.size < 1000000)
                          ? Text('${(file.size / 1024).round()} KB')
                          : Text('${(file.size / 1048576).round()} MB'),
                  contentPadding: const EdgeInsets.all(0.0),
                ),
                ListTile(
                  title: Text(
                    'Type',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(file.isFile ? 'File' : 'Folder'),
                  contentPadding: const EdgeInsets.all(0.0),
                ),
              ],
            ),
          );
        });
  }
}

class Component {
  String componentName;
  bool isDir;

  Component(this.componentName, this.isDir);
  List<Component> files = [];
}
