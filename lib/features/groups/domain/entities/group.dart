import 'package:equatable/equatable.dart';

class Group extends Equatable {
  const Group({
    required this.id,
    required this.name,
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String currency;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, currency, createdAt];
}
