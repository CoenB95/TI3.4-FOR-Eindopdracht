import 'package:TI3/formal_language.dart';

main(List<String> arguments) {
  print('Hello world!');
  testCase1_1();
  testCase1_2();
}

void testCase1_1() {
  print("\nTesting Contains 'ab', deterministic");

  var q0 = FiniteAutomatonState('q0');
  var q1 = FiniteAutomatonState('q1');
  var q2 = FiniteAutomatonState('q2', endState: true);

  q0.addTransition('a', q1);
  q0.addTransition('b', q0);
  q1.addTransition('a', q1);
  q1.addTransition('b', q2);
  q2.addTransition('a', q2);
  q2.addTransition('b', q2);

  testContainsAB(q0);
}

void testCase1_2() {
  print("\nTesting Contains 'ab', non-deterministic");

  var q0 = FiniteAutomatonState('q0');
  var q1 = FiniteAutomatonState('q1');
  var q2 = FiniteAutomatonState('q2', endState: true);

  q0.addTransition('a', q0);
  q0.addTransition('b', q0);
  q0.addTransition('a', q1);
  q1.addTransition('b', q2);
  q2.addTransition('a', q2);
  q2.addTransition('b', q2);

  testContainsAB(q0);
}

void testContainsAB(FiniteAutomatonState ndfa) {
  print('Transactions:\n -${ndfa.listTransactions([]).join('\n -')}');

  print('Is expression a DFA? ${ndfa.isDeterministic() ? 'yes': 'no'}');

  assert (!ndfa.hasMatch('a'));
  assert (!ndfa.hasMatch('b'));

  assert (!ndfa.hasMatch('aa'));
  assert (ndfa.hasMatch('ab'));
  assert (!ndfa.hasMatch('ba'));
  assert (!ndfa.hasMatch('bb'));

  assert (!ndfa.hasMatch('aaa'));
  assert (ndfa.hasMatch('aab'));
  assert (ndfa.hasMatch('aba'));
  assert (ndfa.hasMatch('abb'));
  assert (!ndfa.hasMatch('baa'));
  assert (ndfa.hasMatch('bab'));
  assert (!ndfa.hasMatch('bba'));
  assert (!ndfa.hasMatch('bbb'));

  assert (!ndfa.hasMatch('aaaa'));
  assert (ndfa.hasMatch('aaab'));
  assert (ndfa.hasMatch('aaba'));
  assert (ndfa.hasMatch('aabb'));
  assert (ndfa.hasMatch('abaa'));
  assert (ndfa.hasMatch('abab'));
  assert (ndfa.hasMatch('abba'));
  assert (ndfa.hasMatch('abbb'));
  assert (!ndfa.hasMatch('baaa'));
  assert (ndfa.hasMatch('baab'));
  assert (ndfa.hasMatch('baba'));
  assert (ndfa.hasMatch('babb'));
  assert (!ndfa.hasMatch('bbaa'));
  assert (ndfa.hasMatch('bbab'));
  assert (!ndfa.hasMatch('bbba'));
  assert (!ndfa.hasMatch('bbbb'));

  print('All is well with this expression!');
}