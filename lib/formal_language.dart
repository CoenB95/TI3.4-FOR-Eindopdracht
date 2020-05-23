import 'package:TI3/alphabet.dart';

abstract class FormalLanguage {
  Alphabet get alphabet;
  Set<String> generate({int maxSteps = 5});
  bool hasMatch(String input);
}