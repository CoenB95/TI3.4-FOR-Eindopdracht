import 'dart:io';

import 'package:TI3/finite_automaton.dart';
import 'package:TI3/testcases.dart';
import 'package:TI3/thompson.dart';

main(List<String> arguments) {
  print('Hello world!');
  testCase1_1();
  testCase1_2();
  testCase1_3();
  testCase1_4();
  testCase1_5();
  var ndfa = NonDeterministicFiniteAutomaton.startWith("input");
  createGraph(ndfa, "input");
}

void createGraph(NonDeterministicFiniteAutomaton ndfa, String name) async {
  print("Generating graph '$name'...");
  String graph = ndfa.toGraph();
  String graphName = 'out/${name}';
  File graphTempFile = File('${graphName}.gv');
  await graphTempFile.writeAsString(graph);
  await Process.run('dot', ['-Tpng', '-o${graphName}.png', '${graphName}.gv']);
  print("Exported as ${graphName}.png");
}

void testCase1_1() {
  print("\nDFA: Testing Contains 'ab', deterministic");
  var ndfa = LessonTestSets.testset1();
  testContainsAB(ndfa, expectDeterministic: true);
  createGraph(ndfa, "test 1.1");
}

void testCase1_2() {
  print("\nDFA: Testing Contains 'ab', non-deterministic");
  var ndfa = LessonTestSets.testset2();
  testContainsAB(ndfa, expectDeterministic: false);
  createGraph(ndfa, "test 1.2");
}

void testCase1_3() {
  print("Regex: Generating language, contains 'ab'");
  var reg = LessonTestSets.testset3();
  print('Language (max: 5):');
  var lang = reg.generate(maxSteps: 5);
  lang.forEach((w) => print('-> $w'));

  print("DFA: Testing Contains 'ab' using regex, deterministic");
  var dfa = LessonTestSets.testset1();
  lang.forEach((w) { assert(dfa.hasMatch(w)); });
  print("DFA: Testing Contains 'ab' using regex, non-deterministic");
  var ndfa = LessonTestSets.testset2();
  lang.forEach((w) { assert(ndfa.hasMatch(w)); });
}

void testCase1_4({int maxSteps = 5}) {
  print("\nTest 4: Regex '(a|bc)*' to NDFA (Thompson contruction)");
  var regex = LessonTestSets.testset4();
  print('Language (max: $maxSteps):');
  var lang = regex.generate(maxSteps: maxSteps);
  lang.forEach((w) => print('-> $w'));
  var ndfa = Thompson.convertRegexToNDFA(regex);
  //lang.forEach((w) { assert(ndfa.hasMatch(w)); });
  createGraph(ndfa, "Test-4-Thompson");
}

void testCase1_5({int maxSteps = 5}) {
  print("\nTest 5: Regex '((ba*b)|(bb)+|(aa)+)+' to NDFA (Thompson contruction)");
  var regex = LessonTestSets.testset5();
  print('Language (max: $maxSteps):');
  var lang = regex.generate(maxSteps: maxSteps);
  lang.forEach((w) => print('-> $w'));
  var ndfa = Thompson.convertRegexToNDFA(regex);
  //lang.forEach((w) { assert(ndfa.hasMatch(w)); });
  createGraph(ndfa, "Test-5-Thompson");
}

void testContainsAB(NonDeterministicFiniteAutomaton ndfa, {bool expectDeterministic}) async {
    print('Transitions:\n -${ndfa.listAllTransitions().join('\n -')}');

  print('Is expression a DFA? ${ndfa.isDeterministic() ? 'yes': 'no'}');
  if (expectDeterministic != null) assert (ndfa.isDeterministic() == expectDeterministic);

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