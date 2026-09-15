class FuelHealthAnalysis {
  final double consumptionL100km;
  final double distanceDriven;
  final bool hasSpikeAlert;
  final String? alertMessage;

  FuelHealthAnalysis({
    required this.consumptionL100km,
    required this.distanceDriven,
    required this.hasSpikeAlert,
    this.alertMessage,
  });
}

class EfficiencyService {
  /// Calculates efficiency and checks for anomalous consumption spikes (> 20% over average)
  static FuelHealthAnalysis analyzeFillUp({
    required double currentLitres,
    required int currentOdometer,
    required int previousOdometer,
    required List<double> historicalL100km,
  }) {
    final distance = (currentOdometer - previousOdometer).toDouble();
    if (distance <= 0) {
      throw Exception('Current odometer must be greater than previous odometer.');
    }

    // Formula: (Litres / Distance in KM) * 100
    final l100km = (currentLitres / distance) * 100;

    bool isSpike = false;
    String? alertMsg;

    if (historicalL100km.length >= 3) {
      final avgConsumption = historicalL100km.reduce((a, b) => a + b) / historicalL100km.length;
      final threshold = avgConsumption * 1.20; // 20% spike threshold

      if (l100km > threshold) {
        isSpike = true;
        alertMsg = 'Warning: Consumption spiked to ${l100km.toStringAsFixed(1)} L/100km '
            '(${((l100km - avgConsumption) / avgConsumption * 100).toStringAsFixed(0)}% above average). '
            'Check tire pressure, air filter, or spark plugs.';
      }
    }

    return FuelHealthAnalysis(
      consumptionL100km: l100km,
      distanceDriven: distance,
      hasSpikeAlert: isSpike,
      alertMessage: alertMsg,
    );
  }
}