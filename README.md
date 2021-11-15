# html_xpath
[![Pub](https://img.shields.io/pub/v/html_xpath.svg?style=flat-square)](https://pub.dartlang.org/packages/xpath_parse)
[![support](https://img.shields.io/badge/platform-dart%20vm-ff69b4.svg?style=flat-square)](https://github.com/codingfd/xpath)

XPath selector based on html.

Null safety version of [xpath_parse](https://pub.flutter-io.cn/packages/xpath_parse)
## Get started
### Add dependency
```yaml
dependencies:
  xpath_parse: lastVersion
```
### Super simple to use

```dart
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

XPath.source(html).query("//div/a/text()").list()

```

more simple refer to [this](https://github.com/simonkimi/xpath/blob/master/example/xpath_example.dart)



## Syntax supported:
|Name|Expression|
|---|---|
|immediate parent|/|
|parent|//|
|attribute|	[@key=value]|
|nth child|	tag[n]|
|attribute|	/@key|
|wildcard in tagname| /*|
|function|function()|

### Extended syntax supported:

These XPath syntax are extended only in Xsoup (for convenience in extracting HTML, refer to Jsoup CSS Selector):

|Name|Expression|Support|
|---|---|---|
|attribute value not equals|[@key!=value]|√|
|attribute value start with|[@key~=value]|√|
|attribute value end with|[@key$=value]|√|
|attribute value contains|[@key*=value]|√|
|attribute value match regex|[@key~=value]|√|