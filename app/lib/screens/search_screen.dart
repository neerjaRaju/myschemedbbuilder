import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import '../models/scheme.dart';
import '../widgets/scheme_card.dart';

/// Full-text search over scheme name, ministry, keywords and benefits.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<Scheme> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final repo = context.read<AppState>().repository;
      setState(() => _results = repo.search(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: s.get('searchHint'),
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: _results.isEmpty
          ? Center(
              child: Text(
                _controller.text.isEmpty ? s.get('searchHint') : s.get('noResults'),
              ),
            )
          : SafeArea(
              child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) => SchemeCard(
                scheme: _results[index],
                showCompareToggle: true,
              ),
            )),
    );
  }
}
