# xpath
[![Pub](https://img.shields.io/pub/v/xpath_parse.svg?style=flat-square)](https://pub.dartlang.org/packages/xpath_parse)
[![support](https://img.shields.io/badge/platform-flutter%7Cdart%20vm-ff69b4.svg?style=flat-square)](https://github.com/codingfd/xpath)<br>
XPath selector based on html.
## Get started
### Add dependency
```yaml
dependencies:
  xpath_parse: lastVersion
```
### Super simple to use

```dart
final String html = '''
<html>
<div><a href='https://github.com'>github.com</a></div>
<div class="head">head</div>
<table><tr><td>1</td><td>2</td><td>3</td><td>4</td></tr></table>
<div class="end">end</div>
</html>
''';

XPath.source(html).query("//div/a/text()").list()

```

more simple refer to [this](https://github.com/codingfd/xpath/blob/master/test/xpath_test.dart)



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