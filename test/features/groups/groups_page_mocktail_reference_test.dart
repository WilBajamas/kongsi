// REFERENCE / STUDY FILE — the mocktail way, side by side with the hand-rolled
// fake in groups_page_test.dart. Same create-group flow, but the repository is
// a mocktail mock instead of a real in-memory stand-in. Read the comments; they
// point out each mocktail move. (§7-B: a mock verifies interactions; a fake
// stands in for stateful behaviour. This repo is only stubbed + verified here,
// so a mock is the right tool.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/features/groups/domain/entities/group.dart';
import 'package:kongsi/features/groups/domain/repositories/groups_repository.dart';
import 'package:kongsi/features/groups/groups_providers.dart';
import 'package:kongsi/features/groups/presentation/pages/groups_page.dart';
import 'package:kongsi/features/groups/presentation/widgets/create_group_dialog.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Group(id: '', name: '', currency: '', createdAt: DateTime(2000)),
    );
  });

  testWidgets('creates a group from the dialog (mocktail)', (tester) async {
    final repository = MockGroupsRepository();
    // `when` tells the test to define the response for this behaviour
    // when being used later.
    // "If watchGroups() gets called later, respond with an empty stream."
    when(repository.watchGroups).thenAnswer((_) => Stream.value([]));
    // "If createGroup(anything) gets called later, complete successfully."
    when(() => repository.createGroup(any())).thenAnswer((_) async {});

    // overrides injects the mock; watchGroups() is then called when the
    // page builds.
    await tester.pumpApp(
      const GroupsPage(),
      overrides: [groupsRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Japan Trip');
    // This is where the we simulate creating the group.
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // `verify` asserts the interaction happened exactly once. `captureAny()`
    // additionally grabs the argument so you can inspect it — this replaces
    // the hand-rolled fake's `created` list.
    final captured = verify(
      () => repository.createGroup(captureAny()),
    ).captured;

    expect(captured, hasLength(1));
    final group = captured.single as Group;
    expect(group.name, 'Japan Trip');
    expect(group.currency, 'MYR');
    expect(find.byType(CreateGroupDialog), findsNothing);
  });
}
