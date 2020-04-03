import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:xpath_parse/token_kind.dart';
import 'package:xpath_parse/xpath_parser.dart';


class XPath {
  final rootElement;

  XPath(this.rootElement);

  static XPath source(String html) {
    var node = parse(html).documentElement;
    var evaluator = XPath(node);
    return evaluator;
  }

  SelectorEvaluator query(String xpath) {
    var evaluator = SelectorEvaluator();
    evaluator.matchSelectorGroup(rootElement, parseSelectorGroup(xpath));
    return evaluator;
  }
}

class SelectorEvaluator extends VisitorBase {
  Element _element;

  //结果
  var _results = <Element>[];
  var _temps = <Element>[];
  String _output;

  SelectorEvaluator query(String xpath) {
    return this;
  }

  void matchSelector(Node node, Selector selector) {
    _temps.clear();
    if (node is! Element) return;
    switch (selector.operatorKind) {
      case TokenKind.CHILD:
        {
          for (var item in node.nodes) {
            if (item is! Element) continue;
            _element = item;
            if (selector.visit(this)) {
              _temps.add(item);
            }
          }
          removeIfNotMatchPosition(selector);
          _results.addAll(_temps);
        }
        break;
      case TokenKind.ROOT:
        for (var item in node.nodes) {
          if (item is! Element) continue;
          _element = item;
          if (selector.visit(this)) {
            _temps.add(item);
          }
        }
        removeIfNotMatchPosition(selector);
        _results.addAll(_temps);
        for (var item in node.nodes) {
          matchSelector(item, selector);
        }

        break;
      case TokenKind.CURRENT:
        _element = node;
        if (selector.visit(this)) {
          _results.add(node);
        }
        break;
      case TokenKind.PARENT:
        _element = node.parent;
        if (selector.visit(this)) {
          _results.add(_element);
        }
        break;
    }
  }

  void matchSelectorGroup(Node node, SelectorGroup group) {
    _output = group.output;
    _results = [node];
    for (var selector in group.selectors) {
      var list = List.of(_results);
      _results.clear();
      for (var item in list) {
        matchSelector(item, selector);
      }
    }
  }

  String get() {
    var data = list();
    if (data.isNotEmpty) {
      return data.first;
    } else {
      return "";
    }
  }

  List<String> list() {
    var list = <String>[];

    if (_output == "/text()") {
      for (var element in elements()) {
        list.add(element.text.trim());
      }
    } else if (_output == "//text()") {
      void getTextByElement(List<Element> elements) {
        for (var item in elements) {
          list.add(item.text.trim());
          getTextByElement(item.children);
        }
      }

      getTextByElement(elements());
    } else if (_output?.startsWith("/@") == true) {
      var attr = _output.substring(2, _output.length);
      for (var element in elements()) {
        var attrValue = element.attributes[attr].trim();
        if (attrValue != null) {
          list.add(attrValue);
        }
      }
    } else if (_output?.startsWith("//@") == true) {
      var attr = _output.substring(3, _output.length);
      void getAttrByElements(List<Element> elements){
        for (var element in elements) {
          var attrValue = element.attributes[attr].trim();
          if (attrValue != null) {
            list.add(attrValue);
          }
        }
        for (var element in elements) {
          getAttrByElements(element.children);
        }
      }
      getAttrByElements(elements());
    } else {
      for (var element in elements()) {
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
  bool visitAttributeSelector(AttributeSelector selector) {
    // Match name first
    var value = _element.attributes[selector.name.toLowerCase()];
    if (value == null) return false;

    if (selector.operatorKind == TokenKind.NO_MATCH) return true;

    var select = '${selector.value}';
    switch (selector.operatorKind) {
      case TokenKind.EQUALS:
        return value == select;
      case TokenKind.NOT_EQUALS:
        return value != select;
      case TokenKind.INCLUDES:
        return value.split(' ').any((v) => v.isNotEmpty && v == select);
      case TokenKind.PREFIX_MATCH:
        return value.startsWith(select);
      case TokenKind.SUFFIX_MATCH:
        return value.endsWith(select);
      case TokenKind.SUBSTRING_MATCH:
        return value.contains(select);
      default:
        throw _unsupported(selector);
    }
  }

  @override
  bool visitElementSelector(ElementSelector selector) =>
      selector.isWildcard || _element.localName == selector.name.toLowerCase();

  @override
  bool visitPositionSelector(PositionSelector selector) {
    var index = _temps.indexOf(_element) + 1;
    if (index == -1) return false;
    var value = selector.value;
    if (selector._position == TokenKind.NUM) {
      return index == value;
    } else if (selector._position == TokenKind.POSITION) {
      switch (selector.operatorKind) {
        case TokenKind.GREATER:
          return index > value;
        case TokenKind.GREATER_OR_EQUALS:
          return index >= value;
        case TokenKind.LESS:
          return index < value;
        case TokenKind.LESS_OR_EQUALS:
          return index <= value;
        default:
          throw _unsupported(selector);
      }
    } else if (selector._position == TokenKind.LAST) {
      switch (selector.operatorKind) {
        case TokenKind.MINUS:
          return index == _temps.length - value - 1;
        case TokenKind.NO_MATCH:
          return index >= _temps.length - 1;
        default:
          throw _unsupported(selector);
      }
    } else {
      throw _unsupported(selector);
    }
  }

  @override
  bool visitSelector(Selector selector) {
    var result = true;
    for (var s in selector.simpleSelectors) {
      result = s.visit(this);
      if (!result) break;
    }
    return result;
  }

  void removeIfNotMatchPosition(Selector node) {
    _temps.removeWhere((item) {
      _element = item;
      return node.positionSelector?.visit(this) == false;
    });
  }

  @override
  visitSimpleSelector(SimpleSelector node) => false;
}

class SelectorGroup {
  final List<Selector> selectors;
  final String source;
  final String output;

  SelectorGroup(this.selectors, this.output, this.source);
}

class Selector {
  final int _nodeType;

  final List<SimpleSelector> simpleSelectors;

  PositionSelector positionSelector;

  int get operatorKind => _nodeType;

  Selector(this._nodeType, this.simpleSelectors);

  bool visit(VisitorBase visitor) => visitor.visitSelector(this);
}

//<editor-fold desc="selector for element attr  position ..">
// All other selectors (element, #id, .class, attribute, pseudo, negation,
// namespace, *) are derived from this selector.
class SimpleSelector {
  final String _name;
  final String _source;

  SimpleSelector(this._name, this._source);

  String get name => _name;

  bool get isWildcard => _name == "*";

  visit(VisitorBase visitor) => visitor.visitSimpleSelector(this);

  @override
  String toString() => _source;
}

// element name
class ElementSelector extends SimpleSelector {
  ElementSelector(String name, String source) : super(name, source);

  visit(VisitorBase visitor) => visitor.visitElementSelector(this);

  ElementSelector clone() => ElementSelector(_name, _source);

  String toString() => name;
}

// [attr op value]
class AttributeSelector extends SimpleSelector {
  final int _op;
  final _value;

  AttributeSelector(String name, this._op, this._value, String source)
      : super(name, source);

  int get operatorKind => _op;

  get value => _value;

  String matchOperator() {
    /*   switch (_op) {
      case TokenKind.EQUALS:
        return '=';
      case TokenKind.INCLUDES:
        return '~=';
      case TokenKind.DASH_MATCH:
        return '|=';
      case TokenKind.PREFIX_MATCH:
        return '^=';
      case TokenKind.SUFFIX_MATCH:
        return '\$=';
      case TokenKind.SUBSTRING_MATCH:
        return '*=';
      case TokenKind.NO_MATCH:
        return '';
    }
    return null;*/
  }

  // Return the TokenKind for operator used by visitAttributeSelector.
  String matchOperatorAsTokenString() {
    /* switch (_op) {
      case TokenKind.EQUALS:
        return 'EQUALS';
      case TokenKind.INCLUDES:
        return 'INCLUDES';
      case TokenKind.DASH_MATCH:
        return 'DASH_MATCH';
      case TokenKind.PREFIX_MATCH:
        return 'PREFIX_MATCH';
      case TokenKind.SUFFIX_MATCH:
        return 'SUFFIX_MATCH';
      case TokenKind.SUBSTRING_MATCH:
        return 'SUBSTRING_MATCH';
    }
    return null;*/
  }

  AttributeSelector clone() => AttributeSelector(_name, _op, _value, _source);

  visit(VisitorBase visitor) => visitor.visitAttributeSelector(this);
}

// list position of  elements
class PositionSelector extends SimpleSelector {
  // last() position()
  final int _position;

  // >  >=  <  <=  or null
  final int _op;
  final int _value;

  PositionSelector(this._position, this._op, this._value, String source)
      : super("*", source);

//  static PositionSelector new1(int value, source) => PositionSelector(
//      "*", TokenKind.NO_MATCH, TokenKind.NO_MATCH, value, source);

  int get operatorKind => _op;

  get value => _value;

  visit(VisitorBase visitor) => visitor.visitPositionSelector(this);
}

abstract class VisitorBase {
  visitSimpleSelector(SimpleSelector node);

  bool visitElementSelector(ElementSelector node);

  bool visitAttributeSelector(AttributeSelector node);

  bool visitPositionSelector(PositionSelector node);

  bool visitSelector(Selector node);

//  bool visitSelectorGroup(SelectorGroup node);
}
//</editor-fold>
