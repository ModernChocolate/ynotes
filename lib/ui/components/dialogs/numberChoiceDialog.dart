import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ynotes/core/utils/themeUtils.dart';

class NumberChoiceDialog extends StatefulWidget {
  final String unit;
  final bool isDouble;
  const NumberChoiceDialog(this.unit, {this.isDouble = false});
  @override
  _NumberChoiceDialogState createState() => _NumberChoiceDialogState();
}

class _NumberChoiceDialogState extends State<NumberChoiceDialog> {
  TextEditingController textController = TextEditingController(text: "");
  var value;
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context);
    return AlertDialog(
      elevation: 50,
      backgroundColor: Theme.of(context).primaryColor,
      content: Container(
        height: screenSize.size.height / 10 * 1.2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              child: Text(
                "Choisir ${widget.unit}",
                style: TextStyle(fontFamily: 'Asap', color: ThemeUtils.textColor()),
                textAlign: TextAlign.left,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Container(
                width: screenSize.size.width / 5 * 4.3,
                height: screenSize.size.height / 10 * 0.8,
                child: TextFormField(
                  controller: textController,
                  keyboardType: TextInputType.numberWithOptions(decimal: widget.isDouble),
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: ThemeUtils.textColor()),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: ThemeUtils.textColor()),
                    ),
                  ),
                  onChanged: (newValue) {
                    setState(() {
                      if (widget.isDouble) {
                        value = double.parse(newValue);
                      } else {
                        value = int.parse(newValue);
                      }
                    });
                  },
                  style: TextStyle(
                    fontFamily: 'Asap',
                    color: ThemeUtils.textColor(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('ANNULER', style: TextStyle(color: Colors.red), textScaleFactor: 1.0),
          onPressed: () {
            Navigator.pop(context, null);
          },
        ),
        TextButton(
          child: Text(
            "VALIDER",
            style: TextStyle(color: Colors.green),
            textScaleFactor: 1.0,
          ),
          onPressed: () async {
            Navigator.pop(context, value);
          },
        )
      ],
    );
  }
}
