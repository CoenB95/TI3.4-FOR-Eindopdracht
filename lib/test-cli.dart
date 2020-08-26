import 'dart:convert';
import 'dart:io';

import 'package:TI3/conversions.dart';
import 'package:TI3/dfa.dart';
import 'package:TI3/finite_automaton.dart';
import 'package:TI3/formal_language.dart';
import 'package:TI3/ndfa.dart';
import 'package:TI3/regular_expression.dart';
import 'package:TI3/testcases.dart';

class TestCLI {
  final Encoding encoding;

  TestCLI({this.encoding = systemEncoding});

  Future generate(FormalLanguage fl) async {
    print('Choose maximum amount of steps: [2-9]');
    var maxSteps = int.tryParse(encoding.decode([stdin.readByteSync()]));
    maxSteps = maxSteps ?? 2;
    maxSteps = maxSteps < 2 ? 2 : maxSteps;
    print("Generating language using max $maxSteps step(s) ...");
    var lang = fl.generate(maxSteps: maxSteps).toList();
    lang.sort();
    String fileName = 'out/language';
    File languageTempFile = File('${fileName}.txt');
    var t = languageTempFile.openWrite();
    t.writeln('LANGUAGE:\n');
    lang.forEach((w) => t.writeln(" - '$w'"));
    await t.flush();
    await t.close();
    print("Language exported as ${fileName}.txt");
  }

  Future graph(FiniteAutomaton fa) async {
    print("Generating graph ...");
    String graph = fa.toGraph();
    String graphName = 'out/graph';
    File graphTempFile = File('${graphName}.gv');
    await graphTempFile.writeAsString(graph);
    await Process.run(
        'dot', ['-Tpng', '-o${graphName}.png', '${graphName}.gv']);
    print("Graph exported as ${graphName}.png");
  }

  Future<RegularExpression> inputRegex() async {
    RegularExpression regex;
    do {
      print('Type a regex:');
      String str = await _inputString();
      try {
        regex = str.toRegex();
      } catch (e) {
        print('Failed to parse regex: $e');
        print('Please try again');
      }
    } while (regex == null);
    return regex;
  }

  Future<String> _inputString() async {
    return Future(() {
      stdin.lineMode = true;
      stdin.echoMode = true;
      String result = stdin.readLineSync(encoding: encoding);
      stdin.echoMode = false;
      stdin.lineMode = false;
      return result;
    });
  }

  Future<_CliOption> _optionMenu(
      String headline, List<_CliOption> options) async {
    return Future(() {
      int choice = -1;
      bool choiceMade = false;
      int page = 0;

      do {
        int startIndex = page * 8;
        int endIndex =
            startIndex + 8 <= options.length ? startIndex + 8 : options.length;

        print('|<>| ${headline.toUpperCase().padRight(50)} |<>|');
        if (startIndex > 0) print('| 0| (previous page)');
        for (int i = 0; i < endIndex - startIndex; i++) {
          print('|${(i + 1).toString().padLeft(2)}| '
              '${startIndex + i + 1}. ${options[startIndex + i].title}');
        }
        if (endIndex < options.length) print('| 9| (next page)');
        print('');

        bool pageChange = false;
        do {
          choice = -1;
          var choiceRaw = int.tryParse(encoding.decode([stdin.readByteSync()]));
          if (choiceRaw != null) choice = choiceRaw + page * 8 - 1;
          if (startIndex > 0 && choiceRaw == 0) {
            pageChange = true;
            page--;
          } else if (endIndex < options.length && choiceRaw == 9) {
            pageChange = true;
            page++;
          } else if (choice >= 0 && choice < options.length) {
            choiceMade = true;
          }
        } while (!choiceMade && !pageChange);
      } while (!choiceMade);

      print(" < ${choice + 1}");
      print("You selected: ${options[choice].title}");
      sleep(Duration(milliseconds: 500));
      print('');
      return options[choice];
    });
  }

  Future run() async {
    print('');
    print('<<<==>>> FORMAL LANGUAGE TEST-CLI <<<==>>>');
    print('');
    sleep(Duration(seconds: 2));
    stdin.echoMode = false;
    stdin.lineMode = false;
    await startMenu();
  }

  Future selectActivity(FormalLanguage language) async {
    _CliOption o;

    List<_CliOption> options = [];
    if (language is FiniteAutomaton) {
      options.add(_CliOption('Graph', () => graph(language)));
    }
    if (language is DeterministicFiniteAutomaton) {
      options
          .add(_CliOption('[DFA] Generate Language', () => generate(language)));
      options.add(
          _CliOption('[DFA] Invert', () => selectActivity(language.not())));
      options.add(_CliOption(
          '[DFA] Minimize (reverse, DFA, reverse, DFA)',
          () =>
              selectActivity(language.reversed().toDFA().reversed().toDFA())));
      options.add(_CliOption(
          '[DFA] Reverse -> NDFA', () => selectActivity(language.reversed())));
      options.add(_CliOption(
          '[DFA] Clean up labels', () => selectActivity(language.clean())));
    }
    if (language is NonDeterministicFiniteAutomaton) {
      options.add(_CliOption(
          '[NDFA] Convert To DFA', () => selectActivity(language.toDFA())));
    }
    if (language is RegularExpression) {
      options.add(
          _CliOption('[REGEX] Generate Language', () => generate(language)));
      options.add(_CliOption(
          '[REGEX] Convert To NDFA', () => selectActivity(language.toNDFA())));
    }
    options.add(_CliOption('<= Back', null));

    do {
      o = await _optionMenu("Select action to do with language", options);
      await o.onSelect?.call();
    } while (o.onSelect != null);
  }

  Future selectAutomaton() async {
    _CliOption o;
    do {
      o = await _optionMenu("Select a formal language", [
        _CliOption(
            "[DFA] Starts with 'bbabbabba'",
            () => selectActivity(
                DeterministicFiniteAutomaton.startWith("bbabbabba"))),
        _CliOption(
            "[DFA] Ends with 'bbabbabba'",
            () => selectActivity(
                DeterministicFiniteAutomaton.endWith("bbabbabba"))),
        _CliOption(
            "[DFA] Contains 'bbabbabba'",
            () => selectActivity(
                DeterministicFiniteAutomaton.contains("bbabbabba"))),
        _CliOption(
            "[DFA] Ends with 'bbab' or contains an even amount of 'b'",
            () => selectActivity(DeterministicFiniteAutomaton.endWith("bbab")
                .or(TestDFA.evenB()))),
        _CliOption(
            "[DFA] Starts with 'abcd'",
            () =>
                selectActivity(DeterministicFiniteAutomaton.startWith("abcd"))),
        _CliOption(
            "[DFA] Ends with 'dcba'",
            () => selectActivity(
                DeterministicFiniteAutomaton.endWith("dcba").not())),
        _CliOption("[NDFA] Contains 'ab'",
            () => selectActivity(TestNDFA.containsAB())),
        _CliOption("[REGEX] Contains 'ab'",
            () => selectActivity(TestRegex.containsAB())),
        _CliOption("[REGEX] Build your own!",
            () async => selectActivity(await inputRegex())),
        _CliOption('<= Back', null),
      ]);
      await o.onSelect?.call();
    } while (o.onSelect != null);
  }

  Future startMenu() async {
    _CliOption choice;
    do {
      choice = await _optionMenu("What to do?", [
        _CliOption('Language Selection [REGEX|DFA|NDFA|..]', selectAutomaton),
        _CliOption('Nothing 2', nothing),
        _CliOption('Nothing 3', nothing),
        _CliOption('Nothing 4', nothing),
        _CliOption('Nothing 5', nothing),
        _CliOption('Nothing 6', nothing),
        _CliOption('Nothing 7', nothing),
        _CliOption('Nothing 8', nothing),
        _CliOption('Nothing 9', nothing),
        _CliOption('Nothing 10', nothing),
        _CliOption('Nothing 11', nothing),
        _CliOption('Nothing 12', nothing),
        _CliOption('Nothing 13', nothing),
        _CliOption('Exit', null),
      ]);
      await choice.onSelect?.call();
    } while (choice.onSelect != null);
    stop();
  }

  void stop() {
    print('Thanks for stopping by o/');
    sleep(Duration(seconds: 1));
  }

  Future nothing() async {
    print("Like I said, nothing");
    await sleep(Duration(seconds: 1));
  }
}

class _CliOption {
  final String title;
  final Function() onSelect;

  _CliOption(this.title, this.onSelect);
}
