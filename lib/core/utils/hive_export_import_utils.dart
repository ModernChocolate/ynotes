import 'dart:convert';
import 'dart:io';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:hive/hive.dart';
import 'file_utils.dart';
import 'logging_utils.dart';

class HiveBackUpManager {
  Box? box;
  final String? subBoxName;
  final dataToImport;
  HiveBackUpManager(this.box, {this.subBoxName, this.dataToImport});
  export() {
    try {
      CustomLogger.log("HIVE EXP. IMP. UTILS", "Exporting data");
      //getting map
      Map map = this.box!.toMap();
      var data;
      if (subBoxName != null) {
        data = map[subBoxName];
        CustomLogger.log("HIVE EXP. IMP. UTILS", "Box data runtime type: ${data.runtimeType}");
        if (data.runtimeType.toString().contains("LinkedHashMap")) {
          data = Map<dynamic, dynamic>.from(data);
        }
      } else {
        data = map;
      }

      //Encoded JSON
      String encoded = jsonEncode(data);

      return encoded;
    } catch (e) {
      CustomLogger.log("HIVE EXP. IMP. UTILS", "An error occured while exporting data");
      CustomLogger.error(e);
      throw "Failed to export a box :" + e.toString();
    }
  }

  import() async {
    assert(this.dataToImport != null, "Data to import can't be null");
    //Old values
    Map map = Map();
    if (this.box != null) {
      map = this.box!.toMap();

      //New values (back up values)
      var data = this.dataToImport;

      if (subBoxName != null) {
        if (data.runtimeType.toString().contains("List")) {
          var oldData = map[subBoxName];
          //Try to merge the two lists
          if (oldData != null && oldData.runtimeType.toString().contains("List")) {
            CustomLogger.log("HIVE EXP. IMP. UTILS", "Merging lists");
            List finalData = oldData;
            data.forEach((dataElement) {
              if (!finalData.any((finalDataElement) => dataElement.id == finalDataElement.id)) {
                finalData.add(dataElement);
              }
            });

            data = finalData;
          }
        }
        await this.box!.delete(subBoxName);
        await this.box!.put(subBoxName, data);
      } else {
        //Concatenate
        Map finalMap = {
          ...map,
          ...data,
        };

        await this.box!.clear();

        await this.box!.putAll(finalMap);
      }
    }
    CustomLogger.log("HIVE EXP. IMP. UTILS", "Imported data");
  }

  writeBackUpFile(String data) async {
    //Write a temporary file
    final directory = await FolderAppUtil.getTempDirectory();
    final File file = File('${directory.path}/backup.json');
    await file.writeAsString(data, mode: FileMode.write);
    //request to save a new file
    final params = SaveFileDialogParams(sourceFilePath: file.path);
    await FlutterFileDialog.saveFile(params: params);
    await file.delete();
  }

  getBackUpFileData() async {
    final params = OpenFileDialogParams(
      dialogType: OpenFileDialogType.document,
    );
    final filePath = await (FlutterFileDialog.pickFile(params: params) as Future<String>);
    final File file = File(filePath);
    String data = await file.readAsString();
    return data;
  }
}