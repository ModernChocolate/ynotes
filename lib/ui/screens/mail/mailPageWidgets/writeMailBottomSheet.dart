import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:ynotes/core/apis/EcoleDirecte.dart';
import 'package:ynotes/core/logic/modelsExporter.dart';
import 'package:ynotes/core/utils/themeUtils.dart';
import 'package:ynotes/globals.dart';

import '../../../components/dialogs.dart';

class WriteMailBottomSheet extends StatefulWidget {
  final List<Recipient>? defaultRecipients;
  final String? defaultSubject;
  const WriteMailBottomSheet({Key? key, this.defaultRecipients, this.defaultSubject}) : super(key: key);

  @override
  _WriteMailBottomSheetState createState() => _WriteMailBottomSheetState();
}

class _WriteMailBottomSheetState extends State<WriteMailBottomSheet> {
  List<Recipient>? selectedRecipients = [];
  bool monochromatic = false;
  DateFormat format = DateFormat("dd-MM-yyyy HH:hh");
  var subjectController = TextEditingController(text: "");

  HtmlEditorController controller = HtmlEditorController();
  @override
  Widget build(BuildContext context) {
    MediaQueryData screenSize = MediaQuery.of(context);
    return Container(
      height: screenSize.size.height,
      color: Theme.of(context).backgroundColor,
      padding: EdgeInsets.all(0),
      child: SingleChildScrollView(
        child: new Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: screenSize.size.height / 10 * 0.1),
              width: screenSize.size.width,
              height: screenSize.size.height / 10 * 1.0,
              child: Stack(
                children: [
                  Row(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () async {
                            if ((await (CustomDialogs.showConfirmationDialog(context, null,
                                    alternativeText: "Êtes vous sûr de vouloir supprimer ce mail ?",
                                    alternativeButtonConfirmText: "Supprimer ce mail")) ??
                                false)) {
                              Navigator.pop(context);
                            }
                          },
                          icon: Icon(MdiIcons.arrowLeft, color: ThemeUtils.textColor()),
                        ),
                      ),
                      SizedBox(
                        width: screenSize.size.width / 5 * 0.1,
                      ),
                      AutoSizeText(
                        "Ecrire un mail",
                        style: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor()),
                      )
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () async {
                            print(await controller.getText());
                          
                            if (selectedRecipients!.isNotEmpty) {
                              Navigator.pop(context, [
                                subjectController.text,
                                await controller.getText(),
                                selectedRecipients,
                              ]);
                            } else {
                              CustomDialogs.showAnyDialog(context, "Ajoutez au moins un destinataire.");
                            }
                          },
                          icon: Icon(Icons.send, color: ThemeUtils.textColor()),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Container(
              width: screenSize.size.width,
              height: screenSize.size.height / 10 * 0.6,
              child: Stack(
                children: [
                  Positioned(
                    left: screenSize.size.width / 5 * 0.1,
                    child: Container(
                      width: screenSize.size.width / 5 * 4.4,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (selectedRecipients!.length == 0)
                              Container(
                                margin: EdgeInsets.only(right: screenSize.size.width / 5 * 0.1),
                                child: Chip(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  label: Text("(aucun destinataire)",
                                      style: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor())),
                                ),
                              ),
                            for (Recipient recipient in selectedRecipients!)
                              Container(
                                margin: EdgeInsets.only(right: screenSize.size.width / 5 * 0.1),
                                child: Chip(
                                  deleteIcon: Icon(Icons.delete),
                                  onDeleted: () {
                                    setState(() {
                                      selectedRecipients!.remove(recipient);
                                    });
                                  },
                                  label: Text(recipient.name! + " " + recipient.surname!),
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: screenSize.size.width / 5 * 0.5,
                    child: Container(
                      width: screenSize.size.width / 5 * 0.5,
                      child: IconButton(
                        onPressed: () async {
                          var recipient = await CustomDialogs.showNewRecipientDialog(context);
                          if (recipient != null) {
                            setState(() {
                              selectedRecipients!.add(recipient);
                            });
                          }
                        },
                        icon: Icon(Icons.add, color: ThemeUtils.textColor()),
                      ),
                    ),
                  ),
                  Positioned(
                    right: screenSize.size.width / 5 * 0.1,
                    child: Container(
                      width: screenSize.size.width / 5 * 0.5,
                      child: IconButton(
                        onPressed: () async {
                          //Get the recipients
                          List<Recipient>? recipients = await ((appSys.api as APIEcoleDirecte).mailRecipients());
                          List<String> recipientsName = [];
                          if (recipients != null) {
                            recipients.forEach((element) {
                              print(element.id);
                              String name = element.name ?? "";
                              String surname = element.surname ?? "";
                              String discipline = element.discipline ?? "";
                              String toAdd = name + " " + surname + " - (" + discipline + ")";
                              recipientsName.add(toAdd);
                            });
                          }
                          List<int> alreadySelected = [];
                          selectedRecipients!.forEach((selected) {
                            if (recipients!.indexOf(selected) >= 0) alreadySelected.add(recipients.indexOf(selected));
                          });
                          List<int>? selection = (await (CustomDialogs.showMultipleChoicesDialog(
                              context, recipientsName, alreadySelected,
                              singleChoice: false))) as List<int>?;
                          if (selection != null) {
                            print(selection);
                            setState(() {
                              selection.forEach((index) {
                                if (!selectedRecipients!.contains(recipients![index]))
                                  selectedRecipients!.add(recipients[index]);
                              });
                            });
                          }
                        },
                        icon: Icon(Icons.contact_page, color: ThemeUtils.textColor()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: screenSize.size.height / 10 * 0.1,
            ),
            Container(
              height: screenSize.size.height / 10 * 0.6,
              width: screenSize.size.width / 5 * 4.5,
              child: TextField(
                controller: subjectController,
                maxLines: 1,
                style: TextStyle(
                    fontFamily: "Asap", color: ThemeUtils.textColor(), fontSize: screenSize.size.width / 5 * 0.35),
                decoration: new InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: screenSize.size.width / 5 * 0.04, vertical: screenSize.size.height / 10 * 0.1),
                  labelText: 'Sujet',
                  labelStyle: TextStyle(
                    fontFamily: "Asap",
                    color: ThemeUtils.textColor().withOpacity(0.5),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: screenSize.size.height / 10 * 0.1,
            ),
            Container(
              height: screenSize.size.height / 10 * 6.5,
              width: screenSize.size.width,
              child: ClipRRect(
                child: HtmlEditor(
                  hint: "Saisissez votre mail ici..",
                  options: HtmlEditorOptions(
                    darkMode: ThemeUtils.isThemeDark,
                    showBottomToolbar: false,
                  ),
                  controller: controller,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  getMonochromaticColors(String html) {
    if (!monochromatic) {
      return html;
    }
    String finalHTML = html.replaceAll("color", "");
    return finalHTML;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) => setState(() {
          if (this.widget.defaultRecipients != null) {
            selectedRecipients = this.widget.defaultRecipients;
          }
          if (this.widget.defaultSubject != null) {
            subjectController.text = "Re: [${this.widget.defaultSubject}]";
          }
        }));
  }
}
