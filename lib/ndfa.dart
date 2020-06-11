import 'alphabet.dart';
import 'finite_automaton.dart';
import 'package:characters/characters.dart';

class NonDeterministicFiniteAutomaton extends FiniteAutomaton {
  NonDeterministicFiniteAutomaton(Alphabet alphabet) : super(alphabet);

  static NonDeterministicFiniteAutomaton contains(String input, {Alphabet alphabet}) {
    NonDeterministicFiniteAutomaton ndfa = NonDeterministicFiniteAutomaton(alphabet ?? Alphabet.ofString(input));
    FiniteAutomatonState start = ndfa.createState('S', startState: true);
    FiniteAutomatonState last = start;
    for (int i = 0; i < input.length; i++) {
      String char = input.substring(i, i + 1);
      FiniteAutomatonState fromState = last;
      FiniteAutomatonState toState = ndfa.createState('Q${i + 1}', endState: i + 1 == input.length);
      ndfa.addTransition(fromState, toState, char);
      last = toState;
    }
    return ndfa;
  }

  /// List all the states that can be reached from this state using the supplied symbol.
  /// Considers epsilon-transitions as well.
  Set<FiniteAutomatonState> _deltaE(FiniteAutomatonState state, String symbol) {
    Set<FiniteAutomatonState> epsilonStates = _eClosure(state);
    var y = transitions.where((t) => epsilonStates.contains(t.fromState) && t.test(symbol)).map((t) => t.toState).toSet();
    return y;
  }

  /// List all the states that can be reached from this state without consuming a character (epsilon-only).
  Set<FiniteAutomatonState> _eClosure(FiniteAutomatonState state) {
    Set<FiniteAutomatonState> epsilonStates = {state}; // Of course we can reach ourselves.

    // Recursively check whether there are more 'free' transitions.
    var epsilonTransitions = transitions.where((t) => t.fromState == state && t.test());
    epsilonStates.addAll(epsilonTransitions.expand((t) => _eClosure(t.toState)));

    return epsilonStates;
  }

  static NonDeterministicFiniteAutomaton endsWith(String input, {Alphabet alphabet}) {
    NonDeterministicFiniteAutomaton ndfa = NonDeterministicFiniteAutomaton(alphabet ?? Alphabet.ofString(input));
    FiniteAutomatonState start = ndfa.createState('S', startState: true);
    FiniteAutomatonState last = start;
    for (int i = 0; i < input.length; i++) {
      String char = input.substring(i, i + 1);
      FiniteAutomatonState fromState = last;
      FiniteAutomatonState toState = ndfa.createState('Q${i + 1}', endState: i + 1 == input.length);
      ndfa.addTransition(fromState, toState, char);
      last = toState;
    }
    return ndfa;
  }

  Set<String> generate({int maxSteps = 5}) {
    return null;
  }
  
  @override
  bool hasMatch(String input) {
    var startStates = states.where((s) => s.isStartState);
    return startStates.any((s) => _match(s, input));
  }

  /// Check whether this FiniteAutomaton is a DFA (fully-defined transitions between states).
  bool isDeterministic() {
    // Check whether every state has exactly ONE transition to a different state
    // for every letter from the alphabet.
    for (var s in states) {
      for (var c in alphabet.letters) {
        if (transitions.where((t) => t.fromState == s && t.test(c)).length != 1) {
          return false;
        }
      }
    }
    return true;
  }

  /// Internal method to recursively check whether the supplied string is accepted by this NDFA.
  bool _match(FiniteAutomatonState state, String string) {
    // In case we've reached the end of the string:
    // Check to see if we are in a end-state (= match).
    // Otherwise, check if we can reach a different end-state still using epsilon-transitions.
    if (string.isEmpty)
      return _eClosure(state).any((s) => s.isEndState);
    
    String symbol = string.characters.first;
    return _deltaE(state, symbol).any((s) => _match(s, string.substring(1)));
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
      ndfa.addTransition(fromState, toState, char);
      last = toState;
    }

    for (String character in alphabet.letters) {
      ndfa.addTransition(last, last, character);
    }

    return ndfa;
  }
}