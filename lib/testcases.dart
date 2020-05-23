import 'package:TI3/alphabet.dart';
import 'package:TI3/finite_automaton.dart';
import 'package:TI3/regular_expression.dart';

class LessonTestSets {
  //DFA: contains 'ab'
  static NonDeterministicFiniteAutomaton testset1() {
    var dfa = NonDeterministicFiniteAutomaton(Alphabet.ab());
    var q0 = dfa.createState('q0', startState: true);
    var q1 = dfa.createState('q1');
    var q2 = dfa.createState('q2', endState: true);

    q0.addTransition(q1, 'a');
    q0.addTransition(q0, 'b');
    q1.addTransition(q1, 'a');
    q1.addTransition(q2, 'b');
    q2.addTransition(q2, 'a');
    q2.addTransition(q2, 'b');

    return dfa;
  }

  ///NDFA: contains 'ab'
  static NonDeterministicFiniteAutomaton testset2() {
    var ndfa = NonDeterministicFiniteAutomaton(Alphabet.ab());
    var q0 = ndfa.createState('q0', startState: true);
    var q1 = ndfa.createState('q1');
    var q2 = ndfa.createState('q2', endState: true);

    q0.addTransition(q0, 'a');
    q0.addTransition(q0, 'b');
    q0.addTransition(q1, 'a');
    q1.addTransition(q2, 'b');
    q2.addTransition(q2, 'a');
    q2.addTransition(q2, 'b');

    return ndfa;
  }

  // Regex: (a*|b*)ab(a*|b*) "contains ab"
  static RegularExpression testset3() {
    return RegularExpression.one('a').star().or(RegularExpression.one('b').star()).dot(
      RegularExpression.one('a').dot(RegularExpression.one('b')).plus()).dot(
      RegularExpression.one('a').star().or(RegularExpression.one('b').star())
    );
  }

  // Regex: (a|bc)*
  static RegularExpression testset4() {
    return RegularExpression.one('a').or(
      RegularExpression.one('b').dot(RegularExpression.one('c')))
      .star();
  }

  // Regex: ((ba*b)|(bb)+|(aa)+)+
  static RegularExpression testset5() {
    return
    RegularExpression.one('b').dot(RegularExpression.one('a').star()).dot(RegularExpression.one('b'))
    .or(RegularExpression.one('b').dot(RegularExpression.one('b')).plus())
    .or(RegularExpression.one('a').dot(RegularExpression.one('a')).plus())
    .plus()
    ;
  }
}
