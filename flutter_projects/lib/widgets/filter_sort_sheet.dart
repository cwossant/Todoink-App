import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_status.dart';
import '../providers/filter_sort_provider.dart';

class FilterSortSheet extends ConsumerWidget {
  const FilterSortSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(filterStatusProvider);
    final selectedSort = ref.watch(sortOptionProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Filter & Sort',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          // Filter Section
          Text(
            'Filter by Status',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              // "All" option
              FilterChip(
                label: const Text('All'),
                selected: selectedFilter == null,
                onSelected: (_) {
                  ref.read(filterStatusProvider.notifier).state = null;
                },
              ),
              // Status options
              ...TaskStatus.values.map((status) {
                return FilterChip(
                  label: Text(status.displayName),
                  selected: selectedFilter == status,
                  onSelected: (_) {
                    ref.read(filterStatusProvider.notifier).state = status;
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 32),

          // Sort Section
          Text(
            'Sort by',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: SortOption.values.map((option) {
              return FilterChip(
                label: Text(option.displayName),
                selected: selectedSort == option,
                onSelected: (_) {
                  ref.read(sortOptionProvider.notifier).state = option;
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Clear Filters Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(filterStatusProvider.notifier).state = null;
                ref.read(sortOptionProvider.notifier).state = SortOption.date;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]
                    : Colors.grey[300],
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
              child: const Text('Reset Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
