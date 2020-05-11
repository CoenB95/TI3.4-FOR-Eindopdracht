abstract class FormalLanguage {
  Set<String> generate({int maxSteps = 5});
  bool hasMatch(String input);
}