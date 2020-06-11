import 'dart:collection';

import 'package:characters/characters.dart';

import 'alphabet.dart';
import 'finite_automaton.dart';

class DeterministicFiniteAutomaton extends FiniteAutomaton  {
  DeterministicFiniteAutomaton(Alphabet alphabet) : super(alphabet);

  FiniteAutomatonState get startState => states.where((s) => s.isStartState).first;

  /// Add a new state-transition to this DFA.
  /// Note that a DFA is extra picky about its uniqueness.
  @override
  void addTransition(FiniteAutomatonTransition transition) {
    if (transitions.any((t) => t.equalsTransition(transition)))
      throw UnsupportedError("Cannot add transition '$transition' to DFA, similar transition already defined for state.");
    
    super.addTransition(transition);
  }

  /// List all the states that can be reached from this state using the supplied symbol.
  /// Because 
  FiniteAutomatonState _delta(FiniteAutomatonState state, String symbol) {
    if (!alphabet.isValid(symbol))
      throw ArgumentError.value(symbol, 'symbol', 'Not part of alphabet');
    return transitions.where((t) => t.fromState == state && t.test(symbol)).first.toState;
  }

  @override
  Set<String> generate({int maxSteps = 5}) {
    return {};
  }
  
  @override
  bool hasMatch(String input) {
    var startStates = states.where((s) => s.isStartState);
    return startStates.any((s) => _match(s, input));
  }

  /// Internal method to recursively check whether the supplied string is accepted by this NDFA.
  bool _match(FiniteAutomatonState state, String string) {
    // In case we've reached the end of the string:
    // Check to see if we are in a end-state (= match).
    if (string.isEmpty)
      return state.isEndState;
    
    String symbol = string.characters.first;
    return _match(_delta(state, symbol), string.substring(1));
  }

  DeterministicFiniteAutomaton and(DeterministicFiniteAutomaton other) {
    if (this.alphabet != other.alphabet)
      throw ArgumentError("Can't combine DFA's: different Alphabet's");

    
    DeterministicFiniteAutomaton dfa = DeterministicFiniteAutomaton(alphabet);
    var startTuple = TupleFiniteAutomatonState(this, this.startState, other, other.startState, startState: true);
    dfa.addState(startTuple);
    var traverseTuples = Queue.of([startTuple]);

    while (traverseTuples.isNotEmpty) {
      var tuple = traverseTuples.removeFirst();
      for (var char in alphabet.letters) {
        var nextStateA = tuple.automatonA._delta(tuple.stateA, char);
        var nextStateB = tuple.automatonB._delta(tuple.stateB, char);
        var newTuple = TupleFiniteAutomatonState(tuple.automatonA, nextStateA, tuple.automatonB, nextStateB);
        if (!dfa.states.contains(newTuple)) {
          dfa.addState(newTuple);
          traverseTuples.add(newTuple);
        }
        dfa.createTransition(tuple, newTuple, char);
      }
    }

    return dfa;
  }
}

class TupleFiniteAutomatonState extends FiniteAutomatonState {
  final DeterministicFiniteAutomaton automatonA;
  final DeterministicFiniteAutomaton automatonB;
  final FiniteAutomatonState stateA;
  final FiniteAutomatonState stateB;

  TupleFiniteAutomatonState(this.automatonA, this.stateA, this.automatonB, this.stateB, {bool startState, bool endState})
   : super(stateA.name + ', ' + stateB.name, isStartState: startState, isEndState: endState);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TupleFiniteAutomatonState &&
      automatonA == other.automatonA &&
      automatonB == other.automatonB &&
      stateA == other.stateA &&
      stateB == other.stateB;

  @override
  int get hashCode =>
      automatonA.hashCode ^
      automatonB.hashCode ^
      stateA.hashCode ^
      stateB.hashCode;
}