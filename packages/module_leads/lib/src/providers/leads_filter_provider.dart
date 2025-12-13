import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'leads_provider.dart';

class LeadsFilter {
  final String searchQuery;
  final List<String> selectedStatuses;
  final List<String> selectedOrigins;
  final DateTime? startDate;
  final DateTime? endDate;

  const LeadsFilter({
    this.searchQuery = '',
    this.selectedStatuses = const [],
    this.selectedOrigins = const [],
    this.startDate,
    this.endDate,
  });

  LeadsFilter copyWith({
    String? searchQuery,
    List<String>? selectedStatuses,
    List<String>? selectedOrigins,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return LeadsFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedOrigins: selectedOrigins ?? this.selectedOrigins,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  bool get hasFilters =>
      searchQuery.isNotEmpty ||
      selectedStatuses.isNotEmpty ||
      selectedOrigins.isNotEmpty ||
      startDate != null ||
      endDate != null;

  void clear() {}
}

class LeadsFilterNotifier extends StateNotifier<LeadsFilter> {
  LeadsFilterNotifier() : super(const LeadsFilter());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleStatus(String status) {
    final current = List<String>.from(state.selectedStatuses);
    if (current.contains(status)) {
      current.remove(status);
    } else {
      current.add(status);
    }
    state = state.copyWith(selectedStatuses: current);
  }

  void toggleOrigin(String origin) {
    final current = List<String>.from(state.selectedOrigins);
    if (current.contains(origin)) {
      current.remove(origin);
    } else {
      current.add(origin);
    }
    state = state.copyWith(selectedOrigins: current);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void clearFilters() {
    state = const LeadsFilter();
  }
}

final leadsFilterProvider =
    StateNotifierProvider<LeadsFilterNotifier, LeadsFilter>((ref) {
  return LeadsFilterNotifier();
});

final filteredLeadsProvider = Provider.autoDispose
    .family<AsyncValue<List<LeadModel>>, String>((ref, tenantId) {
  final leadsAsync = ref.watch(leadsProvider(tenantId));
  final filter = ref.watch(leadsFilterProvider);

  return leadsAsync.whenData((leads) {
    return leads.where((lead) {
      // Filter by Search Query
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        final matchesName = lead.nome.toLowerCase().contains(query);
        final matchesPhone = lead.telefone.contains(query);
        if (!matchesName && !matchesPhone) return false;
      }

      // Filter by Status
      if (filter.selectedStatuses.isNotEmpty) {
        if (!filter.selectedStatuses.contains(lead.status)) return false;
      }

      // Filter by Origin
      if (filter.selectedOrigins.isNotEmpty) {
        if (!filter.selectedOrigins.contains(lead.origem)) return false;
      }

      // Filter by Date Range
      if (filter.startDate != null) {
        if (lead.dataCriacao.isBefore(filter.startDate!)) return false;
      }
      if (filter.endDate != null) {
        // Add 1 day to end date to include the end date itself (since times are involved)
        final endOfDay = filter.endDate!
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));
        if (lead.dataCriacao.isAfter(endOfDay)) return false;
      }

      return true;
    }).toList();
  });
});
