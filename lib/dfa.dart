import 'dart:collection';

import 'package:characters/characters.dart';

import 'alphabet.dart';
import 'finite_automaton.dart';

class DeterministicFiniteAutomaton extends FiniteAutomaton {
  DeterministicFiniteAutomaton(Alphabet alphabet) : super(alphabet);

  FiniteAutomatonState get startState =>
      states.where((s) => s.isStartState).first;

  final Set<SymbolTransition> _transitions = {};
  @override
  Iterable<SymbolTransition> get transitions => List.unmodifiable(_transitions);

  /// Add a new state-transition to this DFA.
  /// Note that a DFA is extra picky about its uniqueness.
  @override
  void addTransition(FiniteAutomatonTransition transition) {
    if (!(transition is SymbolTransition))
      throw UnsupportedError(
          "Cannot add transition '$transition'; DFA does not support epsilon.");

    if (transitions.any((t) => t.equalsTransition(transition)))
      throw UnsupportedError(
          "Cannot add transition '$transition' to DFA, similar transition already defined for state.");

    _transitions.add(transition);
  }

  DeterministicFiniteAutomaton and(DeterministicFiniteAutomaton other) {
    if (this.alphabet != other.alphabet)
      throw ArgumentError("Can't combine DFA's: different Alphabet's");

    DeterministicFiniteAutomaton dfa = DeterministicFiniteAutomaton(alphabet);
    var startTuple = _MergedFiniteAutomatonState(
        this, this.startState, other, other.startState,
        startState: true,
        endState: this.startState.isEndState && other.startState.isEndState);
    dfa.addState(startTuple);
    var traverseTuples = Queue.of([startTuple]);

    while (traverseTuples.isNotEmpty) {
      var tuple = traverseTuples.removeFirst();
      for (var char in alphabet.letters) {
        var nextStateA = tuple.automatonA.delta(tuple.stateA, char);
        var nextStateB = tuple.automatonB.delta(tuple.stateB, char);
        var newTuple = _MergedFiniteAutomatonState(
            tuple.automatonA, nextStateA, tuple.automatonB, nextStateB,
            endState: nextStateA.isEndState && nextStateB.isEndState);
        if (!dfa.states.contains(newTuple)) {
          dfa.addState(newTuple);
          traverseTuples.add(newTuple);
        }
        dfa.createTransition(tuple, newTuple, char);
      }
    }

    return dfa;
  }

  DeterministicFiniteAutomaton clean() {
    DeterministicFiniteAutomaton dfa = DeterministicFiniteAutomaton(alphabet);
    Map<FiniteAutomatonState, FiniteAutomatonState> mapping = {};
    for (int i = 0; i < states.length; i++) {
      var oldState = states.toList()[i];
      mapping[oldState] = FiniteAutomatonState('Q$i',
          isStartState: oldState.isStartState, isEndState: oldState.isEndState);
    }
    states.forEach((s) => dfa.addState(mapping[s]));
    transitions.forEach((t) => dfa.addTransition(
        SymbolTransition(mapping[t.fromState], mapping[t.toState], t.symbol)));
    return dfa;
  }

  /// Constructs a new DFA that only accepts words that contains a specific
  /// sequence. Any deviation of the supplied sequence will result in the
  /// DFA denying the input word.
  static DeterministicFiniteAutomaton contains(String input,
      {Alphabet alphabet}) {
    alphabet = (alphabet ?? Alphabet.ofString(input));
    DeterministicFiniteAutomaton dfa = DeterministicFiniteAutomaton(alphabet);
    FiniteAutomatonState startState = dfa.createState('S', startState: true);
    FiniteAutomatonState fromState = startState;
    List<FiniteAutomatonState> states = [startState];

    for (int i = 0; i < input.length; i++) {
      bool isLastCharOfSequence =
          i == input.length - 1; // Final char of end-sequence?

      String char = input.characters.elementAt(i);
      FiniteAutomatonState toState =
          dfa.createState('Q${i + 1}', endState: isLastCharOfSequence);
      states.add(toState);

      for (String letter in alphabet.letters) {
        if (letter == char) {
          dfa.createTransition(fromState, toState, letter);
        } else {
          // Add the invalid character at the end, then consecutively
          // reduce the string's length from the front until the string
          // is considered valid again.
          FiniteAutomatonState latestValidState = startState;
          var testString = input.substring(0, i) + letter;
          for (int j = 0; j < i; j++) {
            if (input.startsWith(testString.substring(j + 1))) {
              latestValidState = states[i - j];
              break;
            }
          }

          dfa.createTransition(fromState, latestValidState, letter);
        }
      }

      fromState = toState;
    }

    // Finish: any more characters -> same (success) state.
    for (String letter in alphabet.letters) {
      dfa.createTransition(fromState, fromState, letter);
    }

    assert(dfa.isDeterministic());
    return dfa;
  }

  /// List all the states that can be reached from this state using the supplied symbol.
  /// Because
  FiniteAutomatonState delta(FiniteAutomatonState state, String symbol) {
    if (!alphabet.isValid(symbol))
      throw ArgumentError.value(symbol, 'symbol', 'Not part of alphabet');
    return transitions
        .where((t) => t.fromState == state && t.test(symbol))
        .first
        .toState;
  }

  /// Constructs a new DFA that only accepts words that end with a specific
  /// sequence. Any deviation of the supplied sequence will result in the
  /// DFA denying the input word.
  static DeterministicFiniteAutomaton endWith(String input,
      {Alphabet alphabet}) {
    alphabet = (alphabet ?? Alphabet.ofString(input));
    DeterministicFiniteAutomaton dfa = DeterministicFiniteAutomaton(alphabet);
    FiniteAutomatonState startState = dfa.createState('S', startState: true);
    FiniteAutomatonState fromState = startState;
    List<FiniteAutomatonState> states = [startState];

    for (int i = 0; i < input.length; i++) {
      bool isLastCharOfSequence =
          i == input.length - 1; // Final char of end-sequence?

      String char = input.characters.elementAt(i);
      FiniteAutomatonState toState =
          dfa.createState('Q${i + 1}', endState: isLastCharOfSequence);
      states.add(toState);

      // On each correct letter, go to next state.
      // Otherwise try to recover to the state that can still be matched.
      for (String letter in alphabet.letters) {
        if (letter == char) {
          dfa.createTransition(fromState, toState, letter);
        } else {
          // Add the invalid character at the end, then consecutively
          // reduce the string's length from the front until the string
          // is considered valid again.
          FiniteAutomatonState latestValidState = startState;
          var testString = input.substring(0, i) + letter;
          for (int j = 0; j < i; j++) {
            if (input.startsWith(testString.substring(j + 1))) {
              latestValidState = states[i - j];
              break;
            }
          }

          dfa.createTransition(fromState, latestValidState, letter);
        }
      }

      fromState = toState;
    }

    // Finish: any more characters -> recover state.
    for (String letter in alphabet.letters) {
      // Add the invalid character at the end, then consecutively
      // reduce the string's length from the front until the string
      // is considered valid again.
      FiniteAutomatonState latestValidState = startState;
      var testString = input + letter;
      for (int j = 0; j < input.length; j++) {
        if (input.startsWith(testString.substring(j + 1))) {
          latestValidState = states[input.length - j];
          break;
        }
      }
      dfa.createTransition(fromState, latestValidState, letter);
    }

    assert(dfa.isDeterministic());
    return dfa;
  }

  @override
  Set<String> generate({int maxSteps = 5}) {
    return _generate(startState, maxSteps);
  }

  Set<String> _generate(FiniteAutomatonState state, int maxSteps) {
    Set<String> languageResult = {};
    if (maxSteps < 0) return languageResult;
    maxSteps--;

    for (var char in alphabet.letters) {
      var nextState = delta(state, char);
      if (nextState.isEndState) {
        languageResult.add(char);
      }
      languageResult
          .addAll(_generate(nextState, maxSteps).map((v) => char + v));
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
    if (string.isEmpty) return state.isEndState;

    String symbol = string.characters.first;
    return _match(delta(state, symbol), string.substring(1));
  }

  DeterministicFiniteAutomaton not() {
    DeterministicFiniteAutomaton dfa = DeterministicFiniteAutomaton(alphabet);
    transitions.forEach((t) => dfa.addTransition(SymbolTransition(
        FiniteAutomatonState(t.fromState.name,
            isStartState: t.fromState.isStartState,
            isEndState: !t.fromState.isEndState),
        FiniteAutomatonState(t.toState.name,
            isStartState: t.toState.isStartState,
            isEndState: !t.toState.isEndState),
        t.symbol)));
    states.forEach((s) => dfa.addState(FiniteAutomatonState(s.name,
        isStartState: s.isStartState, isEndState: !s.isEndState)));
    return dfa;
  }

  DeterministicFiniteAutomaton or(DeterministicFiniteAutomaton other) {
    if (this.alphabet != other.alphabet)
      throw ArgumentError("Can't combine DFA's: different Alphabet's");

    DeterministicFiniteAutomaton dfa = DeterministicFiniteAutomaton(alphabet);
    var startTuple = _MergedFiniteAutomatonState(
        this, this.startState, other, other.startState,
        startState: true,
        endState: this.startState.isEndState || other.startState.isEndState);
    dfa.addState(startTuple);
    var traverseTuples = Queue.of([startTuple]);

    while (traverseTuples.isNotEmpty) {
      var tuple = traverseTuples.removeFirst();
      for (var char in alphabet.letters) {
        var nextStateA = tuple.automatonA.delta(tuple.stateA, char);
        var nextStateB = tuple.automatonB.delta(tuple.stateB, char);
        var newTuple = _MergedFiniteAutomatonState(
            tuple.automatonA, nextStateA, tuple.automatonB, nextStateB,
            startState: nextStateA == startTuple.stateA &&
                nextStateB == startTuple.stateB,
            endState: nextStateA.isEndState || nextStateB.isEndState);
        if (!dfa.states.contains(newTuple)) {
          dfa.addState(newTuple);
          traverseTuples.add(newTuple);
        }
        dfa.createTransition(tuple, newTuple, char);
      }
    }

    return dfa;
  }

  /// Constructs a new DFA that only accepts words that start with a specific
  /// sequence. Any deviation of the supplied sequence will result in the
  /// DFA denying the input word.
  static DeterministicFiniteAutomaton startWith(String input,
      {Alphabet alphabet}) {
    // Check whether the input-word can be constructed by the alphabet used.
    // If no alphabet is supplied, create one based on the input-word.
    alphabet = (alphabet ?? Alphabet.ofString(input));
    assert(alphabet.isValid(input));

    DeterministicFiniteAutomaton dfa = DeterministicFiniteAutomaton(alphabet);
    FiniteAutomatonState startState = dfa.createState('S', startState: true);
    FiniteAutomatonState fromState = startState;

    // Construct the trap (fault-state).
    FiniteAutomatonState errorState = dfa.createState('X', endState: false);
    for (String letter in alphabet.letters) {
      dfa.createTransition(errorState, errorState, letter);
    }

    for (int i = 0; i < input.length; i++) {
      bool isLastCharOfSequence =
          i == input.length - 1; // Final char of start-sequence?

      String char = input.characters.elementAt(i);
      FiniteAutomatonState toState =
          dfa.createState('Q${i + 1}', endState: isLastCharOfSequence);

      for (String letter in alphabet.letters) {
        dfa.createTransition(
            fromState, (char == letter ? toState : errorState), letter);
      }

      fromState = toState;
    }

    // Finish: any more characters -> same (success) state.
    for (String letter in alphabet.letters) {
      dfa.createTransition(fromState, fromState, letter);
    }

    assert(dfa.isDeterministic());
    return dfa;
  }
}

class _MergedFiniteAutomatonState extends FiniteAutomatonState {
  final DeterministicFiniteAutomaton automatonA;
  final DeterministicFiniteAutomaton automatonB;
  final FiniteAutomatonState stateA;
  final FiniteAutomatonState stateB;

  _MergedFiniteAutomatonState(
      this.automatonA, this.stateA, this.automatonB, this.stateB,
      {bool startState = false, bool endState = false})
      : super(stateA.name + ', ' + stateB.name,
            isStartState: startState, isEndState: endState);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MergedFiniteAutomatonState &&
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
