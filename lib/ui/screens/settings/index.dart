import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info/package_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:ynotes/core/apis/utils.dart';
import 'package:ynotes/core/logic/app_config/controller.dart';
import 'package:ynotes/core/logic/agenda/models.dart';
import 'package:ynotes/core/logic/appConfig/controller.dart';
import 'package:ynotes/core/services/notifications.dart';
import 'package:ynotes/core/services/platform.dart';
import 'package:ynotes/core/utils/settings/settings_utils.dart';
import 'package:ynotes/core/utils/theme_utils.dart';
import 'package:ynotes/globals.dart';
import 'package:ynotes/ui/components/dialogs.dart';
import 'package:ynotes/ui/components/y_page/mixins.dart';
import 'package:ynotes/ui/components/y_page/y_page_local.dart';
import 'package:ynotes/ui/screens/settings/sub_pages/account.dart';
import 'package:ynotes/ui/screens/settings/sub_pages/logs.dart';

import '../../../tests.dart';
import '../../../useful_methods.dart';

bool? isFirstAvatarSelected;

final storage = new FlutterSecureStorage();

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SettingsPageState();
  }
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin, YPageMixin {
  late AnimationController leftToRightAnimation;
  late AnimationController rightToLeftAnimation;
  //Avatar's animations :
  Animation<double>? movingRow;
  //To use by the actual image when switching
  Animation<double>? avatarSize;

  //Disable new grades when battery saver is enabled
  bool? disableNotification;

  @override
  Widget build(BuildContext context) {
    MediaQueryData screenSize = MediaQuery.of(context);
//animation left to right

    return ChangeNotifierProvider<ApplicationSystem>.value(
      value: appSys,
      child: Consumer<ApplicationSystem>(builder: (context, _appSys, child) {
        return Theme(
          data: ThemeData(brightness: ThemeUtils.isThemeDark ? Brightness.dark : Brightness.light),
          child: SettingsList(
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            backgroundColor: Theme.of(context).backgroundColor,
            darkBackgroundColor: Theme.of(context).backgroundColor,
            lightBackgroundColor: Theme.of(context).backgroundColor,
            contentPadding: EdgeInsets.symmetric(vertical: screenSize.size.height / 10 * 0.1),
            sections: [
              SettingsSection(
                title: 'Mon compte',
                titleTextStyle: TextStyle(color: ThemeUtils.textColor(), fontFamily: "Asap"),
                tiles: [
                  SettingsTile(
                      title: 'Compte actuellement connecté',
                      titleTextStyle: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                      subtitleTextStyle: TextStyle(
                          fontFamily: "Asap",
                          color:
                              ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                      subtitle: '${appSys.currentSchoolAccount?.name ?? "Invité"}',
                      leading: Icon(MdiIcons.account, color: ThemeUtils.textColor()),
                      trailing: Icon(Icons.chevron_right, color: ThemeUtils.textColor()),
                      onPressed: (context) => openLocalPage(YPageLocal(child: AccountPage(), title: "Compte")),
                      iosChevron: Icon(Icons.chevron_right)),
                ],
              ),
              SettingsSection(
                title: 'Apparence/Comportement',
                titleTextStyle: TextStyle(color: ThemeUtils.textColor()),
                tiles: [
                  SettingsTile.switchTile(
                    title: 'Mode nuit',
                    titleTextStyle: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                    subtitleTextStyle: TextStyle(
                        fontFamily: "Asap",
                        color: ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                    leading: Icon(MdiIcons.themeLightDark, color: ThemeUtils.textColor()),
                    switchValue: ThemeUtils.isThemeDark,
                    onToggle: (value) async {
                      _appSys.updateTheme(value ? "sombre" : "clair");
                    },
                  ),
                  SettingsTile.switchTile(
                    title: 'Economiseur de batterie',
                    subtitle: "Réduit les interactions reseaux",
                    titleTextStyle: TextStyle(
                      fontFamily: "Asap",
                      color: ThemeUtils.textColor(),
                    ),
                    subtitleTextStyle: TextStyle(
                        fontFamily: "Asap",
                        color: ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                    leading: Icon(MdiIcons.batteryHeart, color: ThemeUtils.textColor()),
                    switchValue: _appSys.settings.user.global.batterySaver,
                    onToggle: (value) async {
                      _appSys.settings.user.global.batterySaver = value;
                      appSys.saveSettings();
                    },
                  ),
                ],
              ),
              SettingsSection(
                title: 'Notifications',
                titleTextStyle: TextStyle(color: ThemeUtils.textColor()),
                tiles: [
                  SettingsTile.switchTile(
                    title: 'Notification de nouveau mail',
                    enabled: !_appSys.settings.user.global.batterySaver,
                    titleTextStyle: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                    subtitleTextStyle: TextStyle(
                        fontFamily: "Asap",
                        color: ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                    switchValue: _appSys.settings.user.global.notificationNewMail,
                    onToggle: (bool value) async {
                      if (value == false ||
                          (!kIsWeb && Platform.isIOS && await Permission.notification.request().isGranted) ||
                          (await Permission.ignoreBatteryOptimizations.isGranted)) {
                        _appSys.settings.user.global.notificationNewMail = value;
                        appSys.saveSettings();
                      } else {
                        if (await CustomDialogs.showAuthorizationsDialog(
                                context,
                                "la configuration d'optimisation de batterie",
                                "Pouvoir s'exécuter en arrière plan sans être automatiquement arrêté par Android.") ??
                            false) {
                          if (await Permission.ignoreBatteryOptimizations.request().isGranted) {
                            _appSys.settings.user.global.notificationNewMail = value;
                            appSys.saveSettings();
                          }
                        }
                      }
                    },
                  ),
                  SettingsTile.switchTile(
                    title: 'Notification de nouvelle note',
                    enabled: !_appSys.settings.user.global.batterySaver,
                    titleTextStyle: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                    subtitleTextStyle: TextStyle(
                        fontFamily: "Asap",
                        color: ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                    switchValue: _appSys.settings.user.global.notificationNewGrade,
                    onToggle: (bool value) async {
                      if (value == false ||
                          (!kIsWeb && Platform.isIOS && await Permission.notification.request().isGranted) ||
                          (await Permission.ignoreBatteryOptimizations.isGranted)) {
                        _appSys.settings.user.global.notificationNewGrade = value;
                        appSys.saveSettings();
                      } else {
                        if (await CustomDialogs.showAuthorizationsDialog(
                                context,
                                "la configuration d'optimisation de batterie",
                                "Pouvoir s'exécuter en arrière plan sans être automatiquement arrêté par Android.") ??
                            false) {
                          if (await Permission.ignoreBatteryOptimizations.request().isGranted) {
                            _appSys.settings.user.global.notificationNewGrade = value;
                            appSys.saveSettings();
                          }
                        }
                      }
                    },
                  ),
                  SettingsTile(
                    title: 'Je ne reçois pas de notifications',
                    iosChevron: Icon(Icons.chevron_right),
                    leading: Icon(MdiIcons.bellAlert, color: ThemeUtils.textColor()),
                    onPressed: (context) async {
                      if (!kIsWeb && Platform.isIOS) {
                        await Permission.notification.request();
                        return;
                      }

                      //Check battery optimization setting
                      if (!await Permission.ignoreBatteryOptimizations.isGranted &&
                          await CustomDialogs.showAuthorizationsDialog(
                              context,
                              "la configuration d'optimisation de batterie",
                              "Pouvoir s'exécuter en arrière plan sans être automatiquement arrêté par Android.")) {
                        await Permission.ignoreBatteryOptimizations.request().isGranted;
                      }

                      if (await CustomDialogs.showAuthorizationsDialog(
                              context,
                              "la liste blanche de lancement en arrière plan / démarrage",
                              "Pouvoir lancer yNotes au démarrage de l'appareil et ainsi régulièrement rafraichir en arrière plan.") ??
                          false) {
                        await AndroidPlatformChannel.openAutoStartSettings();
                      }
                      await AppNotification.showDebugNotification();
                      Flushbar(
                        flushbarPosition: FlushbarPosition.BOTTOM,
                        backgroundColor: Colors.orange.shade200,
                        duration: Duration(seconds: 10),
                        isDismissible: true,
                        margin: EdgeInsets.all(8),
                        messageText: Text(
                          "Toujours pas de notifications ?",
                          style: TextStyle(fontFamily: "Asap"),
                        ),
                        mainButton: TextButton(
                          onPressed: () {
                            const url = 'https://ynotes.fr/help/notifications';
                            launchURL(url);
                          },
                          child: Text(
                            "Aide liée aux notifications",
                            style: TextStyle(color: Colors.blue, fontFamily: "Asap"),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      )..show(context);
                    },
                    titleTextStyle: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                    subtitleTextStyle: TextStyle(
                        fontFamily: "Asap",
                        color: ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                  ),
                ],
              ),
              SettingsSection(
                titleTextStyle: TextStyle(color: ThemeUtils.textColor()),
                title: 'Paramètres scolaires',
                tiles: [
                  SettingsTile(
                    title: 'Choisir mes spécialités',
                    titleTextStyle: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                    subtitleTextStyle: TextStyle(
                        fontFamily: "Asap",
                        color: ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                    leading: Icon(MdiIcons.formatListBulleted, color: ThemeUtils.textColor()),
                    iosChevron: Icon(Icons.chevron_right),
                    onPressed: (context) {
                      CustomDialogs.showSpecialtiesChoice(context);
                    },
                  ),
                ],
              ),
              SettingsSection(titleTextStyle: TextStyle(color: ThemeUtils.textColor()), title: 'Assistance', tiles: [
                SettingsTile.switchTile(
                    title: 'Secouer pour signaler',
                    titleTextStyle: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                    subtitleTextStyle: TextStyle(
                        fontFamily: "Asap",
                        color: ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                    switchValue: _appSys.settings.user.global.shakeToReport,
                    onToggle: (bool value) async {
                      _appSys.settings.user.global.shakeToReport = value;
                      appSys.saveSettings();
                    }),
                SettingsTile(
                  title: 'Afficher les logs',
                  leading: Icon(MdiIcons.bug, color: ThemeUtils.textColor()),
                  onPressed: (context) {
                    Navigator.of(context).push(router(LogsPage()));
                  },
                  titleTextStyle: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                  subtitleTextStyle: TextStyle(
                      fontFamily: "Asap",
                      color: ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                  iosChevron: Icon(Icons.chevron_right),
                ),
              ]),
              SettingsSection(
                titleTextStyle: TextStyle(color: ThemeUtils.textColor()),
                title: 'Autres paramètres',
                tiles: [
                  SettingsTile(
                    title: 'Supprimer les données hors ligne',
                    leading: Icon(MdiIcons.deleteAlert, color: ThemeUtils.textColor()),
                    onPressed: (context) async {
                      if ((await (CustomDialogs.showConfirmationDialog(context, null,
                              alternativeText: "Êtes vous sûr de vouloir supprimer les données hors ligne?",
                              alternativeButtonConfirmText: "Supprimer")) ??
                          false)) {
                        await appSys.offline.clearAll();
                        appSys.api = apiManager(appSys.offline);
                      }
                    },
                    titleTextStyle: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                    subtitleTextStyle: TextStyle(
                        fontFamily: "Asap",
                        color: ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                    iosChevron: Icon(Icons.chevron_right),
                  ),
                  SettingsTile(
                    title: 'Note de mise à jour',
                    leading: Icon(MdiIcons.file, color: ThemeUtils.textColor()),
                    onPressed: (context) async {
                      CustomDialogs.showUpdateNoteDialog(context);
                    },
                    titleTextStyle: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                    subtitleTextStyle: TextStyle(
                        fontFamily: "Asap",
                        color: ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                    iosChevron: Icon(Icons.chevron_right),
                  ),
                  SettingsTile(
                    title: 'Forcer la restauration des anciens paramètres',
                    leading: Icon(MdiIcons.emoticonConfused, color: ThemeUtils.textColor()),
                    onPressed: (context) async {
                      var temp = await SettingsUtils.forceRestoreOldSettings();
                      setState(() {
                        appSys.settings = temp;
                        appSys.saveSettings();
                      });
                      CustomDialogs.showAnyDialog(context, "Anciens paramètres restaurés.");
                    },
                    titleTextStyle: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                    subtitleTextStyle: TextStyle(
                        fontFamily: "Asap",
                        color: ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                    iosChevron: Icon(Icons.chevron_right),
                  ),
                  SettingsTile(
                    title: 'A propos de cette application',
                    leading: Icon(MdiIcons.information, color: ThemeUtils.textColor()),
                    iosChevron: Icon(Icons.chevron_right),
                    onPressed: (context) async {
                      PackageInfo packageInfo = await PackageInfo.fromPlatform();

                      showAboutDialog(
                          context: this.context,
                          applicationIcon: Image(
                            image: AssetImage('assets/appico/foreground.png'),
                            width: screenSize.size.width / 5 * 0.7,
                          ),
                          applicationName: "yNotes",
                          applicationVersion:
                              packageInfo.version + "+" + packageInfo.buildNumber + " T" + Tests.testVersion,
                          applicationLegalese:
                              "Developpé avec amour en France.\nAPI Pronote adaptée à l'aide de l'API pronotepy développée par Bain sous licence MIT.\nJe remercie la participation des bêta testeurs et des développeurs ayant participé au développement de l'application.");
                    },
                    titleTextStyle: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                    subtitleTextStyle: TextStyle(
                        fontFamily: "Asap",
                        color: ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                  ),
                  if (!kReleaseMode)
                    SettingsTile(
                      title: 'Bouton magique',
                      leading: Icon(MdiIcons.testTube, color: ThemeUtils.textColor()),
                      onPressed: (context) async {
                        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                          await DesktopWindow.setWindowSize(Size(768, 1024));
                        }
                        AppNotification.showNewLessonCancellationNotification(Lesson(room: '110', canceled: true, start: DateTime.now(), end: DateTime(500,500,500), discipline: 'Phusique', teachers: ['M. José']));
                      },
                      titleTextStyle: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                      subtitleTextStyle: TextStyle(
                          fontFamily: "Asap",
                          color:
                              ThemeUtils.isThemeDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                      iosChevron: Icon(Icons.chevron_right),
                    ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    // Don't forget to dispose the animation controller on class destruction
    leftToRightAnimation.dispose();
    rightToLeftAnimation.dispose();
    super.dispose();
  }

  @override
  void initState() {
    setState(() {
      isFirstAvatarSelected = true;
    });
    super.initState();
    leftToRightAnimation = AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    rightToLeftAnimation = AnimationController(duration: Duration(milliseconds: 800), vsync: this);
  }
}
