import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';

List<String> archiveFiles = [];
Map<String, ArchiveFile> filesMap = Map();

class DecodeParam {
  final String file;
  final SendPort sendPort;
  DecodeParam(this.file, this.sendPort);
}

void decode(DecodeParam param) {
  archiveFiles.clear();
  List<int> bytes = new File(param.file).readAsBytesSync();

  // Decode the Zip file
  Archive archive = new ZipDecoder().decodeBytes(bytes);

  // Extract the contents of the Zip archive to disk.
  for (ArchiveFile file in archive) {
    String filename = file.name;
    filesMap[filename] = file;
    archiveFiles.add(filename);
    print('$archiveFiles $filename');
    if (file.isFile) {
      List<int> data = file.content;
      // new File('out/' + filename)
      //   ..createSync(recursive: true)
      //   ..writeAsBytesSync(data);
    } else {
      // new Directory('out/' + filename)
      //   ..create(recursive: true);
    }
  }

  //param.sendPort.send(archiveFiles);
  param.sendPort.send(filesMap);
}

class DecompressedArchiveDetails extends StatefulWidget {
  final String path;

  const DecompressedArchiveDetails({Key key, this.path}) : super(key: key);

  @override
  _DecompressedArchiveDetailsState createState() =>
      _DecompressedArchiveDetailsState();
}

class _DecompressedArchiveDetailsState
    extends State<DecompressedArchiveDetails> {
  String title;

  @override
  void initState() {
    super.initState();

    var split = widget.path.split('/');

    title = split[split.length - 1];
    print(title);
    //_decodeArchive(widget.path);
    archiveFiles.clear();
    _decode();
  }

  _decode() async {
    ReceivePort receivePort = new ReceivePort();

    await Isolate.spawn(
        decode, new DecodeParam(widget.path, receivePort.sendPort));

    // Get the processed image from the isolate.
    var image = await receivePort.first;
    setState(() {
      print(archiveFiles);
    });
    print(image);
    setState(() {
      //archiveFiles = image;
      filesMap = image;
    });
  }

  _decodeArchive(String filePath) {
    archiveFiles.clear();
    List<int> bytes = new File(filePath).readAsBytesSync();

    // Decode the Zip file
    Archive archive = new ZipDecoder().decodeBytes(bytes);

    // Extract the contents of the Zip archive to disk.
    for (ArchiveFile file in archive) {
      String filename = file.name;
      setState(() {
        archiveFiles.add(filename);
      });
      print(filename);
      if (file.isFile) {
        List<int> data = file.content;
        // new File('out/' + filename)
        //   ..createSync(recursive: true)
        //   ..writeAsBytesSync(data);
      } else {
        // new Directory('out/' + filename)
        //   ..create(recursive: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0.0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          title,
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: filesMap.length != 0
          ? ListView.builder(
              shrinkWrap: true,
              itemCount: filesMap.length,
              itemBuilder: (BuildContext context, int index) {
                String key = filesMap.keys.elementAt(index);
                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 24.0, right: 8.0),
                  leading: Icon(
                    filesMap[key].isFile
                        ? Icons.insert_drive_file
                        : Icons.folder_open,
                    color: Colors.grey[700],
                  ),
                  title: Text(key),
                  subtitle: filesMap[key].size < 1000
                      ? Text('${filesMap[key].size} Bytes')
                      : (filesMap[key].size > 1000 &&
                              filesMap[key].size < 1000000)
                          ? Text('${(filesMap[key].size / 1024).round()} KB')
                          : Text(
                              '${(filesMap[key].size / 1048576).round()} MB'),
                  trailing: PopupMenuButton(
                    itemBuilder: (BuildContext context) {
                      return [
                        new PopupMenuItem<String>(
                            child: new Text('Extract'), value: 'Extract'),
                        new PopupMenuItem<String>(
                            child: new Text('Info'), value: 'Info'),
                      ];
                    },
                    icon: Icon(Icons.arrow_drop_down),
                    onSelected: (value) {
                      print(value);
                      if (value == 'Info') {
                        _showFileInfoDialog(filesMap[key]);
                      }
                    },
                  ),
                  onTap: () {
                    _showFileInfoDialog(filesMap[key]);
                  },
                );
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

  showLoading({@required String message, @required BuildContext context}) {
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

  _showFileInfoDialog(ArchiveFile file) {
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
            content: ListView(
              shrinkWrap: true,
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
