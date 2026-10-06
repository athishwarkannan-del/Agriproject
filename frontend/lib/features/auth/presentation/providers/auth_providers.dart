import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user ?? ref.read(supabaseClientProvider).auth.currentUser;
});

class AuthStateData {
  final bool isLoading;
  final String? error;
  
  AuthStateData({this.isLoading = false, this.error});
  
  AuthStateData copyWith({bool? isLoading, String? error}) {
    return AuthStateData(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Can be null
    );
  }
}

class AuthNotifier extends Notifier<AuthStateData> {
  @override
  AuthStateData build() {
    return AuthStateData();
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(supabaseClientProvider).auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(supabaseClientProvider).auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthStateData>(AuthNotifier.new);
