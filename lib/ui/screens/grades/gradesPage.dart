import 'package:auto_size_text/auto_size_text.dart';
import 'package:badges/badges.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ynotes/core/logic/grades/controller.dart';
import 'package:ynotes/core/logic/modelsExporter.dart';
import 'package:ynotes/core/logic/stats/gradesStats.dart';
import 'package:ynotes/globals.dart';
import 'package:ynotes/main.dart';
import 'package:ynotes/core/services/shared_preferences.dart';
import 'package:ynotes/ui/components/buttons.dart';
import 'package:ynotes/ui/components/dialogs.dart';
import 'package:ynotes/ui/components/modalBottomSheets/disciplinesModalBottomSheet.dart';
import 'package:ynotes/ui/components/modalBottomSheets/gradesModalBottomSheet/gradesModalBottomSheet.dart';
import 'package:ynotes/ui/components/modalBottomSheets/simulatorModalBottomSheet/simulatorModalBottomSheet.dart';
import 'package:ynotes/ui/screens/grades/gradesPageWidgets/gradesGroup.dart';
import 'package:ynotes/usefulMethods.dart';
import 'package:ynotes/core/utils/themeUtils.dart';

class GradesPage extends StatefulWidget {
  final GradesController gradesController;
  const GradesPage({Key key, this.gradesController}) : super(key: key);
  State<StatefulWidget> createState() {
    return _GradesPageState();
  }
}

//This boolean show a little badge if true
bool newGrades = false;
//If true, show a carousel
bool firstStart = true;
int initialIndexGradesOffset = 0;
List specialties;

class _GradesPageState extends State<GradesPage> {
  void initState() {
    super.initState();

    initializeDateFormatting("fr_FR", null);
  }

  Future<void> forceRefreshGrades() async {
    await widget.gradesController.refresh(force: true);
  }

  _buildBackground(BuildContext context, GradesController model) {
    var screenSize = MediaQuery.of(context);

    return AnimatedContainer(
      duration: Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.blue,
      ),
      width: model.isSimulating ? screenSize.size.height : 0,
      height: model.isSimulating ? screenSize.size.height : 0,
    );
  }

  _buildResetButton(GradesController controller) {
    var screenSize = MediaQuery.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: screenSize.size.height / 10 * 0.1),
      child:
          CustomButtons.materialButton(context, screenSize.size.width / 5 * 3.2, screenSize.size.height / 10 * 0.5, () {
        controller.simulationReset();
      }, label: "Réinitialiser les notes", textColor: Colors.white, backgroundColor: Colors.blue),
    );
  }

  _buildFloatingButton(BuildContext context) {
    var screenSize = MediaQuery.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: screenSize.size.height / 10 * 0.1),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          child: FloatingActionButton(
            heroTag: "simulBtn",
            backgroundColor: Colors.transparent,
            child: Container(
              width: screenSize.size.width / 5 * 0.8,
              height: screenSize.size.width / 5 * 0.8,
              child: Icon(
                Icons.add,
                size: screenSize.size.width / 5 * 0.5,
              ),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xff100A30)),
            ),
            onPressed: () async {
              Grade a = await simulatorModalBottomSheet(this.widget.gradesController, context);
              if (a != null) {
                widget.gradesController.simulationAdd(a);
              }
            },
          ),
        ),
      ),
    );
  }

  openSortBox(GradesController gradesController) {
    MediaQueryData screenSize;
    screenSize = MediaQuery.of(context);
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
            contentPadding: EdgeInsets.only(top: 10.0),
            content: Container(
              height: screenSize.size.height / 10 * 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Container(
                    margin:
                        EdgeInsets.only(left: screenSize.size.width / 5 * 0.1, right: screenSize.size.width / 5 * 0.1),
                    height: screenSize.size.height / 10 * 0.8,
                    decoration: BoxDecoration(),
                    child: Material(
                      color: Color(0xff252B62),
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      child: InkWell(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        onTap: () {
                          gradesController.sorter = "spécialités";
                          Navigator.pop(context);
                        },
                        child: Row(
                          children: <Widget>[
                            Image(
                              image: AssetImage('assets/images/space/space.png'),
                              width: screenSize.size.width / 5 * 0.8,
                            ),
                            Container(
                              width: screenSize.size.width / 5 * 2.5,
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text(
                                  "Mes spécialités",
                                  style: TextStyle(
                                      fontSize: screenSize.size.width / 5 * 0.3,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: "Asap",
                                      color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin:
                        EdgeInsets.only(left: screenSize.size.width / 5 * 0.1, right: screenSize.size.width / 5 * 0.1),
                    height: screenSize.size.height / 10 * 0.8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    child: Material(
                      color: Color(0xff42735B),
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      child: InkWell(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        onTap: () {
                          gradesController.sorter = "sciences";
                          Navigator.pop(context);
                        },
                        child: Row(
                          children: <Widget>[
                            Container(
                                margin: EdgeInsets.only(left: screenSize.size.width / 5 * 0.1),
                                child: Icon(
                                  MdiIcons.atomVariant,
                                  size: screenSize.size.width / 5 * 0.5,
                                  color: Colors.white,
                                )),
                            Container(
                              margin: EdgeInsets.only(left: screenSize.size.width / 5 * 0.2),
                              child: Text(
                                "Sciences",
                                style: TextStyle(
                                    fontSize: screenSize.size.width / 5 * 0.3,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: "Asap",
                                    color: Colors.white),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin:
                        EdgeInsets.only(left: screenSize.size.width / 5 * 0.1, right: screenSize.size.width / 5 * 0.1),
                    height: screenSize.size.height / 10 * 0.8,
                    decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(30))),
                    child: Material(
                      color: Color(0xff6C4273),
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      child: InkWell(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        onTap: () {
                          gradesController.sorter = "littérature";
                          Navigator.pop(context);
                        },
                        child: Row(
                          children: <Widget>[
                            Container(
                                margin: EdgeInsets.only(left: screenSize.size.width / 5 * 0.1),
                                child: Icon(
                                  MdiIcons.bookOpenVariant,
                                  size: screenSize.size.width / 5 * 0.5,
                                  color: Colors.white,
                                )),
                            Container(
                              margin: EdgeInsets.only(left: screenSize.size.width / 5 * 0.2),
                              child: Text(
                                "Littérature",
                                style: TextStyle(
                                    fontSize: screenSize.size.width / 5 * 0.3,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: "Asap",
                                    color: Colors.white),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin:
                        EdgeInsets.only(left: screenSize.size.width / 5 * 0.1, right: screenSize.size.width / 5 * 0.1),
                    height: screenSize.size.height / 10 * 0.8,
                    decoration: BoxDecoration(),
                    child: Material(
                      color: isDarkModeEnabled ? Colors.white10 : Colors.grey,
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      child: InkWell(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        onTap: () {
                          gradesController.sorter = "all";
                          Navigator.pop(context);
                        },
                        child: Row(
                          children: <Widget>[
                            Container(
                                margin: EdgeInsets.only(left: screenSize.size.width / 5 * 0.1),
                                child: Icon(
                                  MdiIcons.borderNoneVariant,
                                  size: screenSize.size.width / 5 * 0.5,
                                  color: ThemeUtils.textColor(),
                                )),
                            Container(
                              margin: EdgeInsets.only(left: screenSize.size.width / 5 * 0.2),
                              child: Text(
                                "Aucun filtre",
                                style: TextStyle(
                                    fontSize: screenSize.size.width / 5 * 0.3,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: "Asap",
                                    color: ThemeUtils.textColor()),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  showShowCaseDialog(BuildContext _context) async {
    if ((!await getSetting("gradesShowCase"))) {
      await setSetting("gradesShowCase", true);
    }
  }

  ///Start building grades box from here
  @override
  Widget build(BuildContext context) {
    MediaQueryData screenSize = MediaQuery.of(context);
    ScrollController controller = ScrollController();

    return Container(
      child: ChangeNotifierProvider<GradesController>.value(
        value: widget.gradesController,
        child: Consumer<GradesController>(builder: (context, model, child) {
          return Stack(
            children: [
              Container(
                color: Theme.of(context).backgroundColor,
                height: screenSize.size.height,
                child: Stack(
                  children: [
                    _buildBackground(context, model),
                    Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
                      ///Button container

                      Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                        color: Theme.of(context).backgroundColor,
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.only(top: (screenSize.size.height / 10 * 8.8) / 10 * 1 / 6),
                              height: screenSize.size.height / 10 * 0.7,
                              width: screenSize.size.width,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                                border: Border.all(width: 0.00000, color: Colors.transparent),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    height: screenSize.size.height / 10 * 9,
                                    width: (screenSize.size.width / 5) * 2.2,
                                    padding: EdgeInsets.symmetric(horizontal: (screenSize.size.width / 5) * 0.4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(screenSize.size.width / 5 * 0.15),
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.fitWidth,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Theme(
                                              data: Theme.of(context).copyWith(
                                                canvasColor: Theme.of(context).primaryColor,
                                              ),
                                              child: (model.periods == null ||
                                                      model.period == "" ||
                                                      model.periods.length == 0)
                                                  ? Container(
                                                      child: Text(
                                                        "Pas de periode",
                                                        style: TextStyle(
                                                            fontFamily: "Asap", color: ThemeUtils.textColor()),
                                                      ),
                                                    )
                                                  : DropdownButtonHideUnderline(
                                                      child: DropdownButton<String>(
                                                        value: model.period,
                                                        iconSize: 0.0,
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            fontFamily: "Asap",
                                                            color: ThemeUtils.textColor()),
                                                        onChanged: (String newValue) {
                                                          model.period = newValue;
                                                        },
                                                        focusColor: Theme.of(context).primaryColor,
                                                        items: model.periods
                                                            .toSet()
                                                            .map<DropdownMenuItem<String>>((Period period) {
                                                          return DropdownMenuItem<String>(
                                                            value: period != null ? period.name : "-",
                                                            child: Text(
                                                              period != null ? period.name : "-",
                                                              textAlign: TextAlign.center,
                                                              style: TextStyle(
                                                                  fontSize: 18,
                                                                  fontFamily: "Asap",
                                                                  color: ThemeUtils.textColor()),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ))
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: (screenSize.size.height / 10 * 8.8) / 10 * 0.1),
                                    child: Material(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(screenSize.size.width / 5 * 0.15),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(screenSize.size.width / 5 * 0.15),
                                        onTap: () {
                                          openSortBox(model);
                                        },
                                        child: Container(
                                            height: (screenSize.size.height / 10 * 8.8) / 10 * 0.6,
                                            padding: EdgeInsets.all(screenSize.size.width / 5 * 0.1),
                                            child: FittedBox(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Icon(
                                                    Icons.settings,
                                                    color: ThemeUtils.textColor(),
                                                  ),
                                                  Text(
                                                    "Trier",
                                                    style: TextStyle(
                                                      fontFamily: "Asap",
                                                      color: ThemeUtils.textColor(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                      ),
                                    ),
                                  ),

                                  //For now only enable simulator on debug mode
                                  if (kDebugMode)
                                    Container(
                                      margin: EdgeInsets.only(left: (screenSize.size.height / 10 * 8.8) / 10 * 0.1),
                                      child: Material(
                                        color: model.isSimulating ? Colors.blue : Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(screenSize.size.width / 5 * 0.15),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(screenSize.size.width / 5 * 0.15),
                                          onTap: () {
                                            model.isSimulating = !model.isSimulating;
                                          },
                                          child: Container(
                                              height: (screenSize.size.height / 10 * 8.8) / 10 * 0.6,
                                              padding: EdgeInsets.all(screenSize.size.width / 5 * 0.1),
                                              child: FittedBox(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Icon(
                                                      MdiIcons.flask,
                                                      color: ThemeUtils.textColor(),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            ///Grades container

                            RefreshIndicator(
                                onRefresh: forceRefreshGrades,
                                child: Container(
                                    width: screenSize.size.width / 5 * 4.7,
                                    padding: EdgeInsets.only(top: screenSize.size.height / 10 * 0.1),
                                    height: screenSize.size.height / 10 * 6.7,
                                    margin: EdgeInsets.only(top: 0),
                                    decoration: BoxDecoration(
                                        border: Border.all(width: 0.000000, color: Colors.transparent),
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(15),
                                          bottomRight: Radius.circular(15),
                                        ),
                                        color: Theme.of(context).backgroundColor),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(0),
                                          child: Consumer<GradesController>(builder: (context, model, child) {
                                            if (!model.isFetching) {
                                              if (model
                                                  .disciplines()
                                                  .any((Discipline element) => (element.gradesList.length > 0))) {
                                                return Column(
                                                  children: [
                                                    if (model.isSimulating) _buildResetButton(model),
                                                    Expanded(
                                                      child: Container(
                                                        child: ListView.builder(
                                                            physics: AlwaysScrollableScrollPhysics(),
                                                            itemCount: model.disciplines().length,
                                                            padding: EdgeInsets.symmetric(
                                                                vertical: screenSize.size.width / 5 * 0.1,
                                                                horizontal: screenSize.size.width / 5 * 0.05),
                                                            itemBuilder: (BuildContext context, int index) {
                                                              return GradesGroup(
                                                                  discipline: model.disciplines()[index],
                                                                  gradesController: model);
                                                            }),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              } else {
                                                return Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Image(
                                                        image: AssetImage('assets/images/book.png'),
                                                        width: screenSize.size.width / 5 * 4),
                                                    Container(
                                                      margin: EdgeInsets.symmetric(
                                                          horizontal: screenSize.size.width / 5 * 0.5),
                                                      child: AutoSizeText("Pas de notes pour cette periode.",
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                              fontFamily: "Asap", color: ThemeUtils.textColor())),
                                                    ),
                                                    FlatButton(
                                                      onPressed: () {
                                                        //Reload list
                                                        forceRefreshGrades();
                                                      },
                                                      child: !model.isFetching
                                                          ? Text("Recharger",
                                                              style: TextStyle(
                                                                  fontFamily: "Asap",
                                                                  color: ThemeUtils.textColor(),
                                                                  fontSize:
                                                                      (screenSize.size.height / 10 * 8.8) / 10 * 0.2))
                                                          : FittedBox(
                                                              child: SpinKitThreeBounce(
                                                                  color: Theme.of(context).primaryColorDark,
                                                                  size: screenSize.size.width / 5 * 0.4)),
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius: new BorderRadius.circular(18.0),
                                                          side: BorderSide(color: Theme.of(context).primaryColorDark)),
                                                    )
                                                  ],
                                                );
                                              }
                                            }
                                            if (!model.isFetching && model.disciplines == null) {
                                              return Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Image(
                                                    image: AssetImage('assets/images/totor.png'),
                                                    width: screenSize.size.width / 5 * 3.5,
                                                  ),
                                                  Container(
                                                    margin: EdgeInsets.symmetric(
                                                        horizontal: screenSize.size.width / 5 * 0.5),
                                                    child: AutoSizeText(
                                                        "Hum... on dirait que tout ne s'est pas passé comme prévu.",
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontFamily: "Asap",
                                                          color: ThemeUtils.textColor(),
                                                        )),
                                                  ),
                                                ],
                                              );
                                            } else {
                                              //Loading group
                                              return ListView.builder(
                                                  itemCount: 5,
                                                  padding: EdgeInsets.all(screenSize.size.width / 5 * 0.3),
                                                  itemBuilder: (BuildContext context, int index) {
                                                    return GradesGroup(
                                                      gradesController: model,
                                                      discipline: null,
                                                    );
                                                  });
                                            }
                                          }),
                                        ),
                                        if (model.isSimulating) _buildFloatingButton(context)
                                      ],
                                    )))
                          ],
                        ),
                      ),

                      //Average section
                      Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                        color: Theme.of(context).backgroundColor,
                        child: Container(
                          margin: EdgeInsets.only(left: (screenSize.size.width / 5 * 0.25)),
                          width: screenSize.size.width,
                          height: (screenSize.size.height / 10 * 8.8) / 10 * 1.8,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Consumer<GradesController>(builder: (context, model, child) {
                                Discipline lastDiscipline;
                                if (model.disciplines != null) {
                                  try {
                                    lastDiscipline = model
                                        .disciplines()
                                        .lastWhere((disciplinesList) => disciplinesList.period == model.period);
                                  } catch (exception) {}

                                  //If everything is ok, show stuff
                                  return Stack(
                                    children: <Widget>[
                                      Align(
                                        alignment: Alignment.center,
                                        child: Container(
                                          height: (screenSize.size.height / 10 * 8.8) / 10 * 1.15,
                                          width: screenSize.size.width / 5 * 4,
                                          decoration: BoxDecoration(
                                            boxShadow: <BoxShadow>[
                                              BoxShadow(
                                                blurRadius: 2.67,
                                                color: Colors.black.withOpacity(0.2),
                                                offset: Offset(0, 2.67),
                                              ),
                                            ],
                                            color: Theme.of(context).primaryColor,
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: FittedBox(
                                            child: Container(
                                              height: (screenSize.size.height / 10 * 8.8) / 10 * 1.15,
                                              width: screenSize.size.width / 5 * 3.3,
                                              child: FittedBox(
                                                child: Stack(
                                                  children: <Widget>[
                                                    Container(
                                                      margin: EdgeInsets.only(left: (screenSize.size.width / 5) * 2),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: <Widget>[
                                                          if (model.sorter == "all")
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: <Widget>[
                                                                Text("Moyenne de la classe :",
                                                                    style: TextStyle(
                                                                        fontFamily: "Asap",
                                                                        color: ThemeUtils.textColor(),
                                                                        fontSize: (screenSize.size.width / 5) * 0.18)),
                                                                Container(
                                                                  margin: EdgeInsets.only(
                                                                      left: (screenSize.size.width / 5) * 0.1),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.all(Radius.circular(15)),
                                                                      color: Color(0xff2C2C2C)),
                                                                  padding: EdgeInsets.symmetric(
                                                                      horizontal: (screenSize.size.width / 5) * 0.1,
                                                                      vertical: (screenSize.size.width / 5) * 0.08),
                                                                  child: Text(
                                                                    (lastDiscipline != null &&
                                                                            lastDiscipline.classGeneralAverage != null
                                                                        ? lastDiscipline.classGeneralAverage
                                                                        : "-"),
                                                                    style: TextStyle(
                                                                        fontFamily: "Asap",
                                                                        color: Colors.white,
                                                                        fontSize: (screenSize.size.width / 5) * 0.18),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          if (model.sorter == "all")
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: <Widget>[
                                                                Text("Meilleure moyenne :",
                                                                    style: TextStyle(
                                                                        fontFamily: "Asap",
                                                                        color: ThemeUtils.textColor(),
                                                                        fontSize: (screenSize.size.width / 5) * 0.18)),
                                                                Container(
                                                                  margin: EdgeInsets.only(
                                                                      left: (screenSize.size.width / 5) * 0.1),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.all(Radius.circular(15)),
                                                                      color: Color(0xff2C2C2C)),
                                                                  padding: EdgeInsets.symmetric(
                                                                      horizontal: (screenSize.size.width / 5) * 0.1,
                                                                      vertical: (screenSize.size.width / 5) * 0.08),
                                                                  child: Text(
                                                                    model.bestAverage ?? "-",
                                                                    style: TextStyle(
                                                                        fontFamily: "Asap",
                                                                        color: Colors.white,
                                                                        fontSize: (screenSize.size.width / 5) * 0.18),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          if (lastDiscipline != null &&
                                                              lastDiscipline.generalRank != null &&
                                                              model.sorter == "all")
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: <Widget>[
                                                                Text("Rang :",
                                                                    style: TextStyle(
                                                                        fontFamily: "Asap",
                                                                        color: ThemeUtils.textColor(),
                                                                        fontSize: (screenSize.size.width / 5) * 0.18)),
                                                                Container(
                                                                  margin: EdgeInsets.only(
                                                                      left: (screenSize.size.width / 5) * 0.1),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.all(Radius.circular(15)),
                                                                      color: Color(0xff2C2C2C)),
                                                                  padding: EdgeInsets.symmetric(
                                                                      horizontal: (screenSize.size.width / 5) * 0.1,
                                                                      vertical: (screenSize.size.width / 5) * 0.08),
                                                                  child: Text(
                                                                    (lastDiscipline.generalRank != null &&
                                                                            lastDiscipline.classNumber != null)
                                                                        ? lastDiscipline.generalRank +
                                                                            "/" +
                                                                            lastDiscipline.classNumber
                                                                        : "- / -",
                                                                    style: TextStyle(
                                                                        fontFamily: "Asap",
                                                                        color: Colors.white,
                                                                        fontSize: (screenSize.size.width / 5) * 0.18),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          if (model.sorter != "all")
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: <Widget>[
                                                                Text("Moyenne du filtre ",
                                                                    style: TextStyle(
                                                                        fontFamily: "Asap",
                                                                        color: ThemeUtils.textColor(),
                                                                        fontSize: (screenSize.size.width / 5) * 0.2)),
                                                                Text(model.sorter,
                                                                    style: TextStyle(
                                                                        fontFamily: "Asap",
                                                                        fontWeight: FontWeight.bold,
                                                                        color: ThemeUtils.textColor(),
                                                                        fontSize: (screenSize.size.width / 5) * 0.2)),
                                                              ],
                                                            )
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      //Circle with the moyenneGenerale
                                      Positioned(
                                        left: screenSize.size.width / 6 * 0.015,
                                        top: (screenSize.size.height / 10 * 8.8) / 10 * 0.2,
                                        child: Container(
                                          padding: EdgeInsets.all(screenSize.size.height / 10 * 0.3),
                                          width: screenSize.size.width / 5 * 1.5,
                                          height: (screenSize.size.height / 10 * 8.8) / 10 * 1.4,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: <BoxShadow>[
                                                BoxShadow(
                                                  blurRadius: 2.67,
                                                  color: Colors.black.withOpacity(0.2),
                                                  offset: Offset(0, 2.67),
                                                ),
                                              ],
                                              color: (model.sorter == "all" ? Colors.white : Colors.green)),
                                          child: Center(
                                            child: FittedBox(
                                              child: Text(
                                                (model.average.toString() != null && !model.average.isNaN
                                                    ? model.average.toStringAsFixed(2)
                                                    : "-"),
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontFamily: "Asap",
                                                    fontSize: (screenSize.size.width / 5) * 0.35),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                //To do if it can't get the data
                                if (model.average == null) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(
                                        Icons.error,
                                        color: ThemeUtils.textColor(),
                                        size: screenSize.size.width / 8,
                                      ),
                                    ],
                                  );
                                } else {
                                  return SpinKitFadingFour(
                                    color: Theme.of(context).primaryColorDark,
                                    size: screenSize.size.width / 5 * 0.7,
                                  );
                                }
                              })),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
