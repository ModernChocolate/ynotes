import 'package:html/parser.dart' show parse;
import 'package:requests/requests.dart';
import 'package:ynotes/core/apis/Pronote/PronoteCas.dart';

class TotalBug {
  static parseNumber(var data) {
    var parsed = parse(data);
    var onload = parsed.getElementById("nb24h");
    print(onload?.outerHtml);
    return int.parse(onload?.text ?? "");
  }

  static request(String websiteName) async {
    var getResponse = await Requests.get("https://www.totalbug.com/$websiteName/");
    return getResponse.content();
  }

  static Future<int?> websiteReportsNumber(String websiteName) async {
    return parseNumber(await request(websiteName));
  }
}
