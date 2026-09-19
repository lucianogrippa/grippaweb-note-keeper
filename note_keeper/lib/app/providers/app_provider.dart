import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/features/auth/auth_controller.dart';

/// auth provider
final authProvider = AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
