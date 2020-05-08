import 'dart:io';

import 'package:TI3/finite_automaton.dart';
import 'package:TI3/testcases.dart';

main(List<String> arguments) {
  print('Hello world!');
  testCase1_1();
  testCase1_2();
  testCase1_3();
}

void testCase1_1() {
  print("\nTesting Contains 'ab', deterministic");
  var ndfa = LessonTestSets.testset1();
  testContainsAB(ndfa,
      expectDeterministic: true);
}

void testCase1_2() {
  print("\nTesting Contains 'ab', non-deterministic");
  var ndfa = LessonTestSets.testset2();
  testContainsAB(ndfa,
      expectDeterministic: false);
}

void testCase1_3() {
  print("\nTesting Contains 'ab', regular expression generation");
  var reg = LessonTestSets.testset3();
  print('Language (max: 4):');
  var lang = reg.generate(4);
  print(lang);
}

int graphCount = 0;
void testContainsAB(NonDeterministicFiniteAutomaton ndfa, {bool expectDeterministic}) async {
  graphCount++;

  print('Transitions:\n -${ndfa.listAllTransitions().join('\n -')}');

  print('Is expression a DFA? ${ndfa.isDeterministic() ? 'yes': 'no'}');
  if (expectDeterministic != null) assert (ndfa.isDeterministic() == expectDeterministic);

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