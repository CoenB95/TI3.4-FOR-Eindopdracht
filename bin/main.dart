import 'dart:io';

import 'package:TI3/dfa.dart';
import 'package:TI3/finite_automaton.dart';
import 'package:TI3/formal_language.dart';
import 'package:TI3/testcases.dart';
import 'package:TI3/thompson.dart';

bool breakOnAssertFailure = true;

main(List<String> arguments) {
  int maxSteps = 5;
  print('Hello world!');
  var dfa1 = DeterministicFiniteAutomaton.startWith("bbabbabba");
  createGraph(dfa1, "HOI1");
  var dfa2 = DeterministicFiniteAutomaton.endWith("bbabbabba");
  createGraph(dfa2, "HOI2");
  var dfa3 = DeterministicFiniteAutomaton.contains("bbabbabba");
  createGraph(dfa3, "HOI3");
  test1(maxSteps);
  test2(maxSteps);
  test3(maxSteps);
  test4(maxSteps);
  test5(maxSteps);
  test6(maxSteps);
  test7(maxSteps);
}

void test1(int maxSteps) {
  print("\nTest 1: DFA (contains 'ab')");
  var dfa = TestDFA.containsAB();
  printLanguage(dfa, maxSteps);
  assertContainsAB(dfa);
  assertEqualEachOther(dfa, dfa, maxSteps);
  createGraph(dfa, "Test 1");
}

void test2(int maxSteps) {
  print("\nTest 2: NDFA (contains 'ab')");
  var ndfa = TestNDFA.containsAB();
  printLanguage(ndfa, maxSteps);
  assertContainsAB(ndfa);
  createGraph(ndfa, "Test 2");
}

void test3(int maxSteps) {
  print("\nTest 3: Regex '(a|b)*ab(a|b)*' (contains 'ab')");
  var regex = TestRegex.containsAB();
  printLanguage(regex, maxSteps);
  //assertContainsAB(regex);
}

void test4(int maxSteps) {
  print(
      "\nTest 4: Compare 'contains ab' from DFA, NDFA and Regex with each other");
  var dfa = TestDFA.containsAB();
  var ndfa = TestNDFA.containsAB();
  var regex = TestRegex.containsAB();

  print("Test 4a: Compare regex with DFA");
  assertEqualEachOther(regex, dfa, maxSteps);
  print("Test 4b: Compare regex with NDFA");
  assertEqualEachOther(regex, ndfa, maxSteps);
}

void test5(int maxSteps) {
  print("\nTest 5: Regex '(a|bc)*' to NDFA (Thompson contruction)");
  print("Test 5a: The regex");
  var regex = TestRegex.regex2();
  printLanguage(regex, maxSteps);

  print("Test 5b: The NDFA converted from said regex");
  var ndfa = Thompson.convertRegexToNDFA(regex);
  printAutomatonDetails(ndfa);
  assertEqualEachOther(regex, ndfa, maxSteps);
  createGraph(ndfa, "Test 5 (Thompson)");
}

void test6(int maxSteps) {
  print(
      "\nTest 6: Regex '((ba*b)|(bb)+|(aa)+)+' to NDFA (Thompson contruction)");
  print("Test 6a: The regex");
  var regex = TestRegex.regex3();
  printLanguage(regex, maxSteps);

  print("Test 6b: The NDFA converted from said regex");
  var ndfa = Thompson.convertRegexToNDFA(regex);
  printAutomatonDetails(ndfa);
  assertEqualEachOther(regex, ndfa, maxSteps);
  createGraph(ndfa, "Test 6 (Thompson)");
}

void test7(int maxSteps) {
  //var ndfa1 = NonDeterministicFiniteAutomaton.endsWith("bbab");
  var ndfa1 = TestDFA.containsAB();
  var ndfa2 = TestDFA.evenB();
  var ndfa3 = ndfa1.and(ndfa2);
  createGraph(ndfa3, "Test 7");
}

void assertContainsAB(FormalLanguage fl) async {
  Set<String> correctValues = {
    'ab',
    'aab',
    'aba',
    'abb',
    'bab',
    'aaab',
    'aaba',
    'aabb',
    'abab',
    'abaa',
    'abba',
    'abbb',
    'baab',
    'baba',
    'babb',
    'bbab'
  };
  Set<String> incorrectValues = {
    'a',
    'b',
    'aa',
    'ba',
    'bb',
    'aaa',
    'baa',
    'bba',
    'bbb',
    'aaaa',
    'baaa',
    'bbaa',
    'bbba',
    'bbbb'
  };
  bool failed = false;

  print('The next values should match the formal language:');
  for (String value in correctValues) {
    bool check = fl.hasMatch(value);
    print(" - '$value': ${check ? 'OK' : 'ERROR'}");
    if (breakOnAssertFailure)
      assert(check);
    else if (!check) failed = true;
  }

  print('The next values should NOT match the formal language:');
  for (String value in incorrectValues) {
    bool check = !fl.hasMatch(value);
    print(" - !'$value': ${check ? 'OK' : 'ERROR'}");
    if (breakOnAssertFailure)
      assert(check);
    else if (!check) failed = true;
  }

  print('Assert ${failed ? "Failed" : "Succeeded"}');
}

void assertEqualEachOther(
    FormalLanguage fl1, FormalLanguage fl2, int maxSteps) async {
  Set<String> correctValues = fl1.generate(maxSteps: maxSteps);
  bool failed = false;

  print('The next values should match the formal language:');
  for (String value in correctValues) {
    bool check = fl2.hasMatch(value);
    print(" - '$value': ${check ? 'OK' : 'ERROR'}");
    if (breakOnAssertFailure)
      assert(fl2.hasMatch(value));
    else if (!check) failed = true;
  }

  print('Assert ${failed ? "Failed" : "Succeeded"}');
}

void createGraph(FiniteAutomaton fa, String name) async {
  print("Generating graph '$name'...");
  String graph = fa.toGraph();
  String graphName = 'out/${name}';
  File graphTempFile = File('${graphName}.gv');
  await graphTempFile.writeAsString(graph);
  await Process.run('dot', ['-Tpng', '-o${graphName}.png', '${graphName}.gv']);
  print("Exported as ${graphName}.png");
}

void printAutomatonDetails(FiniteAutomaton fa) {
  print('Transitions:');
  fa.transitions.forEach((t) => print(" - $t"));
}

void printLanguage(FormalLanguage fl, int maxSteps) {
  Set<String> lang = fl.generate(maxSteps: maxSteps);
  print('Language (max: $maxSteps):');
  lang.forEach((w) => print(" - '$w'"));
}
