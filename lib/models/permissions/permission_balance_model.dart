

import 'permission_type_model.dart';

class PermissionBalance {
  final PermissionType type;
  final int total;
  final int consumed;
  final int remaining;

  PermissionBalance({
    required this.type,
    required this.total,
    required this.consumed,
    required this.remaining,
  });
}