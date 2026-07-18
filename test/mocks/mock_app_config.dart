import 'package:kongsi/core/config/app_config.dart';

/// Default config for tests — dev flavor with throwaway Supabase values.
const mockAppConfig = AppConfig(
  supabaseUrl: 'https://mock.supabase.co',
  supabaseAnonKey: 'mock-anon-key',
  flavor: Flavor.dev,
);
