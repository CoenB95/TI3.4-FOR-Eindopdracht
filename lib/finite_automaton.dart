import 'alphabet.dart';
import 'formal_language.dart';

class FiniteAutomatonState {
  final bool isEndState;
  final bool isStartState;
  final String name;

  FiniteAutomatonState(this.name, {this.isStartState = false, this.isEndState = false});

  @override
  String toString() => 'State (name=$name${isStartState ? ', isStart' : ''}${isEndState ? ', isEnd' : ''})';
}

abstract class FiniteAutomatonTransition {
  final FiniteAutomatonState fromState;
  final FiniteAutomatonState toState;
  String get label;

  FiniteAutomatonTransition(this.fromState, this.toState);

  bool test([String symbol]);
}

class SymbolTransition extends FiniteAutomatonTransition {
  final String symbol;
  String get label => symbol;

  SymbolTransition(FiniteAutomatonState oldState, FiniteAutomatonState nextState, this.symbol) : super(oldState, nextState);

  @override
  bool test([String symbol]) => this.symbol == symbol;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymbolTransition &&
      fromState == other.fromState &&
      toState == other.toState &&
      symbol == other.symbol;

  @override
  int get hashCode =>
      fromState.hashCode ^
      toState.hashCode ^
      symbol.hashCode;

  @override
  String toString() => '$fromState --$symbol--> $toState';
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
      fromState == other.fromState &&
      toState == other.toState;

  @override
  int get hashCode =>
      fromState.hashCode ^
      toState.hashCode;

  @override
  String toString() => '$fromState --?--> $toState';
}

abstract class FiniteAutomaton implements FormalLanguage {
  final Set<FiniteAutomatonState> _states = {};
  final Set<FiniteAutomatonTransition> _transitions = {};
  final Alphabet alphabet;

  Iterable<FiniteAutomatonState> get startStates => _states.where((s) => s.isStartState);
  Iterable<FiniteAutomatonState> get states => List.unmodifiable(_states);
  Iterable<FiniteAutomatonTransition> get transitions => List.unmodifiable(_transitions);
  
  FiniteAutomaton(this.alphabet);

  void addTransition(FiniteAutomatonState fromState, FiniteAutomatonState toState, [String symbol]) {
    if (symbol == null)
      _transitions.add(EpsilonTransition(fromState, toState));
    else
      _transitions.add(SymbolTransition(fromState, toState, symbol));
  }

  FiniteAutomatonState createState(String name, {bool startState = false, bool endState = false}) {
    FiniteAutomatonState state = FiniteAutomatonState(name, isStartState: startState, isEndState: endState);
    _states.add(state);
    return state;
  }

  /// Check whether this FiniteAutomaton is a DFA (fully-defined transitions between states).
  bool isDeterministic() {
    // Check whether every state has exactly ONE transition to a different state
    // for every letter from the alphabet.
    for (var s in _states) {
      for (var c in alphabet.letters) {
        if (_transitions.where((t) => t.fromState == s && t.test(c)).length != 1) {
          return false;
        }
      }
    }
    return true;
  }

  String toGraph() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('digraph dfa {');
    buffer.writeln('rankdir=LR');
    buffer.writeln();
    buffer.writeln('NOTHING [label="", shape=none]');
    _states.toSet().forEach((s) {
      buffer.write('${s.name} [label="${s.name}", shape=ellipse');
      if (s.isStartState) buffer.write(', color=cyan');
      if (s.isEndState) buffer.write(', peripheries=2');
      buffer.writeln(']');
    });
    buffer.writeln();
    startStates.forEach((s) {
      buffer.writeln('NOTHING -> ${s.name}');
    });
    _transitions.forEach((t) {
      buffer.writeln('${t.fromState.name} -> ${t.toState.name} [label="${t.label}"]');
    });
    buffer.writeln('}');
    return buffer.toString();
  }
}