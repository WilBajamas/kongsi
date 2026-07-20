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

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Japan Trip');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(repository.created, hasLength(1));
    expect(repository.created.single.name, 'Japan Trip');
    expect(repository.created.single.currency, 'MYR');
    expect(find.byType(CreateGroupDialog), findsNothing);
  });
}
