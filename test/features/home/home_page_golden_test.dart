import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kongsi/core/di/core_providers.dart';
import 'package:kongsi/features/home/presentation/home_page.dart';

import '../../mocks/mock_app_config.dart';

void main() {
  unawaited(
    goldenTest(
      'HomePage golden',
      fileName: 'home_page',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'default',
            child: ProviderScope(
              overrides: [
                appConfigProvider.overrideWithValue(mockAppConfig),
              ],
              child: const SizedBox(
                width: 400,
                height: 800,
                child: HomePage(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
