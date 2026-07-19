import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/features/groups/domain/entities/group.dart';
import 'package:kongsi/features/groups/groups_providers.dart';
import 'package:kongsi/features/groups/presentation/pages/groups_page.dart';

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
}
