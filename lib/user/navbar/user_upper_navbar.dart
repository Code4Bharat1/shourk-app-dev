import 'package:flutter/material.dart';

class UserUpperNavbar extends StatelessWidget implements PreferredSizeWidget {
  const UserUpperNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFCFBF7),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Shourk',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: () {
            // TODO: Add search logic or open search delegate
            showSearch(context: context, delegate: DummySearchDelegate());
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_alt_outlined, color: Colors.black),
          onPressed: () {
            // TODO: Open filter bottom sheet or dialog
            showModalBottomSheet(
              context: context,
              builder: (_) => const DummyFilterSheet(),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.card_giftcard, color: Colors.black),
          onPressed: () {
            // TODO: Navigate to gift page or perform action
            Navigator.pushNamed(context, '/gift');
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class DummySearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    return Center(child: Text('Search for: "$query"'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? ['Psychologist', 'Therapist', 'Career Coach']
        : ['Suggestion 1', 'Suggestion 2'];

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (_, index) => ListTile(
        title: Text(suggestions[index]),
        onTap: () => query = suggestions[index],
      ),
    );
  }
}

class DummyFilterSheet extends StatelessWidget {
  const DummyFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Options',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            title: const Text('Available Now'),
            value: true,
            onChanged: (val) {},
          ),
          CheckboxListTile(
            title: const Text('Top Rated'),
            value: false,
            onChanged: (val) {},
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}