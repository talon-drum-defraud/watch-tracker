import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/watch_provider.dart';
import 'watch_detail_screen.dart';
import 'add_watch_screen.dart';
import 'settings_screen.dart';
import '../widgets/watch_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WatchProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WatchTracker',
                style: Theme.of(context).textTheme.titleLarge),
            Text('Mechanical accuracy log',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<WatchProvider>(
        builder: (_, provider, __) => provider.watches.length < 5
            ? FloatingActionButton.extended(
                onPressed: () => _openAddWatch(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Watch'),
              )
            : const SizedBox.shrink(),
      ),
      body: Consumer<WatchProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          if (provider.watches.isEmpty) {
            return _EmptyState(onAdd: () => _openAddWatch(context));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: provider.watches.length,
            itemBuilder: (ctx, i) {
              final watch = provider.watches[i];
              final latest = provider.latestReadingFor(watch.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: WatchCard(
                  watch: watch,
                  latestReading: latest,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WatchDetailScreen(watchId: watch.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openAddWatch(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddWatchScreen()),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⌚', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('No watches yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Add your first mechanical watch to start tracking.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Watch'),
          ),
        ],
      ),
    );
  }
}
