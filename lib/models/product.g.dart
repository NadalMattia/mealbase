// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as String,
      nome: fields[1] as String,
      quantita: fields[2] as double,
      unita: fields[3] as String,
      categoria: fields[4] as String,
      posizione: fields[5] as String,
      dataAcquisto: fields[6] as DateTime,
      dataScadenza: fields[7] as DateTime?,
      imagePath: fields[8] as String?,
      marca: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.quantita)
      ..writeByte(3)
      ..write(obj.unita)
      ..writeByte(4)
      ..write(obj.categoria)
      ..writeByte(5)
      ..write(obj.posizione)
      ..writeByte(6)
      ..write(obj.dataAcquisto)
      ..writeByte(7)
      ..write(obj.dataScadenza)
      ..writeByte(8)
      ..write(obj.imagePath)
      ..writeByte(9)
      ..write(obj.marca);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
