import 'package:ynotes/core/apis/model.dart';
import 'package:ynotes/core/logic/models_exporter.dart';
import 'package:ynotes/core/offline/offline.dart';
import 'package:ynotes/core/apis/utils.dart';
import 'package:ynotes/core/utils/logging_utils.dart';
import 'package:ynotes/core/services/notifications.dart';

class RemindersOffline {
  late Offline parent;
  RemindersOffline(Offline _parent) {
    parent = _parent;
  }
  Future<List<AgendaReminder>?> getReminders(String? idLesson) async {
    try {
      return parent.agendaBox
          ?.get("reminders")
          ?.where((element) => element.lessonID == idLesson)
          .toList()
          ?.cast<AgendaReminder>();
    } catch (e) {
      CustomLogger.log("REMINDERS", "An error occured while returning agenda reminders");
      CustomLogger.error(e);
      return null;
    }
  }

  ///Remove a reminder with its `id`
  void remove(String? id) async {
    try {
      var old = await parent.agendaBox?.get("reminders");
      List<AgendaReminder>? offline = [];
      if (old != null) {
        offline = old.cast<AgendaReminder>();
      }
      if (offline != null) {
        offline.removeWhere((a) => a.id == id);
      }
      await parent.agendaBox?.put("reminders", offline);
    } catch (e) {
      CustomLogger.log("REMINDERS", "An error occured while removing reminders");
      CustomLogger.error(e);
    }
  }

  ///Remove all reminders associated with the give `lessonId`
  removeAll(String? lessonId) async {
    try {
      var old = await parent.agendaBox?.get("reminders");
      List<AgendaReminder>? offline = [];
      if (old != null) {
        offline = old.cast<AgendaReminder>();
      }
      if (offline != null) {
        offline.removeWhere((element) => element.lessonID == lessonId);
      }
      await parent.agendaBox?.put("reminders", offline);
    } catch (e) {
      CustomLogger.log("REMINDERS", "An error occured while removing reminders");
      CustomLogger.error(e);
    }
  }

  ///Update existing reminders (clear old data) with passed data
  void updateReminders(AgendaReminder newData) async {
    try {
      var old = await parent.agendaBox?.get("reminders");
      List<AgendaReminder>? offline = [];
      if (old != null) {
        offline.addAll(old.cast<AgendaReminder>());
      }
      Offline _offline = Offline();
      API api = apiManager(_offline);
      var lessons = await (api.getNextLessons(DateTime.now()) as Future<List<Lesson>>);
      offline.forEach((a) {
        var lesson = lessons.firstWhere((element) => element.id == a.id);
        var newLesson = lessons.firstWhere((element) => element.id == a.id);
        if(newLesson.canceled != lesson.canceled && newLesson.canceled == true){
          AppNotification.showNewLessonCancellationNotification(newLesson);
        }
      });
      offline.removeWhere((a) => a.id == newData.id);
      offline.add(newData);
      await parent.agendaBox?.put("reminders", offline);

      CustomLogger.log("REMINDERS", "Updated reminders");
    } catch (e) {
      CustomLogger.log("REMINDERS", "An error occured while updating reminders");
      CustomLogger.error(e);
    }
  }
}
