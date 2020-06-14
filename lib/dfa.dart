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

  DeterministicFiniteAutomaton and(DeterministicFiniteAutomaton other) {
    if (this.alphabet != other.alphabet)
      throw ArgumentError("Can't combine DFA's: different Alphabet's");

    
    DeterministicFiniteAutomaton dfa = DeterministicFiniteAutomaton(alphabet);
    var startTuple = TupleFiniteAutomatonState(this, this.startState, other, other.startState, startState: true,
        endState: this.startState.isEndState && other.startState.isEndState);
    dfa.addState(startTuple);
    var traverseTuples = Queue.of([startTuple]);

    while (traverseTuples.isNotEmpty) {
      var tuple = traverseTuples.removeFirst();
      print('CHECK ${tuple.name}');
      for (var char in alphabet.letters) {
        var nextStateA = tuple.automatonA._delta(tuple.stateA, char);
        var nextStateB = tuple.automatonB._delta(tuple.stateB, char);
        var newTuple = TupleFiniteAutomatonState(tuple.automatonA, nextStateA, tuple.automatonB, nextStateB, endState: nextStateA.isEndState && nextStateB.isEndState);
        if (!dfa.states.contains(newTuple)) {
          dfa.addState(newTuple);
          traverseTuples.add(newTuple);
        }
        dfa.createTransition(tuple, newTuple, char);
      }
    }

    return dfa;
  }

  static DeterministicFiniteAutomaton contains(String input, {Alphabet alphabet}) {
    alphabet = (alphabet ?? Alphabet.ofString(input));
    DeterministicFiniteAutomaton dfa = DeterministicFiniteAutomaton(alphabet);
    FiniteAutomatonState startState = dfa.createState('S', startState: true);
    FiniteAutomatonState fromState = startState;

    // Construct the trap.
    FiniteAutomatonState errorState = dfa.createState('X', endState: false);
    for (String letter in alphabet.letters) {
      dfa.createTransition(errorState, errorState, letter);
    }

    for (int i = 0; i < input.length; i++) {
      bool isFirstCharOfSequence = i == 0; // First char of end-sequence?
      bool isLastCharOfSequence = i == input.length - 1; // Final char of end-sequence?
       
      String char = input.characters.elementAt(i);
      FiniteAutomatonState toState = dfa.createState('Q${i + 1}', endState: isLastCharOfSequence);

      for (String letter in alphabet.letters) {
        if (letter == char) {
          dfa.createTransition(fromState, toState, letter);
        } else if (isFirstCharOfSequence) {
          dfa.createTransition(fromState, fromState, letter);
        } else {
          dfa.createTransition(fromState, errorState, letter);
        }
      }

      if (isLastCharOfSequence) {
        for (String letter in alphabet.letters) {
          dfa.createTransition(toState, toState, letter);
        }
      }

      fromState = toState;
    }

    assert (dfa.isDeterministic());

    return dfa;
  }

  /// List all the states that can be reached from this state using the supplied symbol.
  /// Because 
  FiniteAutomatonState _delta(FiniteAutomatonState state, String symbol) {
    if (!alphabet.isValid(symbol))
      throw ArgumentError.value(symbol, 'symbol', 'Not part of alphabet');
    return transitions.where((t) => t.fromState == state && t.test(symbol)).first.toState;
  }

  static DeterministicFiniteAutomaton endWith(String input, {Alphabet alphabet}) {
    alphabet = (alphabet ?? Alphabet.ofString(input));
    DeterministicFiniteAutomaton dfa = DeterministicFiniteAutomaton(alphabet);
    FiniteAutomatonState startState = dfa.createState('S', startState: true);
    FiniteAutomatonState fromState = startState;
    List<FiniteAutomatonState> states = [startState];

    // Construct the trap.
    FiniteAutomatonState errorState = dfa.createState('X', endState: false);
    for (String letter in alphabet.letters) {
      dfa.createTransition(errorState, errorState, letter);
    }

    for (int i = 0; i < input.length; i++) {
      bool isLastCharOfSequence = i == input.length - 1; // Final char of end-sequence?
       
      String char = input.characters.elementAt(i);
      FiniteAutomatonState toState = dfa.createState('Q${i + 1}', endState: isLastCharOfSequence);
      states.add(toState);

      // On each correct letter, go to next state.
      // Otherwise try to recover to the state that can still be matched.
      for (String letter in alphabet.letters) {
        if (letter == char) {
          dfa.createTransition(fromState, toState, letter);
        } else {
          FiniteAutomatonState put;
          for (int j = 1; j <= i; j++) {
            var test1 = input.substring(0, i - j + 1);
            var test2 = input.substring(0 + j, i) + letter;
            if (test1 == test2) {
              put = states[i - j + 1];
              break;
            }
          }

          put = put ?? startState;
          dfa.createTransition(fromState, put, letter);
        }
      }

      // Finish: any more characters -> error state.
      if (isLastCharOfSequence) {
        for (String letter in alphabet.letters) {
          dfa.createTransition(toState, errorState, letter);
        }
      }

      fromState = toState;
    }

    assert (dfa.isDeterministic());
    return dfa;
  }

  @override
  Set<String> generate({int maxSteps = 5}) {
    return _generate(startState, maxSteps);
  }

  Set<String> _generate(FiniteAutomatonState state, int maxSteps) {
    Set<String> languageResult = {};
    if (maxSteps < 0)
      return languageResult;
    maxSteps--;

    for (var char in alphabet.letters) {
      var nextState = _delta(state, char);
      if (nextState.isEndState) {
        languageResult.add(char);
      }
      languageResult.addAll(_generate(nextState, maxSteps).map((v) => char + v));
      
    }

    return languageResult;
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

  static DeterministicFiniteAutomaton startWith(String input, {Alphabet alphabet}) {
    alphabet = (alphabet ?? Alphabet.ofString(input));
    DeterministicFiniteAutomaton dfa = DeterministicFiniteAutomaton(alphabet);
    FiniteAutomatonState startState = dfa.createState('S', startState: true);
    FiniteAutomatonState fromState = startState;

    // Construct the trap.
    FiniteAutomatonState errorState = dfa.createState('X', endState: false);
    for (String letter in alphabet.letters) {
      dfa.createTransition(errorState, errorState, letter);
    }

    for (int i = 0; i < input.length; i++) {
      bool isLastCharOfSequence = i == input.length - 1; // Final char of start-sequence?
       
      String char = input.characters.elementAt(i);
      FiniteAutomatonState toState = dfa.createState('Q${i + 1}', endState: isLastCharOfSequence);

      for (String letter in alphabet.letters) {
        dfa.createTransition(fromState, (char == letter ? toState : errorState), letter);
      }

      if (isLastCharOfSequence) {
        for (String letter in alphabet.letters) {
          dfa.createTransition(toState, toState, letter);
        }
      }

      fromState = toState;
    }

    assert (dfa.isDeterministic());
    return dfa;
  }
}

class TupleFiniteAutomatonState extends FiniteAutomatonState {
  final DeterministicFiniteAutomaton automatonA;
  final DeterministicFiniteAutomaton automatonB;
  final FiniteAutomatonState stateA;
  final FiniteAutomatonState stateB;

  TupleFiniteAutomatonState(this.automatonA, this.stateA, this.automatonB, this.stateB, {bool startState = false, bool endState = false})
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