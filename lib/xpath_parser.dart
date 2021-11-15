import 'package:xpath_parse/token_kind.dart';
import 'package:xpath_parse/xpath_selector.dart';

/// Parse the [XPath] string to [SelectorGroup]
///
SelectorGroup parseSelectorGroup(String xpath) {
  final selectors = <Selector>[];
  String? output;

  final matches = RegExp("//|/").allMatches(xpath).toList();
  final selectorSources = <String>[];
  for (var index = 0; index < matches.length; index++) {
    if (index > 0) {
      selectorSources
          .add(xpath.substring(matches[index - 1].start, matches[index].start));
    }
    if (index == matches.length - 1) {
      selectorSources.add(xpath.substring(matches[index].start, xpath.length));
    }
  }

  final lastSource = selectorSources.last.replaceAll("/", "");
  if (lastSource == "text()" || lastSource.startsWith("@")) {
    output = selectorSources.last;
    selectorSources.removeLast();
  }

  for (final source in selectorSources) {
    selectors.add(_parseSelector(source));
  }

  final firstSelector = selectors.first;
  if (firstSelector.operatorKind == TokenKind.child) {
    final simpleSelector = firstSelector.simpleSelectors.first;
    if (simpleSelector.name != "body" || simpleSelector.name != "head") {
      selectors.insert(
          0, Selector(TokenKind.child, [ElementSelector("body", "/body")]));
    }
  }

  return SelectorGroup(selectors, output, xpath);
}

///parse input string to [Selector]
///
Selector _parseSelector(String input) {
  int type;
  String source;
  final simpleSelectors = <SimpleSelector>[];
  if (input.startsWith("//")) {
    type = TokenKind.root;
    source = input.substring(2, input.length);
  } else if (input.startsWith("/")) {
    type = TokenKind.child;
    source = input.substring(1, input.length);
  } else {
    throw FormatException("'$input' is not a valid xpath query string");
  }

  // 匹配所有父节点
  if (source == "..") {
    return Selector(TokenKind.parent, [ElementSelector("*", "")]);
  }

  final selector = Selector(type, simpleSelectors);

  // 匹配条件
  final match = RegExp("(.+)\\[(.+)\\]").firstMatch(source);
  if (match != null) {
    final elementName = match.group(1);
    simpleSelectors.add(ElementSelector(elementName!, input));
    final group = match.group(2);
    //匹配Attr
    if (group!.startsWith("@")) {
      final m =
          RegExp("^@(.+?)(=|!=|\\^=|~=|\\*=|\\\$=)(.+)\$").firstMatch(group);
      if (m != null) {
        final name = m.group(1);
        final op = TokenKind.matchAttrOperator(m.group(2)!);
        final value = m.group(3)!.replaceAll(RegExp("['\"]"), "");
        simpleSelectors.add(AttributeSelector(name!, op, value, group));
      } else {
        simpleSelectors.add(AttributeSelector(
            group.substring(1, group.length), TokenKind.noMatch, null, group));
      }
    }
    // 匹配数字
    final m = RegExp("^\\d+\$").firstMatch(group);
    if (m != null) {
      final position = int.tryParse(m.group(0)!);
      selector.positionSelector =
          PositionSelector(TokenKind.num, TokenKind.noMatch, position, input);
    }

    // 匹配position()方法
    final m2 = RegExp("^position\\(\\)(<|<=|>|>=)(\\d+)\$").firstMatch(group);
    if (m2 != null) {
      final op = TokenKind.matchPositionOperator(m2.group(1)!);
      final value = int.tryParse(m2.group(2)!);
      selector.positionSelector =
          PositionSelector(TokenKind.position, op, value, input);
    }

    //匹配last()方法
    final m3 = RegExp("^last\\(\\)(-)?(\\d+)?\$").firstMatch(group);
    if (m3 != null) {
      final op = TokenKind.matchPositionOperator(m3.group(1));
      final value = int.tryParse(m3.group(2) ?? "");
      selector.positionSelector =
          PositionSelector(TokenKind.last, op, value, input);
    }
  } else {
    simpleSelectors.add(ElementSelector(source, input));
  }

  return selector;
}
