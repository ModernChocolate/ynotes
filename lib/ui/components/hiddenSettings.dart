import 'package:flutter/material.dart';
// ignore: must_be_immutable
class HiddenSettings extends StatefulWidget {
  final Widget? child;
  final Widget? settingsWidget;
  PageController? controller = PageController(initialPage: 0);
  HiddenSettings({Key? key, this.child, this.settingsWidget, this.controller})
      : super(key: key);
  @override
  _HiddenSettingsState createState() => _HiddenSettingsState();
}

class _HiddenSettingsState extends State<HiddenSettings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context);
    return PageView(
      scrollDirection: Axis.vertical,
      controller: widget.controller,
      physics: NeverScrollableScrollPhysics(),
      children: [
        Container(
            height: screenSize.size.height,
            width: screenSize.size.width,
            child: widget.settingsWidget),
        widget.child!
      ],
    );
  }
}
