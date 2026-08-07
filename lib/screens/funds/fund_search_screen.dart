import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/fund.dart';
import '../../services/funds_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/money.dart';

/// Fund search and add.
///
/// Pops `true` when a fund was added, so the list behind it knows to reload.
class FundSearchScreen extends StatefulWidget {
  const FundSearchScreen({super.key});

  @override
  State<FundSearchScreen> createState() => _FundSearchScreenState();
}

class _FundSearchScreenState extends State<FundSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  List<Fund> _results = [];
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Debounced: the scheme list is 14,000 rows and a request per keystroke
    // would search it a dozen times while someone types one fund name.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }

    setState(() => _searching = true);
    final results = await FundsService.instance.search(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
      _searched = true;
    });
  }

  Future<void> _add(Fund fund) async {
    final unitsController = TextEditingController();
    final investedController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(fund.shortName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NAV ${Money.format(fund.nav, 'INR')}'
              '${fund.navDate != null ? ' · ${fund.navDate}' : ''}',
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: unitsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Units',
                // Units, not an amount: a SIP buys a different number of units
                // every month, so only units tie the invested figure to what
                // the holding is worth today.
                helperText: 'From your fund statement',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: investedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total invested (₹)',
                helperText: 'Optional — needed to show your gain',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Add')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await FundsService.instance.add(
      fund,
      units: double.tryParse(unitsController.text),
      invested: double.tryParse(investedController.text),
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't add that fund. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a fund')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search by fund name',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            _searched
                ? "No funds matched that. Try the fund house name, like \"HDFC Flexi Cap\"."
                // Naming the old-name behaviour here, because someone who types
                // "SBI Bluechip" and sees "SBI Large Cap" come back would
                // otherwise think the app got it wrong.
                : 'Type at least 3 letters.\n\nOld fund names work too — "SBI Bluechip" finds '
                    'SBI Large Cap, which is what it was renamed to.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final fund = _results[i];
        return ListTile(
          title: Text(fund.shortName, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            fund.planLabel ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            Money.format(fund.nav, 'INR'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () => _add(fund),
        );
      },
    );
  }
}
