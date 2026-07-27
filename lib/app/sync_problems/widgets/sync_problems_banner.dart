import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kongsi/app/sync_problems/cubits/sync_problems_cubit.dart';
import 'package:kongsi/app/sync_problems/cubits/sync_problems_state.dart';
import 'package:kongsi/l10n/l10n_extension.dart';

/// Wraps the whole app rather than one screen: a change can be stuck no
/// matter where the user has navigated to, so the warning can't belong to a
/// single page.
///
/// ! Built above the Navigator, which is what supplies the Overlay — so no
/// ! Tooltip, SnackBar or popup menu in here; they look one up and throw at
/// ! build time.
///
/// Deliberately minimal for now — it satisfies ADR-024's "never fail
/// silently" and nothing more. The real UX is unplanned; open questions are
/// listed in the learning log under "Sync-failure UX".
// TODO(wilbert): design the full sync-failure UX (see docs/learning-log.md).
class SyncProblemsBanner extends StatelessWidget {
  const SyncProblemsBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncProblemsCubit, SyncProblemsState>(
      builder: (context, state) => switch (state) {
        SyncProblemsNone() => child,
        SyncProblemsFound(:final failedIds) => Column(
          children: [
            SafeArea(bottom: false, child: _Bar(count: failedIds.length)),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child,
              ),
            ),
          ],
        ),
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        child: Row(
          children: [
            Icon(Icons.sync_problem, color: colors.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.syncProblemsBanner(count),
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: context.read<SyncProblemsCubit>().retryAll,
              child: Text(context.l10n.syncProblemsRetry),
            ),
          ],
        ),
      ),
    );
  }
}
