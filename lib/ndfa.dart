import 'alphabet.dart';
import 'finite_automaton.dart';
import 'package:characters/characters.dart';

class NonDeterministicFiniteAutomaton extends FiniteAutomaton {
  NonDeterministicFiniteAutomaton(Alphabet alphabet) : super(alphabet);

  Iterable<FiniteAutomatonState> get startStates =>
      states.where((s) => s.isStartState);

  final Set<FiniteAutomatonTransition> _transitions = {};
  Iterable<FiniteAutomatonTransition> get transitions =>
      List.unmodifiable(_transitions);

  void addTransition(FiniteAutomatonTransition transition) {
    _transitions.add(transition);
  }

  static NonDeterministicFiniteAutomaton contains(String input,
      {Alphabet alphabet}) {
    NonDeterministicFiniteAutomaton ndfa =
        NonDeterministicFiniteAutomaton(alphabet ?? Alphabet.ofString(input));
    FiniteAutomatonState start = ndfa.createState('S', startState: true);
    FiniteAutomatonState last = start;
    for (int i = 0; i < input.length; i++) {
      String char = input.substring(i, i + 1);
      FiniteAutomatonState fromState = last;
      FiniteAutomatonState toState =
          ndfa.createState('Q${i + 1}', endState: i + 1 == input.length);
      ndfa.createTransition(fromState, toState, char);
      last = toState;
    }
    return ndfa;
  }

  /// List all the states that can be reached from this state using the supplied symbol.
  /// Considers epsilon-transitions as well.
  Set<FiniteAutomatonState> deltaE(FiniteAutomatonState state, String symbol) {
    Set<FiniteAutomatonState> epsilonStates = eClosure(state);
    var y = transitions
        .where((t) => epsilonStates.contains(t.fromState) && t.test(symbol))
        .map((t) => t.toState)
        .toSet();
    return y;
  }

  /// List all the states that can be reached from this state without consuming a character (epsilon-only).
  Set<FiniteAutomatonState> eClosure(FiniteAutomatonState state) {
    Set<FiniteAutomatonState> epsilonStates = {
      state
    }; // Of course we can reach ourselves.

    // Recursively check whether there are more 'free' transitions.
    var epsilonTransitions =
        transitions.where((t) => t.fromState == state && t.test());
    epsilonStates.addAll(epsilonTransitions.expand((t) => eClosure(t.toState)));

    return epsilonStates;
  }

  static NonDeterministicFiniteAutomaton endsWith(String input,
      {Alphabet alphabet}) {
    NonDeterministicFiniteAutomaton ndfa =
        NonDeterministicFiniteAutomaton(alphabet ?? Alphabet.ofString(input));
    FiniteAutomatonState start = ndfa.createState('S', startState: true);
    FiniteAutomatonState last = start;
    for (int i = 0; i < input.length; i++) {
      String char = input.substring(i, i + 1);
      FiniteAutomatonState fromState = last;
      FiniteAutomatonState toState =
          ndfa.createState('Q${i + 1}', endState: i + 1 == input.length);
      ndfa.createTransition(fromState, toState, char);
      last = toState;
    }
    return ndfa;
  }

  Set<String> generate({int maxSteps = 5}) {
    return {};
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
        if (transitions.where((t) => t.fromState == s && t.test(c)).length !=
            1) {
          return false;
        }
      }
    }
    return true;
  }

  /// Internal method to recursively check whether the supplied string is accepted by this NDFA.
  bool _match(FiniteAutomatonState state, String string) {
    // A true DFA allows transitions to be 'incomplete'; missing transitions for certain characters.
    // So sometimes we'll need to circle-in-place until a character is read with which we can continue.
    int i = 0;
    while (i < string.length) {
      String symbol = string.characters.elementAt(i);
      String subString = string.substring(i + 1);
      if (deltaE(state, symbol).any((s) => _match(s, subString))) return true;
      i++;
    }

    return eClosure(state).any((s) => s.isEndState);
  }

  static NonDeterministicFiniteAutomaton startWith(String input,
      {Alphabet alphabet}) {
    alphabet = (alphabet ?? Alphabet.ofString(input));
    NonDeterministicFiniteAutomaton ndfa =
        NonDeterministicFiniteAutomaton(alphabet);
    FiniteAutomatonState start = ndfa.createState('S', startState: true);
    FiniteAutomatonState last = start;
    for (int i = 0; i < input.length; i++) {
      String char = input.substring(i, i + 1);
      FiniteAutomatonState fromState = last;
      FiniteAutomatonState toState =
          ndfa.createState('Q${i + 1}', endState: i + 1 == input.length);
      ndfa.createTransition(fromState, toState, char);
      last = toState;
    }

    for (String character in alphabet.letters) {
      ndfa.createTransition(last, last, character);
    }

    return ndfa;
  }
}
