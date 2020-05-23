import 'package:TI3/regular_expression.dart';

import 'finite_automaton.dart';
class Thompson {
  static NonDeterministicFiniteAutomaton convertRegexToNDFA(RegularExpression regex) {
    NonDeterministicFiniteAutomaton ndfa = NonDeterministicFiniteAutomaton(regex.alphabet);
    FiniteAutomatonState start = ndfa.createState('S', startState: true);
    FiniteAutomatonState end = ndfa.createState('F', endState: true);
    _thompsonConstruction(ndfa, start, end, regex);
    return ndfa;
  }

  static int _thompsonConstruction(NonDeterministicFiniteAutomaton ndfa, FiniteAutomatonState left, FiniteAutomatonState right,
      RegularExpression regex, [int stateCount = 0]) {
    switch (regex.operation) {
      case Operator.ONE:
        left.addTransition(right, regex.terminal);
        break;
      case Operator.PLUS:
      case Operator.STAR:
        FiniteAutomatonState q1 = ndfa.createState('Q${stateCount + 1}');
        FiniteAutomatonState q2 = ndfa.createState('Q${stateCount + 2}');
        stateCount += 2;
        left.addTransition(q1);
        q2.addTransition(right);
        q2.addTransition(q1);
        if (regex.operation == Operator.STAR)
          left.addTransition(right);
        stateCount = _thompsonConstruction(ndfa, q1, q2, regex.left, stateCount);
        break;
      case Operator.OR:
        FiniteAutomatonState q1 = ndfa.createState('Q${stateCount + 1}');
        FiniteAutomatonState q2 = ndfa.createState('Q${stateCount + 2}');
        FiniteAutomatonState q3 = ndfa.createState('Q${stateCount + 3}');
        FiniteAutomatonState q4 = ndfa.createState('Q${stateCount + 4}');
        stateCount += 4;
        left.addTransition(q1);
        q2.addTransition(right);
        left.addTransition(q3);
        q4.addTransition(right);
        stateCount = _thompsonConstruction(ndfa, q1, q2, regex.left, stateCount);
        stateCount = _thompsonConstruction(ndfa, q3, q4, regex.right, stateCount);
        break;
      case Operator.DOT:
        FiniteAutomatonState q1 = ndfa.createState('Q${stateCount + 1}');
        stateCount += 1;
        stateCount = _thompsonConstruction(ndfa, left, q1, regex.left, stateCount);
        stateCount = _thompsonConstruction(ndfa, q1, right, regex.right, stateCount);
        break;
      // case Operator.EPSILON:
        // left.addTransition(right);
    }
    return stateCount;
  }
}