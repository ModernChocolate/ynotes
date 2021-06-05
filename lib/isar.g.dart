// ignore_for_file: unused_import, implementation_imports

import 'dart:ffi';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:isar/src/isar_native.dart';
import 'package:isar/src/query_builder.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'core/logic/mails/models.dart';
import 'core/logic/shared/models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:ynotes/core/offline/isar/data/adapters.dart';

const _utf8Encoder = Utf8Encoder();

final _schema =
    '[{"name":"Mail","idProperty":"dbId","properties":[{"name":"dbId","type":3},{"name":"id","type":5},{"name":"mtype","type":5},{"name":"read","type":0},{"name":"idClasseur","type":5},{"name":"from","type":5},{"name":"to","type":5},{"name":"subject","type":5},{"name":"date","type":5},{"name":"content","type":5}],"indexes":[],"links":[{"name":"files","collection":"Document"}]},{"name":"Document","idProperty":"dbId","properties":[{"name":"dbId","type":3},{"name":"documentName","type":5},{"name":"id","type":5},{"name":"type","type":5},{"name":"length","type":3}],"indexes":[],"links":[]}]';

Future<Isar> openIsar(
    {String name = 'isar',
    String? directory,
    int maxSize = 1000000000,
    Uint8List? encryptionKey}) async {
  final path = await _preparePath(directory);
  return openIsarInternal(
      name: name,
      directory: path,
      maxSize: maxSize,
      encryptionKey: encryptionKey,
      schema: _schema,
      getCollections: (isar) {
        final collectionPtrPtr = malloc<Pointer>();
        final propertyOffsetsPtr = malloc<Uint32>(10);
        final propertyOffsets = propertyOffsetsPtr.asTypedList(10);
        final collections = <String, IsarCollection>{};
        nCall(IC.isar_get_collection(isar.ptr, collectionPtrPtr, 0));
        IC.isar_get_property_offsets(
            collectionPtrPtr.value, propertyOffsetsPtr);
        collections['Mail'] = IsarCollectionImpl<Mail>(
          isar: isar,
          adapter: _MailAdapter(),
          ptr: collectionPtrPtr.value,
          propertyOffsets: propertyOffsets.sublist(0, 10),
          propertyIds: {
            'dbId': 0,
            'id': 1,
            'mtype': 2,
            'read': 3,
            'idClasseur': 4,
            'from': 5,
            'to': 6,
            'subject': 7,
            'date': 8,
            'content': 9
          },
          indexIds: {},
          linkIds: {'files': 0},
          backlinkIds: {},
          getId: (obj) => obj.dbId,
          setId: (obj, id) => obj.dbId = id,
        );
        nCall(IC.isar_get_collection(isar.ptr, collectionPtrPtr, 1));
        IC.isar_get_property_offsets(
            collectionPtrPtr.value, propertyOffsetsPtr);
        collections['Document'] = IsarCollectionImpl<Document>(
          isar: isar,
          adapter: _DocumentAdapter(),
          ptr: collectionPtrPtr.value,
          propertyOffsets: propertyOffsets.sublist(0, 5),
          propertyIds: {
            'dbId': 0,
            'documentName': 1,
            'id': 2,
            'type': 3,
            'length': 4
          },
          indexIds: {},
          linkIds: {},
          backlinkIds: {},
          getId: (obj) => obj.dbId,
          setId: (obj, id) => obj.dbId = id,
        );
        malloc.free(propertyOffsetsPtr);
        malloc.free(collectionPtrPtr);

        return collections;
      });
}

Future<String> _preparePath(String? path) async {
  if (path == null || p.isRelative(path)) {
    WidgetsFlutterBinding.ensureInitialized();
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, path ?? 'isar');
  } else {
    return path;
  }
}

class _MailAdapter extends TypeAdapter<Mail> {
  static const _MapConverter = MapConverter();
  static const _ListMapConverter = ListMapConverter();

  @override
  int serialize(IsarCollectionImpl<Mail> collection, RawObject rawObj,
      Mail object, List<int> offsets,
      [int? existingBufferSize]) {
    var dynamicSize = 0;
    final value0 = object.dbId;
    final _dbId = value0;
    final value1 = object.id;
    Uint8List? _id;
    if (value1 != null) {
      _id = _utf8Encoder.convert(value1);
    }
    dynamicSize += _id?.length ?? 0;
    final value2 = object.mtype;
    Uint8List? _mtype;
    if (value2 != null) {
      _mtype = _utf8Encoder.convert(value2);
    }
    dynamicSize += _mtype?.length ?? 0;
    final value3 = object.read;
    final _read = value3;
    final value4 = object.idClasseur;
    Uint8List? _idClasseur;
    if (value4 != null) {
      _idClasseur = _utf8Encoder.convert(value4);
    }
    dynamicSize += _idClasseur?.length ?? 0;
    final value5 = _MailAdapter._MapConverter.toIsar(object.from);
    Uint8List? _from;
    if (value5 != null) {
      _from = _utf8Encoder.convert(value5);
    }
    dynamicSize += _from?.length ?? 0;
    final value6 = _MailAdapter._ListMapConverter.toIsar(object.to);
    Uint8List? _to;
    if (value6 != null) {
      _to = _utf8Encoder.convert(value6);
    }
    dynamicSize += _to?.length ?? 0;
    final value7 = object.subject;
    Uint8List? _subject;
    if (value7 != null) {
      _subject = _utf8Encoder.convert(value7);
    }
    dynamicSize += _subject?.length ?? 0;
    final value8 = object.date;
    Uint8List? _date;
    if (value8 != null) {
      _date = _utf8Encoder.convert(value8);
    }
    dynamicSize += _date?.length ?? 0;
    final value9 = object.content;
    Uint8List? _content;
    if (value9 != null) {
      _content = _utf8Encoder.convert(value9);
    }
    dynamicSize += _content?.length ?? 0;
    final size = dynamicSize + 75;

    late int bufferSize;
    if (existingBufferSize != null) {
      if (existingBufferSize < size) {
        malloc.free(rawObj.buffer);
        rawObj.buffer = malloc(size);
        bufferSize = size;
      } else {
        bufferSize = existingBufferSize;
      }
    } else {
      rawObj.buffer = malloc(size);
      bufferSize = size;
    }
    rawObj.buffer_length = size;
    final buffer = rawObj.buffer.asTypedList(size);
    final writer = BinaryWriter(buffer, 75);
    writer.writeLong(offsets[0], _dbId);
    writer.writeBytes(offsets[1], _id);
    writer.writeBytes(offsets[2], _mtype);
    writer.writeBool(offsets[3], _read);
    writer.writeBytes(offsets[4], _idClasseur);
    writer.writeBytes(offsets[5], _from);
    writer.writeBytes(offsets[6], _to);
    writer.writeBytes(offsets[7], _subject);
    writer.writeBytes(offsets[8], _date);
    writer.writeBytes(offsets[9], _content);
    if (!(object.files as IsarLinksImpl).attached) {
      (object.files as IsarLinksImpl).attach(
        collection,
        collection.isar.documents as IsarCollectionImpl<Document>,
        object,
        0,
        false,
      );
    }
    return bufferSize;
  }

  @override
  Mail deserialize(IsarCollectionImpl<Mail> collection, BinaryReader reader,
      List<int> offsets) {
    final object = Mail();
    object.dbId = reader.readLongOrNull(offsets[0]);
    object.id = reader.readStringOrNull(offsets[1]);
    object.mtype = reader.readStringOrNull(offsets[2]);
    object.read = reader.readBoolOrNull(offsets[3]);
    object.idClasseur = reader.readStringOrNull(offsets[4]);
    object.from = _MailAdapter._MapConverter.fromIsar(
        reader.readStringOrNull(offsets[5]));
    object.to = _MailAdapter._ListMapConverter.fromIsar(
        reader.readStringOrNull(offsets[6]));
    object.subject = reader.readStringOrNull(offsets[7]);
    object.date = reader.readStringOrNull(offsets[8]);
    object.content = reader.readStringOrNull(offsets[9]);
    object.files = IsarLinksImpl()
      ..attach(
        collection,
        collection.isar.documents as IsarCollectionImpl<Document>,
        object,
        0,
        false,
      );

    return object;
  }

  @override
  P deserializeProperty<P>(BinaryReader reader, int propertyIndex, int offset) {
    switch (propertyIndex) {
      case 0:
        return (reader.readLongOrNull(offset)) as P;
      case 1:
        return (reader.readStringOrNull(offset)) as P;
      case 2:
        return (reader.readStringOrNull(offset)) as P;
      case 3:
        return (reader.readBoolOrNull(offset)) as P;
      case 4:
        return (reader.readStringOrNull(offset)) as P;
      case 5:
        return (_MailAdapter._MapConverter.fromIsar(
            reader.readStringOrNull(offset))) as P;
      case 6:
        return (_MailAdapter._ListMapConverter.fromIsar(
            reader.readStringOrNull(offset))) as P;
      case 7:
        return (reader.readStringOrNull(offset)) as P;
      case 8:
        return (reader.readStringOrNull(offset)) as P;
      case 9:
        return (reader.readStringOrNull(offset)) as P;
      default:
        throw 'Illegal propertyIndex';
    }
  }
}

class _DocumentAdapter extends TypeAdapter<Document> {
  @override
  int serialize(IsarCollectionImpl<Document> collection, RawObject rawObj,
      Document object, List<int> offsets,
      [int? existingBufferSize]) {
    var dynamicSize = 0;
    final value0 = object.dbId;
    final _dbId = value0;
    final value1 = object.documentName;
    Uint8List? _documentName;
    if (value1 != null) {
      _documentName = _utf8Encoder.convert(value1);
    }
    dynamicSize += _documentName?.length ?? 0;
    final value2 = object.id;
    Uint8List? _id;
    if (value2 != null) {
      _id = _utf8Encoder.convert(value2);
    }
    dynamicSize += _id?.length ?? 0;
    final value3 = object.type;
    Uint8List? _type;
    if (value3 != null) {
      _type = _utf8Encoder.convert(value3);
    }
    dynamicSize += _type?.length ?? 0;
    final value4 = object.length;
    final _length = value4;
    final size = dynamicSize + 42;

    late int bufferSize;
    if (existingBufferSize != null) {
      if (existingBufferSize < size) {
        malloc.free(rawObj.buffer);
        rawObj.buffer = malloc(size);
        bufferSize = size;
      } else {
        bufferSize = existingBufferSize;
      }
    } else {
      rawObj.buffer = malloc(size);
      bufferSize = size;
    }
    rawObj.buffer_length = size;
    final buffer = rawObj.buffer.asTypedList(size);
    final writer = BinaryWriter(buffer, 42);
    writer.writeLong(offsets[0], _dbId);
    writer.writeBytes(offsets[1], _documentName);
    writer.writeBytes(offsets[2], _id);
    writer.writeBytes(offsets[3], _type);
    writer.writeLong(offsets[4], _length);
    return bufferSize;
  }

  @override
  Document deserialize(IsarCollectionImpl<Document> collection,
      BinaryReader reader, List<int> offsets) {
    final object = Document();
    object.dbId = reader.readLongOrNull(offsets[0]);
    object.documentName = reader.readStringOrNull(offsets[1]);
    object.id = reader.readStringOrNull(offsets[2]);
    object.type = reader.readStringOrNull(offsets[3]);
    object.length = reader.readLongOrNull(offsets[4]);
    return object;
  }

  @override
  P deserializeProperty<P>(BinaryReader reader, int propertyIndex, int offset) {
    switch (propertyIndex) {
      case 0:
        return (reader.readLongOrNull(offset)) as P;
      case 1:
        return (reader.readStringOrNull(offset)) as P;
      case 2:
        return (reader.readStringOrNull(offset)) as P;
      case 3:
        return (reader.readStringOrNull(offset)) as P;
      case 4:
        return (reader.readLongOrNull(offset)) as P;
      default:
        throw 'Illegal propertyIndex';
    }
  }
}

extension GetCollection on Isar {
  IsarCollection<Mail> get mails {
    return getCollection('Mail');
  }

  IsarCollection<Document> get documents {
    return getCollection('Document');
  }
}

extension MailQueryWhereSort on QueryBuilder<Mail, QWhere> {
  QueryBuilder<Mail, QAfterWhere> anyDbId() {
    return addWhereClause(WhereClause(indexName: 'dbId'));
  }
}

extension MailQueryWhere on QueryBuilder<Mail, QWhereClause> {}

extension DocumentQueryWhereSort on QueryBuilder<Document, QWhere> {
  QueryBuilder<Document, QAfterWhere> anyDbId() {
    return addWhereClause(WhereClause(indexName: 'dbId'));
  }
}

extension DocumentQueryWhere on QueryBuilder<Document, QWhereClause> {}

extension MailQueryFilter on QueryBuilder<Mail, QFilterCondition> {
  QueryBuilder<Mail, QAfterFilterCondition> dbIdIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'dbId',
      value: null,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> dbIdEqualTo(int? value) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'dbId',
      value: value,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> dbIdGreaterThan(int? value) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Gt,
      property: 'dbId',
      value: value,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> dbIdLessThan(int? value) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Lt,
      property: 'dbId',
      value: value,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> dbIdBetween(
      int? lower, int? upper) {
    return addFilterCondition(FilterCondition.between(
      property: 'dbId',
      lower: lower,
      upper: upper,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> idIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'id',
      value: null,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> idEqualTo(String? value,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'id',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> idStartsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.StartsWith,
      property: 'id',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> idEndsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.EndsWith,
      property: 'id',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> idContains(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'id',
      value: '*$convertedValue*',
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> idMatches(String pattern,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'id',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> mtypeIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'mtype',
      value: null,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> mtypeEqualTo(String? value,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'mtype',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> mtypeStartsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.StartsWith,
      property: 'mtype',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> mtypeEndsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.EndsWith,
      property: 'mtype',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> mtypeContains(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'mtype',
      value: '*$convertedValue*',
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> mtypeMatches(String pattern,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'mtype',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> readIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'read',
      value: null,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> readEqualTo(bool? value) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'read',
      value: value,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> idClasseurIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'idClasseur',
      value: null,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> idClasseurEqualTo(String? value,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'idClasseur',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> idClasseurStartsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.StartsWith,
      property: 'idClasseur',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> idClasseurEndsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.EndsWith,
      property: 'idClasseur',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> idClasseurContains(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'idClasseur',
      value: '*$convertedValue*',
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> idClasseurMatches(String pattern,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'idClasseur',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> fromIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'from',
      value: null,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> fromEqualTo(
      Map<dynamic, dynamic>? value,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'from',
      value: _MailAdapter._MapConverter.toIsar(value),
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> fromStartsWith(
      Map<dynamic, dynamic>? value,
      {bool caseSensitive = true}) {
    final convertedValue = _MailAdapter._MapConverter.toIsar(value);
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.StartsWith,
      property: 'from',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> fromEndsWith(
      Map<dynamic, dynamic>? value,
      {bool caseSensitive = true}) {
    final convertedValue = _MailAdapter._MapConverter.toIsar(value);
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.EndsWith,
      property: 'from',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> fromContains(
      Map<dynamic, dynamic>? value,
      {bool caseSensitive = true}) {
    final convertedValue = _MailAdapter._MapConverter.toIsar(value);
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'from',
      value: '*$convertedValue*',
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> fromMatches(String pattern,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'from',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> toIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'to',
      value: null,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> toEqualTo(
      List<Map<dynamic, dynamic>?>? value,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'to',
      value: _MailAdapter._ListMapConverter.toIsar(value),
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> toStartsWith(
      List<Map<dynamic, dynamic>?>? value,
      {bool caseSensitive = true}) {
    final convertedValue = _MailAdapter._ListMapConverter.toIsar(value);
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.StartsWith,
      property: 'to',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> toEndsWith(
      List<Map<dynamic, dynamic>?>? value,
      {bool caseSensitive = true}) {
    final convertedValue = _MailAdapter._ListMapConverter.toIsar(value);
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.EndsWith,
      property: 'to',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> toContains(
      List<Map<dynamic, dynamic>?>? value,
      {bool caseSensitive = true}) {
    final convertedValue = _MailAdapter._ListMapConverter.toIsar(value);
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'to',
      value: '*$convertedValue*',
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> toMatches(String pattern,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'to',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> subjectIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'subject',
      value: null,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> subjectEqualTo(String? value,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'subject',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> subjectStartsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.StartsWith,
      property: 'subject',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> subjectEndsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.EndsWith,
      property: 'subject',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> subjectContains(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'subject',
      value: '*$convertedValue*',
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> subjectMatches(String pattern,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'subject',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> dateIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'date',
      value: null,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> dateEqualTo(String? value,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'date',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> dateStartsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.StartsWith,
      property: 'date',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> dateEndsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.EndsWith,
      property: 'date',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> dateContains(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'date',
      value: '*$convertedValue*',
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> dateMatches(String pattern,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'date',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> contentIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'content',
      value: null,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> contentEqualTo(String? value,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'content',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> contentStartsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.StartsWith,
      property: 'content',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> contentEndsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.EndsWith,
      property: 'content',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> contentContains(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'content',
      value: '*$convertedValue*',
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Mail, QAfterFilterCondition> contentMatches(String pattern,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'content',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }
}

extension DocumentQueryFilter on QueryBuilder<Document, QFilterCondition> {
  QueryBuilder<Document, QAfterFilterCondition> dbIdIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'dbId',
      value: null,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> dbIdEqualTo(int? value) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'dbId',
      value: value,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> dbIdGreaterThan(int? value) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Gt,
      property: 'dbId',
      value: value,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> dbIdLessThan(int? value) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Lt,
      property: 'dbId',
      value: value,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> dbIdBetween(
      int? lower, int? upper) {
    return addFilterCondition(FilterCondition.between(
      property: 'dbId',
      lower: lower,
      upper: upper,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> documentNameIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'documentName',
      value: null,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> documentNameEqualTo(
      String? value,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'documentName',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> documentNameStartsWith(
      String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.StartsWith,
      property: 'documentName',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> documentNameEndsWith(
      String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.EndsWith,
      property: 'documentName',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> documentNameContains(
      String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'documentName',
      value: '*$convertedValue*',
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> documentNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'documentName',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> idIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'id',
      value: null,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> idEqualTo(String? value,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'id',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> idStartsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.StartsWith,
      property: 'id',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> idEndsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.EndsWith,
      property: 'id',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> idContains(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'id',
      value: '*$convertedValue*',
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> idMatches(String pattern,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'id',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> typeIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'type',
      value: null,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> typeEqualTo(String? value,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'type',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> typeStartsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.StartsWith,
      property: 'type',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> typeEndsWith(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.EndsWith,
      property: 'type',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> typeContains(String? value,
      {bool caseSensitive = true}) {
    final convertedValue = value;
    assert(convertedValue != null, 'Null values are not allowed');
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'type',
      value: '*$convertedValue*',
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> typeMatches(String pattern,
      {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: 'type',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> lengthIsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'length',
      value: null,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> lengthEqualTo(int? value) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: 'length',
      value: value,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> lengthGreaterThan(int? value) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Gt,
      property: 'length',
      value: value,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> lengthLessThan(int? value) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Lt,
      property: 'length',
      value: value,
    ));
  }

  QueryBuilder<Document, QAfterFilterCondition> lengthBetween(
      int? lower, int? upper) {
    return addFilterCondition(FilterCondition.between(
      property: 'length',
      lower: lower,
      upper: upper,
    ));
  }
}

extension MailQueryLinks on QueryBuilder<Mail, QFilterCondition> {
  QueryBuilder<Mail, QAfterFilterCondition> files(FilterQuery<Document> q) {
    return linkInternal(
      isar.documents,
      q,
      'files',
    );
  }
}

extension DocumentQueryLinks on QueryBuilder<Document, QFilterCondition> {}

extension MailQueryWhereSortBy on QueryBuilder<Mail, QSortBy> {
  QueryBuilder<Mail, QAfterSortBy> sortByDbId() {
    return addSortByInternal('dbId', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByDbIdDesc() {
    return addSortByInternal('dbId', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortById() {
    return addSortByInternal('id', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByIdDesc() {
    return addSortByInternal('id', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByMtype() {
    return addSortByInternal('mtype', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByMtypeDesc() {
    return addSortByInternal('mtype', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByRead() {
    return addSortByInternal('read', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByReadDesc() {
    return addSortByInternal('read', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByIdClasseur() {
    return addSortByInternal('idClasseur', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByIdClasseurDesc() {
    return addSortByInternal('idClasseur', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByFrom() {
    return addSortByInternal('from', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByFromDesc() {
    return addSortByInternal('from', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByTo() {
    return addSortByInternal('to', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByToDesc() {
    return addSortByInternal('to', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortBySubject() {
    return addSortByInternal('subject', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortBySubjectDesc() {
    return addSortByInternal('subject', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByDate() {
    return addSortByInternal('date', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByDateDesc() {
    return addSortByInternal('date', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByContent() {
    return addSortByInternal('content', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> sortByContentDesc() {
    return addSortByInternal('content', Sort.Desc);
  }
}

extension MailQueryWhereSortThenBy on QueryBuilder<Mail, QSortThenBy> {
  QueryBuilder<Mail, QAfterSortBy> thenByDbId() {
    return addSortByInternal('dbId', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByDbIdDesc() {
    return addSortByInternal('dbId', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenById() {
    return addSortByInternal('id', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByIdDesc() {
    return addSortByInternal('id', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByMtype() {
    return addSortByInternal('mtype', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByMtypeDesc() {
    return addSortByInternal('mtype', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByRead() {
    return addSortByInternal('read', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByReadDesc() {
    return addSortByInternal('read', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByIdClasseur() {
    return addSortByInternal('idClasseur', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByIdClasseurDesc() {
    return addSortByInternal('idClasseur', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByFrom() {
    return addSortByInternal('from', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByFromDesc() {
    return addSortByInternal('from', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByTo() {
    return addSortByInternal('to', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByToDesc() {
    return addSortByInternal('to', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenBySubject() {
    return addSortByInternal('subject', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenBySubjectDesc() {
    return addSortByInternal('subject', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByDate() {
    return addSortByInternal('date', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByDateDesc() {
    return addSortByInternal('date', Sort.Desc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByContent() {
    return addSortByInternal('content', Sort.Asc);
  }

  QueryBuilder<Mail, QAfterSortBy> thenByContentDesc() {
    return addSortByInternal('content', Sort.Desc);
  }
}

extension DocumentQueryWhereSortBy on QueryBuilder<Document, QSortBy> {
  QueryBuilder<Document, QAfterSortBy> sortByDbId() {
    return addSortByInternal('dbId', Sort.Asc);
  }

  QueryBuilder<Document, QAfterSortBy> sortByDbIdDesc() {
    return addSortByInternal('dbId', Sort.Desc);
  }

  QueryBuilder<Document, QAfterSortBy> sortByDocumentName() {
    return addSortByInternal('documentName', Sort.Asc);
  }

  QueryBuilder<Document, QAfterSortBy> sortByDocumentNameDesc() {
    return addSortByInternal('documentName', Sort.Desc);
  }

  QueryBuilder<Document, QAfterSortBy> sortById() {
    return addSortByInternal('id', Sort.Asc);
  }

  QueryBuilder<Document, QAfterSortBy> sortByIdDesc() {
    return addSortByInternal('id', Sort.Desc);
  }

  QueryBuilder<Document, QAfterSortBy> sortByType() {
    return addSortByInternal('type', Sort.Asc);
  }

  QueryBuilder<Document, QAfterSortBy> sortByTypeDesc() {
    return addSortByInternal('type', Sort.Desc);
  }

  QueryBuilder<Document, QAfterSortBy> sortByLength() {
    return addSortByInternal('length', Sort.Asc);
  }

  QueryBuilder<Document, QAfterSortBy> sortByLengthDesc() {
    return addSortByInternal('length', Sort.Desc);
  }
}

extension DocumentQueryWhereSortThenBy on QueryBuilder<Document, QSortThenBy> {
  QueryBuilder<Document, QAfterSortBy> thenByDbId() {
    return addSortByInternal('dbId', Sort.Asc);
  }

  QueryBuilder<Document, QAfterSortBy> thenByDbIdDesc() {
    return addSortByInternal('dbId', Sort.Desc);
  }

  QueryBuilder<Document, QAfterSortBy> thenByDocumentName() {
    return addSortByInternal('documentName', Sort.Asc);
  }

  QueryBuilder<Document, QAfterSortBy> thenByDocumentNameDesc() {
    return addSortByInternal('documentName', Sort.Desc);
  }

  QueryBuilder<Document, QAfterSortBy> thenById() {
    return addSortByInternal('id', Sort.Asc);
  }

  QueryBuilder<Document, QAfterSortBy> thenByIdDesc() {
    return addSortByInternal('id', Sort.Desc);
  }

  QueryBuilder<Document, QAfterSortBy> thenByType() {
    return addSortByInternal('type', Sort.Asc);
  }

  QueryBuilder<Document, QAfterSortBy> thenByTypeDesc() {
    return addSortByInternal('type', Sort.Desc);
  }

  QueryBuilder<Document, QAfterSortBy> thenByLength() {
    return addSortByInternal('length', Sort.Asc);
  }

  QueryBuilder<Document, QAfterSortBy> thenByLengthDesc() {
    return addSortByInternal('length', Sort.Desc);
  }
}

extension MailQueryWhereDistinct on QueryBuilder<Mail, QDistinct> {
  QueryBuilder<Mail, QDistinct> distinctByDbId() {
    return addDistinctByInternal('dbId');
  }

  QueryBuilder<Mail, QDistinct> distinctById({bool caseSensitive = true}) {
    return addDistinctByInternal('id', caseSensitive: caseSensitive);
  }

  QueryBuilder<Mail, QDistinct> distinctByMtype({bool caseSensitive = true}) {
    return addDistinctByInternal('mtype', caseSensitive: caseSensitive);
  }

  QueryBuilder<Mail, QDistinct> distinctByRead() {
    return addDistinctByInternal('read');
  }

  QueryBuilder<Mail, QDistinct> distinctByIdClasseur(
      {bool caseSensitive = true}) {
    return addDistinctByInternal('idClasseur', caseSensitive: caseSensitive);
  }

  QueryBuilder<Mail, QDistinct> distinctByFrom({bool caseSensitive = true}) {
    return addDistinctByInternal('from', caseSensitive: caseSensitive);
  }

  QueryBuilder<Mail, QDistinct> distinctByTo({bool caseSensitive = true}) {
    return addDistinctByInternal('to', caseSensitive: caseSensitive);
  }

  QueryBuilder<Mail, QDistinct> distinctBySubject({bool caseSensitive = true}) {
    return addDistinctByInternal('subject', caseSensitive: caseSensitive);
  }

  QueryBuilder<Mail, QDistinct> distinctByDate({bool caseSensitive = true}) {
    return addDistinctByInternal('date', caseSensitive: caseSensitive);
  }

  QueryBuilder<Mail, QDistinct> distinctByContent({bool caseSensitive = true}) {
    return addDistinctByInternal('content', caseSensitive: caseSensitive);
  }
}

extension DocumentQueryWhereDistinct on QueryBuilder<Document, QDistinct> {
  QueryBuilder<Document, QDistinct> distinctByDbId() {
    return addDistinctByInternal('dbId');
  }

  QueryBuilder<Document, QDistinct> distinctByDocumentName(
      {bool caseSensitive = true}) {
    return addDistinctByInternal('documentName', caseSensitive: caseSensitive);
  }

  QueryBuilder<Document, QDistinct> distinctById({bool caseSensitive = true}) {
    return addDistinctByInternal('id', caseSensitive: caseSensitive);
  }

  QueryBuilder<Document, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return addDistinctByInternal('type', caseSensitive: caseSensitive);
  }

  QueryBuilder<Document, QDistinct> distinctByLength() {
    return addDistinctByInternal('length');
  }
}

extension MailQueryProperty on QueryBuilder<Mail, QQueryProperty> {
  QueryBuilder<int?, QQueryOperations> dbIdProperty() {
    return addPropertyName('dbId');
  }

  QueryBuilder<String?, QQueryOperations> idProperty() {
    return addPropertyName('id');
  }

  QueryBuilder<String?, QQueryOperations> mtypeProperty() {
    return addPropertyName('mtype');
  }

  QueryBuilder<bool?, QQueryOperations> readProperty() {
    return addPropertyName('read');
  }

  QueryBuilder<String?, QQueryOperations> idClasseurProperty() {
    return addPropertyName('idClasseur');
  }

  QueryBuilder<Map<dynamic, dynamic>?, QQueryOperations> fromProperty() {
    return addPropertyName('from');
  }

  QueryBuilder<List<Map<dynamic, dynamic>?>?, QQueryOperations> toProperty() {
    return addPropertyName('to');
  }

  QueryBuilder<String?, QQueryOperations> subjectProperty() {
    return addPropertyName('subject');
  }

  QueryBuilder<String?, QQueryOperations> dateProperty() {
    return addPropertyName('date');
  }

  QueryBuilder<String?, QQueryOperations> contentProperty() {
    return addPropertyName('content');
  }
}

extension DocumentQueryProperty on QueryBuilder<Document, QQueryProperty> {
  QueryBuilder<int?, QQueryOperations> dbIdProperty() {
    return addPropertyName('dbId');
  }

  QueryBuilder<String?, QQueryOperations> documentNameProperty() {
    return addPropertyName('documentName');
  }

  QueryBuilder<String?, QQueryOperations> idProperty() {
    return addPropertyName('id');
  }

  QueryBuilder<String?, QQueryOperations> typeProperty() {
    return addPropertyName('type');
  }

  QueryBuilder<int?, QQueryOperations> lengthProperty() {
    return addPropertyName('length');
  }
}