import 'dart:io';

import 'package:TI3/formal_language.dart';
import 'package:TI3/testcases.dart';

main(List<String> arguments) {
  print('Hello world!');
  testCase1_1();
  testCase1_2();
}

void testCase1_1() {
  print("\nTesting Contains 'ab', deterministic");
  var ndfa = LessonTestSets.testset1();
  testContainsAB(ndfa);
}

void testCase1_2() {
  print("\nTesting Contains 'ab', non-deterministic");
  var ndfa = LessonTestSets.testset1();
  testContainsAB(ndfa);
}

int graphCount = 0;
void testContainsAB(NonDeterministicFiniteAutomaton ndfa) async {
  graphCount++;

  print('Transitions:\n -${ndfa.listAllTransitions().join('\n -')}');

  print('Is expression a DFA? ${ndfa.isDeterministic() ? 'yes': 'no'}');

  print('Finite automaton graph:');
  String graph = ndfa.toGraph();
  String graphName = 'out/graph-${graphCount}';
  File graphTempFile = File('${graphName}.gv');
  await graphTempFile.writeAsString(graph);
  await Process.run('dot', ['-Tpng', '-o${graphName}.png', '${graphName}.gv']);
  print("Exported as ${graphName}.png");

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