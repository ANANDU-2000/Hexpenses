// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_database.dart';

// ignore_for_file: type=lint
class $CachedExpensesTable extends CachedExpenses
    with TableInfo<$CachedExpensesTable, CachedExpense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevisionAtMeta = const VerificationMeta(
    'clientRevisionAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientRevisionAt =
      GeneratedColumn<DateTime>(
        'client_revision_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastKnownServerAtMeta = const VerificationMeta(
    'lastKnownServerAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastKnownServerAt =
      GeneratedColumn<DateTime>(
        'last_known_server_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _expenseSortDateMeta = const VerificationMeta(
    'expenseSortDate',
  );
  @override
  late final GeneratedColumn<DateTime> expenseSortDate =
      GeneratedColumn<DateTime>(
        'expense_sort_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    payloadJson,
    syncStatus,
    clientRevisionAt,
    lastKnownServerAt,
    expenseSortDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedExpense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('client_revision_at')) {
      context.handle(
        _clientRevisionAtMeta,
        clientRevisionAt.isAcceptableOrUnknown(
          data['client_revision_at']!,
          _clientRevisionAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientRevisionAtMeta);
    }
    if (data.containsKey('last_known_server_at')) {
      context.handle(
        _lastKnownServerAtMeta,
        lastKnownServerAt.isAcceptableOrUnknown(
          data['last_known_server_at']!,
          _lastKnownServerAtMeta,
        ),
      );
    }
    if (data.containsKey('expense_sort_date')) {
      context.handle(
        _expenseSortDateMeta,
        expenseSortDate.isAcceptableOrUnknown(
          data['expense_sort_date']!,
          _expenseSortDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expenseSortDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedExpense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedExpense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      clientRevisionAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_revision_at'],
      )!,
      lastKnownServerAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_known_server_at'],
      ),
      expenseSortDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expense_sort_date'],
      )!,
    );
  }

  @override
  $CachedExpensesTable createAlias(String alias) {
    return $CachedExpensesTable(attachedDatabase, alias);
  }
}

class CachedExpense extends DataClass implements Insertable<CachedExpense> {
  final String id;
  final String payloadJson;
  final int syncStatus;
  final DateTime clientRevisionAt;
  final DateTime? lastKnownServerAt;
  final DateTime expenseSortDate;
  const CachedExpense({
    required this.id,
    required this.payloadJson,
    required this.syncStatus,
    required this.clientRevisionAt,
    this.lastKnownServerAt,
    required this.expenseSortDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload_json'] = Variable<String>(payloadJson);
    map['sync_status'] = Variable<int>(syncStatus);
    map['client_revision_at'] = Variable<DateTime>(clientRevisionAt);
    if (!nullToAbsent || lastKnownServerAt != null) {
      map['last_known_server_at'] = Variable<DateTime>(lastKnownServerAt);
    }
    map['expense_sort_date'] = Variable<DateTime>(expenseSortDate);
    return map;
  }

  CachedExpensesCompanion toCompanion(bool nullToAbsent) {
    return CachedExpensesCompanion(
      id: Value(id),
      payloadJson: Value(payloadJson),
      syncStatus: Value(syncStatus),
      clientRevisionAt: Value(clientRevisionAt),
      lastKnownServerAt: lastKnownServerAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownServerAt),
      expenseSortDate: Value(expenseSortDate),
    );
  }

  factory CachedExpense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedExpense(
      id: serializer.fromJson<String>(json['id']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      clientRevisionAt: serializer.fromJson<DateTime>(json['clientRevisionAt']),
      lastKnownServerAt: serializer.fromJson<DateTime?>(
        json['lastKnownServerAt'],
      ),
      expenseSortDate: serializer.fromJson<DateTime>(json['expenseSortDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'clientRevisionAt': serializer.toJson<DateTime>(clientRevisionAt),
      'lastKnownServerAt': serializer.toJson<DateTime?>(lastKnownServerAt),
      'expenseSortDate': serializer.toJson<DateTime>(expenseSortDate),
    };
  }

  CachedExpense copyWith({
    String? id,
    String? payloadJson,
    int? syncStatus,
    DateTime? clientRevisionAt,
    Value<DateTime?> lastKnownServerAt = const Value.absent(),
    DateTime? expenseSortDate,
  }) => CachedExpense(
    id: id ?? this.id,
    payloadJson: payloadJson ?? this.payloadJson,
    syncStatus: syncStatus ?? this.syncStatus,
    clientRevisionAt: clientRevisionAt ?? this.clientRevisionAt,
    lastKnownServerAt: lastKnownServerAt.present
        ? lastKnownServerAt.value
        : this.lastKnownServerAt,
    expenseSortDate: expenseSortDate ?? this.expenseSortDate,
  );
  CachedExpense copyWithCompanion(CachedExpensesCompanion data) {
    return CachedExpense(
      id: data.id.present ? data.id.value : this.id,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      clientRevisionAt: data.clientRevisionAt.present
          ? data.clientRevisionAt.value
          : this.clientRevisionAt,
      lastKnownServerAt: data.lastKnownServerAt.present
          ? data.lastKnownServerAt.value
          : this.lastKnownServerAt,
      expenseSortDate: data.expenseSortDate.present
          ? data.expenseSortDate.value
          : this.expenseSortDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedExpense(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('clientRevisionAt: $clientRevisionAt, ')
          ..write('lastKnownServerAt: $lastKnownServerAt, ')
          ..write('expenseSortDate: $expenseSortDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    payloadJson,
    syncStatus,
    clientRevisionAt,
    lastKnownServerAt,
    expenseSortDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedExpense &&
          other.id == this.id &&
          other.payloadJson == this.payloadJson &&
          other.syncStatus == this.syncStatus &&
          other.clientRevisionAt == this.clientRevisionAt &&
          other.lastKnownServerAt == this.lastKnownServerAt &&
          other.expenseSortDate == this.expenseSortDate);
}

class CachedExpensesCompanion extends UpdateCompanion<CachedExpense> {
  final Value<String> id;
  final Value<String> payloadJson;
  final Value<int> syncStatus;
  final Value<DateTime> clientRevisionAt;
  final Value<DateTime?> lastKnownServerAt;
  final Value<DateTime> expenseSortDate;
  final Value<int> rowid;
  const CachedExpensesCompanion({
    this.id = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.clientRevisionAt = const Value.absent(),
    this.lastKnownServerAt = const Value.absent(),
    this.expenseSortDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedExpensesCompanion.insert({
    required String id,
    required String payloadJson,
    required int syncStatus,
    required DateTime clientRevisionAt,
    this.lastKnownServerAt = const Value.absent(),
    required DateTime expenseSortDate,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payloadJson = Value(payloadJson),
       syncStatus = Value(syncStatus),
       clientRevisionAt = Value(clientRevisionAt),
       expenseSortDate = Value(expenseSortDate);
  static Insertable<CachedExpense> custom({
    Expression<String>? id,
    Expression<String>? payloadJson,
    Expression<int>? syncStatus,
    Expression<DateTime>? clientRevisionAt,
    Expression<DateTime>? lastKnownServerAt,
    Expression<DateTime>? expenseSortDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (clientRevisionAt != null) 'client_revision_at': clientRevisionAt,
      if (lastKnownServerAt != null) 'last_known_server_at': lastKnownServerAt,
      if (expenseSortDate != null) 'expense_sort_date': expenseSortDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? payloadJson,
    Value<int>? syncStatus,
    Value<DateTime>? clientRevisionAt,
    Value<DateTime?>? lastKnownServerAt,
    Value<DateTime>? expenseSortDate,
    Value<int>? rowid,
  }) {
    return CachedExpensesCompanion(
      id: id ?? this.id,
      payloadJson: payloadJson ?? this.payloadJson,
      syncStatus: syncStatus ?? this.syncStatus,
      clientRevisionAt: clientRevisionAt ?? this.clientRevisionAt,
      lastKnownServerAt: lastKnownServerAt ?? this.lastKnownServerAt,
      expenseSortDate: expenseSortDate ?? this.expenseSortDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (clientRevisionAt.present) {
      map['client_revision_at'] = Variable<DateTime>(clientRevisionAt.value);
    }
    if (lastKnownServerAt.present) {
      map['last_known_server_at'] = Variable<DateTime>(lastKnownServerAt.value);
    }
    if (expenseSortDate.present) {
      map['expense_sort_date'] = Variable<DateTime>(expenseSortDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedExpensesCompanion(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('clientRevisionAt: $clientRevisionAt, ')
          ..write('lastKnownServerAt: $lastKnownServerAt, ')
          ..write('expenseSortDate: $expenseSortDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedAccountsTable extends CachedAccounts
    with TableInfo<$CachedAccountsTable, CachedAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevisionAtMeta = const VerificationMeta(
    'clientRevisionAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientRevisionAt =
      GeneratedColumn<DateTime>(
        'client_revision_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastKnownServerAtMeta = const VerificationMeta(
    'lastKnownServerAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastKnownServerAt =
      GeneratedColumn<DateTime>(
        'last_known_server_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    payloadJson,
    syncStatus,
    clientRevisionAt,
    lastKnownServerAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('client_revision_at')) {
      context.handle(
        _clientRevisionAtMeta,
        clientRevisionAt.isAcceptableOrUnknown(
          data['client_revision_at']!,
          _clientRevisionAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientRevisionAtMeta);
    }
    if (data.containsKey('last_known_server_at')) {
      context.handle(
        _lastKnownServerAtMeta,
        lastKnownServerAt.isAcceptableOrUnknown(
          data['last_known_server_at']!,
          _lastKnownServerAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      clientRevisionAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_revision_at'],
      )!,
      lastKnownServerAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_known_server_at'],
      ),
    );
  }

  @override
  $CachedAccountsTable createAlias(String alias) {
    return $CachedAccountsTable(attachedDatabase, alias);
  }
}

class CachedAccount extends DataClass implements Insertable<CachedAccount> {
  final String id;
  final String payloadJson;
  final int syncStatus;
  final DateTime clientRevisionAt;
  final DateTime? lastKnownServerAt;
  const CachedAccount({
    required this.id,
    required this.payloadJson,
    required this.syncStatus,
    required this.clientRevisionAt,
    this.lastKnownServerAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload_json'] = Variable<String>(payloadJson);
    map['sync_status'] = Variable<int>(syncStatus);
    map['client_revision_at'] = Variable<DateTime>(clientRevisionAt);
    if (!nullToAbsent || lastKnownServerAt != null) {
      map['last_known_server_at'] = Variable<DateTime>(lastKnownServerAt);
    }
    return map;
  }

  CachedAccountsCompanion toCompanion(bool nullToAbsent) {
    return CachedAccountsCompanion(
      id: Value(id),
      payloadJson: Value(payloadJson),
      syncStatus: Value(syncStatus),
      clientRevisionAt: Value(clientRevisionAt),
      lastKnownServerAt: lastKnownServerAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownServerAt),
    );
  }

  factory CachedAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAccount(
      id: serializer.fromJson<String>(json['id']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      clientRevisionAt: serializer.fromJson<DateTime>(json['clientRevisionAt']),
      lastKnownServerAt: serializer.fromJson<DateTime?>(
        json['lastKnownServerAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'clientRevisionAt': serializer.toJson<DateTime>(clientRevisionAt),
      'lastKnownServerAt': serializer.toJson<DateTime?>(lastKnownServerAt),
    };
  }

  CachedAccount copyWith({
    String? id,
    String? payloadJson,
    int? syncStatus,
    DateTime? clientRevisionAt,
    Value<DateTime?> lastKnownServerAt = const Value.absent(),
  }) => CachedAccount(
    id: id ?? this.id,
    payloadJson: payloadJson ?? this.payloadJson,
    syncStatus: syncStatus ?? this.syncStatus,
    clientRevisionAt: clientRevisionAt ?? this.clientRevisionAt,
    lastKnownServerAt: lastKnownServerAt.present
        ? lastKnownServerAt.value
        : this.lastKnownServerAt,
  );
  CachedAccount copyWithCompanion(CachedAccountsCompanion data) {
    return CachedAccount(
      id: data.id.present ? data.id.value : this.id,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      clientRevisionAt: data.clientRevisionAt.present
          ? data.clientRevisionAt.value
          : this.clientRevisionAt,
      lastKnownServerAt: data.lastKnownServerAt.present
          ? data.lastKnownServerAt.value
          : this.lastKnownServerAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAccount(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('clientRevisionAt: $clientRevisionAt, ')
          ..write('lastKnownServerAt: $lastKnownServerAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    payloadJson,
    syncStatus,
    clientRevisionAt,
    lastKnownServerAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAccount &&
          other.id == this.id &&
          other.payloadJson == this.payloadJson &&
          other.syncStatus == this.syncStatus &&
          other.clientRevisionAt == this.clientRevisionAt &&
          other.lastKnownServerAt == this.lastKnownServerAt);
}

class CachedAccountsCompanion extends UpdateCompanion<CachedAccount> {
  final Value<String> id;
  final Value<String> payloadJson;
  final Value<int> syncStatus;
  final Value<DateTime> clientRevisionAt;
  final Value<DateTime?> lastKnownServerAt;
  final Value<int> rowid;
  const CachedAccountsCompanion({
    this.id = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.clientRevisionAt = const Value.absent(),
    this.lastKnownServerAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAccountsCompanion.insert({
    required String id,
    required String payloadJson,
    required int syncStatus,
    required DateTime clientRevisionAt,
    this.lastKnownServerAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payloadJson = Value(payloadJson),
       syncStatus = Value(syncStatus),
       clientRevisionAt = Value(clientRevisionAt);
  static Insertable<CachedAccount> custom({
    Expression<String>? id,
    Expression<String>? payloadJson,
    Expression<int>? syncStatus,
    Expression<DateTime>? clientRevisionAt,
    Expression<DateTime>? lastKnownServerAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (clientRevisionAt != null) 'client_revision_at': clientRevisionAt,
      if (lastKnownServerAt != null) 'last_known_server_at': lastKnownServerAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? payloadJson,
    Value<int>? syncStatus,
    Value<DateTime>? clientRevisionAt,
    Value<DateTime?>? lastKnownServerAt,
    Value<int>? rowid,
  }) {
    return CachedAccountsCompanion(
      id: id ?? this.id,
      payloadJson: payloadJson ?? this.payloadJson,
      syncStatus: syncStatus ?? this.syncStatus,
      clientRevisionAt: clientRevisionAt ?? this.clientRevisionAt,
      lastKnownServerAt: lastKnownServerAt ?? this.lastKnownServerAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (clientRevisionAt.present) {
      map['client_revision_at'] = Variable<DateTime>(clientRevisionAt.value);
    }
    if (lastKnownServerAt.present) {
      map['last_known_server_at'] = Variable<DateTime>(lastKnownServerAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAccountsCompanion(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('clientRevisionAt: $clientRevisionAt, ')
          ..write('lastKnownServerAt: $lastKnownServerAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedBudgetsTable extends CachedBudgets
    with TableInfo<$CachedBudgetsTable, CachedBudget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedBudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthKeyMeta = const VerificationMeta(
    'monthKey',
  );
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
    'month_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevisionAtMeta = const VerificationMeta(
    'clientRevisionAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientRevisionAt =
      GeneratedColumn<DateTime>(
        'client_revision_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastKnownServerAtMeta = const VerificationMeta(
    'lastKnownServerAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastKnownServerAt =
      GeneratedColumn<DateTime>(
        'last_known_server_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    monthKey,
    payloadJson,
    syncStatus,
    clientRevisionAt,
    lastKnownServerAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedBudget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(
        _monthKeyMeta,
        monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('client_revision_at')) {
      context.handle(
        _clientRevisionAtMeta,
        clientRevisionAt.isAcceptableOrUnknown(
          data['client_revision_at']!,
          _clientRevisionAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientRevisionAtMeta);
    }
    if (data.containsKey('last_known_server_at')) {
      context.handle(
        _lastKnownServerAtMeta,
        lastKnownServerAt.isAcceptableOrUnknown(
          data['last_known_server_at']!,
          _lastKnownServerAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedBudget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedBudget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      monthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_key'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      clientRevisionAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_revision_at'],
      )!,
      lastKnownServerAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_known_server_at'],
      ),
    );
  }

  @override
  $CachedBudgetsTable createAlias(String alias) {
    return $CachedBudgetsTable(attachedDatabase, alias);
  }
}

class CachedBudget extends DataClass implements Insertable<CachedBudget> {
  final String id;
  final String monthKey;
  final String payloadJson;
  final int syncStatus;
  final DateTime clientRevisionAt;
  final DateTime? lastKnownServerAt;
  const CachedBudget({
    required this.id,
    required this.monthKey,
    required this.payloadJson,
    required this.syncStatus,
    required this.clientRevisionAt,
    this.lastKnownServerAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['month_key'] = Variable<String>(monthKey);
    map['payload_json'] = Variable<String>(payloadJson);
    map['sync_status'] = Variable<int>(syncStatus);
    map['client_revision_at'] = Variable<DateTime>(clientRevisionAt);
    if (!nullToAbsent || lastKnownServerAt != null) {
      map['last_known_server_at'] = Variable<DateTime>(lastKnownServerAt);
    }
    return map;
  }

  CachedBudgetsCompanion toCompanion(bool nullToAbsent) {
    return CachedBudgetsCompanion(
      id: Value(id),
      monthKey: Value(monthKey),
      payloadJson: Value(payloadJson),
      syncStatus: Value(syncStatus),
      clientRevisionAt: Value(clientRevisionAt),
      lastKnownServerAt: lastKnownServerAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownServerAt),
    );
  }

  factory CachedBudget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedBudget(
      id: serializer.fromJson<String>(json['id']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      clientRevisionAt: serializer.fromJson<DateTime>(json['clientRevisionAt']),
      lastKnownServerAt: serializer.fromJson<DateTime?>(
        json['lastKnownServerAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'monthKey': serializer.toJson<String>(monthKey),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'clientRevisionAt': serializer.toJson<DateTime>(clientRevisionAt),
      'lastKnownServerAt': serializer.toJson<DateTime?>(lastKnownServerAt),
    };
  }

  CachedBudget copyWith({
    String? id,
    String? monthKey,
    String? payloadJson,
    int? syncStatus,
    DateTime? clientRevisionAt,
    Value<DateTime?> lastKnownServerAt = const Value.absent(),
  }) => CachedBudget(
    id: id ?? this.id,
    monthKey: monthKey ?? this.monthKey,
    payloadJson: payloadJson ?? this.payloadJson,
    syncStatus: syncStatus ?? this.syncStatus,
    clientRevisionAt: clientRevisionAt ?? this.clientRevisionAt,
    lastKnownServerAt: lastKnownServerAt.present
        ? lastKnownServerAt.value
        : this.lastKnownServerAt,
  );
  CachedBudget copyWithCompanion(CachedBudgetsCompanion data) {
    return CachedBudget(
      id: data.id.present ? data.id.value : this.id,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      clientRevisionAt: data.clientRevisionAt.present
          ? data.clientRevisionAt.value
          : this.clientRevisionAt,
      lastKnownServerAt: data.lastKnownServerAt.present
          ? data.lastKnownServerAt.value
          : this.lastKnownServerAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedBudget(')
          ..write('id: $id, ')
          ..write('monthKey: $monthKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('clientRevisionAt: $clientRevisionAt, ')
          ..write('lastKnownServerAt: $lastKnownServerAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    monthKey,
    payloadJson,
    syncStatus,
    clientRevisionAt,
    lastKnownServerAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedBudget &&
          other.id == this.id &&
          other.monthKey == this.monthKey &&
          other.payloadJson == this.payloadJson &&
          other.syncStatus == this.syncStatus &&
          other.clientRevisionAt == this.clientRevisionAt &&
          other.lastKnownServerAt == this.lastKnownServerAt);
}

class CachedBudgetsCompanion extends UpdateCompanion<CachedBudget> {
  final Value<String> id;
  final Value<String> monthKey;
  final Value<String> payloadJson;
  final Value<int> syncStatus;
  final Value<DateTime> clientRevisionAt;
  final Value<DateTime?> lastKnownServerAt;
  final Value<int> rowid;
  const CachedBudgetsCompanion({
    this.id = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.clientRevisionAt = const Value.absent(),
    this.lastKnownServerAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedBudgetsCompanion.insert({
    required String id,
    required String monthKey,
    required String payloadJson,
    required int syncStatus,
    required DateTime clientRevisionAt,
    this.lastKnownServerAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       monthKey = Value(monthKey),
       payloadJson = Value(payloadJson),
       syncStatus = Value(syncStatus),
       clientRevisionAt = Value(clientRevisionAt);
  static Insertable<CachedBudget> custom({
    Expression<String>? id,
    Expression<String>? monthKey,
    Expression<String>? payloadJson,
    Expression<int>? syncStatus,
    Expression<DateTime>? clientRevisionAt,
    Expression<DateTime>? lastKnownServerAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monthKey != null) 'month_key': monthKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (clientRevisionAt != null) 'client_revision_at': clientRevisionAt,
      if (lastKnownServerAt != null) 'last_known_server_at': lastKnownServerAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedBudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? monthKey,
    Value<String>? payloadJson,
    Value<int>? syncStatus,
    Value<DateTime>? clientRevisionAt,
    Value<DateTime?>? lastKnownServerAt,
    Value<int>? rowid,
  }) {
    return CachedBudgetsCompanion(
      id: id ?? this.id,
      monthKey: monthKey ?? this.monthKey,
      payloadJson: payloadJson ?? this.payloadJson,
      syncStatus: syncStatus ?? this.syncStatus,
      clientRevisionAt: clientRevisionAt ?? this.clientRevisionAt,
      lastKnownServerAt: lastKnownServerAt ?? this.lastKnownServerAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (clientRevisionAt.present) {
      map['client_revision_at'] = Variable<DateTime>(clientRevisionAt.value);
    }
    if (lastKnownServerAt.present) {
      map['last_known_server_at'] = Variable<DateTime>(lastKnownServerAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedBudgetsCompanion(')
          ..write('id: $id, ')
          ..write('monthKey: $monthKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('clientRevisionAt: $clientRevisionAt, ')
          ..write('lastKnownServerAt: $lastKnownServerAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
    'local_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _opCodeMeta = const VerificationMeta('opCode');
  @override
  late final GeneratedColumn<String> opCode = GeneratedColumn<String>(
    'op_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    opCode,
    entityId,
    payloadJson,
    idempotencyKey,
    createdAt,
    attempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    }
    if (data.containsKey('op_code')) {
      context.handle(
        _opCodeMeta,
        opCode.isAcceptableOrUnknown(data['op_code']!, _opCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_opCodeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  SyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxData(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_id'],
      )!,
      opCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_code'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }
}

class SyncOutboxData extends DataClass implements Insertable<SyncOutboxData> {
  final int localId;
  final String opCode;
  final String entityId;
  final String payloadJson;
  final String idempotencyKey;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
  const SyncOutboxData({
    required this.localId,
    required this.opCode,
    required this.entityId,
    required this.payloadJson,
    required this.idempotencyKey,
    required this.createdAt,
    required this.attempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['op_code'] = Variable<String>(opCode);
    map['entity_id'] = Variable<String>(entityId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      localId: Value(localId),
      opCode: Value(opCode),
      entityId: Value(entityId),
      payloadJson: Value(payloadJson),
      idempotencyKey: Value(idempotencyKey),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxData(
      localId: serializer.fromJson<int>(json['localId']),
      opCode: serializer.fromJson<String>(json['opCode']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'opCode': serializer.toJson<String>(opCode),
      'entityId': serializer.toJson<String>(entityId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncOutboxData copyWith({
    int? localId,
    String? opCode,
    String? entityId,
    String? payloadJson,
    String? idempotencyKey,
    DateTime? createdAt,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
  }) => SyncOutboxData(
    localId: localId ?? this.localId,
    opCode: opCode ?? this.opCode,
    entityId: entityId ?? this.entityId,
    payloadJson: payloadJson ?? this.payloadJson,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncOutboxData copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxData(
      localId: data.localId.present ? data.localId.value : this.localId,
      opCode: data.opCode.present ? data.opCode.value : this.opCode,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxData(')
          ..write('localId: $localId, ')
          ..write('opCode: $opCode, ')
          ..write('entityId: $entityId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    opCode,
    entityId,
    payloadJson,
    idempotencyKey,
    createdAt,
    attempts,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxData &&
          other.localId == this.localId &&
          other.opCode == this.opCode &&
          other.entityId == this.entityId &&
          other.payloadJson == this.payloadJson &&
          other.idempotencyKey == this.idempotencyKey &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxData> {
  final Value<int> localId;
  final Value<String> opCode;
  final Value<String> entityId;
  final Value<String> payloadJson;
  final Value<String> idempotencyKey;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  const SyncOutboxCompanion({
    this.localId = const Value.absent(),
    this.opCode = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    this.localId = const Value.absent(),
    required String opCode,
    required String entityId,
    required String payloadJson,
    required String idempotencyKey,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : opCode = Value(opCode),
       entityId = Value(entityId),
       payloadJson = Value(payloadJson),
       idempotencyKey = Value(idempotencyKey),
       createdAt = Value(createdAt);
  static Insertable<SyncOutboxData> custom({
    Expression<int>? localId,
    Expression<String>? opCode,
    Expression<String>? entityId,
    Expression<String>? payloadJson,
    Expression<String>? idempotencyKey,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (opCode != null) 'op_code': opCode,
      if (entityId != null) 'entity_id': entityId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<int>? localId,
    Value<String>? opCode,
    Value<String>? entityId,
    Value<String>? payloadJson,
    Value<String>? idempotencyKey,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<String?>? lastError,
  }) {
    return SyncOutboxCompanion(
      localId: localId ?? this.localId,
      opCode: opCode ?? this.opCode,
      entityId: entityId ?? this.entityId,
      payloadJson: payloadJson ?? this.payloadJson,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (opCode.present) {
      map['op_code'] = Variable<String>(opCode.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('localId: $localId, ')
          ..write('opCode: $opCode, ')
          ..write('entityId: $entityId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $LedgerKvTable extends LedgerKv
    with TableInfo<$LedgerKvTable, LedgerKvData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerKvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kMeta = const VerificationMeta('k');
  @override
  late final GeneratedColumn<String> k = GeneratedColumn<String>(
    'k',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vMeta = const VerificationMeta('v');
  @override
  late final GeneratedColumn<String> v = GeneratedColumn<String>(
    'v',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [k, v];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerKvData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('k')) {
      context.handle(_kMeta, k.isAcceptableOrUnknown(data['k']!, _kMeta));
    } else if (isInserting) {
      context.missing(_kMeta);
    }
    if (data.containsKey('v')) {
      context.handle(_vMeta, v.isAcceptableOrUnknown(data['v']!, _vMeta));
    } else if (isInserting) {
      context.missing(_vMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {k};
  @override
  LedgerKvData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerKvData(
      k: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}k'],
      )!,
      v: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}v'],
      )!,
    );
  }

  @override
  $LedgerKvTable createAlias(String alias) {
    return $LedgerKvTable(attachedDatabase, alias);
  }
}

class LedgerKvData extends DataClass implements Insertable<LedgerKvData> {
  final String k;
  final String v;
  const LedgerKvData({required this.k, required this.v});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['k'] = Variable<String>(k);
    map['v'] = Variable<String>(v);
    return map;
  }

  LedgerKvCompanion toCompanion(bool nullToAbsent) {
    return LedgerKvCompanion(k: Value(k), v: Value(v));
  }

  factory LedgerKvData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerKvData(
      k: serializer.fromJson<String>(json['k']),
      v: serializer.fromJson<String>(json['v']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'k': serializer.toJson<String>(k),
      'v': serializer.toJson<String>(v),
    };
  }

  LedgerKvData copyWith({String? k, String? v}) =>
      LedgerKvData(k: k ?? this.k, v: v ?? this.v);
  LedgerKvData copyWithCompanion(LedgerKvCompanion data) {
    return LedgerKvData(
      k: data.k.present ? data.k.value : this.k,
      v: data.v.present ? data.v.value : this.v,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerKvData(')
          ..write('k: $k, ')
          ..write('v: $v')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(k, v);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerKvData && other.k == this.k && other.v == this.v);
}

class LedgerKvCompanion extends UpdateCompanion<LedgerKvData> {
  final Value<String> k;
  final Value<String> v;
  final Value<int> rowid;
  const LedgerKvCompanion({
    this.k = const Value.absent(),
    this.v = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerKvCompanion.insert({
    required String k,
    required String v,
    this.rowid = const Value.absent(),
  }) : k = Value(k),
       v = Value(v);
  static Insertable<LedgerKvData> custom({
    Expression<String>? k,
    Expression<String>? v,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (k != null) 'k': k,
      if (v != null) 'v': v,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerKvCompanion copyWith({
    Value<String>? k,
    Value<String>? v,
    Value<int>? rowid,
  }) {
    return LedgerKvCompanion(
      k: k ?? this.k,
      v: v ?? this.v,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (k.present) {
      map['k'] = Variable<String>(k.value);
    }
    if (v.present) {
      map['v'] = Variable<String>(v.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerKvCompanion(')
          ..write('k: $k, ')
          ..write('v: $v, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LedgerDatabase extends GeneratedDatabase {
  _$LedgerDatabase(QueryExecutor e) : super(e);
  $LedgerDatabaseManager get managers => $LedgerDatabaseManager(this);
  late final $CachedExpensesTable cachedExpenses = $CachedExpensesTable(this);
  late final $CachedAccountsTable cachedAccounts = $CachedAccountsTable(this);
  late final $CachedBudgetsTable cachedBudgets = $CachedBudgetsTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  late final $LedgerKvTable ledgerKv = $LedgerKvTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedExpenses,
    cachedAccounts,
    cachedBudgets,
    syncOutbox,
    ledgerKv,
  ];
}

typedef $$CachedExpensesTableCreateCompanionBuilder =
    CachedExpensesCompanion Function({
      required String id,
      required String payloadJson,
      required int syncStatus,
      required DateTime clientRevisionAt,
      Value<DateTime?> lastKnownServerAt,
      required DateTime expenseSortDate,
      Value<int> rowid,
    });
typedef $$CachedExpensesTableUpdateCompanionBuilder =
    CachedExpensesCompanion Function({
      Value<String> id,
      Value<String> payloadJson,
      Value<int> syncStatus,
      Value<DateTime> clientRevisionAt,
      Value<DateTime?> lastKnownServerAt,
      Value<DateTime> expenseSortDate,
      Value<int> rowid,
    });

class $$CachedExpensesTableFilterComposer
    extends Composer<_$LedgerDatabase, $CachedExpensesTable> {
  $$CachedExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientRevisionAt => $composableBuilder(
    column: $table.clientRevisionAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastKnownServerAt => $composableBuilder(
    column: $table.lastKnownServerAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expenseSortDate => $composableBuilder(
    column: $table.expenseSortDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedExpensesTableOrderingComposer
    extends Composer<_$LedgerDatabase, $CachedExpensesTable> {
  $$CachedExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientRevisionAt => $composableBuilder(
    column: $table.clientRevisionAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastKnownServerAt => $composableBuilder(
    column: $table.lastKnownServerAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expenseSortDate => $composableBuilder(
    column: $table.expenseSortDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedExpensesTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $CachedExpensesTable> {
  $$CachedExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientRevisionAt => $composableBuilder(
    column: $table.clientRevisionAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastKnownServerAt => $composableBuilder(
    column: $table.lastKnownServerAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expenseSortDate => $composableBuilder(
    column: $table.expenseSortDate,
    builder: (column) => column,
  );
}

class $$CachedExpensesTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $CachedExpensesTable,
          CachedExpense,
          $$CachedExpensesTableFilterComposer,
          $$CachedExpensesTableOrderingComposer,
          $$CachedExpensesTableAnnotationComposer,
          $$CachedExpensesTableCreateCompanionBuilder,
          $$CachedExpensesTableUpdateCompanionBuilder,
          (
            CachedExpense,
            BaseReferences<
              _$LedgerDatabase,
              $CachedExpensesTable,
              CachedExpense
            >,
          ),
          CachedExpense,
          PrefetchHooks Function()
        > {
  $$CachedExpensesTableTableManager(
    _$LedgerDatabase db,
    $CachedExpensesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> clientRevisionAt = const Value.absent(),
                Value<DateTime?> lastKnownServerAt = const Value.absent(),
                Value<DateTime> expenseSortDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedExpensesCompanion(
                id: id,
                payloadJson: payloadJson,
                syncStatus: syncStatus,
                clientRevisionAt: clientRevisionAt,
                lastKnownServerAt: lastKnownServerAt,
                expenseSortDate: expenseSortDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payloadJson,
                required int syncStatus,
                required DateTime clientRevisionAt,
                Value<DateTime?> lastKnownServerAt = const Value.absent(),
                required DateTime expenseSortDate,
                Value<int> rowid = const Value.absent(),
              }) => CachedExpensesCompanion.insert(
                id: id,
                payloadJson: payloadJson,
                syncStatus: syncStatus,
                clientRevisionAt: clientRevisionAt,
                lastKnownServerAt: lastKnownServerAt,
                expenseSortDate: expenseSortDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $CachedExpensesTable,
      CachedExpense,
      $$CachedExpensesTableFilterComposer,
      $$CachedExpensesTableOrderingComposer,
      $$CachedExpensesTableAnnotationComposer,
      $$CachedExpensesTableCreateCompanionBuilder,
      $$CachedExpensesTableUpdateCompanionBuilder,
      (
        CachedExpense,
        BaseReferences<_$LedgerDatabase, $CachedExpensesTable, CachedExpense>,
      ),
      CachedExpense,
      PrefetchHooks Function()
    >;
typedef $$CachedAccountsTableCreateCompanionBuilder =
    CachedAccountsCompanion Function({
      required String id,
      required String payloadJson,
      required int syncStatus,
      required DateTime clientRevisionAt,
      Value<DateTime?> lastKnownServerAt,
      Value<int> rowid,
    });
typedef $$CachedAccountsTableUpdateCompanionBuilder =
    CachedAccountsCompanion Function({
      Value<String> id,
      Value<String> payloadJson,
      Value<int> syncStatus,
      Value<DateTime> clientRevisionAt,
      Value<DateTime?> lastKnownServerAt,
      Value<int> rowid,
    });

class $$CachedAccountsTableFilterComposer
    extends Composer<_$LedgerDatabase, $CachedAccountsTable> {
  $$CachedAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientRevisionAt => $composableBuilder(
    column: $table.clientRevisionAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastKnownServerAt => $composableBuilder(
    column: $table.lastKnownServerAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedAccountsTableOrderingComposer
    extends Composer<_$LedgerDatabase, $CachedAccountsTable> {
  $$CachedAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientRevisionAt => $composableBuilder(
    column: $table.clientRevisionAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastKnownServerAt => $composableBuilder(
    column: $table.lastKnownServerAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAccountsTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $CachedAccountsTable> {
  $$CachedAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientRevisionAt => $composableBuilder(
    column: $table.clientRevisionAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastKnownServerAt => $composableBuilder(
    column: $table.lastKnownServerAt,
    builder: (column) => column,
  );
}

class $$CachedAccountsTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $CachedAccountsTable,
          CachedAccount,
          $$CachedAccountsTableFilterComposer,
          $$CachedAccountsTableOrderingComposer,
          $$CachedAccountsTableAnnotationComposer,
          $$CachedAccountsTableCreateCompanionBuilder,
          $$CachedAccountsTableUpdateCompanionBuilder,
          (
            CachedAccount,
            BaseReferences<
              _$LedgerDatabase,
              $CachedAccountsTable,
              CachedAccount
            >,
          ),
          CachedAccount,
          PrefetchHooks Function()
        > {
  $$CachedAccountsTableTableManager(
    _$LedgerDatabase db,
    $CachedAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> clientRevisionAt = const Value.absent(),
                Value<DateTime?> lastKnownServerAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAccountsCompanion(
                id: id,
                payloadJson: payloadJson,
                syncStatus: syncStatus,
                clientRevisionAt: clientRevisionAt,
                lastKnownServerAt: lastKnownServerAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payloadJson,
                required int syncStatus,
                required DateTime clientRevisionAt,
                Value<DateTime?> lastKnownServerAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAccountsCompanion.insert(
                id: id,
                payloadJson: payloadJson,
                syncStatus: syncStatus,
                clientRevisionAt: clientRevisionAt,
                lastKnownServerAt: lastKnownServerAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $CachedAccountsTable,
      CachedAccount,
      $$CachedAccountsTableFilterComposer,
      $$CachedAccountsTableOrderingComposer,
      $$CachedAccountsTableAnnotationComposer,
      $$CachedAccountsTableCreateCompanionBuilder,
      $$CachedAccountsTableUpdateCompanionBuilder,
      (
        CachedAccount,
        BaseReferences<_$LedgerDatabase, $CachedAccountsTable, CachedAccount>,
      ),
      CachedAccount,
      PrefetchHooks Function()
    >;
typedef $$CachedBudgetsTableCreateCompanionBuilder =
    CachedBudgetsCompanion Function({
      required String id,
      required String monthKey,
      required String payloadJson,
      required int syncStatus,
      required DateTime clientRevisionAt,
      Value<DateTime?> lastKnownServerAt,
      Value<int> rowid,
    });
typedef $$CachedBudgetsTableUpdateCompanionBuilder =
    CachedBudgetsCompanion Function({
      Value<String> id,
      Value<String> monthKey,
      Value<String> payloadJson,
      Value<int> syncStatus,
      Value<DateTime> clientRevisionAt,
      Value<DateTime?> lastKnownServerAt,
      Value<int> rowid,
    });

class $$CachedBudgetsTableFilterComposer
    extends Composer<_$LedgerDatabase, $CachedBudgetsTable> {
  $$CachedBudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientRevisionAt => $composableBuilder(
    column: $table.clientRevisionAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastKnownServerAt => $composableBuilder(
    column: $table.lastKnownServerAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedBudgetsTableOrderingComposer
    extends Composer<_$LedgerDatabase, $CachedBudgetsTable> {
  $$CachedBudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientRevisionAt => $composableBuilder(
    column: $table.clientRevisionAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastKnownServerAt => $composableBuilder(
    column: $table.lastKnownServerAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedBudgetsTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $CachedBudgetsTable> {
  $$CachedBudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientRevisionAt => $composableBuilder(
    column: $table.clientRevisionAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastKnownServerAt => $composableBuilder(
    column: $table.lastKnownServerAt,
    builder: (column) => column,
  );
}

class $$CachedBudgetsTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $CachedBudgetsTable,
          CachedBudget,
          $$CachedBudgetsTableFilterComposer,
          $$CachedBudgetsTableOrderingComposer,
          $$CachedBudgetsTableAnnotationComposer,
          $$CachedBudgetsTableCreateCompanionBuilder,
          $$CachedBudgetsTableUpdateCompanionBuilder,
          (
            CachedBudget,
            BaseReferences<_$LedgerDatabase, $CachedBudgetsTable, CachedBudget>,
          ),
          CachedBudget,
          PrefetchHooks Function()
        > {
  $$CachedBudgetsTableTableManager(
    _$LedgerDatabase db,
    $CachedBudgetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> monthKey = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> clientRevisionAt = const Value.absent(),
                Value<DateTime?> lastKnownServerAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedBudgetsCompanion(
                id: id,
                monthKey: monthKey,
                payloadJson: payloadJson,
                syncStatus: syncStatus,
                clientRevisionAt: clientRevisionAt,
                lastKnownServerAt: lastKnownServerAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String monthKey,
                required String payloadJson,
                required int syncStatus,
                required DateTime clientRevisionAt,
                Value<DateTime?> lastKnownServerAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedBudgetsCompanion.insert(
                id: id,
                monthKey: monthKey,
                payloadJson: payloadJson,
                syncStatus: syncStatus,
                clientRevisionAt: clientRevisionAt,
                lastKnownServerAt: lastKnownServerAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedBudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $CachedBudgetsTable,
      CachedBudget,
      $$CachedBudgetsTableFilterComposer,
      $$CachedBudgetsTableOrderingComposer,
      $$CachedBudgetsTableAnnotationComposer,
      $$CachedBudgetsTableCreateCompanionBuilder,
      $$CachedBudgetsTableUpdateCompanionBuilder,
      (
        CachedBudget,
        BaseReferences<_$LedgerDatabase, $CachedBudgetsTable, CachedBudget>,
      ),
      CachedBudget,
      PrefetchHooks Function()
    >;
typedef $$SyncOutboxTableCreateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<int> localId,
      required String opCode,
      required String entityId,
      required String payloadJson,
      required String idempotencyKey,
      required DateTime createdAt,
      Value<int> attempts,
      Value<String?> lastError,
    });
typedef $$SyncOutboxTableUpdateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<int> localId,
      Value<String> opCode,
      Value<String> entityId,
      Value<String> payloadJson,
      Value<String> idempotencyKey,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<String?> lastError,
    });

class $$SyncOutboxTableFilterComposer
    extends Composer<_$LedgerDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opCode => $composableBuilder(
    column: $table.opCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$LedgerDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opCode => $composableBuilder(
    column: $table.opCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get opCode =>
      $composableBuilder(column: $table.opCode, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncOutboxTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $SyncOutboxTable,
          SyncOutboxData,
          $$SyncOutboxTableFilterComposer,
          $$SyncOutboxTableOrderingComposer,
          $$SyncOutboxTableAnnotationComposer,
          $$SyncOutboxTableCreateCompanionBuilder,
          $$SyncOutboxTableUpdateCompanionBuilder,
          (
            SyncOutboxData,
            BaseReferences<_$LedgerDatabase, $SyncOutboxTable, SyncOutboxData>,
          ),
          SyncOutboxData,
          PrefetchHooks Function()
        > {
  $$SyncOutboxTableTableManager(_$LedgerDatabase db, $SyncOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                Value<String> opCode = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncOutboxCompanion(
                localId: localId,
                opCode: opCode,
                entityId: entityId,
                payloadJson: payloadJson,
                idempotencyKey: idempotencyKey,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                required String opCode,
                required String entityId,
                required String payloadJson,
                required String idempotencyKey,
                required DateTime createdAt,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncOutboxCompanion.insert(
                localId: localId,
                opCode: opCode,
                entityId: entityId,
                payloadJson: payloadJson,
                idempotencyKey: idempotencyKey,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $SyncOutboxTable,
      SyncOutboxData,
      $$SyncOutboxTableFilterComposer,
      $$SyncOutboxTableOrderingComposer,
      $$SyncOutboxTableAnnotationComposer,
      $$SyncOutboxTableCreateCompanionBuilder,
      $$SyncOutboxTableUpdateCompanionBuilder,
      (
        SyncOutboxData,
        BaseReferences<_$LedgerDatabase, $SyncOutboxTable, SyncOutboxData>,
      ),
      SyncOutboxData,
      PrefetchHooks Function()
    >;
typedef $$LedgerKvTableCreateCompanionBuilder =
    LedgerKvCompanion Function({
      required String k,
      required String v,
      Value<int> rowid,
    });
typedef $$LedgerKvTableUpdateCompanionBuilder =
    LedgerKvCompanion Function({
      Value<String> k,
      Value<String> v,
      Value<int> rowid,
    });

class $$LedgerKvTableFilterComposer
    extends Composer<_$LedgerDatabase, $LedgerKvTable> {
  $$LedgerKvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get k => $composableBuilder(
    column: $table.k,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get v => $composableBuilder(
    column: $table.v,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LedgerKvTableOrderingComposer
    extends Composer<_$LedgerDatabase, $LedgerKvTable> {
  $$LedgerKvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get k => $composableBuilder(
    column: $table.k,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get v => $composableBuilder(
    column: $table.v,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LedgerKvTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $LedgerKvTable> {
  $$LedgerKvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get k =>
      $composableBuilder(column: $table.k, builder: (column) => column);

  GeneratedColumn<String> get v =>
      $composableBuilder(column: $table.v, builder: (column) => column);
}

class $$LedgerKvTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $LedgerKvTable,
          LedgerKvData,
          $$LedgerKvTableFilterComposer,
          $$LedgerKvTableOrderingComposer,
          $$LedgerKvTableAnnotationComposer,
          $$LedgerKvTableCreateCompanionBuilder,
          $$LedgerKvTableUpdateCompanionBuilder,
          (
            LedgerKvData,
            BaseReferences<_$LedgerDatabase, $LedgerKvTable, LedgerKvData>,
          ),
          LedgerKvData,
          PrefetchHooks Function()
        > {
  $$LedgerKvTableTableManager(_$LedgerDatabase db, $LedgerKvTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerKvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerKvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerKvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> k = const Value.absent(),
                Value<String> v = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerKvCompanion(k: k, v: v, rowid: rowid),
          createCompanionCallback:
              ({
                required String k,
                required String v,
                Value<int> rowid = const Value.absent(),
              }) => LedgerKvCompanion.insert(k: k, v: v, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LedgerKvTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $LedgerKvTable,
      LedgerKvData,
      $$LedgerKvTableFilterComposer,
      $$LedgerKvTableOrderingComposer,
      $$LedgerKvTableAnnotationComposer,
      $$LedgerKvTableCreateCompanionBuilder,
      $$LedgerKvTableUpdateCompanionBuilder,
      (
        LedgerKvData,
        BaseReferences<_$LedgerDatabase, $LedgerKvTable, LedgerKvData>,
      ),
      LedgerKvData,
      PrefetchHooks Function()
    >;

class $LedgerDatabaseManager {
  final _$LedgerDatabase _db;
  $LedgerDatabaseManager(this._db);
  $$CachedExpensesTableTableManager get cachedExpenses =>
      $$CachedExpensesTableTableManager(_db, _db.cachedExpenses);
  $$CachedAccountsTableTableManager get cachedAccounts =>
      $$CachedAccountsTableTableManager(_db, _db.cachedAccounts);
  $$CachedBudgetsTableTableManager get cachedBudgets =>
      $$CachedBudgetsTableTableManager(_db, _db.cachedBudgets);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
  $$LedgerKvTableTableManager get ledgerKv =>
      $$LedgerKvTableTableManager(_db, _db.ledgerKv);
}
