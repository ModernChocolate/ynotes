import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ynotes/core/logic/modelsExporter.dart';
import 'package:ynotes/core/utils/fileUtils.dart';
import 'package:ynotes/globals.dart';

///Class download to notify view when download is ended
class DownloadController extends ChangeNotifier {
  bool _isDownloading = false;
  double? _progress = 0;
  get downloadProgress => _progress;
  get isDownloading => _isDownloading;

  download(Document document) async {
    _isDownloading = true;
    _progress = null;
    String? filename = document.documentName;
    notifyListeners();
    Request request = await appSys.api!.downloadRequest(document);
    //Make a response client
    final StreamedResponse response = await Client().send(request);
    final contentLength = response.contentLength;
    // final contentLength = double.parse(response.headers['x-decompressed-content-length']);

    _progress = 0;
    notifyListeners();
    print("Downloading a file : $filename");

    List<int> bytes = [];
    final file = await FileAppUtil.getFilePath(filename);
    response.stream.listen(
      (List<int> newBytes) {
        bytes.addAll(newBytes);
        final downloadedLength = bytes.length;
        _progress = downloadedLength / contentLength!;

        notifyListeners();
      },
      onDone: () async {
        _progress = 100;
        notifyListeners();
        print("Téléchargement du fichier terminé : ${file.path}");
        final dir = await FolderAppUtil.getDirectory(download: true);
        final Directory _appDocDirFolder = Directory('$dir/yNotesDownloads/');

        if (!await _appDocDirFolder.exists()) {
          //if folder already exists return path
          final Directory _appDocDirNewFolder = await _appDocDirFolder.create(recursive: true);
        } //if folder not exists create folder and then return its path

        await file.writeAsBytes(bytes);
      },
      onError: (e) {
        print("Downloading file error : $e, on $filename");
      },
      cancelOnError: true,
    );
  }

//Download a file in the app directory
  ///Check if file exists
  Future<bool> fileExists(filename) async {
    try {
      if (await Permission.storage.request().isGranted) {
        final dir = await FolderAppUtil.getDirectory(download: true);
        FolderAppUtil.createDirectory("$dir/yNotesDownloads/");
        Directory downloadsDir = Directory("$dir/yNotesDownloads/");
        List<FileSystemEntity> list = downloadsDir.listSync();
        bool toReturn = false;
        await Future.forEach(list, (dynamic element) async {
          if (filename == await FileAppUtil.getFileNameWithExtension(element)) {
            toReturn = true;
          }
        });
        return toReturn;
      } else {
        print("Not granted");
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
