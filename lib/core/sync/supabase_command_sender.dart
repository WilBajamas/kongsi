import 'package:dio/dio.dart';
import 'package:kongsi/core/sync/command.dart';
import 'package:kongsi/core/sync/command_sender.dart';
import 'package:kongsi/core/sync/send_failure.dart';

/// Pushes a command to Supabase via PostgREST. Generic — a new command type
/// needs no change here, since each command carries its own table and row.
class SupabaseCommandSender implements CommandSender {
  const SupabaseCommandSender({required this.dio, required this.anonKey});

  final Dio dio;
  final String anonKey;

  @override
  Future<void> send(Command command) async {
    try {
      await dio.post<void>(
        '/rest/v1/${command.table}',
        data: command.toRow(),
        options: Options(
          headers: {
            // Both carry the anon key for now; AuthInterceptor swaps a user
            // JWT into Authorization once auth lands.
            'apikey': anonKey,
            'Authorization': 'Bearer $anonKey',
            'Prefer': 'return=minimal',
          },
        ),
      );
    } on DioException catch (e) {
      throw _classify(e);
    }
  }

  // 4xx = the server refused this slip (counts against the ceiling); everything
  // else is transient. 401 → auth refresh, 429 → rate limit.
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
