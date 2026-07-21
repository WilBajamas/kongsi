import 'package:dio/dio.dart';
import 'package:kongsi/core/sync/command.dart';
import 'package:kongsi/core/sync/command_sender.dart';
import 'package:kongsi/core/sync/send_failure.dart';

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
    try {
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
    } on DioException catch (e) {
      throw _classify(e);
    }
  }

  // A 4xx means the server refused THIS command (bad data, not bad luck), so
  // it counts toward the ceiling. Everything else — offline, timeout, 5xx — is
  // transient and worth retrying without blaming the slip. 401 is left to the
  // auth refresh; 429 is rate-limiting, not a bad slip.
  SendFailure _classify(DioException e) {
    final status = e.response?.statusCode;
    final rejected =
        status != null &&
        status >= 400 &&
        status < 500 &&
        status != 401 &&
        status != 429;
    return rejected ? CommandRejected(e) : DeliveryFailed(e);
  }
}
