import 'package:TI3/alphabet.dart';
import 'package:TI3/formal_language.dart';
import 'package:characters/characters.dart';

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
  bool hasMatch(String input) {
    // In case we've reached the end of the string:
    // Check to see if we are in a end-state (= match).
    // Otherwise, check if we can reach a different end-state still using epsilon-transitions.
    if (input.isEmpty)
      return _eClosure().any((s) => s.endState);
    
    String symbol = input.characters.first;
    return _deltaE(symbol).any((s) => s.hasMatch(input.substring(1)));
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

  Set<FiniteAutomatonState> _delta(String symbol) {
    return _transitions.where((t) => t.test(symbol)).map((t) => t.nextState).toSet();
  }

  Set<FiniteAutomatonState> _deltaE(String symbol) {
    return _eClosure().expand((s) => s._transitions).where((t) => t.test(symbol)).map((t) => t.nextState).toSet();
  }

  Set<FiniteAutomatonState> _eClosure() {
    return _transitions.where((t) => t.test()).expand((t) => t.nextState._eClosure()).toSet()..add(this);
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

    checkedStates.add(this);
    for (var t in _transitions) {
      trans.add(t);
      trans.addAll(t.nextState._listTransitions(checkedStates));
    }

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

  bool test([String symbol]);
}

class SymbolTransition extends FiniteAutomatonTransition {
  final String _symbol;
  String get label => _symbol;

  SymbolTransition(FiniteAutomatonState oldState, FiniteAutomatonState nextState, this._symbol) : super(oldState, nextState);

  @override
  bool test([String symbol]) => _symbol == symbol;

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
  bool test([String symbol]) => true;

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
  final Set<FiniteAutomatonState> _startStates = {};
  final Alphabet alphabet;

  Set<FiniteAutomatonState> get startStates => _startStates;
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