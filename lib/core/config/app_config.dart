enum Flavor {
  dev,
  staging,
  prod;

  static Flavor fromString(String value) => Flavor.values.byName(value);
}

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.flavor,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      supabaseUrl: const String.fromEnvironment('supabaseUrl'),
      supabaseAnonKey: const String.fromEnvironment('supabaseAnonKey'),
      flavor: Flavor.fromString(const String.fromEnvironment('flavor')),
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final Flavor flavor;
}
