import 'dart:convert';
import 'dart:io';

class TestCLI {
  final Encoding encoding;

  TestCLI({this.encoding = systemEncoding});

  _CliOption _optionMenu(String headline, List<_CliOption> options) {
    int choice = -1;
    bool choiceMade = false;
    int page = 0;

    print('\n|<>| ${headline.toUpperCase()} |<>|');
    do {
      int startIndex = page * 8;
      int endIndex =
          startIndex + 8 <= options.length ? startIndex + 8 : options.length;

      if (startIndex > 0) print('|0| (previous page)');
      for (int i = 0; i < endIndex - startIndex; i++) {
        print('${(i + 1).toString().padLeft(2)}> '
            '${startIndex + i + 1}. ${options[startIndex + i].title}');
      }
      if (endIndex < options.length) print('|9| (next page)');

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

    print(" < ${choice + 1} \n");
    return options[choice];
  }

  void run() {
    print('<<<==>>> FORMAL LANGUAGE TEST-CLI <<<==>>>');
    stdin.echoMode = false;
    stdin.lineMode = false;
    startMenu();
  }

  void startMenu() {
    var choice = _optionMenu("What to do?", [
      _CliOption('Nothing 1', nothing),
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
      _CliOption('Exit', stop),
    ]);
    choice.onSelect();
  }

  void stop() {
    print('Thanks for stopping by o/');
    sleep(Duration(seconds: 1));
  }

  void nothing() {
    print("Like I said, nothing");
    sleep(Duration(seconds: 1));
    startMenu();
  }
}

class _CliOption {
  final String title;
  final Function() onSelect;

  _CliOption(this.title, this.onSelect);
}
