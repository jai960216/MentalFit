import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// === 즐겨찾기 Provider ===
final favoriteCounselorsProvider =
    StateNotifierProvider<FavoriteCounselorsNotifier, Set<String>>((ref) {
      return FavoriteCounselorsNotifier();
    });

// === 특정 상담사 즐겨찾기 여부 Provider ===
final isFavoriteProvider = Provider.family<bool, String>((ref, counselorId) {
  final favorites = ref.watch(favoriteCounselorsProvider);
  return favorites.contains(counselorId);
});

// === 즐겨찾기 Notifier ===
class FavoriteCounselorsNotifier extends StateNotifier<Set<String>> {
  static const String _storageKey = 'favorite_counselors';

  FavoriteCounselorsNotifier() : super(<String>{}) {
    _loadFavorites();
  }

  // === 즐겨찾기 로드 ===
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList(_storageKey) ?? [];
      state = Set<String>.from(favoritesList);
    } catch (e) {
      // SharedPreferences 오류 시 빈 세트 유지
      state = <String>{};
    }
  }

  // === 즐겨찾기 토글 ===
  Future<void> toggleFavorite(String counselorId) async {
    final newState = Set<String>.from(state);

    if (newState.contains(counselorId)) {
      newState.remove(counselorId);
    } else {
      newState.add(counselorId);
    }

    state = newState;
    await _saveFavorites();
  }

  // === 즐겨찾기 추가 ===
  Future<void> addFavorite(String counselorId) async {
    if (!state.contains(counselorId)) {
      state = {...state, counselorId};
      await _saveFavorites();
    }
  }

  // === 즐겨찾기 제거 ===
  Future<void> removeFavorite(String counselorId) async {
    if (state.contains(counselorId)) {
      final newState = Set<String>.from(state);
      newState.remove(counselorId);
      state = newState;
      await _saveFavorites();
    }
  }

  // === 즐겨찾기 확인 ===
  bool isFavorite(String counselorId) {
    return state.contains(counselorId);
  }

  // === 즐겨찾기 저장 ===
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, state.toList());
    } catch (e) {
      // 저장 실패 시 무시 (다음에 다시 시도)
    }
  }

  // === 즐겨찾기 목록 가져오기 ===
  List<String> get favoriteIds => state.toList();

  // === 즐겨찾기 개수 ===
  int get favoriteCount => state.length;

  // === 모든 즐겨찾기 삭제 ===
  Future<void> clearAllFavorites() async {
    state = <String>{};
    await _saveFavorites();
  }
}
