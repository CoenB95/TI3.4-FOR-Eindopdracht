import 'dart:collection';

import 'package:TI3/alphabet.dart';
import 'package:TI3/formal_language.dart';

enum Operator { PLUS, STAR, OR, DOT, ONE }

class RegularExpression implements FormalLanguage {
  Alphabet get alphabet => Alphabet(_computeAlphabet());

  Operator operation;
  String terminal;

  RegularExpression left;
  RegularExpression right;

  static final Comparator<String> compareByLength = (String s1, String s2) {
    if (s1.length == s2.length) {
      return s1.compareTo(s2);
    } else {
      return s1.length - s2.length;
    }
  };

  RegularExpression._impl(this.operation,
      {this.terminal = '', this.left, this.right});

  factory RegularExpression.one(String terminal) {
    if (terminal.length != 1) throw StateError('Terminal must be 1 character.');
    return RegularExpression._impl(Operator.ONE, terminal: terminal);
  }

  RegularExpression plus() =>
      RegularExpression._impl(Operator.PLUS, left: this);

  RegularExpression star() =>
      RegularExpression._impl(Operator.STAR, left: this);

  RegularExpression or(RegularExpression e2) =>
      RegularExpression._impl(Operator.OR, left: this, right: e2);

  RegularExpression dot(RegularExpression e2) =>
      RegularExpression._impl(Operator.DOT, left: this, right: e2);

  Set<String> _computeAlphabet() {
    Set<String> result = {};

    switch (this.operation) {
      case Operator.ONE:
        result.add(terminal);
        break;
      case Operator.OR:
      case Operator.DOT:
      case Operator.STAR:
      case Operator.PLUS:
        result.addAll(left == null ? {} : left._computeAlphabet());
        result.addAll(right == null ? {} : right._computeAlphabet());
        break;
      default:
        throw StateError(
            "Error generating language from regex: unknown operator '$operation'");
        break;
    }
    return result;
  }

  Set<String> generate({int maxSteps = 5}) {
    Set<String> emptyLanguage = SplayTreeSet<String>(compareByLength);
    Set<String> languageResult = SplayTreeSet<String>(compareByLength);

    Set<String> languageLeft, languageRight;

    maxSteps--;
    if (maxSteps < 0) return {};

    switch (this.operation) {
      case Operator.ONE:
        languageResult.add(terminal);
        break;
      case Operator.OR:
        languageLeft =
            left == null ? emptyLanguage : left.generate(maxSteps: maxSteps);
        languageRight =
            right == null ? emptyLanguage : right.generate(maxSteps: maxSteps);
        languageResult.addAll(languageLeft);
        languageResult.addAll(languageRight);
        break;
      case Operator.DOT:
        languageLeft =
            left == null ? emptyLanguage : left.generate(maxSteps: maxSteps);
        languageRight =
            right == null ? emptyLanguage : right.generate(maxSteps: maxSteps);
        for (String s1 in languageLeft)
          for (String s2 in languageRight) {
            languageResult.add(s1 + s2);
          }
        break;
      case Operator.STAR:
      case Operator.PLUS:
        languageLeft =
            left == null ? emptyLanguage : left.generate(maxSteps: maxSteps);
        languageResult.addAll(languageLeft);
        for (int i = 1; i < maxSteps; i++) {
          HashSet<String> languageTemp = HashSet.from(languageResult);
          for (String s1 in languageLeft) {
            for (String s2 in languageTemp) {
              languageResult.add(s1 + s2);
            }
          }
        }
        if (this.operation == Operator.STAR) {
          languageResult.add("");
        }
        break;
      default:
        throw StateError(
            "Error generating language from regex: unknown operator '$operation'");
        break;
    }
    return languageResult;
  }

  @override
  bool hasMatch(String input) {
    throw UnimplementedError();
  }

  @override
  String toString() {
    switch (operation) {
      case Operator.PLUS:
        return 'ONE OR MORE TIMES ${left.toString()}';
      case Operator.STAR:
        return 'ZERO OR MORE TIMES ${left.toString()}';
      case Operator.OR:
        return '(${left.toString()}) OR (${right.toString()})';
      case Operator.DOT:
        return '${left.toString()} THEN ${right.toString()}';
      case Operator.ONE:
        return terminal;
      default:
        return '?';
    }
  }
}
