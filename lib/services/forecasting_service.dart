class FuelForecast {
  final double projectedMonthlySpend;
  final double averageCostPerKm;
  final double estimatedRangeRemaining;

  FuelForecast({
    required this.projectedMonthlySpend,
    required this.averageCostPerKm,
    required this.estimatedRangeRemaining,
  });
}

class ForecastingService {
  static FuelForecast calculateForecast({
    required List<Map<String, dynamic>> fuelLogs, // Recent fuel slips with dates and amounts
    required double currentFuelPricePerLitre,
    required double tankCapacityLitres,
    required double avgL100km,
  }) {
    if (fuelLogs.length < 2) {
      return FuelForecast(projectedMonthlySpend: 0.0, averageCostPerKm: 0.0, estimatedRangeRemaining: 0.0);
    }

    fuelLogs.sort((a, b) => (a['transaction_date'] as DateTime).compareTo(b['transaction_date'] as DateTime));

    final firstDate = fuelLogs.first['transaction_date'] as DateTime;
    final lastDate = fuelLogs.last['transaction_date'] as DateTime;
    final totalDays = lastDate.difference(firstDate).inDays;

    final totalSpent = fuelLogs.fold<double>(0.0, (sum, item) => sum + (item['total_amount'] as double));
    final totalKm = fuelLogs.fold<double>(0.0, (sum, item) => sum + ((item['distance_driven'] ?? 0.0) as double));

    final avgDailySpend = totalDays > 0 ? (totalSpent / totalDays) : 0.0;
    final projectedMonthly = avgDailySpend * 30.0;
    final costPerKm = totalKm > 0 ? (totalSpent / totalKm) : 0.0;

    // Full tank estimated range: (Tank Size / Consumption rate) * 100
    final rangeRemaining = avgL100km > 0 ? (tankCapacityLitres / avgL100km) * 100 : 0.0;

    return FuelForecast(
      projectedMonthlySpend: projectedMonthly,
      averageCostPerKm: costPerKm,
      estimatedRangeRemaining: rangeRemaining,
    );
  }
}