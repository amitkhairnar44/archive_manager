import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'decompressed_archive.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String path;

  PermissionStatus permissionStatus;

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
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Center(
              child: Text(
                'Open a file to continue',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8.0)),
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
                if (permissionStatus == PermissionStatus.granted) {
                  //_decodeArchive();
                  _chooseFile();
                } else {
                  print('Storage permissions are not granted');
                  _requestPermission();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getPath();
    _requestPermission();
  }

  _chooseFile() async {
    final path = await FilePicker.getFilePath(type: FileType.ANY);

    if (path != null) {
      print(path);

      var split = path.split('.');
      var extension = split[split.length - 1];
      print('Selected file extension : $extension');
      if (extension == 'zip' ||
          extension == 'tar' ||
          extension == 'gz' ||
          extension == 'bz2' ||
          extension == 'bzip2') {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (BuildContext context) {
          return DecompressedArchiveDetails(
            path: path,
          );
        }));
      }
    }
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
              style: TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
          );
        });
  }
}
