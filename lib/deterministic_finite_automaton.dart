import 'dart:collection';

import 'package:TI3/alphabet.dart';
import 'package:TI3/finite_automaton.dart';

class DeterministicFiniteAutomaton extends NonDeterministicFiniteAutomaton {
  DeterministicFiniteAutomaton(Alphabet alphabet) : super(alphabet);

  DeterministicFiniteAutomaton and(DeterministicFiniteAutomaton other) {
    if (this.alphabet != other.alphabet)
      throw ArgumentError("Can't combine DFA's: different Alphabet's");

    if (this.startStates.length != 1 || other.startStates.length != 1)
      throw StateError('ERRIR');
    
    var startTuple = TupleFiniteAutomatonState(this.startStates.first, other.startStates.first);
    var traverseTuples = Queue.of([startTuple]);
    Set<TupleFiniteAutomatonState> tuples = {startTuple};
    Set<TupleTransition> tupleTransitions = {};

    while (traverseTuples.isNotEmpty) {
      var tuple = traverseTuples.removeFirst();
      for (var char in alphabet.letters) {
        var newTuple = TupleFiniteAutomatonState(tuple.stateA.next(char), tuple.stateB.next(char));
        if (tuples.add(newTuple))
          traverseTuples.add(newTuple);
        tupleTransitions.add(TupleTransition(tuple, newTuple, char));
      }
    }

    DeterministicFiniteAutomaton dfa = DeterministicFiniteAutomaton(alphabet);
    for (var tuple in tuples) {
      var state = dfa.createState('${tuple.stateA.name},${tuple.stateB.name}', startState: tuple == startTuple, endState: tuple.stateA.endState && tuple.stateB.endState);
      for (var t in tupleTransitions.where((t) => t.tupleA == tuple)) {
        state.addTransition(t.tupleB);
      }
    }
  }
}

// FiniteAutomatonState tuple(FiniteAutomatonState stateA, FiniteAutomatonState stateB) {
//   if (stateA.alphabet != stateB.alphabet)
//     throw ArgumentError("Cannot combine two states of different DFA's that have different alphabets");

//   FiniteAutomatonState newState = FiniteAutomatonState(stateA.alphabet, '${stateA.name},${stateB.name}', endState: stateA.endState || stateB.endState);
//   return newState;
// }

class TupleFiniteAutomatonState {
  final FiniteAutomatonState stateA;
  final FiniteAutomatonState stateB;

  TupleFiniteAutomatonState(this.stateA, this.stateB);

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
      other is TupleFiniteAutomatonState &&
      runtimeType == other.runtimeType &&
      stateA == other.stateA &&
      stateB == other.stateB;
}

class TupleTransition {
  final TupleFiniteAutomatonState tupleA;
  final TupleFiniteAutomatonState tupleB;
  final String symbol;

  TupleTransition(this.tupleA, this.tupleB, this.symbol);

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
      other is TupleTransition &&
      runtimeType == other.runtimeType &&
      tupleA == other.tupleA &&
      tupleB == other.tupleB &&
      symbol == other.symbol;
}

// class TupleFiniteAutomatonState extends FiniteAutomatonState {
//   final FiniteAutomatonState stateA;
//   final FiniteAutomatonState stateB;

//   TupleFiniteAutomatonState._(this.stateA, this.stateB) :
//       super(stateA.alphabet, '${stateA.name},${stateB.name}', endState: stateA.endState || stateB.endState) {
    
//   }

//   factory TupleFiniteAutomatonState.of(FiniteAutomatonState stateA, FiniteAutomatonState stateB) {
//     if (stateA.alphabet != stateB.alphabet)
//       throw ArgumentError("Cannot combine two states of different DFA's that have different alphabets");

//     TupleFiniteAutomatonState newState = TupleFiniteAutomatonState._(stateA, stateB);
//     return newState;
//   }
// }