abstract class FormalLanguage {
  bool hasMatch(String input);
}

class FiniteAutomatonState implements FormalLanguage {
  final bool endState;
  final String name;

  Map<String, List<FiniteAutomatonState>> _transitions = Map();

  FiniteAutomatonState(this.name, {this.endState = false});

  void addTransition(String symbol, FiniteAutomatonState nextState) {
    if (!_transitions.containsKey(symbol))
      _transitions[symbol] = List();
    _transitions[symbol].add(nextState);
  }

  @override
  bool hasMatch(String input) => allMatches(input).isNotEmpty;

  Iterable<FiniteAutomatonState> allMatches(String input) {
    if (input == null || input.isEmpty)
      return endState ? [this] : [];

    String character = input[0];
    if (!_transitions.containsKey(character))
      return null;

    var options = _transitions[character];
    var validOptions = options
        .map((s) => s.match(input.substring(1)))
        .where((s) => s != null && s.endState).toList();
    return validOptions;
  }

  FiniteAutomatonState match(String input) {
    var validOptions = allMatches(input);
    return (validOptions?.isEmpty ?? true) ? null : validOptions.first;
  }

  bool isDeterministic() {
    List<FiniteAutomatonTransition> t = listTransactions([]);
    return t.length == t.toSet().length;
  }

  List<FiniteAutomatonTransition> listTransactions(List<FiniteAutomatonState> checkedStates) {
    List<FiniteAutomatonTransition> trans = [];
    if (checkedStates.contains(this))
      return trans;

    _transitions.entries.forEach((e) {
      e.value.where((s) => !checkedStates.contains(s)).forEach((s) {
        trans.add(FiniteAutomatonTransition(this, e.key, s));
        trans.addAll(s.listTransactions([this]..addAll(checkedStates)));
      });
    });

    return trans;
  }

  @override
  String toString() => 'State{name=$name${endState ? ', isEnd' : ''}}';
}

class FiniteAutomatonTransition {
  final FiniteAutomatonState oldState;
  final String symbol;
  final FiniteAutomatonState nextState;
  FiniteAutomatonTransition(this.oldState, this.symbol, this.nextState);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FiniteAutomatonTransition &&
              runtimeType == other.runtimeType &&
              oldState == other.oldState &&
              symbol == other.symbol;

  @override
  int get hashCode =>
      oldState.hashCode ^
      symbol.hashCode;

  @override
  String toString() => '$oldState --$symbol--> $nextState';
}