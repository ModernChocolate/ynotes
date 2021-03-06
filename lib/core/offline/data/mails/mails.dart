import 'package:ynotes/core/logic/modelsExporter.dart';
import 'package:ynotes/core/offline/offline.dart';

class MailsOffline {
  late Offline parent;
  MailsOffline(Offline _parent) {
    parent = _parent;
  }
  Future<List<Mail>?> getAllMails() async {
    try {
      return parent.mailsBox?.values.toList();
    } catch (e) {
      print("Error while returning mails " + e.toString());
      return null;
    }
  }

  Future<void> updateMailContent(String content, String id) async {
    Mail? mail = parent.mailsBox?.values.toList().firstWhere((element) => element.id == id);
    if (mail != null) {
      mail.content = content;
      mail.read = true;
      await mail.save();
    }
  }

  ///Update existing mails with passed data
  updateMails(List<Mail> mails) async {
    print("Update offline mails");
    try {
      List<Mail>? oldMails = [];
      if (parent.mailsBox?.values != null) {
        oldMails = await getAllMails();
      }
      if (oldMails != null) {
        await Future.forEach(oldMails, (Mail oldMail) async {
          await Future.forEach(mails, (Mail mail) async {
            if (mail.id == oldMail.id) {
              //Fields succeptible to be updated (technically mails are immutable but "read" boolean can change)
              oldMail.read = mail.read;
              oldMail.idClasseur = mail.idClasseur;
              oldMail.files = mail.files;
              await oldMail.save();
            }
          });
        });
      }
      final old = (parent.mailsBox?.values.toList().cast<Mail>())
          ?.where((oldMail) => mails.any((newMail) => newMail.id == oldMail.id));
      if (old != null) {
        mails.removeWhere((newMail) => old.any((oldMail) => oldMail.id == newMail.id));
        print(mails.length);
      }
      await parent.mailsBox?.addAll(mails);
    } catch (e) {
      print("Error while updating mails " + e.toString());
    }
  }
}
