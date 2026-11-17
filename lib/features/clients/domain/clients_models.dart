/// Summary card for a company client returned by `/business/clients`.
final class ClientSummary {
  const ClientSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.linked,
    this.email,
  });

  final int id;
  final String name;
  final String phone;
  final String? email;
  final bool linked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientSummary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          email == other.email &&
          linked == other.linked;

  @override
  int get hashCode => Object.hash(id, name, phone, email, linked);
}

/// Paginated response of company clients.
final class ClientsPage {
  const ClientsPage({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
  });

  final List<ClientSummary> items;
  final int page;
  final int perPage;
  final int total;

  bool get hasMore => page * perPage < total;
}

/// Contract for company client CRM operations.
abstract interface class ClientsRepository {
  Future<ClientsPage> listClients({
    String? search,
    int page = 1,
    int perPage = 20,
  });

  Future<int> createClient({
    required String name,
    required String phone,
    String? email,
  });

  Future<bool> mergeClients({required int sourceId, required int targetId});
}
