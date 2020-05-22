import 'package:TI3/alphabet.dart';
import 'package:TI3/formal_language.dart';

class FiniteAutomatonState implements FormalLanguage {
  final Alphabet alphabet;
  final bool endState;
  final String name;

  final List<FiniteAutomatonTransition> _transitions = [];

  FiniteAutomatonState(this.alphabet, this.name, {this.endState = false});

  void addTransition(FiniteAutomatonState nextState, [String symbol]) {
    if (symbol == null)
      _transitions.add(EpsilonTransition(this, nextState));
    else
      _transitions.add(SymbolTransition(this, nextState, symbol));
  }

  @override
  Set<String> generate({int maxSteps = 5}) {
    return null;
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

  bool _checkDeterministic(Alphabet alphabet, List<FiniteAutomatonState> checkedStates) {
    if (checkedStates.contains(this))
      return true;
    else
      checkedStates.add(this);
    
    for (var c in alphabet.letters) {
      if (_transitions.where((t) => t.test(c)).length > 1) {
        return false;
      }
    }
    
    for (var t in _transitions) {
      if (!t.nextState._checkDeterministic(alphabet, checkedStates))
        return false;
    }

    return true;
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

class NonDeterministicFiniteAutomaton implements FormalLanguage {
  final List<FiniteAutomatonState> _startStates = [];
  final Alphabet alphabet;

  NonDeterministicFiniteAutomaton(this.alphabet);

  static NonDeterministicFiniteAutomaton contains(String input, {Alphabet alphabet}) {
    NonDeterministicFiniteAutomaton ndfa = NonDeterministicFiniteAutomaton(alphabet ?? Alphabet.ofString(input));
    FiniteAutomatonState start = ndfa.createState('S', startState: true);
    FiniteAutomatonState last = start;
    for (int i = 0; i < input.length; i++) {
      String char = input.substring(i, i + 1);
      FiniteAutomatonState fromState = last;
      FiniteAutomatonState toState = ndfa.createState('Q${i + 1}', endState: i + 1 == input.length);
      fromState.addTransition(toState, char);
      last = toState;
    }
    return ndfa;
  }

  FiniteAutomatonState createState(String name, {bool startState = false, bool endState = false}) {
    FiniteAutomatonState state = FiniteAutomatonState(alphabet, name, endState: endState);
    if (startState)
      _startStates.add(state);
    return state;
  }

  static NonDeterministicFiniteAutomaton endsWith(String input, {Alphabet alphabet}) {
    NonDeterministicFiniteAutomaton ndfa = NonDeterministicFiniteAutomaton(alphabet ?? Alphabet.ofString(input));
    FiniteAutomatonState start = ndfa.createState('S', startState: true);
    FiniteAutomatonState last = start;
    for (int i = 0; i < input.length; i++) {
      String char = input.substring(i, i + 1);
      FiniteAutomatonState fromState = last;
      FiniteAutomatonState toState = ndfa.createState('Q${i + 1}', endState: i + 1 == input.length);
      fromState.addTransition(toState, char);
      last = toState;
    }
    return ndfa;
  }

  Set<String> generate({int maxSteps = 5}) {
    return null;
  }
  
  @override
  bool hasMatch(String input) {
    var state = _startStates.firstWhere((s) => s.hasMatch(input), orElse: () => null);
    return state != null;
  }

  bool isDeterministic() {
    //Check that there are *no* cases of *non*-deterministic branches (double-negative).
    var safe = !_startStates.any((s) => !s._checkDeterministic(alphabet, []));
    return safe;
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

  static NonDeterministicFiniteAutomaton startWith(String input, {Alphabet alphabet}) {
    alphabet = (alphabet ?? Alphabet.ofString(input));
    NonDeterministicFiniteAutomaton ndfa = NonDeterministicFiniteAutomaton(alphabet);
    FiniteAutomatonState start = ndfa.createState('S', startState: true);
    FiniteAutomatonState last = start;
    for (int i = 0; i < input.length; i++) {
      String char = input.substring(i, i + 1);
      FiniteAutomatonState fromState = last;
      FiniteAutomatonState toState = ndfa.createState('Q${i + 1}', endState: i + 1 == input.length);
      fromState.addTransition(toState, char);
      last = toState;
    }

    for (String character in alphabet.letters) {
      last.addTransition(last, character);
    }

    return ndfa;
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