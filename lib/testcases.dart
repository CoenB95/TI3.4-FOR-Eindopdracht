import 'package:TI3/formal_language.dart';

class LessonTestSets {
  //DFA: contains 'ab'
  static NonDeterministicFiniteAutomaton testset1() {
    var dfa = NonDeterministicFiniteAutomaton();
    var q0 = FiniteAutomatonState('q0');
    var q1 = FiniteAutomatonState('q1');
    var q2 = FiniteAutomatonState('q2', endState: true);

    dfa.addStartState(q0);
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
    var ndfa = NonDeterministicFiniteAutomaton();
    var q0 = FiniteAutomatonState('q0');
    var q1 = FiniteAutomatonState('q1');
    var q2 = FiniteAutomatonState('q2', endState: true);

    ndfa.addStartState(q0);
    q0.addTransition(q0, 'a');
    q0.addTransition(q0, 'b');
    q0.addTransition(q1, 'a');
    q1.addTransition(q2, 'b');
    q2.addTransition(q2, 'a');
    q2.addTransition(q2, 'b');

    return ndfa;
  }
}
