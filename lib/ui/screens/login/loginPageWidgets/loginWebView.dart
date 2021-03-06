import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:ynotes/core/apis/Pronote/PronoteCas.dart';
import 'package:ynotes/core/apis/utils.dart';
import 'package:ynotes/globals.dart';
import 'package:ynotes/ui/components/buttons.dart';
import 'package:uuid/uuid.dart';

// ignore: must_be_immutable
class LoginWebView extends StatefulWidget {
  final String? url;
  final String? spaceUrl;
  InAppWebViewController? controller;

  LoginWebView({Key? key, this.url, this.controller, this.spaceUrl}) : super(key: key);
  @override
  _LoginWebViewState createState() => _LoginWebViewState();
}

class _LoginWebViewState extends State<LoginWebView> {
  var loginData;
  late Map currentProfile;
  //locals, but shouldn't be obviously

  Map? loginStatus;
  String? serverUrl;
  String? espaceUrl;
  bool auth = false;
  int step = 3;
  authAndValidateProfile() async {
    print("Validating profile");
    //navigate to address

    Timer(new Duration(milliseconds: 1500), () async {
      setState(() {
        auth = true;
      });
      String loginDataProcess =
          "(function(){return window && window.loginState ? JSON.stringify(window.loginState) : \'\';})();";
      String? loginDataProcessResult = await (widget.controller!.evaluateJavascript(source: loginDataProcess));
      getCreds(loginDataProcessResult);
      if (loginStatus != null) {
        setState(() {
          step = 5;
        });
        //url: widget.url + "?fd=1&bydlg=A6ABB224-12DD-4E31-AD3E-8A39A1C2C335"
        await widget.controller!.loadUrl(
            urlRequest: URLRequest(url: Uri.parse(widget.url! + "?fd=1&bydlg=A6ABB224-12DD-4E31-AD3E-8A39A1C2C335")));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
                url: Uri.parse(getRootAddress(widget.url)[0] +
                    (widget.url![widget.url!.length - 1] == "/" ? "" : "/") +
                    "InfoMobileApp.json?id=0D264427-EEFC-4810-A9E9-346942A862A4")),

            ///1) We open a page with the serverUrl + weird string hardcoded
            initialOptions: InAppWebViewGroupOptions(
                android: AndroidInAppWebViewOptions(useHybridComposition: true),
                crossPlatform: InAppWebViewOptions(
                    supportZoom: true,
                    javaScriptEnabled: true,
                    allowFileAccessFromFileURLs: true,
                    userAgent:
                        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.106 Safari/537.36 OPR/38.0.2220.41",
                    allowUniversalAccessFromFileURLs: true)),
            onWebViewCreated: (InAppWebViewController controller) {
              widget.controller = controller;
              //Clear cookies
              controller.clearCache();
            },
            onConsoleMessage: (a, b) {},

            onLoadHttpError: (d, c, a, f) {},
            onLoadError: (a, b, c, d) {},
            onLoadStop: (controller, url) async {
              await stepper();
            },
            onProgressChanged: (InAppWebViewController controller, int progress) {},
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildText(loginStatus != null ? loginStatus!["mdp"] : ""),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: _buildFloatingButton(context),
          ),
          if (!auth)
            Container(
              width: screenSize.size.width,
              height: screenSize.size.height,
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!kIsWeb && Platform.isLinux)
                      Text(
                        "La connexion par ENT n'est pas encore supportée sur Linux...",
                        style: TextStyle(fontFamily: "Asap", color: Colors.red),
                      ),
                    if (!kIsWeb && !Platform.isLinux)
                      Text(
                        "Patientez... nous vous connectons à l'ENT",
                        style: TextStyle(fontFamily: "Asap"),
                      ),
                    CustomButtons.materialButton(context, null, null, () {
                      Navigator.of(context).pop();
                    }, label: "Quitter")
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  getCookie() {}

  getCreds(String? credsData) {
    if (credsData != null && credsData.length > 0) {
      printWrapped(credsData);
      Map temp = json.decode(credsData);
      print(temp["status"]);
      if (temp["status"] == 0) {
        loginStatus = temp;
        Navigator.of(context).pop(loginStatus);
      } else {}
    } else {
      print("NULL");
    }
  }

  getMetas() async {
    print("Getting metas");
    //Injected function to get metas
    String metaGetFunction = "(function(){return document.body.innerText;})()";
    String? metaGetResult = await (widget.controller!.evaluateJavascript(source: metaGetFunction));
    if (metaGetResult != null && metaGetResult.length > 0) {
      loginData = json.decode(metaGetResult);
      setState(() {
        step = 2;
      });
      stepper();
    } else {
      print("Failed to get metas");
    }
  }

  loginTest() async {
    print("Login test");
    Timer(new Duration(milliseconds: 1500), () async {
      String toexecute = 'if(!window.messageData) /*window.messageData = [];*/'
          /*'window._finLoadingScriptAppliMobile = function(){' +
          '  messageData.push({action: \'load\'});' +
          '};' */
          /*'if(document.querySelectorAll(\'.conteneur\').length === 1){' +
          '  messageData.push({action: \'errorMsg\', msg: document.querySelectorAll(\'.conteneur\')[0].innerText});' +
          '}' */
          /*'var isError = document.body.textContent.match(/HTTP Error ([0-9]{3})/i);' +
          'if(isError && isError.length > 1 && parseInt(isError[1]) > 399) {' +
          '  messageData.push({action: \'errorStatus\', msg: isError[1]});' +
          '}'*/
          ;
      await widget.controller!.evaluateJavascript(source: toexecute);
      /* print("A" + a.toString());
      String toexecute3 =
          "(function(){var lMessData = window.messageData && window.messageData.length ? window.messageData.splice(0, window.messageData.length) : \'\';return lMessData ? JSON.stringify(lMessData) : \'\';})()";
      String c = await widget.controller.evaluateJavascript(source: toexecute3);*/

      /*  String amiajoketou = await widget.controller.evaluateJavascript(source: joker);
      print(amiajoketou);*/
    });
  }

  selectProfile() async {
    print("Selecting profile");

    //lets hardcode the profile
    currentProfile = Map();

    ///TO DO NOT HARCODE
    currentProfile["serverUrl"] = widget.url;
    currentProfile["espaceUrl"] = loginData["espaces"][5]["URL"];
    currentProfile["nomEsp"] = loginData["espaces"][5]["nom"];
    currentProfile["nomEtab"] = loginData["nomEtab"];
    currentProfile["estCAS"] = loginData["CAS"]["actif"];
    currentProfile["casURL"] = loginData["CAS"]["casURL"];
    currentProfile["login"] = "";
    currentProfile["jeton"] = "";

    setState(() {
      step = 3;
    });
    stepper();
  }

  setCookie() async {
    print("Setting cookie");
    //generate UUID
    await appSys.updateSetting(appSys.settings!["system"], "uuid", Uuid().v4());

    //set cookie
    String cookieFunction = '(function(){try{' +
        'var lJetonCas = "", lJson = JSON.parse(document.body.innerText);' +
        'lJetonCas = !!lJson && !!lJson.CAS && lJson.CAS.jetonCAS;' +
        'document.cookie = "appliMobile=;expires=" + new Date(0).toUTCString();' +
        'if(!!lJetonCas) {' +
        'document.cookie = "validationAppliMobile="+lJetonCas+";expires=" + new Date(new Date().getTime() + (5*60*1000)).toUTCString();' +
        'document.cookie = "uuidAppliMobile=' +
        appSys.settings!["system"]["uuid"] +
        ';expires=" + new Date(new Date().getTime() + (5*60*1000)).toUTCString();' +
        'document.cookie = "ielang=' +
        "1036" +
        ';expires=" + new Date(new Date().getTime() + (365*24*60*60*1000)).toUTCString();' +
        'return "ok";' +
        '} else return "ko";' +
        '} catch(e){return "ko";}})();';
    String? cookieFunctionResult = await (widget.controller!.evaluateJavascript(source: cookieFunction));
    if (cookieFunctionResult == "ok") {
      String authFunction = 'location.assign("' + widget.url! + '?fd=1")';
      setState(() {
        step = 4;
      });
      await (widget.controller!.evaluateJavascript(source: authFunction));

      stepper();
    }
  }

  ///called on load stop
  stepper() async {
    switch (step) {
      //Get url metas
      case 1:
        {
          await getMetas();
        }
        break;
      //It should let the user chose its space...
      case 2:
        {
          await selectProfile();
        }
        break;
      case 3:
        {
          await setCookie();
        }
        break;
      case 4:
        {
          await authAndValidateProfile();
        }
        break;
      case 5:
        {
          await loginTest();
        }
    }
  }

  _buildFloatingButton(BuildContext context) {
    var screenSize = MediaQuery.of(context);
    return Container(
      margin: EdgeInsets.all(screenSize.size.width / 5 * 0.1),
      child: FloatingActionButton(
        heroTag: "btn2",
        backgroundColor: Colors.transparent,
        child: Container(
          width: 90,
          height: 90,
          child: Center(
            child: Icon(
              MdiIcons.exitRun,
              size: 40,
            ),
          ),
          decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xff100A30)),
        ),
        onPressed: () async {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  _buildText(String text) {
    return SelectableText(text);
  }

  //I have to get an address like that
  //https://0782540m.index-education.net/pronote/InfoMobileApp.json?id=0D264427-EEFC-4810-A9E9-346942A862A4

}
