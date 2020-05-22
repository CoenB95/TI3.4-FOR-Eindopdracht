import 'package:characters/characters.dart';

class Alphabet {
  Set<String> _alphabet;

  Alphabet(this._alphabet) {
    if (_alphabet.any((c) => c.length != 1))
      throw StateError('Alpabet should exist of characters only');
  }
  
  Alphabet.ab() : this({'a', 'b'});
  Alphabet.ofString(String alphabet) : this(alphabet.characters.toSet());

  bool isValid(String word) => !word.characters.any((c) => !_alphabet.contains(c));

  Iterable<String> get letters => _alphabet;
}