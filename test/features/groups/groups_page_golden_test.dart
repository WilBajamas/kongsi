import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/features/groups/domain/entities/group.dart';
import 'package:kongsi/features/groups/groups_providers.dart';
import 'package:kongsi/features/groups/presentation/pages/groups_page.dart';

import '../../mocks/mock_groups_repository.dart';

void main() {
  final demoGroup = Group(
    id: 'g1',
    name: 'Japan Trip',
    currency: 'MYR',
    createdAt: DateTime.utc(2026),
  );

  unawaited(
    goldenTest(
      'GroupsPage golden',
      fileName: 'groups_page',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'loaded',
            child: ProviderScope(
              overrides: [
                groupsRepositoryProvider.overrideWithValue(
                  MockGroupsRepository([demoGroup]),
                ),
              ],
              child: const SizedBox(
                width: 400,
                height: 800,
                child: GroupsPage(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
