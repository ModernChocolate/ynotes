import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:ynotes/core/apis/Pronote/PronoteAPI.dart';
import 'package:ynotes/core/apis/Pronote/converters/polls.dart';
import 'package:ynotes/core/apis/Pronote/convertersExporter.dart';
import 'package:ynotes/core/apis/model.dart';
import 'package:ynotes/core/apis/utils.dart';
import 'package:ynotes/core/logic/modelsExporter.dart';
import 'package:ynotes/core/logic/shared/loginController.dart';
import 'package:ynotes/core/offline/data/agenda/lessons.dart';
import 'package:ynotes/core/offline/data/disciplines/disciplines.dart';
import 'package:ynotes/core/offline/data/homework/homework.dart';
import 'package:ynotes/core/offline/data/polls/polls.dart';
import 'package:ynotes/core/offline/offline.dart';
import 'package:ynotes/core/utils/nullSafeMapGetter.dart';
import 'package:ynotes/globals.dart';
import 'package:ynotes/usefulMethods.dart';

class PronoteMethod {
  Map locks = Map();
  PronoteClient? client;
  final Offline _offlineController;

  PronoteMethod(this.client, this._offlineController);

  Future<List<SchoolAccount>?> accounts() async {}

  Future<List<CloudItem>?> cloudFolders() async {}

  Future<dynamic> fetchAnyData(dynamic onlineFetch, dynamic offlineFetch, String lockName,
      {bool forceFetch = false, isOfflineLocked = false, dynamic onlineArguments, dynamic offlineArguments}) async {
    //Test connection status
    var connectivityResult = await (Connectivity().checkConnectivity());
    //Offline
    if (connectivityResult == ConnectivityResult.none && !isOfflineLocked) {
      return await (offlineArguments != null ? offlineFetch(offlineArguments) : offlineFetch());
    } else if (forceFetch && !isOfflineLocked) {
      try {
        await onlineFetchWithLock(onlineFetch, lockName, arguments: onlineArguments);
        return await offlineFetch();
      } catch (e) {
        return await (offlineArguments != null ? offlineFetch(offlineArguments) : offlineFetch());
      }
    } else {
      //Offline data;
      var data;
      if (!isOfflineLocked) {
        data = await (offlineArguments != null ? offlineFetch(offlineArguments) : offlineFetch());
      }
      if (data == null) {
        print("Online fetch because offline is null");
        await onlineFetchWithLock(onlineFetch, lockName, arguments: onlineArguments);
        return await (offlineArguments != null ? offlineFetch(offlineArguments) : offlineFetch());
      }
      return data;
    }
  }

  Future<List<Discipline>> grades() async {
    List<PronotePeriod>? periods = this.client?.periods();
    List<Discipline> listDisciplines = [];
    if (periods != null) {
      await Future.forEach(periods, (PronotePeriod period) async {
        var jsonData = {
          'donnees': {
            'Periode': {'N': period.id, 'L': period.name}
          },
        };
        var temp = await request("DernieresNotes", PronoteDisciplineConverter.disciplines, data: jsonData, onglet: 198);
        temp.forEach((Discipline element) {
          element.periodName = period.name;
          element.periodCode = period.id;
        });
        listDisciplines.addAll(temp);
        listDisciplines = await refreshDisciplinesListColors(listDisciplines);
      });
    }
    print("Completed disciplines request");

    await DisciplinesOffline(_offlineController).updateDisciplines(listDisciplines);

    appSys.updateSetting(appSys.settings!["system"], "lastGradeCount",
        (getAllGrades(listDisciplines, overrideLimit: true) ?? []).length);
    return listDisciplines;
  }

  Future<List<Homework>?> homeworkFor(DateTime date) async {
    var jsonData = {
      'donnees': {
        'domaine': {'_T': 8, 'V': "[${await getWeek(date)}..${await getWeek(date)}]"}
      },
    };
    List<Homework>? hw =
        await request("PageCahierDeTexte", PronoteHomeworkConverter.homework, data: jsonData, onglet: 88);
    (hw ?? []).removeWhere((element) => element.date != date);
    if (hw != null) {
      await HomeworkOffline(_offlineController).updateHomework(hw);
    }
    return hw;
  }

  Future<List<Lesson>?> lessons(DateTime dateFrom, {DateTime? dateTo}) async {
    List<Lesson>? lessons = [];
    var user = mapGet(client?.paramsUser, ['donneesSec', 'donnees', 'ressource']) ?? "";
    Map jsonData = {
      "donnees": {
        "ressource": user,
        "avecAbsencesEleve": false,
        "avecConseilDeClasse": true,
        "estEDTPermanence": false,
        "avecAbsencesRessource": true,
        "avecDisponibilites": true,
        "avecInfosPrefsGrille": true,
        "Ressource": user,
      }
    };
    var firstWeek = await getWeek(dateFrom);
    if (dateTo == null) {
      dateTo = dateFrom;
    }
    var lastWeek = await getWeek(dateTo);
    for (int week = firstWeek; week < (lastWeek + 1); week++) {
      jsonData["donnees"]["NumeroSemaine"] = week;
      jsonData["donnees"]["numeroSemaine"] = week;
      List<Lesson> newLessons =
          await request("PageEmploiDuTemps", PronoteLessonsConverter.lessons, data: jsonData, onglet: 16);
      lessons.addAll(newLessons);
      await LessonsOffline(_offlineController).updateLessons(newLessons, week);
    }

    return lessons;
  }

  nextHomework() async {
    DateTime now = DateTime.now();
    List<Homework> listHW = [];
    final f = new DateFormat('dd/MM/yyyy');
    var dateTo = f.parse(this.client?.funcOptions['donneesSec']['donnees']['General']['DerniereDate']['V']);
    var jsonData = {
      'donnees': {
        'domaine': {'_T': 8, 'V': "[${await getWeek(now)}..${await getWeek(dateTo)}]"}
      },
    };
    List<Homework>? hws =
        await request("PageCahierDeTexte", PronoteHomeworkConverter.homework, data: jsonData, onglet: 88);
    hws?.removeWhere((element) => element.date == null && element.date!.isBefore(now));

    listHW.addAll(hws ?? []);
    await HomeworkOffline(_offlineController).updateHomework(listHW);

    return listHW;
  }

  onlineFetchWithLock(dynamic onlineFetch, lockName, {dynamic arguments}) async {
    int req = 0;
    //Time out of 20 seconds. Wait until the task is unlocked
    while (testLock(lockName) && req < 10) {
      req++;
      await Future.delayed(const Duration(seconds: 2), () => "1");
    }
    if (!locks[lockName]) {
      try {
        //Lock current function
        locks[lockName] = true;
        print("Fetching task with name " + lockName);
        var toReturn = await (arguments != null ? onlineFetch(arguments) : onlineFetch());
        //Unlock it
        locks[lockName] = false;
        return toReturn;
      } catch (e) {
        print("Error while fetching for " + (lockName ?? "") + " " + e.toString());
        locks[lockName] = false;
        if (!testLock("recursive_" + lockName)) {
          print("Refreshing client");
          locks["recursive_" + lockName] = true;
        }
      }
    } else {
      return null;
    }
  }

  //Test if another concurrent task is not running
  Future<List<PollInfo>?> polls() async {
    List<PollInfo>? polls = await request("PageActualites", PronotePollsConverter.polls, data: {}, onglet: 8);
    await PollsOffline(_offlineController).update(polls);
  }

  refreshClient() async {
    if (appSys.loginController.actualState != loginStatus.loggedIn) {
      await appSys.loginController.login();
      //reset all recursives
      if (appSys.loginController.actualState == loginStatus.loggedIn) {
        //reset every locks
        locks.keys.forEach((element) {
          locks[element] = false;
        });
      }
    }
  }

  Future<dynamic> request(String functionName, Function? converter, {var data, var customURL, int? onglet}) async {
    data = Map.from(data);
    if (onglet != null && appSys.currentSchoolAccount != null && !appSys.account!.isParentMainAccount)
      data['_Signature_'] = {'onglet': onglet};
    //If it is a parent account
    if (onglet != null && appSys.currentSchoolAccount != null && appSys.account!.isParentMainAccount) {
      data['_Signature_'] = {
        'onglet': onglet,
        'membre': {'N': appSys.currentSchoolAccount!.studentID, 'G': 4}
      };
    }
    if (converter != null) {
      return await converter(this.client, await this.client?.communication!.post(functionName, data: data));
    } else {
      return await this.client?.communication!.post(functionName, data: data);
    }
  }

  testLock(String key) {
    if (locks.containsKey(key)) {
      return locks[key];
    } else {
      locks[key] = false;
      return false;
    }
  }
}
