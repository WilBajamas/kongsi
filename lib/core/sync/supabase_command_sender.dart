import 'package:dio/dio.dart';
import 'package:kongsi/core/sync/command.dart';
import 'package:kongsi/core/sync/command_sender.dart';

/// Pushes a command to Supabase via PostgREST. Stays generic: it asks each
/// command for its [Command.table] and [Command.toRow], so a new command type
/// needs no change here.
class SupabaseCommandSender implements CommandSender {
  const SupabaseCommandSender({required this.dio, required this.anonKey});

  final Dio dio;
  final String anonKey;

  @override
  Future<void> send(Command command) async {
    // PostgREST needs both headers. With no user yet, both carry the anon key;
    // once auth lands, AuthInterceptor overrides Authorization with the user's
    // JWT while apikey stays the anon key.
    await dio.post<void>(
      '/rest/v1/${command.table}',
      data: command.toRow(),
      options: Options(
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          // Don't ask PostgREST to echo the inserted row back — unused.
          'Prefer': 'return=minimal',
        },
      ),
    );
    // A non-2xx makes dio throw DioException (an Exception), which SyncBloc
    // catches to halt the drain and keep FIFO order.
  }
}
