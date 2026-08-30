// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HouseAdapter extends TypeAdapter<House> {
  @override
  final int typeId = 3;

  @override
  House read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return House(
      id: fields[0] as String,
      nome: fields[1] as String,
      ordine: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, House obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.ordine);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HouseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
