// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kpi_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KpiHistoryAdapter extends TypeAdapter<KpiHistory> {
  @override
  final int typeId = 0;

  @override
  KpiHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KpiHistory(
      timestamp: fields[0] as DateTime,
      temperature: fields[1] as double,
      vibration: fields[2] as double,
      current: fields[3] as double,
      healthIndex: fields[4] as double,
      rul: fields[5] as double,
      oee: fields[6] as double,
      availability: fields[7] as double,
      efficiency: fields[8] as double,
      mtbf: fields[9] as double,
      mttr: fields[10] as double,
      maintenanceCost: fields[11] as double,
      alertStatus: fields[12] as String,
      mode: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, KpiHistory obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.temperature)
      ..writeByte(2)
      ..write(obj.vibration)
      ..writeByte(3)
      ..write(obj.current)
      ..writeByte(4)
      ..write(obj.healthIndex)
      ..writeByte(5)
      ..write(obj.rul)
      ..writeByte(6)
      ..write(obj.oee)
      ..writeByte(7)
      ..write(obj.availability)
      ..writeByte(8)
      ..write(obj.efficiency)
      ..writeByte(9)
      ..write(obj.mtbf)
      ..writeByte(10)
      ..write(obj.mttr)
      ..writeByte(11)
      ..write(obj.maintenanceCost)
      ..writeByte(12)
      ..write(obj.alertStatus)
      ..writeByte(13)
      ..write(obj.mode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KpiHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
