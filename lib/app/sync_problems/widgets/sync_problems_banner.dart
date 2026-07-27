import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kongsi/app/sync_problems/cubits/sync_problems_cubit.dart';
import 'package:kongsi/app/sync_problems/cubits/sync_problems_state.dart';
import 'package:kongsi/l10n/l10n_extension.dart';

/// ! TEMPORARY. This is a stopgap, not the answer to "how do we tell someone a
/// ! change didn't save". It exists only so ADR-024's rule — never fail
/// ! silently — holds today, and it is expected to be replaced rather than
/// ! grown. Do not build on it.
///
/// What makes it a stopgap, not a design:
/// - "2 changes could not be saved" tells the user nothing about *which*
///   changes. The outbox stores an opaque payload; no slip can describe
///   itself. Fixing that is a core-sync change, not a UI one.
/// - Retry is all-or-nothing, and there is no discard at all (discarding
///   needs a rollback that can't exist until something records a row's
///   pre-edit value).
/// - A permanent, undismissable red bar on every screen is far too loud for
///   what may be one stale row.
///
/// Full list of open questions: the learning log, under "Sync-failure UX".
// TODO(wilbert): replace with a real sync-failure UX (docs/learning-log.md).
///
/// Wraps the whole app rather than one screen: a change can be stuck no
/// matter where the user has navigated to, so the warning can't belong to a
/// single page.
///
/// ! Built above the Navigator, which is what supplies the Overlay — so no
/// ! Tooltip, SnackBar or popup menu in here; they look one up and throw at
/// ! build time.
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
