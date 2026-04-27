/// Grid layout configuration for weekly schedule
class GridSettings {
  final double courseCellHeight; // Default: 50.0
  final double emptyCellHeight; // Default: 44.0
  final double cellSpacing; // Default: 2.0
  final double periodColumnWidth; // Default: 40.0
  final double dayColumnWidth; // Default: 75.0

  static const double minCellHeight = 30.0;
  static const double maxCellHeight = 100.0;
  static const double minColumnWidth = 50.0;
  static const double maxColumnWidth = 150.0;
  static const double minSpacing = 0.0;
  static const double maxSpacing = 10.0;

  static const GridSettings defaultSettings = GridSettings(
    courseCellHeight: 50.0,
    emptyCellHeight: 44.0,
    cellSpacing: 2.0,
    periodColumnWidth: 40.0,
    dayColumnWidth: 75.0,
  );

  const GridSettings({
    required this.courseCellHeight,
    required this.emptyCellHeight,
    required this.cellSpacing,
    required this.periodColumnWidth,
    required this.dayColumnWidth,
  });

  GridSettings copyWith({
    double? courseCellHeight,
    double? emptyCellHeight,
    double? cellSpacing,
    double? periodColumnWidth,
    double? dayColumnWidth,
  }) =>
      GridSettings(
        courseCellHeight: courseCellHeight ?? this.courseCellHeight,
        emptyCellHeight: emptyCellHeight ?? this.emptyCellHeight,
        cellSpacing: cellSpacing ?? this.cellSpacing,
        periodColumnWidth: periodColumnWidth ?? this.periodColumnWidth,
        dayColumnWidth: dayColumnWidth ?? this.dayColumnWidth,
      );

  Map<String, dynamic> toJson() => {
        'courseCellHeight': courseCellHeight,
        'emptyCellHeight': emptyCellHeight,
        'cellSpacing': cellSpacing,
        'periodColumnWidth': periodColumnWidth,
        'dayColumnWidth': dayColumnWidth,
      };

  factory GridSettings.fromJson(Map<String, dynamic> json) => GridSettings(
        courseCellHeight: (json['courseCellHeight'] as num).toDouble(),
        emptyCellHeight: (json['emptyCellHeight'] as num).toDouble(),
        cellSpacing: (json['cellSpacing'] as num).toDouble(),
        periodColumnWidth: (json['periodColumnWidth'] as num).toDouble(),
        dayColumnWidth: (json['dayColumnWidth'] as num).toDouble(),
      );
}