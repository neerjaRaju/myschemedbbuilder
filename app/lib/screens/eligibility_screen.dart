import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import '../logic/eligibility.dart';
import 'scheme_list_screen.dart';

/// The questionnaire-driven eligibility checker: answer a few questions,
/// see "You may be eligible for N schemes" and browse the matches.
class EligibilityScreen extends StatefulWidget {
  const EligibilityScreen({super.key});

  @override
  State<EligibilityScreen> createState() => _EligibilityScreenState();
}

class _EligibilityScreenState extends State<EligibilityScreen> {
  late final TextEditingController _ageController;
  late final TextEditingController _incomeController;
  String _gender = '';
  String _state = '';
  String _occupation = '';
  String _caste = '';

  @override
  void initState() {
    super.initState();
    final saved = EligibilityProfile.fromMap(
      context.read<AppState>().store.eligibilityProfile,
    );
    _ageController = TextEditingController(text: saved.age?.toString() ?? '');
    _incomeController =
        TextEditingController(text: saved.annualIncome?.toString() ?? '');
    _gender = saved.gender;
    _state = saved.state;
    _occupation = saved.occupation;
    _caste = saved.casteCategory;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  EligibilityProfile _profile() => EligibilityProfile(
        age: int.tryParse(_ageController.text),
        gender: _gender,
        state: _state,
        annualIncome: int.tryParse(_incomeController.text),
        occupation: _occupation,
        casteCategory: _caste,
      );

  Future<void> _check() async {
    final appState = context.read<AppState>();
    final s = S.of(context);
    final profile = _profile();
    await appState.store.saveEligibilityProfile(profile.toMap());

    // Screen the entire corpus.
    final all = appState.repository.byIds(appState.repository.allIds());
    final result = EligibilityChecker.run(all, profile);

    if (!mounted) return;
    final message =
        s.get('eligibleCount').replaceAll('{count}', '${result.count}');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
        content: Text(s.get('eligibilityNote')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SchemeResultsScreen(
                    title: message,
                    schemes: result.eligible,
                  ),
                ),
              );
            },
            child: Text(s.get('viewAll')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final states = context.read<AppState>().repository.states();

    return Scaffold(
      appBar: AppBar(title: Text(s.get('eligibility'))),
      body: SafeArea(
          child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.get('eligibilityNote')),
          const SizedBox(height: 16),
          TextField(
            controller: _ageController,
            decoration: InputDecoration(
              labelText: s.get('age'),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _gender,
            decoration: InputDecoration(
              labelText: s.get('gender'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: '', child: Text(s.get('any'))),
              DropdownMenuItem(value: 'female', child: Text(s.get('female'))),
              DropdownMenuItem(value: 'male', child: Text(s.get('male'))),
            ],
            onChanged: (v) => setState(() => _gender = v ?? ''),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _state.isEmpty ? '' : _state,
            decoration: InputDecoration(
              labelText: s.get('state'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: '', child: Text(s.get('any'))),
              for (final st in states)
                DropdownMenuItem(value: st, child: Text(st)),
            ],
            onChanged: (v) => setState(() => _state = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _incomeController,
            decoration: InputDecoration(
              labelText: s.get('income'),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _occupation,
            decoration: InputDecoration(
              labelText: s.get('occupation'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: '', child: Text(s.get('any'))),
              DropdownMenuItem(value: 'farmer', child: Text(s.get('farmer'))),
              DropdownMenuItem(
                value: 'student',
                child: Text(s.get('student')),
              ),
              DropdownMenuItem(
                value: 'business owner',
                child: Text(s.get('businessOwner')),
              ),
            ],
            onChanged: (v) => setState(() => _occupation = v ?? ''),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _caste,
            decoration: InputDecoration(
              labelText: s.get('casteCategory'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: '', child: Text(s.get('general'))),
              const DropdownMenuItem(value: 'sc', child: Text('SC')),
              const DropdownMenuItem(value: 'st', child: Text('ST')),
              const DropdownMenuItem(value: 'obc', child: Text('OBC')),
            ],
            onChanged: (v) => setState(() => _caste = v ?? ''),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _check,
            icon: const Icon(Icons.checklist),
            label: Text(s.get('checkEligibility')),
          ),
        ],
      )),
    );
  }
}
