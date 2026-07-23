import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/features/groups/domain/entities/group.dart';
import 'package:kongsi/features/groups/groups_providers.dart';
import 'package:kongsi/features/groups/presentation/pages/groups_page.dart';
import 'package:kongsi/features/groups/presentation/widgets/create_group_dialog.dart';

import '../../helpers/pump_app.dart';
import '../../mocks/mock_groups_repository.dart';

void main() {
  final demoGroup = Group(
    id: 'g1',
    name: 'Japan Trip',
    currency: 'MYR',
    createdAt: DateTime.utc(2026),
  );

  testWidgets('shows a spinner until the first emission arrives', (
    tester,
  ) async {
    await tester.pumpApp(
      const GroupsPage(),
      overrides: [
        groupsRepositoryProvider.overrideWithValue(
          MockGroupsRepository([demoGroup]),
        ),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the group list once loaded', (tester) async {
    await tester.pumpApp(
      const GroupsPage(),
      overrides: [
        groupsRepositoryProvider.overrideWithValue(
          MockGroupsRepository([demoGroup]),
        ),
      ],
    );
    // a state change only shows up on screen after another frame pump.
    await tester.pump();

    expect(find.text('Japan Trip'), findsOneWidget);
  });

  testWidgets('shows the empty message when there are no groups', (
    tester,
  ) async {
    await tester.pumpApp(
      const GroupsPage(),
      overrides: [
        groupsRepositoryProvider.overrideWithValue(MockGroupsRepository([])),
      ],
    );
    await tester.pump();

    expect(find.text('No groups yet'), findsOneWidget);
  });

  testWidgets('creates a group from the dialog', (tester) async {
    final repository = MockGroupsRepository([]);
    await tester.pumpApp(
      const GroupsPage(),
      overrides: [
        groupsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.pump();

    // open the dialog by finding a FloatingActionButton
    await tester.tap(find.byType(FloatingActionButton));
    // wait for the dialog to fully animate and settle
    await tester.pumpAndSettle();
    // enter the group name - by finding first TextField
    await tester.enterText(find.byType(TextField).first, 'Japan Trip');
    // tap the create button - by text 'Create'
    await tester.tap(find.text('Create'));
    // wait for the dialog to close and the new group to be added to the list
    await tester.pumpAndSettle();

    expect(repository.created, hasLength(1));
    expect(repository.created.single.name, 'Japan Trip');
    expect(repository.created.single.currency, 'MYR');
    // expect dialog to be closed - "nothing"
    expect(find.byType(CreateGroupDialog), findsNothing);
  });
}
