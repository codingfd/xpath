import 'package:xpath_parse/xpath_selector.dart';

final String html = '''
<html lang="en">
<div><a href='https://github.com'>github.com</a></div>
<div class="head">head</div>
<table>
    <tr>
        <td>1</td>
        <td>2</td>
        <td>3</td>
        <td>4</td>
    </tr>
</table>
<div class="end">end</div>
</html>
''';

void main() {
  var xpath = XPath.source(html);
  print(xpath.query("//div/a/text()").list());
  print(xpath.query("//div/a/@href").get());
  print(xpath.query("//div[@class]/text()").list());
  print(xpath.query("//div[@class='head']/text()").get());
  print(xpath.query("//div[@class^='he']/text()").get());
  print(xpath.query("//div[@class\$='nd']/text()").get());
  print(xpath.query("//div[@class*='ea']/text()").get());
  print(xpath.query("//table//td[1]/text()").get());
  print(xpath.query("//table//td[last()]/text()").get());
  print(xpath.query("//table//td[position()<3]/text()").list());
  print(xpath.query("//table//td[position()>2]/text()").list());
}
