abstract class FormalLanguage {
  bool hasMatch(String input);
}

class FiniteAutomaton implements FormalLanguage {
  final List<FiniteAutomatonState> _startStates = [];

  void addStartState(FiniteAutomatonState state) {
    _startStates.add(state);
  }

  @override
  bool hasMatch(String input) {
    var state = _startStates.firstWhere((s) => s.hasMatch(input), orElse: () => null);
    return state != null;
  }

  bool isDeterministic() {
    List<FiniteAutomatonTransition> t = listAllTransitions();
    return t.length == t.toSet().length;
  }

  List<FiniteAutomatonState> listAllStates() {
    List<FiniteAutomatonState> checkedStates = [];
    List<FiniteAutomatonState> states = [];

    _startStates.forEach((s) {
      states.addAll(s._listStates(checkedStates));
      checkedStates.add(s);
    });

    return states;
  }

  List<FiniteAutomatonTransition> listAllTransitions() {
    List<FiniteAutomatonState> checkedStates = [];
    List<FiniteAutomatonTransition> transitions = [];
    _startStates.forEach((s) {
      transitions.addAll(s._listTransitions(checkedStates));
      checkedStates.add(s);
    });
    return transitions;
  }

  String toGraph() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('digraph dfa {');
    buffer.writeln('rankdir=LR');
    buffer.writeln();
    List<FiniteAutomatonState> states = listAllStates();
    buffer.writeln('NOTHING [label="", shape=none]');
    states.toSet().forEach((s) {
      buffer.write('${s.name} [label="${s.name}", shape=ellipse');
      if (_startStates.contains(s)) buffer.write(', peripheries=2');
      buffer.writeln(']');
    });
    buffer.writeln();
    List<FiniteAutomatonTransition> transitions = listAllTransitions();
    _startStates.forEach((s) {
      buffer.writeln('NOTHING -> ${s.name}');
    });
    transitions.forEach((t) {
      buffer.writeln('${t.oldState.name} -> ${t.nextState.name} [label="${t.symbol}"]');
    });
    buffer.writeln('}');
    return buffer.toString();
  }
}

class FiniteAutomatonState implements FormalLanguage {
  final bool endState;
  final String name;

  final List<FiniteAutomatonTransition> _transitions = [];

  FiniteAutomatonState(this.name, {this.endState = false});

  void addTransition(String symbol, FiniteAutomatonState nextState) {
    _transitions.add(FiniteAutomatonTransition(this, symbol, nextState));
  }

  @override
  bool hasMatch(String input) => allMatches(input).isNotEmpty;

  Iterable<FiniteAutomatonState> allMatches(String input) {
    if (input == null || input.isEmpty)
      return endState ? [this] : [];

    String character = input[0];
    if (!_transitions.any((t) => t.symbol == character))
      return null;

    var options = _transitions.where((t) => t.symbol == character);
    var validOptions = options
        .map((s) => s.nextState.match(input.substring(1)))
        .where((s) => s != null && s.endState).toList();
    return validOptions;
  }

  FiniteAutomatonState match(String input) {
    var validOptions = allMatches(input);
    return (validOptions?.isEmpty ?? true) ? null : validOptions.first;
  }

  List<FiniteAutomatonState> _listStates(List<FiniteAutomatonState> checkedStates) {
    List<FiniteAutomatonState> states = [];
    if (checkedStates.contains(this))
      return [];

    _transitions.where((t) => !checkedStates.contains(t.nextState)).forEach((t) {
      states.add(t.nextState);
      states.addAll(t.nextState._listStates([this]..addAll(checkedStates)));
    });

    return states;
  }

  List<FiniteAutomatonTransition> _listTransitions(List<FiniteAutomatonState> checkedStates) {
    List<FiniteAutomatonTransition> trans = [];
    if (checkedStates.contains(this))
      return [];

    _transitions.where((t) => !checkedStates.contains(t.nextState)).forEach((t) {
      trans.add(t);
      trans.addAll(t.nextState._listTransitions([this]..addAll(checkedStates)));
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