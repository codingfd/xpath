class TokenKind {
  // Path Type
  static const int child = 1; //     /
  static const int root = 2; //       //
  static const int current = 3; //   .
  static const int parent = 4; //    ..

  // List position type
  static const int plus = 11; //               +
  static const int minus = 12; //              -
  static const int greater = 13; //            >
  static const int greaterOrEquals = 14; //  >=
  static const int less = 15; //               <
  static const int lessOrEquals = 16; //     <=

  static const Map<String, int> _positionOperator = {
    "+": plus,
    "-": minus,
    ">": greater,
    ">=": greaterOrEquals,
    "<": less,
    "<=": lessOrEquals
  };

  // Attribute match types:
  static const int equals = 28; //           =
  static const int notEquals = 29; //       !=
  static const int includes = 530; //        ~=
  static const int prefixMatch = 531; //    ^=
  static const int suffixMatch = 532; //    $=
  static const int substringMatch = 533; // *=
  static const int noMatch = 534; // No operator.

  static const Map<String, int> _attrOperator = {
    "=": equals,
    "!=": notEquals,
    "~=": includes,
    "^=": prefixMatch,
    r"$=": suffixMatch,
    "*=": substringMatch
  };

  static const int num = 600; //      [0]
  static const int last = 601; //     last()
  static const int position = 602; // position()

  ///string to position operator
  static int matchPositionOperator(String? text) {
    return _positionOperator[text] ?? noMatch;
  }

  ///string to attr operator
  static int matchAttrOperator(String text) {
    return _attrOperator[text] ?? noMatch;
  }
}
