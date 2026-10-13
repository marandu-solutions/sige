import 'package:flutter/material.dart';

class TimeRange {
  TimeOfDay start;
  TimeOfDay end;

  TimeRange({required this.start, required this.end});

  @override
  String toString() {
    final String startHour = start.hour.toString().padLeft(2, '0');
    final String startMinute = start.minute.toString().padLeft(2, '0');
    final String endHour = end.hour.toString().padLeft(2, '0');
    final String endMinute = end.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  factory TimeRange.fromMap(Map<String, dynamic> map) {
    return TimeRange(
      start: TimeOfDay(
          hour: map['startHour'] ?? 0, minute: map['startMinute'] ?? 0),
      end: TimeOfDay(hour: map['endHour'] ?? 0, minute: map['endMinute'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startHour': start.hour,
      'startMinute': start.minute,
      'endHour': end.hour,
      'endMinute': end.minute,
    };
  }
}

class HorarioFuncionamento {
  Map<String, List<TimeRange>> horarios;

  HorarioFuncionamento({required this.horarios});

  factory HorarioFuncionamento.fromMap(Map<String, dynamic> map) {
    final Map<String, List<TimeRange>> parsedHorarios = {};
    map.forEach((day, ranges) {
      if (ranges is List) {
        parsedHorarios[day] = ranges
            .map((rangeMap) => TimeRange.fromMap(Map<String, dynamic>.from(rangeMap)))
            .toList();
      }
    });
    return HorarioFuncionamento(horarios: parsedHorarios);
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> jsonHorarios = {};
    horarios.forEach((day, ranges) {
      jsonHorarios[day] = ranges.map((range) => range.toMap()).toList();
    });
    return jsonHorarios;
  }
}
