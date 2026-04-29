import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/engine/game_snapshot.dart';
import '../pet/pet_state.dart';

class LocalStore {
  static const _gameKey = 'elementary.game';
  static const _petKey = 'elementary.pet';
  static const _seenTutorialKey = 'elementary.seen_tutorial';
  static const _seenMergeTooltipKey = 'elementary.tooltip_merge';
  static const _seenHintTooltipKey = 'elementary.tooltip_hint';
  static const _seenManaTooltipKey = 'elementary.tooltip_mana';
  static const _seenFeedTooltipKey = 'elementary.tooltip_feed';

  Future<bool> getSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenTutorialKey) ?? false;
  }

  Future<void> setSeenTutorial(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenTutorialKey, value);
  }

  Future<bool> getSeenMergeTooltip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenMergeTooltipKey) ?? false;
  }

  Future<void> setSeenMergeTooltip(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenMergeTooltipKey, value);
  }

  Future<bool> getSeenHintTooltip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenHintTooltipKey) ?? false;
  }

  Future<void> setSeenHintTooltip(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenHintTooltipKey, value);
  }

  Future<bool> getSeenManaTooltip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenManaTooltipKey) ?? false;
  }

  Future<void> setSeenManaTooltip(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenManaTooltipKey, value);
  }

  Future<bool> getSeenFeedTooltip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenFeedTooltipKey) ?? false;
  }

  Future<void> setSeenFeedTooltip(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenFeedTooltipKey, value);
  }

  Future<GameSnapshot?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_gameKey);
    if (raw == null) {
      return null;
    }
    try {
      return GameSnapshot.fromJson(
          Map<String, Object?>.from(jsonDecode(raw) as Map));
    } catch (_) {
      await prefs.remove(_gameKey);
      return null;
    }
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
    try {
      return PetState.fromJson(
          Map<String, Object?>.from(jsonDecode(raw) as Map));
    } catch (_) {
      await prefs.remove(_petKey);
      return PetState.initial();
    }
  }

  Future<void> savePet(PetState pet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_petKey, jsonEncode(pet.toJson()));
  }
}
