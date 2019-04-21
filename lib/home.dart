import 'dart:io';

import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_document_picker/flutter_document_picker.dart';

import 'decompressed_archive.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String path;

  PermissionStatus permissionStatus;

  List<String> archiveFiles = [];

  FlutterDocumentPickerParams params = FlutterDocumentPickerParams(
      allowedFileExtensions: ['zip'], allowedMimeType: 'application/*');

  @override
  void initState() {
    super.initState();
    _getPath();
  }

  _getPath() async {
    Directory appDocDir = await getExternalStorageDirectory();
    String appDocPath = appDocDir.path;
    print(appDocPath);

    if (mounted) {
      setState(() {
        path = appDocPath;
      });
    }
  }

  _getPermissionStatus() async {
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
    print(permission);
    permissionStatus = permission;
  }

  _requestPermission() async {
    final List<PermissionGroup> permissions = <PermissionGroup>[
      PermissionGroup.storage
    ];
    final Map<PermissionGroup, PermissionStatus> permissionRequestResult =
        await PermissionHandler().requestPermissions([PermissionGroup.storage]);

    setState(() {
      permissionStatus = permissionRequestResult[permissions];
      print(permissionStatus);
    });

    await _getPermissionStatus();
  }

  _chooseFile() async {
    //String path = await DocumentChooser.chooseDocument();
    final path = await FlutterDocumentPicker.openDocument(params: params)
        .catchError((error) {
      print(error.message);
      _showInfoDialog();
    });

    if (path != null) {
      print(path);

      Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context){
        return DecompressedArchiveDetails(path: path,);
      }));
    }
  }

  _decodeArchive(String filePath) {
    archiveFiles.clear();
    List<int> bytes =
        new File(filePath).readAsBytesSync();

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

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Archive Manager',
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Colors.black,
              size: 18.0,
            ),
            onPressed: () {
              _showInfoDialog();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ListTile(
              leading: Icon(
                Icons.info,
              ),
              title: Text('Open a file to continue'),
            ),
            FlatButton.icon(
              color: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0)),
              icon: Icon(
                Icons.insert_drive_file,
                color: Colors.white,
              ),
              label: Text(
                'Open',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                if(permissionStatus == PermissionStatus.granted){
                  //_decodeArchive();
                  _chooseFile();
                } else {
                  print('Storage permissions are not granted');
                  _requestPermission();
                }
              },
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: archiveFiles.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(archiveFiles[index]),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  _showInfoDialog() {
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
                'About',
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
            content: Text(
              'Currently this app supports only Zip, Tar, BZip2, GZip, Zlib formats',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          );
        });
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
              title: Text('$message', style: TextStyle(fontSize: 18.0),),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),);
        });
  }
}
