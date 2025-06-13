import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryPieChartScreen extends StatefulWidget {
  const CategoryPieChartScreen({super.key});

  @override
  State<CategoryPieChartScreen> createState() => _CategoryPieChartScreenState();
}

class _CategoryPieChartScreenState extends State<CategoryPieChartScreen> {
  Map<String, double> expenseCategories = {};
  Map<String, double> incomeCategories = {};
  Map<String, String> localCategoryMap = {}; // transactionId -> category

  final incomeCategoryKeywords = {
    'transfers': ['transfer'],
    'donation': ['donation'],
    'salary': ['salary', 'paycheck', 'wage'],
    'investment': ['investment', 'stock'],
    'interest': ['interest'],
    'child allowance': ['child', 'allowance'],
    'refund': ['refund'],
    'gift': ['gift'],
    'other': [],
  };

  final expenseCategoryKeywords = {
    'food': ['restaurant', 'food', 'pizza', 'kfc', 'mcdonalds'],
    'transport': ['uber', 'bus', 'taxi', 'fuel'],
    'shopping': ['amazon', 'shopping', 'mall', 'store'],
    'bills': ['electricity', 'gas', 'water', 'internet'],
    'health': ['pharmacy', 'doctor', 'clinic'],
    'other': [],
  };

  final categoryIcons = {
    'transfers': Icons.compare_arrows,
    'donation': Icons.volunteer_activism,
    'salary': Icons.payments,
    'investment': Icons.trending_up,
    'interest': Icons.percent,
    'child allowance': Icons.child_care,
    'refund': Icons.undo,
    'gift': Icons.card_giftcard,
    'food': Icons.fastfood,
    'transport': Icons.directions_car,
    'shopping': Icons.shopping_cart,
    'bills': Icons.receipt_long,
    'health': Icons.local_hospital,
    'other': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    _loadLocalCategories().then((_) => _processTransactions());
  }

  Future<void> _loadLocalCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tx_categories');
    if (raw != null) {
      final map = Map<String, String>.from(json.decode(raw));
      setState(() => localCategoryMap = map);
    }
  }

  Future<void> _saveLocalCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tx_categories', json.encode(localCategoryMap));
  }

  Future<void> _processTransactions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('transactions')
        .where('ownerUid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .get();

    final Map<String, double> income = {};
    final Map<String, double> expenses = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final txId = doc.id;
      final amount = (data['amount'] as num).toDouble();
      if (amount == 0) continue;

      final description = (data['description'] ?? '').toString().toLowerCase();
      String category = localCategoryMap[txId] ?? 'other';

      if (!localCategoryMap.containsKey(txId)) {
        final keywords = amount > 0 ? incomeCategoryKeywords : expenseCategoryKeywords;
        for (final entry in keywords.entries) {
          if (entry.value.any((keyword) => description.contains(keyword))) {
            category = entry.key;
            break;
          }
        }
      }

      if (amount > 0) {
        income[category] = (income[category] ?? 0) + amount;
      } else {
        expenses[category] = (expenses[category] ?? 0) + amount.abs();
      }
    }

    setState(() {
      incomeCategories = income;
      expenseCategories = expenses;
    });
  }

  List<PieChartSectionData> _buildSections(Map<String, double> dataMap) {
    final total = dataMap.values.fold(0.0, (a, b) => a + b);
    return dataMap.entries.map((entry) {
      final percent = total == 0 ? 0 : entry.value / total * 100;
      final colorIndex = entry.key.hashCode % Colors.primaries.length;
      return PieChartSectionData(
        color: Colors.primaries[colorIndex],
        value: entry.value,
        title: '${entry.key}\n${percent.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Future<void> _showCategoryEditor(bool showIncomeOnly) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('transactions')
        .where('ownerUid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .get();

    final filtered = snapshot.docs.where((doc) {
      final amount = (doc['amount'] ?? 0).toDouble();
      return showIncomeOnly ? amount > 0 : amount < 0;
    }).toList();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final data = doc.data();
            final txId = doc.id;
            final amount = (data['amount'] ?? 0.0).toDouble();
            final desc = data['description'] ?? 'No description';
            final categoryOptions = (amount > 0 ? incomeCategoryKeywords : expenseCategoryKeywords).keys.toList();
            String selectedCat = localCategoryMap[txId] ?? 'other';

            return StatefulBuilder(
              builder: (context, setModalState) {
                return ListTile(
                  title: Text(desc),
                  subtitle: Text('Amount: €${amount.toStringAsFixed(2)}'),
                  trailing: DropdownButton<String>(
                    value: categoryOptions.contains(selectedCat) ? selectedCat : null,
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => selectedCat = value);
                      setState(() => localCategoryMap[txId] = value);
                      _saveLocalCategories();
                      _processTransactions();
                    },
                    items: categoryOptions.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(categoryIcons[cat], size: 16),
                            const SizedBox(width: 6),
                            Text(cat),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Income & Expense Categories'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Expense'),
                Tab(text: 'Income'),
              ],
            ),
          ),
          body: Stack(
            children: [
              TabBarView(
                children: [
                  _buildPie(expenseCategories),
                  _buildPie(incomeCategories),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () {
                    final isIncomeTab = DefaultTabController.of(context).index == 1;
                    _showCategoryEditor(isIncomeTab);
                  },
                  backgroundColor: Colors.deepPurple,
                  child: const Icon(Icons.edit),
                ),
              )
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPie(Map<String, double> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: PieChart(
        PieChartData(
          sections: _buildSections(data),
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}
