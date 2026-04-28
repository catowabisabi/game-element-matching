import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/engine/game_snapshot.dart';
import '../pet/pet_state.dart';

class LocalStore {
  static const _gameKey = 'elementary.game';
  static const _petKey = 'elementary.pet';

  Future<GameSnapshot?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_gameKey);
    if (raw == null) {
      return null;
    }
    return GameSnapshot.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
  }

  Future<void> saveGame(GameSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gameKey, jsonEncode(snapshot.toJson()));
  }

  Future<PetState> loadPet() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_petKey);
    if (raw == null) {
      return PetState.initial();
    }
    return PetState.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
  }

  Future<void> savePet(PetState pet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_petKey, jsonEncode(pet.toJson()));
  }
}
