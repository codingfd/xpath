import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
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
  test('adds one to input values', () async {
    final xpath = XPath.source(html);
    expect(xpath.query("//div/a/text()").list(), ['github.com']);
    expect(xpath.query("//div/a/@href").get(), 'https://github.com');
    expect(xpath.query("//div[@class]/text()").list(), ['head', 'end']);
    expect(xpath.query("//div[@class='head']/text()").get(), 'head');
    expect(xpath.query("//div[@class^='he']/text()").get(), 'head');
    expect(xpath.query(r"//div[@class$='nd']/text()").get(), 'end');
    expect(xpath.query("//div[@class*='ea']/text()").get(), 'head');
    expect(xpath.query("//table//td[1]/text()").get(), '1');
    expect(xpath.query("//table//td[last()]/text()").get(), '3');
    expect(xpath.query("//table//td[position()<3]/text()").list(), ['1', '2']);
    expect(xpath.query("//table//td[position()>2]/text()").list(), ['3', '4']);
  });
}
