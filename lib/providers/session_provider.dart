import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam_session.dart';
import '../core/constants.dart';

final sessionProvider = StateNotifierProvider<SessionNotifier, ExamSession?>((ref) {
  return SessionNotifier();
});

class SessionNotifier extends StateNotifier<ExamSession?> {
  SessionNotifier() : super(null);

  Future<void> startSession(ExamSession session) async {
    state = session;
    await _saveToStorage();
  }

  void updateAnswer(int questionId, int? selectedIndex) {
    if (state == null) return;
    
    final newAnswers = Map<int, int?>.from(state!.userAnswers);
    newAnswers[questionId] = selectedIndex;
    
    final newVisited = Map<int, bool>.from(state!.visitedQuestions);
    newVisited[questionId] = true;

    state = state!.copyWith(userAnswers: newAnswers, visitedQuestions: newVisited);
    _saveToStorage();
  }

  void markVisited(int questionId) {
    if (state == null) return;
    final newVisited = Map<int, bool>.from(state!.visitedQuestions);
    if (newVisited[questionId] != true) {
      newVisited[questionId] = true;
      state = state!.copyWith(visitedQuestions: newVisited);
      _saveToStorage();
    }
  }

  void toggleMarkForReview(int questionId) {
    if (state == null) return;
    
    final newMarked = Map<int, bool>.from(state!.markedForReview);
    newMarked[questionId] = !(newMarked[questionId] ?? false);
    
    state = state!.copyWith(markedForReview: newMarked);
    _saveToStorage();
  }

  void updateTimeRemaining(int time) {
    if (state == null) return;
    state = state!.copyWith(timeRemaining: time);
    _saveToStorage();
  }

  Future<void> clearSession() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.resumeSession);
  }

  Future<void> _saveToStorage() async {
    if (state == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.resumeSession, jsonEncode(state!.toJson()));
  }

  Future<void> restoreFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(StorageKeys.resumeSession);
    if (data != null) {
      try {
        state = ExamSession.fromJson(jsonDecode(data));
      } catch (e) {
        await clearSession();
      }
    }
  }
}
