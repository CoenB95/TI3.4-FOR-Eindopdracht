class FiniteAutomatonState implements FormalLanguage {
  final bool endState;
  final String name;

  final List<FiniteAutomatonTransition> _transitions = [];

  FiniteAutomatonState(this.name, {this.endState = false});

  void addTransition(FiniteAutomatonState nextState, [String symbol]) {
    if (symbol == null)
      _transitions.add(EpsilonTransition(this, nextState));
    else
      _transitions.add(SymbolTransition(this, nextState, symbol));
  }

  Set<String> alphabet([List<FiniteAutomatonState> checkedStates]) {
    Set<String> letters = {};
    if (checkedStates.contains(this))
      return letters;

    checkedStates.add(this);
    _transitions.where((t) => !checkedStates.contains(t.nextState)).forEach((t) {
      letters.add(t.label);
      letters.addAll(t.nextState.alphabet(checkedStates));
    });

    return letters;
  }

  @override
  bool hasMatch(String input) => allMatches(input).isNotEmpty;

  Iterable<FiniteAutomatonState> allMatches(String input) {
    if (input == null || input.isEmpty)
      return endState ? [this] : [];

    String character = input[0];
    if (!_transitions.any((t) => t.test(character)))
      return null;

    var options = _transitions.where((t) => t.test(character));
    var validOptions = options
        .map((s) => s.nextState.match(input.substring(1)))
        .where((s) => s != null && s.endState).toList();
    return validOptions;
  }

  bool _checkDeterministic([List<FiniteAutomatonState> checkedStates]) {
    if (checkedStates.contains(this))
      return true;
    
    checkedStates.add(this);
    _transitions/*.where((t) => !checkedStates.contains(t.nextState))*/.forEach((t) {
      if (!t.nextState._checkDeterministic(checkedStates));
    });

    return trans;
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

abstract class FiniteAutomatonTransition {
  final FiniteAutomatonState oldState;
  final FiniteAutomatonState nextState;
  String get label;

  FiniteAutomatonTransition(this.oldState, this.nextState);

  bool test(String symbol);
}

class SymbolTransition extends FiniteAutomatonTransition {
  final String _symbol;
  String get label => _symbol;

  SymbolTransition(FiniteAutomatonState oldState, FiniteAutomatonState nextState, this._symbol) : super(oldState, nextState);

  @override
  bool test(String symbol) => symbol == _symbol;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SymbolTransition &&
              runtimeType == other.runtimeType &&
              nextState == other.nextState &&
              oldState == other.oldState &&
              _symbol == other._symbol;

  @override
  int get hashCode =>
      nextState.hashCode ^
      oldState.hashCode ^
      _symbol.hashCode;

  @override
  String toString() => '$oldState --$_symbol--> $nextState';
}

class EpsilonTransition extends FiniteAutomatonTransition {
  String get label => '<epsilon>';

  EpsilonTransition(oldState, nextState) : super(oldState, nextState);

  @override
  bool test(String symbol) => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is EpsilonTransition &&
              runtimeType == other.runtimeType &&
              nextState == other.nextState &&
              oldState == other.oldState;

  @override
  int get hashCode =>
      nextState.hashCode ^
      oldState.hashCode;

  @override
  String toString() => '$oldState --?--> $nextState';
}

abstract class FormalLanguage {
  bool hasMatch(String input);
}

class NonDeterministicFiniteAutomaton implements FormalLanguage {
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
    List<FiniteAutomatonTransition> all = listAllTransitions();
    List<FiniteAutomatonTransition> all = all.
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
      if (s.endState) buffer.write(', peripheries=2');
      buffer.writeln(']');
    });
    buffer.writeln();
    List<FiniteAutomatonTransition> transitions = listAllTransitions();
    _startStates.forEach((s) {
      buffer.writeln('NOTHING -> ${s.name}');
    });
    transitions.forEach((t) {
      buffer.writeln('${t.oldState.name} -> ${t.nextState.name} [label="${t.label}"]');
    });
    buffer.writeln('}');
    return buffer.toString();
  }
}
