import 'dart:async';
import 'dart:io';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ynotes/core/apis/model.dart';
import 'package:ynotes/core/apis/utils.dart';
import 'package:ynotes/core/logic/models_exporter.dart';
import 'package:ynotes/core/offline/data/agenda/reminders.dart';
import 'package:ynotes/core/offline/offline.dart';
import 'package:ynotes/core/services/platform.dart';
import 'package:ynotes/core/utils/file_utils.dart';
import 'package:ynotes/core/utils/logging_utils.dart';
import 'package:ynotes/core/utils/theme_utils.dart';
import 'package:ynotes/globals.dart';
import 'package:ynotes/ui/components/dialogs.dart';
import 'package:ynotes/ui/screens/agenda/widgets/agenda.dart';
import 'package:ynotes/useful_methods.dart';

///The notifications class
class AppNotification {
  static Future<void> callback() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    List<Lesson>? lessons = [];
    //Lock offline data
    Offline _offline = Offline();
    API api = apiManager(_offline);
    //Login creds
    String? u = await readStorage("username");
    String? p = await readStorage("password");
    String? url = await readStorage("pronoteurl");
    String? cas = await readStorage("pronotecas");
    if (connectivityResult != ConnectivityResult.none) {
      try {
        await api.login(u, p, additionnalSettings: {
          "url": url,
          "cas": cas,
        });
      } catch (e) {
        CustomLogger.log("NOTIFICATIONS", "An error occured while logging in");
        CustomLogger.error(e);
      }
    }
    var date = DateTime.now();
    int week = await getWeek(date);
    final dir = await FolderAppUtil.getDirectory();
    Hive.init("${dir.path}/offline");
    //Register adapters once
    try {
      Hive.registerAdapter(GradeAdapter());
      Hive.registerAdapter(DisciplineAdapter());
      Hive.registerAdapter(DocumentAdapter());
      Hive.registerAdapter(LessonAdapter());
      Hive.registerAdapter(PollInfoAdapter());
    } catch (e) {
      CustomLogger.log("NOTIFICATIONS", "An error occured while registering adapter");
      CustomLogger.error(e);
    }
    if (connectivityResult == ConnectivityResult.none || !api.loggedIn) {
      Box _offlineBox = await Hive.openBox("offlineData");
      var offlineLessons = await _offlineBox.get("lessons");
      if (offlineLessons[week] != null) {
        lessons = offlineLessons[week].cast<Lesson>();
      }
    } else if (api.loggedIn) {
      try {
        lessons = await (api.getNextLessons(date) as Future<List<Lesson>>);
      } catch (e) {
        CustomLogger.log("NOTIFICATIONS", "An error occured collecting online lessons");
        CustomLogger.error(e);

        Box _offlineBox = await Hive.openBox("offlineData");
        var offlineLessons = await _offlineBox.get("lessons");
        if (offlineLessons[week] != null) {
          lessons = offlineLessons[week].cast<Lesson>();
        }
      }
    }
    Lesson? currentLesson = getCurrentLesson(lessons);
    Lesson? nextLesson = getNextLesson(lessons);
    Lesson? lesson;
    //Show next lesson if this one is after current datetime
    if (nextLesson != null && nextLesson.start!.isAfter(DateTime.now())) {
      if (appSys.settings.user.agendaPage.enableDNDWhenOnGoingNotifEnabled) {
        AndroidPlatformChannel.enableDND();
      }
      lesson = nextLesson;
      await showOngoingNotification(lesson);
    } else {
      final prefs = await (SharedPreferences.getInstance());
      bool? value = prefs.getBool("disableAtDayEnd");
      CustomLogger.log("NOTIFICATIONS", "disableAtDayEnd (prefs): $value");
      CustomLogger.log(
          "NOTIFICATIONS", "disableAtDayEnd (settings): ${appSys.settings.user.agendaPage.disableAtDayEnd}");
      appSys.saveSettings();
      if (appSys.settings.user.agendaPage.disableAtDayEnd) {
        await cancelOnGoingNotification();
      } else {
        lesson = currentLesson;
        await showOngoingNotification(lesson);
      }
    }
    //Logs for tests
    if (lesson != null) {
      CustomLogger.saveLog(
          object: "NOTIFICATIONS",
          text:
              "Persistant notification next lesson callback triggered for the lesson ${lesson.disciplineCode} ${lesson.room}");
    } else {
      CustomLogger.saveLog(
          object: "NOTIFICATIONS", text: "Persistant notification next lesson callback triggered : you are in break.");
    }
  }

//Chose which triggered action to use
  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
    CustomLogger.log("NOTIFICATIONS", "Unscheduled $id");
  }

  static Future<void> cancelOnGoingNotification() async {
    await cancelNotification(333);
    CustomLogger.log("NOTIFICATIONS", "Cancelled on going notification");
  }

  static getRelatedAction(
      ReceivedNotification receivedNotification, BuildContext context, Function navigatorCallback) async {
    if (receivedNotification.channelKey == "newmail" && receivedNotification.toMap()["buttonKeyPressed"] == "REPLY") {
      CustomDialogs.writeModalBottomSheet(context,
          defaultListRecipients: [
            Recipient(receivedNotification.payload!["name"], receivedNotification.payload!["surname"],
                receivedNotification.payload!["id"], receivedNotification.payload!["isTeacher"] == "true", null)
          ],
          defaultSubject: receivedNotification.payload!["subject"]);
      return;
    }

    if (receivedNotification.channelKey == "newmail" && receivedNotification.toMap()["buttonKeyPressed"] != null) {
      navigatorCallback(4);
      return;
    }

    if (receivedNotification.channelKey == "newgrade" && receivedNotification.toMap()["buttonKeyPressed"] != null) {
      navigatorCallback(3);
      return;
    }
    if (receivedNotification.channelKey == "persisnotif" &&
        receivedNotification.toMap()["buttonKeyPressed"] == "REFRESH") {
      await AppNotification.setOnGoingNotification();
      return;
    }
    if (receivedNotification.channelKey == "persisnotif" &&
        receivedNotification.toMap()["buttonKeyPressed"] == "KILL") {
      appSys.settings.user.agendaPage.agendaOnGoingNotification = false;
      appSys.saveSettings();

      await AppNotification.cancelOnGoingNotification();
      return;
    }
  }

  static initNotifications(BuildContext context, Function navigatorCallback) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      AwesomeNotifications().initialize(null, [
        NotificationChannel(
            channelKey: 'alarm',
            defaultPrivacy: NotificationPrivacy.Private,
            channelName: 'Alarmes',
            importance: NotificationImportance.High,
            channelDescription: "Alarmes et rappels de l'application yNotes",
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.white)
      ]);
      try {
        AwesomeNotifications().actionStream.listen((receivedNotification) async {
          await getRelatedAction(receivedNotification, context, navigatorCallback);
        });
      } catch (e) {}
    }
  }

  static Future<void> scheduleAgendaReminders(AgendaEvent event) async {
    try {
      AwesomeNotifications().initialize(null, [
        NotificationChannel(
            icon: 'resource://drawable/calendar',
            channelKey: 'alarm',
            channelName: 'Alarmes',
            channelDescription: 'Alarmes',
            defaultColor: ThemeUtils.spaceColor(),
            ledColor: Colors.white),
      ]);

      //Unschedule existing
      if (event.alarm == AlarmType.none) {
      } else {
        //delay between task start and task end
        Duration delay = Duration();
        if (event.alarm == AlarmType.exactly) {
          delay = Duration.zero;
        }
        if (event.alarm == AlarmType.fiveMinutes) {
          delay = Duration(minutes: 5);
        }
        if (event.alarm == AlarmType.fifteenMinutes) {
          delay = Duration(minutes: 15);
        }
        if (event.alarm == AlarmType.thirtyMinutes) {
          delay = Duration(minutes: 30);
        }
        if (event.alarm == AlarmType.oneDay) {
          delay = Duration(days: 1);
        }
        String time = DateFormat("HH:mm").format(event.start!);
        await AwesomeNotifications().createNotification(
            content: NotificationContent(
                id: event.id.hashCode,
                channelKey: 'alarm',
                title: (event.name ?? "(Sans titre)") + " à $time",
                body: event.description,
                notificationLayout: parse(event.description).documentElement!.text.length < 49
                    ? NotificationLayout.Default
                    : NotificationLayout.BigText),
            schedule: NotificationCalendar.fromDate(date: event.start!.subtract(delay).toUtc()));
        CustomLogger.log("NOTIFICATIONS",
            "Scheduled an alarm" + event.start!.subtract(delay).toString() + " " + event.id.hashCode.toString());
      }
    } catch (e) {
      CustomLogger.log("NOTIFICATIONS", "An error occured while scheduling agenda reminders");
      CustomLogger.error(e);
    }
  }

  static Future<void> scheduleReminders(AgendaEvent event) async {
    await AwesomeNotifications().initialize('resource://drawable/clock', [
      NotificationChannel(
          channelKey: 'reminder',
          defaultPrivacy: NotificationPrivacy.Public,
          channelShowBadge: true,
          channelName: 'Rappel pour un évènement',
          importance: NotificationImportance.High,
          defaultColor: ThemeUtils.spaceColor(),
          ledColor: Colors.white)
    ]);
    List<AgendaReminder> reminders =
        await (RemindersOffline(appSys.offline).getReminders(event.lesson!.id)) as List<AgendaReminder>;
    await Future.forEach(reminders, (AgendaReminder rmd) async {
      //Unschedule existing
      if (rmd.alarm == AlarmType.none) {
        await cancelNotification(event.id.hashCode);
      } else {
        //delay between task start and task end
        Duration delay = Duration();
        if (rmd.alarm == AlarmType.exactly) {
          delay = Duration.zero;
        }
        if (rmd.alarm == AlarmType.fiveMinutes) {
          delay = Duration(minutes: 5);
        }
        if (rmd.alarm == AlarmType.fifteenMinutes) {
          delay = Duration(minutes: 15);
        }
        if (rmd.alarm == AlarmType.thirtyMinutes) {
          delay = Duration(minutes: 30);
        }
        if (rmd.alarm == AlarmType.oneDay) {
          delay = Duration(days: 1);
        }
        String text = "Rappel relié à l'évènement ${event.name} : \n <b>${rmd.name}</b> ${rmd.description}";
        CustomLogger.log("NOTIFICATIONS", "Event will start in ${event.start!.subtract(delay)}");
        CustomLogger.log("NOTIFICATIONS", text);

        await AwesomeNotifications().createNotification(
            content: NotificationContent(
                id: rmd.id.hashCode,
                channelKey: 'reminder',
                title: "Rappel d'évènement",
                body: text,
                notificationLayout:
                    event.description!.length < 49 ? NotificationLayout.Default : NotificationLayout.BigText),
            schedule: NotificationCalendar.fromDate(date: event.start!.subtract(delay).toUtc()));
      }
    });
  }

  ///Set an on going notification which is automatically refreshed (online or not) each hour
  static Future<void> setOnGoingNotification({bool dontShowActual = false}) async {
    //Logs for tests
    CustomLogger.saveLog(object: "NOTIFICATIONS", text: "Setting on going notification.");
    var connectivityResult = await (Connectivity().checkConnectivity());
    List<Lesson>? lessons = [];
    API api = apiManager(appSys.offline);
    //Login creds
    String? u = await readStorage("username");
    String? p = await readStorage("password");
    String? url = await readStorage("pronoteurl");
    String? cas = await readStorage("pronotecas");
    if (connectivityResult != ConnectivityResult.none) {
      try {
        await api.login(u, p, additionnalSettings: {
          "url": url,
          "cas": cas,
        });
      } catch (e) {
        CustomLogger.log("NOTIFICATIONS", "An error occured while logging in");
        CustomLogger.error(e);
      }
    }
    var date = DateTime.now();
    int week = await getWeek(date);
    final dir = await FolderAppUtil.getDirectory();
    Hive.init("${dir.path}/offline");
    //Register adapters once
    try {
      Hive.registerAdapter(LessonAdapter());
      Hive.registerAdapter(GradeAdapter());
      Hive.registerAdapter(DisciplineAdapter());
      Hive.registerAdapter(DocumentAdapter());
      Hive.registerAdapter(HomeworkAdapter());
      Hive.registerAdapter(PollInfoAdapter());
    } catch (e) {
      CustomLogger.log("NOTIFICATIONS", "An error occured while registering adapter");
      CustomLogger.error(e);
    }
    if (connectivityResult == ConnectivityResult.none || !api.loggedIn) {
      Box _offlineBox = await Hive.openBox("agenda");
      var offlineLessons = await _offlineBox.get("lessons");
      if (offlineLessons[week] != null) {
        lessons = offlineLessons[week].cast<Lesson>();
      }
    } else if (api.loggedIn) {
      try {
        lessons = await (api.getNextLessons(date) as Future<List<Lesson>>);
      } catch (e) {
        CustomLogger.log("NOTIFICATIONS", "An error occured while collecting online lessons");
        CustomLogger.error(e);

        Box _offlineBox = await Hive.openBox("offlineData2");
        var offlineLessons = await _offlineBox.get("lessons");
        if (offlineLessons[week] != null) {
          lessons = offlineLessons[week].cast<Lesson>();
        }
      }
    }
    if (appSys.settings.user.agendaPage.agendaOnGoingNotification) {
      Lesson? getActualLesson = getCurrentLesson(lessons);
      if (!dontShowActual) {
        if (appSys.settings.user.agendaPage.enableDNDWhenOnGoingNotifEnabled) {
          AndroidPlatformChannel.enableDND(); // Turn on DND - All notifications are suppressed.
        }
        await showOngoingNotification(getActualLesson);
      }

      int? minutes;

      await Future.forEach(lessons!, (Lesson lesson) async {
        if (lesson.start!.isAfter(date)) {
          try {
            if (await AndroidAlarmManager.oneShotAt(
                lesson.start!.subtract(Duration(minutes: minutes ?? 15)), lesson.start.hashCode, callback,
                allowWhileIdle: true, rescheduleOnReboot: true))
              CustomLogger.log(
                  "NOTIFICATIONS", "Scheduled " + lesson.start.hashCode.toString() + " $minutes minutes before.");
          } catch (e) {
            CustomLogger.log("NOTIFICATIONS", "An error occured while scheduling lesson notification");
            CustomLogger.error(e);
          }
        }
      });
      try {
        if (await AndroidAlarmManager.oneShotAt(
            lessons.last.end!.subtract(Duration(minutes: minutes ?? 15)), lessons.last.end.hashCode, callback,
            allowWhileIdle: true, rescheduleOnReboot: true)) CustomLogger.log("NOTIFICATIONS", "Scheduled last lesson");
      } catch (e) {
        CustomLogger.log("NOTIFICATIONS", "An error occured while scheduling last lesson");
        CustomLogger.error(e);
      }
    }
  }

  ///Shows a debug notification, useful for development purposes
  static showDebugNotification() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
          channelKey: 'debug',
          defaultPrivacy: NotificationPrivacy.Public,
          channelShowBadge: true,
          channelName: 'Notification de déboguage',
          importance: NotificationImportance.High,
          channelDescription: "Notification à usage de développement",
          defaultColor: ThemeUtils.spaceColor(),
          ledColor: Colors.white)
    ]);

    AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: 0,
      channelKey: 'debug',
      title: 'Notification de test',
      notificationLayout: NotificationLayout.BigText,
      body: "Si vous voyez cette notification, alors yNotes est bien autorisé à vous envoyer des notifications.",
    ));
  }

  static Future<void> showLoadingNotification(int id) async {
    AwesomeNotifications().initialize(null, [
      NotificationChannel(
          icon: 'resource://drawable/appicon',
          channelKey: 'loading',
          channelName: 'Chargement',
          channelDescription: 'Indicateur des chargements de yNotes',
          defaultColor: ThemeUtils.spaceColor(),
          importance: NotificationImportance.Min,
          ledColor: Colors.white),
    ]);
    /*if (Platform.isIOS) {
      if (await Permission.notification.request().isGranted)
        await AwesomeNotifications().createNotification(
            content: NotificationContent(
                id: id,
                channelKey: 'loading',
                title: "Rafraichissement des données",
                notificationLayout: NotificationLayout.ProgressBar));
    }*/
    if (Platform.isAndroid) {
      await AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: id,
              channelKey: 'loading',
              title: "Rafraichissement des données",
              notificationLayout: NotificationLayout.ProgressBar,
              progress: null));
    }
  }

  static showNewGradeNotification(Grade grade) async {
    await AwesomeNotifications().initialize('resource://drawable/newgradeicon', [
      NotificationChannel(
          channelKey: 'newgrade',
          defaultPrivacy: NotificationPrivacy.Public,
          channelName: 'Nouvelle note',
          importance: NotificationImportance.High,
          groupKey: "gradesGroup",
          channelDescription: "Nouvelles notes",
          defaultColor: ThemeUtils.spaceColor(),
          ledColor: Colors.white)
    ]);

    AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: grade.hashCode,
          channelKey: 'newgrade',
          notificationLayout: NotificationLayout.BigText,
          title: "Nouvelle note",
          body: "<b>" +
              (grade.disciplineName ?? "(non défini)") +
              "</b><br>" +
              "Note:" +
              (grade.value ?? "N/A") +
              "/" +
              (grade.scale ?? "N/A") +
              "<br>" +
              "Moyenne de la classe:" +
              (grade.classAverage ?? "N/A") +
              "/" +
              (grade.scale ?? "N/A"),
          showWhen: false),
    );
  }

  static showNewMailNotification(Mail mail, String content) async {
    await AwesomeNotifications().initialize('resource://drawable/mail', [
      NotificationChannel(
          channelKey: 'newmail',
          defaultPrivacy: NotificationPrivacy.Public,
          channelShowBadge: true,
          channelName: 'Nouveau mail',
          importance: NotificationImportance.High,
          groupKey: "mailsGroup",
          channelDescription: "Nouveau mail",
          ledColor: Colors.white)
    ]);

    AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: int.parse(mail.id ?? ""),
          notificationLayout: parse(content).documentElement!.text.length < 49 ? null : NotificationLayout.BigText,
          channelKey: 'newmail',
          title: 'Nouveau mail de ${mail.from?["name"]}',
          summary: 'Nouveau mail de ${mail.from?["name"]}',
          body: content,
          payload: {
            "name": mail.from?["prenom"],
            "surname": mail.from?["nom"],
            "id": mail.id.toString(),
            "isTeacher": (mail.from?["type"] == "P").toString(),
            "subject": mail.subject ?? ""
          }),
      actionButtons: [
        NotificationActionButton(
            key: "REPLY", label: "Répondre", autoCancel: true, buttonType: ActionButtonType.Default),
      ],
    );
  }

  static Future<void> showOngoingNotification(Lesson? lesson) async {
    var id = 333;

    if (appSys.settings.user.agendaPage.agendaOnGoingNotification) {
      await AwesomeNotifications().initialize('resource://drawable/tfiche', [
        NotificationChannel(
            channelKey: 'persisnotif',
            defaultPrivacy: NotificationPrivacy.Public,
            channelName: 'Rappel de cours constant',
            importance: NotificationImportance.Low,
            channelDescription: "Notification persistante de cours",
            defaultColor: ThemeUtils.spaceColor(),
            ledColor: Colors.white,
            onlyAlertOnce: true)
      ]);

      String defaultSentence = "";
      if (lesson != null) {
        defaultSentence = 'Vous êtes en <b>${lesson.discipline}</b> dans la salle <b>${lesson.room}</b>';
        if (lesson.room == null || lesson.room == "") {
          defaultSentence = "Vous êtes en ${lesson.discipline}";
        }
      } else {
        defaultSentence = "Vous êtes en pause";
      }

      var sentence = defaultSentence;
      try {
        if (lesson!.canceled!) {
          sentence = "Votre cours a été annulé.";
        }
      } catch (e) {}
      try {
        CustomLogger.log(
            "NOTIFICATIONS", "Ongoing notification text length is ${parse(sentence).documentElement!.text.length}");
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id,
            notificationLayout: parse(sentence).documentElement!.text.length < 49 ? null : NotificationLayout.BigText,
            channelKey: 'persisnotif',
            title: 'Rappel de cours constant',
            body: sentence,
            locked: true,
            autoCancel: false,
          ),
          actionButtons: [
            NotificationActionButton(
                key: "REFRESH", label: "Actualiser", autoCancel: false, buttonType: ActionButtonType.KeepOnTop),
            NotificationActionButton(
                key: "KILL", label: "Désactiver", autoCancel: true, buttonType: ActionButtonType.Default),
          ],
        );
      } catch (e) {
        CustomLogger.log("NOTIFICATIONS", "An error occured while setting ongoing notification");
        CustomLogger.error(e);
      }
    }
  }

  static Future<void> showNewLessonCancellationNotification(Lesson? lesson) async {
    int id = 444;

    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
          channelKey: 'canceled',
          defaultPrivacy: NotificationPrivacy.Public,
          channelName: 'Cours annulé',
          importance: NotificationImportance.High,
          channelDescription: "Notification d'annulation de cours",
          defaultColor: ThemeUtils.spaceColor(),
          ledColor: Colors.red,
          onlyAlertOnce: true)
    ]);

    try {
      await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id,
            notificationLayout: NotificationLayout.Default,
            channelKey: 'canceled',
            title: 'Annulation de cours',
            body: 'Le cours de ${lesson!.discipline} de ${lesson
                .start!.hour}h${lesson.start!.minute} à ${lesson.end!.hour}h${lesson.end!.minute} a été annulé !',
            locked: false,
          )
      );
    }catch (e){
      CustomLogger.log("NOTIFICATIONS", "An error occurred while setting ongoin notification");
      CustomLogger.error(e);
    }
  }
}
