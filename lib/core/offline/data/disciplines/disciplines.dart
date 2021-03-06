import 'package:ynotes/core/logic/modelsExporter.dart';
import 'package:ynotes/core/offline/offline.dart';
import 'package:ynotes/usefulMethods.dart';

class DisciplinesOffline {
  late Offline parent;
  DisciplinesOffline(Offline _parent) {
    parent = _parent;
  }
  //Used to get disciplines, from db or locally
  Future<List<Discipline>?> getDisciplines() async {
    try {
      return await parent.offlineBox?.get("disciplines").cast<Discipline>();
    } catch (e) {
      print("Error while returning disciplines" + e.toString());
      return null;
    }
  }

  ///Get periods from DB (a little bit messy but totally functional)
  getPeriods() async {
    try {
      List<Period> listPeriods = [];
      List<Discipline>? disciplines = await getDisciplines();
      List<Grade>? grades = getAllGrades(disciplines, overrideLimit: true);
      grades?.forEach((grade) {
        if (!listPeriods.any((period) => period.name == grade.periodName || period.id == grade.periodCode)) {
          if (grade.periodName != null && grade.periodName != "") {
            listPeriods.add(Period(grade.periodName, grade.periodCode));
          } else {}
        } else {}
      });
      try {
        listPeriods.sort((a, b) => a.name!.compareTo(b.name!));
      } catch (e) {
        print(e);
      }
      return listPeriods;
    } catch (e) {
      throw ("Error while collecting offline periods " + e.toString());
    }
  }

  ///Update existing disciplines (clear old data) with passed data
  updateDisciplines(List<Discipline> newData) async {
    try {
      print("Updating disciplines");
      await parent.offlineBox?.delete("disciplines");
      await parent.offlineBox?.put("disciplines", newData);
    } catch (e) {
      print("Error while updating disciplines " + e.toString());
    }
  }
}
