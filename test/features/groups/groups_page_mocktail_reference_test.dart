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

// 1. A mock is just an empty subclass — no constructor, no behaviour of its
//    own. mocktail intercepts every call so you can script and inspect them.
class MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  setUpAll(() {
    // 2. registerFallbackValue: needed once per custom type you later match
    //    with any()/captureAny(). mocktail needs a sample Group to stand in
    //    while it reasons about the matcher — the values never matter as real
    //    data. (Primitives like String/int need no fallback.)
    registerFallbackValue(
      Group(id: '', name: '', currency: '', createdAt: DateTime(2000)),
    );
  });

  testWidgets('creates a group from the dialog (mocktail)', (tester) async {
    final repository = MockGroupsRepository();

    // 3. Stub the reads. watchGroups() is called by the page's cubit; an
    //    unstubbed method on a mock throws, so give it a canned empty stream.
    //    thenAnswer (not thenReturn) because the return is computed lazily —
    //    the right choice for Streams/Futures. (Docs often write the closure
    //    form `() => repository.watchGroups()`; a plain tearoff is the same.)
    when(repository.watchGroups).thenAnswer((_) => Stream.value([]));

    // 4. Stub the write so awaiting it completes. any() matches any Group
    //    argument — that's what the fallback value registered above is for.
    when(() => repository.createGroup(any())).thenAnswer((_) async {});

    await tester.pumpApp(
      const GroupsPage(),
      overrides: [groupsRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Japan Trip');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // 5. verify asserts the interaction happened exactly once. captureAny()
    //    additionally grabs the argument so you can inspect it — this replaces
    //    the hand-rolled fake's `created` list.
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
