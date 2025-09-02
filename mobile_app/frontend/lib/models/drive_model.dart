// Drive Model
class Drive {
  final String id;
  final String carName;
  final DateTime date;
  final double distance; // in km
  final double avgScore; // 0-100
  final String scoreTrend; // 'up', 'down', 'stable'
  final Duration duration;
  final double improvementPercent; // compared to previous drive
  final int harshBrakes;
  final int harshAccelerations;
  final double avgSpeed; // km/h
  final List<ScorePoint> scorePoints; // for score vs time graph
  final List<SpeedPoint> speedPoints; // for speed vs time graph
  final List<EventPoint> eventPoints; // for harsh events graph

  const Drive({
    required this.id,
    required this.carName,
    required this.date,
    required this.distance,
    required this.avgScore,
    required this.scoreTrend,
    required this.duration,
    required this.improvementPercent,
    required this.harshBrakes,
    required this.harshAccelerations,
    required this.avgSpeed,
    required this.scorePoints,
    required this.speedPoints,
    required this.eventPoints,
  });
}

class ScorePoint {
  final double time; // minutes from start
  final double score; // 0-100

  const ScorePoint({required this.time, required this.score});
}

class SpeedPoint {
  final double time; // minutes from start
  final double speed; // km/h

  const SpeedPoint({required this.time, required this.speed});
}

class EventPoint {
  final double time; // minutes from start
  final String type; // 'brake' or 'acceleration'
  final double intensity; // 0-10

  const EventPoint({required this.time, required this.type, required this.intensity});
}
