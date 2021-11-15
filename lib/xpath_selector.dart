import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:xpath_parse/token_kind.dart';
import 'package:xpath_parse/xpath_parser.dart';

class XPath {
  XPath(this.rootElement);

  final Node rootElement;

  ///parse [html] to node
  ///
  factory XPath.source(String html) {
    final node = parse(html).documentElement;
    if (node == null) {
      throw Exception('html is null');
    }
    return XPath(node);
  }

  ///query data from [rootElement] by [xpath]
  ///
  SelectorEvaluator query(String xpath) {
    final evaluator = SelectorEvaluator();
    evaluator.matchSelectorGroup(rootElement, parseSelectorGroup(xpath));
    return evaluator;
  }
}

class SelectorEvaluator extends VisitorBase {
  late Element _element;

  // 结果
  var _results = <Element>[];
  final _temps = <Element>[];
  String? _output;

  ///select elements from node or node.child  which match selector
  ///
  void matchSelector(Node? node, Selector selector) {
    _temps.clear();
    if (node is! Element) return;
    switch (selector.operatorKind) {
      case TokenKind.child:
        {
          for (var item in node.nodes) {
            if (item is! Element) continue;
            _element = item;
            if (selector.visit(this)) {
              _temps.add(item);
            }
          }
          _removeIfNotMatchPosition(selector);
          _results.addAll(_temps);
        }
        break;
      case TokenKind.root:
        for (var item in node.nodes) {
          if (item is! Element) continue;
          _element = item;
          if (selector.visit(this)) {
            _temps.add(item);
          }
        }
        _removeIfNotMatchPosition(selector);
        _results.addAll(_temps);
        for (var item in node.nodes) {
          matchSelector(item, selector);
        }

        break;
      case TokenKind.current:
        _element = node;
        if (selector.visit(this)) {
          _results.add(node);
        }
        break;
      case TokenKind.parent:
        _element = node.parent!;
        if (selector.visit(this)) {
          _results.add(_element);
        }
        break;
    }
  }

  ///select elements from node or node.child  which match group
  ///
  void matchSelectorGroup(Node node, SelectorGroup group) {
    _output = group.output;
    _results = [node as Element];
    for (var selector in group.selectors) {
      var list = List.of(_results);
      _results.clear();
      for (var item in list) {
        matchSelector(item, selector);
      }
    }
  }

  ///return first of  [list]
  ///
  String get() {
    final data = list();
    if (data.isNotEmpty) {
      return data.first;
    } else {
      return "";
    }
  }

  ///return List<String> form [_results] output text
  ///
  List<String> list() {
    final list = <String>[];

    if (_output == "/text()") {
      for (final element in elements()) {
        list.add(element.text.trim());
      }
    } else if (_output == "//text()") {
      void getTextByElement(List<Element> elements) {
        for (final item in elements) {
          list.add(item.text.trim());
          getTextByElement(item.children);
        }
      }

      getTextByElement(elements());
    } else if (_output?.startsWith("/@") == true) {
      final attr = _output!.substring(2, _output!.length);
      for (final element in elements()) {
        final attrValue = element.attributes[attr]?.trim();
        if (attrValue != null) {
          list.add(attrValue);
        }
      }
    } else if (_output?.startsWith("//@") == true) {
      final attr = _output!.substring(3, _output!.length);
      void getAttrByElements(List<Element> elements) {
        for (final element in elements) {
          final attrValue = element.attributes[attr]?.trim();
          if (attrValue != null) {
            list.add(attrValue);
          }
        }
        for (final element in elements) {
          getAttrByElements(element.children);
        }
      }

      getAttrByElements(elements());
    } else {
      for (final element in elements()) {
        list.add(element.outerHtml);
      }
    }
    if (list.isEmpty) {
      print("xpath query result is empty");
    }
    return list;
  }

  List<Element> elements() => _results;

  _unsupported(selector) =>
      FormatException("'$selector' is not a valid selector");

  @override
  bool visitAttributeSelector(AttributeSelector node) {
    // Match name first
    final value = _element.attributes[node.name.toLowerCase()];
    if (value == null) return false;

    if (node.operatorKind == TokenKind.noMatch) return true;

    final select = '${node.value}';
    switch (node.operatorKind) {
      case TokenKind.equals:
        return value == select;
      case TokenKind.notEquals:
        return value != select;
      case TokenKind.includes:
        return value.split(' ').any((v) => v.isNotEmpty && v == select);
      case TokenKind.prefixMatch:
        return value.startsWith(select);
      case TokenKind.suffixMatch:
        return value.endsWith(select);
      case TokenKind.substringMatch:
        return value.contains(select);
      default:
        throw _unsupported(node);
    }
  }

  @override
  bool visitElementSelector(ElementSelector node) =>
      node.isWildcard || _element.localName == node.name.toLowerCase();

  @override
  bool visitPositionSelector(PositionSelector node) {
    final index = _temps.indexOf(_element) + 1;
    if (index == -1) return false;
    final value = node.value;
    if (node._position == TokenKind.num) {
      return index == value;
    } else if (node._position == TokenKind.position) {
      switch (node.operatorKind) {
        case TokenKind.greater:
          return index > value;
        case TokenKind.greaterOrEquals:
          return index >= value;
        case TokenKind.less:
          return index < value;
        case TokenKind.lessOrEquals:
          return index <= value;
        default:
          throw _unsupported(node);
      }
    } else if (node._position == TokenKind.last) {
      switch (node.operatorKind) {
        case TokenKind.minus:
          return index == _temps.length - value - 1;
        case TokenKind.noMatch:
          return index >= _temps.length - 1;
        default:
          throw _unsupported(node);
      }
    } else {
      throw _unsupported(node);
    }
  }

  @override
  bool visitSelector(Selector node) {
    for (var s in node.simpleSelectors) {
      if (!s.visit(this)) return false;
    }
    return true;
  }

  void _removeIfNotMatchPosition(Selector node) {
    _temps.removeWhere((item) {
      _element = item;
      return node.positionSelector?.visit(this) == false;
    });
  }

  @override
  visitSimpleSelector(SimpleSelector node) => false;
}

///
/// select element which match [Selector]
///
class SelectorGroup {
  final List<Selector> selectors;
  final String source;
  final String? output;

  SelectorGroup(this.selectors, this.output, this.source);
}

///
/// select element which match [SimpleSelector]
///
class Selector {
  /// [TokenKind.child]
  /// [TokenKind.root]
  /// [TokenKind.CURRENT]
  /// [TokenKind.PARENT]
  ///
  final int _nodeType;

  final List<SimpleSelector> simpleSelectors;

  PositionSelector? positionSelector;

  int get operatorKind => _nodeType;

  Selector(this._nodeType, this.simpleSelectors);

  bool visit(VisitorBase visitor) => visitor.visitSelector(this);
}

class SimpleSelector {
  final String _name;
  final String _source;

  SimpleSelector(this._name, this._source);

  String get name => _name;

  bool get isWildcard => _name == "*";

  ///transfer  [VisitorBase.visitSimpleSelector]
  visit(VisitorBase visitor) => visitor.visitSimpleSelector(this);

  @override
  String toString() => _source;
}

/// select name of elements
class ElementSelector extends SimpleSelector {
  ElementSelector(String name, String source) : super(name, source);

  ///transfer  [VisitorBase.visitElementSelector]
  @override
  visit(VisitorBase visitor) => visitor.visitElementSelector(this);

  @override
  String toString() => name;
}

///select attr of elements
class AttributeSelector extends SimpleSelector {
  final int _op;
  final dynamic _value;

  AttributeSelector(String name, this._op, this._value, String source)
      : super(name, source);

  int get operatorKind => _op;

  get value => _value;

  ///transfer  [VisitorBase.visitAttributeSelector]
  @override
  visit(VisitorBase visitor) => visitor.visitAttributeSelector(this);
}

///select position of elements
class PositionSelector extends SimpleSelector {
  // last() or position()
  final int _position;

  // >  >=  <  <=  or null
  final int? _op;
  final int? _value;

  PositionSelector(this._position, this._op, this._value, String source)
      : super("*", source);

  int? get operatorKind => _op;

  get value => _value;

  ///transfer  [VisitorBase.visitPositionSelector]
  @override
  visit(VisitorBase visitor) => visitor.visitPositionSelector(this);
}

abstract class VisitorBase {
  visitSimpleSelector(SimpleSelector node);

  ///return [bool] type
  ///if element enable visit by ElementSelector  true
  ///else   false
  bool visitElementSelector(ElementSelector node);

  ///return [bool] type
  ///if element enable visit by AttributeSelector  true
  ///else   false
  bool visitAttributeSelector(AttributeSelector node);

  ///return [bool] type
  ///if element enable visit by PositionSelector  true
  ///else   false
  bool visitPositionSelector(PositionSelector node);

  ///return [bool] type
  ///if element enable visit by selector  true
  ///else   false
  bool visitSelector(Selector node);
}
//</editor-fold>
