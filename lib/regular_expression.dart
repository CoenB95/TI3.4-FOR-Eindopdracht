import 'dart:collection';

enum Operator { PLUS, STAR, OR, DOT, ONE }

class RegularExpression {
  Operator operator;
  String terminals;

  // De mogelijke operatoren voor een reguliere expressie (+, *, |, .)
  // Daarnaast ook een operator definitie voor 1 keer repeteren (default)


  RegularExpression left;
  RegularExpression right;

  static final Comparator<String> compareByLength = (String s1, String s2) {
    if (s1.length == s2.length) {
      return s1.compareTo(s2);
    } else {
      return s1.length - s2.length;
    }
  };

  RegularExpression([String p = ""]) {
    operator = Operator.ONE;
    terminals = p;
    left = null;
    right = null;
  }

  RegularExpression plus() {
    RegularExpression result = RegularExpression();
    result.operator = Operator.PLUS;
    result.left = this;
    return result;
  }

  RegularExpression star() {
    RegularExpression result = RegularExpression();
    result.operator = Operator.STAR;
    result.left = this;
    return result;
  }

  RegularExpression or(RegularExpression e2) {
    RegularExpression result = RegularExpression();
    result.operator = Operator.OR;
    result.left = this;
    result.right = e2;
    return result;
  }

  RegularExpression dot(RegularExpression e2) {
    RegularExpression result = RegularExpression();
    result.operator = Operator.DOT;
    result.left = this;
    result.right = e2;
    return result;
  }

  Set<String> generate(int maxCharCount) {
    Set<String> emptyLanguage = SplayTreeSet<String>(compareByLength);
    Set<String> languageResult = SplayTreeSet<String>(compareByLength);

    Set<String> languageLeft, languageRight;

    if (maxCharCount < 1) return {};

    switch (this.operator) {
      case Operator.ONE:
        languageResult.add(terminals);
        break;
      case Operator.OR:
        languageLeft =
        left == null ? emptyLanguage : left.generate(maxCharCount - 1);
        languageRight =
        right == null ? emptyLanguage : right.generate(maxCharCount - 1);
        languageResult.addAll(languageLeft);
        languageResult.addAll(languageRight);
        break;
      case Operator.DOT:
        languageLeft =
        left == null ? emptyLanguage : left.generate(maxCharCount - 1);
        languageRight =
        right == null ? emptyLanguage : right.generate(maxCharCount - 1);
        for (String s1 in languageLeft)
          for (String s2 in languageRight) {
            languageResult.add(s1 + s2);
          }
        break;

    // STAR(*) en PLUS(+) kunnen we bijna op dezelfde manier uitwerken:
      case Operator.STAR:
      case Operator.PLUS:
        languageLeft =
        left == null ? emptyLanguage : left.generate(maxCharCount - 1);
        languageResult.addAll(languageLeft);
        for (int i = 1; i < maxCharCount; i++) {
          HashSet<String> languageTemp = HashSet.from(languageResult);
          for (String s1 in languageLeft) {
            for (String s2 in languageTemp) {
              languageResult.add(s1 + s2);
            }
          }
        }
        if (this.operator == Operator.STAR) {
          languageResult.add("");
        }
        break;
      default:
        print(
            "getLanguage is nog niet gedefinieerd voor de operator: $operator");
        break;
    }
    return languageResult;
  }
}