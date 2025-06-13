import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'CategoryPieChartScreen.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  Map<String, double> incomeMap = {};
  Map<String, double> expenseMap = {};
  double totalIncome = 0;
  double totalExpense = 0;
  String currentPeriod = '';

  @override
  void initState() {
    super.initState();
    _fetchAndProcessData();
  }

  Future<void> _fetchAndProcessData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('transactions')
        .where('ownerUid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .get();

    final formatter = DateFormat('MMM yyyy');
    final Map<String, double> income = {};
    final Map<String, double> expenses = {};
    final Map<String, DateTime> periodTimestamps = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      final amount = (data['amount'] as num).toDouble();
      final groupKey = formatter.format(timestamp);

      periodTimestamps[groupKey] = timestamp;

      if (amount > 0) {
        income[groupKey] = (income[groupKey] ?? 0) + amount;
      } else {
        expenses[groupKey] = (expenses[groupKey] ?? 0) + amount.abs();
      }
    }

    final allPeriods = {...income.keys, ...expenses.keys}.toList()..sort();
    final latestPeriodKey = allPeriods.isNotEmpty
        ? allPeriods.reduce((a, b) =>
    periodTimestamps[a]!.isAfter(periodTimestamps[b]!) ? a : b)
        : '';

    setState(() {
      incomeMap = income;
      expenseMap = expenses;
      currentPeriod = latestPeriodKey;
      totalIncome = income[latestPeriodKey] ?? 0;
      totalExpense = expenses[latestPeriodKey] ?? 0;
    });
  }

  List<BarChartGroupData> _buildChartGroups() {
    final allKeys = {...incomeMap.keys, ...expenseMap.keys}.toList()..sort();

    return List.generate(allKeys.length, (i) {
      final key = allKeys[i];
      final income = incomeMap[key] ?? 0;
      final expense = expenseMap[key] ?? 0;

      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: income, color: Colors.green, width: 7, borderRadius: BorderRadius.circular(3)),
        BarChartRodData(toY: expense, color: Colors.red, width: 7, borderRadius: BorderRadius.circular(3)),
      ]);
    });
  }

  Widget _buildChart() {
    final allKeys = {...incomeMap.keys, ...expenseMap.keys}.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text("Selected Period: $currentPeriod", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.south_west, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text("Income: €${totalIncome.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 20),
                  const Icon(Icons.north_east, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text("Expense: €${totalExpense.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: BarChart(
            BarChartData(
              barGroups: _buildChartGroups(),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, _) =>
                        Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index >= allKeys.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(allKeys[index], style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Income & Spending Graph")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(child: _buildChart()),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CategoryPieChartScreen()),
                  );
                },
                icon: const Icon(Icons.pie_chart),
                label: const Text('View by Category'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
