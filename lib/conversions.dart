import 'dart:collection';

import 'package:collection/collection.dart';

import 'dfa.dart';
import 'finite_automaton.dart';
import 'ndfa.dart';
import 'regular_expression.dart';

extension DeterministicFiniteAutomatonConversions
    on DeterministicFiniteAutomaton {
  NonDeterministicFiniteAutomaton reversed() =>
      FormalLanguageConversions.convertDFAToReversedNDFA(this);
}

extension NonDeterministicFiniteAutomatonConversions
    on NonDeterministicFiniteAutomaton {
  DeterministicFiniteAutomaton toDFA() =>
      FormalLanguageConversions.convertNDFAToDFA(this);
}

extension RegexConversions on RegularExpression {
  NonDeterministicFiniteAutomaton toNDFA() =>
      FormalLanguageConversions.convertRegexToNDFA(this);
}

extension StringConversions on String {
  RegularExpression toRegex() =>
      FormalLanguageConversions.convertStringToRegex(this);
}

class FormalLanguageConversions {
  static NonDeterministicFiniteAutomaton convertDFAToReversedNDFA(
      DeterministicFiniteAutomaton dfa) {
    var ndfa = NonDeterministicFiniteAutomaton(dfa.alphabet);
    dfa.transitions.forEach((t) => ndfa.addTransition(t.reversed()));
    dfa.states.forEach((s) => ndfa.addState(FiniteAutomatonState(s.name,
        isStartState: s.isEndState, isEndState: s.isStartState)));
    return ndfa;
  }

  static DeterministicFiniteAutomaton convertNDFAToDFA(
      NonDeterministicFiniteAutomaton ndfa) {
    var eq = const ListEquality().equals;
    var dfa = DeterministicFiniteAutomaton(ndfa.alphabet);
    var startStates = ndfa.eClosure(ndfa.startStates).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    var startTuple = FiniteAutomatonStateTuple(startStates,
        isStartState: true,
        isEndState: ndfa.startStates.any((s) => s.isEndState));
    dfa.addState(startTuple);
    var traverseTuples = Queue.of([startTuple]);

    while (traverseTuples.isNotEmpty) {
      var tuple = traverseTuples.removeFirst();
      for (var char in ndfa.alphabet.letters) {
        var nextStates = ndfa.deltaE(tuple.states, char).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        var newTuple = FiniteAutomatonStateTuple(nextStates,
            isStartState: eq(startStates, nextStates),
            isEndState: nextStates.any((s) => s.isEndState));
        if (!dfa.states.contains(newTuple)) {
          dfa.addState(newTuple);
          traverseTuples.add(newTuple);
        }
        dfa.createTransition(tuple, newTuple, char);
      }
    }
    return dfa;
  }

  static NonDeterministicFiniteAutomaton convertRegexToNDFA(
      RegularExpression regex) {
    NonDeterministicFiniteAutomaton ndfa =
        NonDeterministicFiniteAutomaton(regex.alphabet);
    FiniteAutomatonState start = ndfa.createState('S', startState: true);
    FiniteAutomatonState end = ndfa.createState('F', endState: true);
    _thompsonConstruction(ndfa, start, end, regex);
    return ndfa;
  }

  static RegularExpression convertStringToRegex(String regexString,
      [int startIndex = 0]) {
    RegularExpression regex;
    RegularExpression previousGroup;

    for (int i = startIndex; i < regexString.length; i++) {
      var char = regexString[i];
      switch (char) {
        case '(':
          int start = i + 1;
          int end = regexString.indexOf(')', i);
          if (end < 0) {
            throw StateError("Missing closing bracket to match"
                " opening bracket at position $i.");
          }

          if (regex == null) {
            regex = previousGroup;
          } else if (previousGroup != null) {
            regex = regex.dot(previousGroup);
          }

          previousGroup = convertStringToRegex(regexString, start);
          i = end;
          break;
        case ')':
          if (regex == null) {
            regex = previousGroup;
          } else if (previousGroup != null) {
            regex = regex.dot(previousGroup);
          }
          return regex;
        case '|':
          int start = i + 1;
          int end = regexString.indexOf(')', i);

          if (regex == null) {
            if (previousGroup == null)
              throw StateError('Missing left side of OR');
            regex = previousGroup;
          } else if (previousGroup != null) {
            regex = regex.dot(previousGroup);
          }

          regex = regex.or(convertStringToRegex(regexString, start));
          previousGroup = null;
          if (end >= 0) {
            return regex;
          } else {
            i = regexString.length;
          }
          break;
        case '+':
          if (previousGroup == null)
            throw StateError('Missing character or group to apply PLUS on'
                ' at position $i');
          if (regex == null) {
            regex = previousGroup.plus();
          } else {
            regex = regex.dot(previousGroup.plus());
          }
          previousGroup = null;
          break;
        case '*':
          if (previousGroup == null)
            throw StateError('Missing character or group to apply STAR on'
                ' at position $i');
          if (regex == null) {
            regex = previousGroup.star();
          } else {
            regex = regex.dot(previousGroup.star());
          }
          previousGroup = null;
          break;
        default:
          if (regex == null) {
            regex = previousGroup;
            previousGroup = RegularExpression.one(char);
          } else if (previousGroup != null) {
            regex = regex.dot(previousGroup);
            previousGroup = RegularExpression.one(char);
          } else {
            previousGroup = RegularExpression.one(char);
          }
          break;
      }
    }

    if (regex == null) {
      regex = previousGroup;
    } else if (previousGroup != null) {
      regex = regex.dot(previousGroup);
    }
    return regex;
  }

  static int _thompsonConstruction(
      NonDeterministicFiniteAutomaton ndfa,
      FiniteAutomatonState left,
      FiniteAutomatonState right,
      RegularExpression regex,
      [int stateCount = 0]) {
    switch (regex.operation) {
      case Operator.ONE:
        ndfa.createTransition(left, right, regex.terminal);
        break;
      case Operator.PLUS:
      case Operator.STAR:
        FiniteAutomatonState q1 = ndfa.createState('Q${stateCount + 1}');
        FiniteAutomatonState q2 = ndfa.createState('Q${stateCount + 2}');
        stateCount += 2;
        ndfa.createTransition(left, q1);
        ndfa.createTransition(q2, right);
        ndfa.createTransition(q2, q1);
        if (regex.operation == Operator.STAR)
          ndfa.createTransition(left, right);
        stateCount =
            _thompsonConstruction(ndfa, q1, q2, regex.left, stateCount);
        break;
      case Operator.OR:
        FiniteAutomatonState q1 = ndfa.createState('Q${stateCount + 1}');
        FiniteAutomatonState q2 = ndfa.createState('Q${stateCount + 2}');
        FiniteAutomatonState q3 = ndfa.createState('Q${stateCount + 3}');
        FiniteAutomatonState q4 = ndfa.createState('Q${stateCount + 4}');
        stateCount += 4;
        ndfa.createTransition(left, q1);
        ndfa.createTransition(q2, right);
        ndfa.createTransition(left, q3);
        ndfa.createTransition(q4, right);
        stateCount =
            _thompsonConstruction(ndfa, q1, q2, regex.left, stateCount);
        stateCount =
            _thompsonConstruction(ndfa, q3, q4, regex.right, stateCount);
        break;
      case Operator.DOT:
        FiniteAutomatonState q1 = ndfa.createState('Q${stateCount + 1}');
        stateCount += 1;
        stateCount =
            _thompsonConstruction(ndfa, left, q1, regex.left, stateCount);
        stateCount =
            _thompsonConstruction(ndfa, q1, right, regex.right, stateCount);
        break;
      // case Operator.EPSILON:
      // left.addTransition(right);
    }
    return stateCount;
  }
}
