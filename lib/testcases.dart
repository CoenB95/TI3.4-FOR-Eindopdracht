import 'alphabet.dart';
import 'dfa.dart';
import 'ndfa.dart';
import 'regular_expression.dart';

class TestDFA {
  /// DFA: contains 'ab'
  static DeterministicFiniteAutomaton containsAB() {
    var dfa = DeterministicFiniteAutomaton(Alphabet.ab());
    var q0 = dfa.createState('q0', startState: true);
    var q1 = dfa.createState('q1');
    var q2 = dfa.createState('q2', endState: true);

    dfa.createTransition(q0, q1, 'a');
    dfa.createTransition(q0, q0, 'b');
    dfa.createTransition(q1, q1, 'a');
    dfa.createTransition(q1, q2, 'b');
    dfa.createTransition(q2, q2, 'a');
    dfa.createTransition(q2, q2, 'b');

    return dfa;
  }

  /// DFA: even number of b's
  static DeterministicFiniteAutomaton evenB() {
    var dfa = DeterministicFiniteAutomaton(Alphabet.ab());
    var q0 = dfa.createState('q0', startState: true, endState: true);
    var q1 = dfa.createState('q1');

    dfa.createTransition(q0, q0, 'a');
    dfa.createTransition(q0, q1, 'b');
    dfa.createTransition(q1, q1, 'a');
    dfa.createTransition(q1, q0, 'b');

    return dfa;
  }
}

class TestNDFA {
  /// NDFA: contains 'ab'
  static NonDeterministicFiniteAutomaton containsAB() {
    var ndfa = NonDeterministicFiniteAutomaton(Alphabet.ab());
    var q0 = ndfa.createState('q0', startState: true);
    var q1 = ndfa.createState('q1');
    var q2 = ndfa.createState('q2', endState: true);

    ndfa.createTransition(q0, q0, 'a');
    ndfa.createTransition(q0, q0, 'b');
    ndfa.createTransition(q0, q1, 'a');
    ndfa.createTransition(q1, q2, 'b');
    ndfa.createTransition(q2, q2, 'a');
    ndfa.createTransition(q2, q2, 'b');

    return ndfa;
  }
}

class TestRegex {
  /// Regex: (a|b)*ab(a|b)*
  static RegularExpression containsAB() {
    return RegularExpression.one('a')
        .or(RegularExpression.one('b'))
        .star()
        .dot(RegularExpression.one('a').dot(RegularExpression.one('b')))
        .dot(RegularExpression.one('a').or(RegularExpression.one('b')).star());
  }

  /// Regex: (a|bc)*
  static RegularExpression regex2() {
    return RegularExpression.one('a')
        .or(RegularExpression.one('b').dot(RegularExpression.one('c')))
        .star();
  }

  /// Regex: ((ba*b)|(bb)+|(aa)+)+
  static RegularExpression regex3() {
    return RegularExpression.one('b')
        .dot(RegularExpression.one('a').star())
        .dot(RegularExpression.one('b'))
        .or(RegularExpression.one('b').dot(RegularExpression.one('b')).plus())
        .or(RegularExpression.one('a').dot(RegularExpression.one('a')).plus())
        .plus();
  }
}
