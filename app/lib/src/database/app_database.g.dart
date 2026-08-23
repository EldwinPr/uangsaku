// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountGroup, String> group =
      GeneratedColumn<String>(
        'group',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccountGroup>($AccountsTable.$convertergroup);
  static const VerificationMeta _openingAmountMeta = const VerificationMeta(
    'openingAmount',
  );
  @override
  late final GeneratedColumn<int> openingAmount = GeneratedColumn<int>(
    'opening_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settledMeta = const VerificationMeta(
    'settled',
  );
  @override
  late final GeneratedColumn<bool> settled = GeneratedColumn<bool>(
    'settled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("settled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _settledAtMeta = const VerificationMeta(
    'settledAt',
  );
  @override
  late final GeneratedColumn<DateTime> settledAt = GeneratedColumn<DateTime>(
    'settled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    name,
    group,
    openingAmount,
    settled,
    settledAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('opening_amount')) {
      context.handle(
        _openingAmountMeta,
        openingAmount.isAcceptableOrUnknown(
          data['opening_amount']!,
          _openingAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingAmountMeta);
    }
    if (data.containsKey('settled')) {
      context.handle(
        _settledMeta,
        settled.isAcceptableOrUnknown(data['settled']!, _settledMeta),
      );
    }
    if (data.containsKey('settled_at')) {
      context.handle(
        _settledAtMeta,
        settledAt.isAcceptableOrUnknown(data['settled_at']!, _settledAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      group: $AccountsTable.$convertergroup.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}group'],
        )!,
      ),
      openingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_amount'],
      )!,
      settled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}settled'],
      )!,
      settledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}settled_at'],
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountGroup, String, String> $convertergroup =
      const EnumNameConverter<AccountGroup>(AccountGroup.values);
}

class Account extends DataClass implements Insertable<Account> {
  final int accountId;
  final String name;

  /// FR-1's three-way split — never a debit/credit column (NFR-1).
  final AccountGroup group;

  /// Minor units of `Settings.currency`. Never a `double` — NFR-2.
  final int openingAmount;

  /// FR-11's "just tick" — a flag, not an enum (`docs/enums.md`).
  final bool settled;
  final DateTime? settledAt;
  const Account({
    required this.accountId,
    required this.name,
    required this.group,
    required this.openingAmount,
    required this.settled,
    this.settledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<int>(accountId);
    map['name'] = Variable<String>(name);
    {
      map['group'] = Variable<String>(
        $AccountsTable.$convertergroup.toSql(group),
      );
    }
    map['opening_amount'] = Variable<int>(openingAmount);
    map['settled'] = Variable<bool>(settled);
    if (!nullToAbsent || settledAt != null) {
      map['settled_at'] = Variable<DateTime>(settledAt);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      accountId: Value(accountId),
      name: Value(name),
      group: Value(group),
      openingAmount: Value(openingAmount),
      settled: Value(settled),
      settledAt: settledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(settledAt),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      accountId: serializer.fromJson<int>(json['accountId']),
      name: serializer.fromJson<String>(json['name']),
      group: $AccountsTable.$convertergroup.fromJson(
        serializer.fromJson<String>(json['group']),
      ),
      openingAmount: serializer.fromJson<int>(json['openingAmount']),
      settled: serializer.fromJson<bool>(json['settled']),
      settledAt: serializer.fromJson<DateTime?>(json['settledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<int>(accountId),
      'name': serializer.toJson<String>(name),
      'group': serializer.toJson<String>(
        $AccountsTable.$convertergroup.toJson(group),
      ),
      'openingAmount': serializer.toJson<int>(openingAmount),
      'settled': serializer.toJson<bool>(settled),
      'settledAt': serializer.toJson<DateTime?>(settledAt),
    };
  }

  Account copyWith({
    int? accountId,
    String? name,
    AccountGroup? group,
    int? openingAmount,
    bool? settled,
    Value<DateTime?> settledAt = const Value.absent(),
  }) => Account(
    accountId: accountId ?? this.accountId,
    name: name ?? this.name,
    group: group ?? this.group,
    openingAmount: openingAmount ?? this.openingAmount,
    settled: settled ?? this.settled,
    settledAt: settledAt.present ? settledAt.value : this.settledAt,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      name: data.name.present ? data.name.value : this.name,
      group: data.group.present ? data.group.value : this.group,
      openingAmount: data.openingAmount.present
          ? data.openingAmount.value
          : this.openingAmount,
      settled: data.settled.present ? data.settled.value : this.settled,
      settledAt: data.settledAt.present ? data.settledAt.value : this.settledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('group: $group, ')
          ..write('openingAmount: $openingAmount, ')
          ..write('settled: $settled, ')
          ..write('settledAt: $settledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(accountId, name, group, openingAmount, settled, settledAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.accountId == this.accountId &&
          other.name == this.name &&
          other.group == this.group &&
          other.openingAmount == this.openingAmount &&
          other.settled == this.settled &&
          other.settledAt == this.settledAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> accountId;
  final Value<String> name;
  final Value<AccountGroup> group;
  final Value<int> openingAmount;
  final Value<bool> settled;
  final Value<DateTime?> settledAt;
  const AccountsCompanion({
    this.accountId = const Value.absent(),
    this.name = const Value.absent(),
    this.group = const Value.absent(),
    this.openingAmount = const Value.absent(),
    this.settled = const Value.absent(),
    this.settledAt = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.accountId = const Value.absent(),
    required String name,
    required AccountGroup group,
    required int openingAmount,
    this.settled = const Value.absent(),
    this.settledAt = const Value.absent(),
  }) : name = Value(name),
       group = Value(group),
       openingAmount = Value(openingAmount);
  static Insertable<Account> custom({
    Expression<int>? accountId,
    Expression<String>? name,
    Expression<String>? group,
    Expression<int>? openingAmount,
    Expression<bool>? settled,
    Expression<DateTime>? settledAt,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (name != null) 'name': name,
      if (group != null) 'group': group,
      if (openingAmount != null) 'opening_amount': openingAmount,
      if (settled != null) 'settled': settled,
      if (settledAt != null) 'settled_at': settledAt,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? accountId,
    Value<String>? name,
    Value<AccountGroup>? group,
    Value<int>? openingAmount,
    Value<bool>? settled,
    Value<DateTime?>? settledAt,
  }) {
    return AccountsCompanion(
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      group: group ?? this.group,
      openingAmount: openingAmount ?? this.openingAmount,
      settled: settled ?? this.settled,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (group.present) {
      map['group'] = Variable<String>(
        $AccountsTable.$convertergroup.toSql(group.value),
      );
    }
    if (openingAmount.present) {
      map['opening_amount'] = Variable<int>(openingAmount.value);
    }
    if (settled.present) {
      map['settled'] = Variable<bool>(settled.value);
    }
    if (settledAt.present) {
      map['settled_at'] = Variable<DateTime>(settledAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('group: $group, ')
          ..write('openingAmount: $openingAmount, ')
          ..write('settled: $settled, ')
          ..write('settledAt: $settledAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [categoryId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {categoryId};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int categoryId;
  final String name;
  const Category({required this.categoryId, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category_id'] = Variable<int>(categoryId);
    map['name'] = Variable<String>(name);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      categoryId: Value(categoryId),
      name: Value(name),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      categoryId: serializer.fromJson<int>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'categoryId': serializer.toJson<int>(categoryId),
      'name': serializer.toJson<String>(name),
    };
  }

  Category copyWith({int? categoryId, String? name}) => Category(
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(categoryId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.categoryId == this.categoryId &&
          other.name == this.name);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> categoryId;
  final Value<String> name;
  const CategoriesCompanion({
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.categoryId = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? categoryId,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
    });
  }

  CategoriesCompanion copyWith({Value<int>? categoryId, Value<String>? name}) {
    return CategoriesCompanion(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $SubcategoriesTable extends Subcategories
    with TableInfo<$SubcategoriesTable, Subcategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubcategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subcategoryIdMeta = const VerificationMeta(
    'subcategoryId',
  );
  @override
  late final GeneratedColumn<int> subcategoryId = GeneratedColumn<int>(
    'subcategory_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (category_id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [subcategoryId, categoryId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subcategories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subcategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subcategory_id')) {
      context.handle(
        _subcategoryIdMeta,
        subcategoryId.isAcceptableOrUnknown(
          data['subcategory_id']!,
          _subcategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subcategoryId};
  @override
  Subcategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subcategory(
      subcategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subcategory_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $SubcategoriesTable createAlias(String alias) {
    return $SubcategoriesTable(attachedDatabase, alias);
  }
}

class Subcategory extends DataClass implements Insertable<Subcategory> {
  final int subcategoryId;
  final int categoryId;
  final String name;
  const Subcategory({
    required this.subcategoryId,
    required this.categoryId,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subcategory_id'] = Variable<int>(subcategoryId);
    map['category_id'] = Variable<int>(categoryId);
    map['name'] = Variable<String>(name);
    return map;
  }

  SubcategoriesCompanion toCompanion(bool nullToAbsent) {
    return SubcategoriesCompanion(
      subcategoryId: Value(subcategoryId),
      categoryId: Value(categoryId),
      name: Value(name),
    );
  }

  factory Subcategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subcategory(
      subcategoryId: serializer.fromJson<int>(json['subcategoryId']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subcategoryId': serializer.toJson<int>(subcategoryId),
      'categoryId': serializer.toJson<int>(categoryId),
      'name': serializer.toJson<String>(name),
    };
  }

  Subcategory copyWith({int? subcategoryId, int? categoryId, String? name}) =>
      Subcategory(
        subcategoryId: subcategoryId ?? this.subcategoryId,
        categoryId: categoryId ?? this.categoryId,
        name: name ?? this.name,
      );
  Subcategory copyWithCompanion(SubcategoriesCompanion data) {
    return Subcategory(
      subcategoryId: data.subcategoryId.present
          ? data.subcategoryId.value
          : this.subcategoryId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subcategory(')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(subcategoryId, categoryId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subcategory &&
          other.subcategoryId == this.subcategoryId &&
          other.categoryId == this.categoryId &&
          other.name == this.name);
}

class SubcategoriesCompanion extends UpdateCompanion<Subcategory> {
  final Value<int> subcategoryId;
  final Value<int> categoryId;
  final Value<String> name;
  const SubcategoriesCompanion({
    this.subcategoryId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
  });
  SubcategoriesCompanion.insert({
    this.subcategoryId = const Value.absent(),
    required int categoryId,
    required String name,
  }) : categoryId = Value(categoryId),
       name = Value(name);
  static Insertable<Subcategory> custom({
    Expression<int>? subcategoryId,
    Expression<int>? categoryId,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
    });
  }

  SubcategoriesCompanion copyWith({
    Value<int>? subcategoryId,
    Value<int>? categoryId,
    Value<String>? name,
  }) {
    return SubcategoriesCompanion(
      subcategoryId: subcategoryId ?? this.subcategoryId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subcategoryId.present) {
      map['subcategory_id'] = Variable<int>(subcategoryId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubcategoriesCompanion(')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $BudgetGroupsTable extends BudgetGroups
    with TableInfo<$BudgetGroupsTable, BudgetGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _budgetGroupIdMeta = const VerificationMeta(
    'budgetGroupId',
  );
  @override
  late final GeneratedColumn<int> budgetGroupId = GeneratedColumn<int>(
    'budget_group_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [budgetGroupId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('budget_group_id')) {
      context.handle(
        _budgetGroupIdMeta,
        budgetGroupId.isAcceptableOrUnknown(
          data['budget_group_id']!,
          _budgetGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {budgetGroupId};
  @override
  BudgetGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetGroup(
      budgetGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget_group_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $BudgetGroupsTable createAlias(String alias) {
    return $BudgetGroupsTable(attachedDatabase, alias);
  }
}

class BudgetGroup extends DataClass implements Insertable<BudgetGroup> {
  final int budgetGroupId;
  final String name;
  const BudgetGroup({required this.budgetGroupId, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['budget_group_id'] = Variable<int>(budgetGroupId);
    map['name'] = Variable<String>(name);
    return map;
  }

  BudgetGroupsCompanion toCompanion(bool nullToAbsent) {
    return BudgetGroupsCompanion(
      budgetGroupId: Value(budgetGroupId),
      name: Value(name),
    );
  }

  factory BudgetGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetGroup(
      budgetGroupId: serializer.fromJson<int>(json['budgetGroupId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'budgetGroupId': serializer.toJson<int>(budgetGroupId),
      'name': serializer.toJson<String>(name),
    };
  }

  BudgetGroup copyWith({int? budgetGroupId, String? name}) => BudgetGroup(
    budgetGroupId: budgetGroupId ?? this.budgetGroupId,
    name: name ?? this.name,
  );
  BudgetGroup copyWithCompanion(BudgetGroupsCompanion data) {
    return BudgetGroup(
      budgetGroupId: data.budgetGroupId.present
          ? data.budgetGroupId.value
          : this.budgetGroupId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetGroup(')
          ..write('budgetGroupId: $budgetGroupId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(budgetGroupId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetGroup &&
          other.budgetGroupId == this.budgetGroupId &&
          other.name == this.name);
}

class BudgetGroupsCompanion extends UpdateCompanion<BudgetGroup> {
  final Value<int> budgetGroupId;
  final Value<String> name;
  const BudgetGroupsCompanion({
    this.budgetGroupId = const Value.absent(),
    this.name = const Value.absent(),
  });
  BudgetGroupsCompanion.insert({
    this.budgetGroupId = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<BudgetGroup> custom({
    Expression<int>? budgetGroupId,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (budgetGroupId != null) 'budget_group_id': budgetGroupId,
      if (name != null) 'name': name,
    });
  }

  BudgetGroupsCompanion copyWith({
    Value<int>? budgetGroupId,
    Value<String>? name,
  }) {
    return BudgetGroupsCompanion(
      budgetGroupId: budgetGroupId ?? this.budgetGroupId,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (budgetGroupId.present) {
      map['budget_group_id'] = Variable<int>(budgetGroupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetGroupsCompanion(')
          ..write('budgetGroupId: $budgetGroupId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
    'transaction_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransactionKind>($TransactionsTable.$converterkind);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredOnMeta = const VerificationMeta(
    'occurredOn',
  );
  @override
  late final GeneratedColumn<DateTime> occurredOn = GeneratedColumn<DateTime>(
    'occurred_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromAccountIdMeta = const VerificationMeta(
    'fromAccountId',
  );
  @override
  late final GeneratedColumn<int> fromAccountId = GeneratedColumn<int>(
    'from_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (account_id)',
    ),
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<int> toAccountId = GeneratedColumn<int>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (account_id)',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (category_id)',
    ),
  );
  static const VerificationMeta _subcategoryIdMeta = const VerificationMeta(
    'subcategoryId',
  );
  @override
  late final GeneratedColumn<int> subcategoryId = GeneratedColumn<int>(
    'subcategory_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subcategories (subcategory_id)',
    ),
  );
  static const VerificationMeta _budgetGroupIdMeta = const VerificationMeta(
    'budgetGroupId',
  );
  @override
  late final GeneratedColumn<int> budgetGroupId = GeneratedColumn<int>(
    'budget_group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES budget_groups (budget_group_id)',
    ),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    transactionId,
    kind,
    amount,
    occurredOn,
    fromAccountId,
    toAccountId,
    categoryId,
    subcategoryId,
    budgetGroupId,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('occurred_on')) {
      context.handle(
        _occurredOnMeta,
        occurredOn.isAcceptableOrUnknown(data['occurred_on']!, _occurredOnMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredOnMeta);
    }
    if (data.containsKey('from_account_id')) {
      context.handle(
        _fromAccountIdMeta,
        fromAccountId.isAcceptableOrUnknown(
          data['from_account_id']!,
          _fromAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('subcategory_id')) {
      context.handle(
        _subcategoryIdMeta,
        subcategoryId.isAcceptableOrUnknown(
          data['subcategory_id']!,
          _subcategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('budget_group_id')) {
      context.handle(
        _budgetGroupIdMeta,
        budgetGroupId.isAcceptableOrUnknown(
          data['budget_group_id']!,
          _budgetGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transactionId};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_id'],
      )!,
      kind: $TransactionsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      occurredOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_on'],
      )!,
      fromAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_account_id'],
      ),
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_account_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      subcategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subcategory_id'],
      ),
      budgetGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget_group_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionKind, String, String> $converterkind =
      const EnumNameConverter<TransactionKind>(TransactionKind.values);
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int transactionId;
  final TransactionKind kind;

  /// Minor units of `Settings.currency`. Never a `double` — NFR-2.
  final int amount;
  final DateTime occurredOn;
  final int? fromAccountId;
  final int? toAccountId;
  final int? categoryId;
  final int? subcategoryId;
  final int? budgetGroupId;

  /// Nullable free text. Optional; nothing in the app reads it to make a
  /// decision, and it is not searchable (decided 2026-08-21; searching or
  /// filtering stays deferred per `docs/fr-nfr.md` §3 — UC-09 amends the
  /// note like any other field and draws no search).
  final String? note;
  const Transaction({
    required this.transactionId,
    required this.kind,
    required this.amount,
    required this.occurredOn,
    this.fromAccountId,
    this.toAccountId,
    this.categoryId,
    this.subcategoryId,
    this.budgetGroupId,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transaction_id'] = Variable<int>(transactionId);
    {
      map['kind'] = Variable<String>(
        $TransactionsTable.$converterkind.toSql(kind),
      );
    }
    map['amount'] = Variable<int>(amount);
    map['occurred_on'] = Variable<DateTime>(occurredOn);
    if (!nullToAbsent || fromAccountId != null) {
      map['from_account_id'] = Variable<int>(fromAccountId);
    }
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<int>(toAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || subcategoryId != null) {
      map['subcategory_id'] = Variable<int>(subcategoryId);
    }
    if (!nullToAbsent || budgetGroupId != null) {
      map['budget_group_id'] = Variable<int>(budgetGroupId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      transactionId: Value(transactionId),
      kind: Value(kind),
      amount: Value(amount),
      occurredOn: Value(occurredOn),
      fromAccountId: fromAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromAccountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      subcategoryId: subcategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategoryId),
      budgetGroupId: budgetGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetGroupId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      transactionId: serializer.fromJson<int>(json['transactionId']),
      kind: $TransactionsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      amount: serializer.fromJson<int>(json['amount']),
      occurredOn: serializer.fromJson<DateTime>(json['occurredOn']),
      fromAccountId: serializer.fromJson<int?>(json['fromAccountId']),
      toAccountId: serializer.fromJson<int?>(json['toAccountId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      subcategoryId: serializer.fromJson<int?>(json['subcategoryId']),
      budgetGroupId: serializer.fromJson<int?>(json['budgetGroupId']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transactionId': serializer.toJson<int>(transactionId),
      'kind': serializer.toJson<String>(
        $TransactionsTable.$converterkind.toJson(kind),
      ),
      'amount': serializer.toJson<int>(amount),
      'occurredOn': serializer.toJson<DateTime>(occurredOn),
      'fromAccountId': serializer.toJson<int?>(fromAccountId),
      'toAccountId': serializer.toJson<int?>(toAccountId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'subcategoryId': serializer.toJson<int?>(subcategoryId),
      'budgetGroupId': serializer.toJson<int?>(budgetGroupId),
      'note': serializer.toJson<String?>(note),
    };
  }

  Transaction copyWith({
    int? transactionId,
    TransactionKind? kind,
    int? amount,
    DateTime? occurredOn,
    Value<int?> fromAccountId = const Value.absent(),
    Value<int?> toAccountId = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
    Value<int?> subcategoryId = const Value.absent(),
    Value<int?> budgetGroupId = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => Transaction(
    transactionId: transactionId ?? this.transactionId,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    occurredOn: occurredOn ?? this.occurredOn,
    fromAccountId: fromAccountId.present
        ? fromAccountId.value
        : this.fromAccountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    subcategoryId: subcategoryId.present
        ? subcategoryId.value
        : this.subcategoryId,
    budgetGroupId: budgetGroupId.present
        ? budgetGroupId.value
        : this.budgetGroupId,
    note: note.present ? note.value : this.note,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      occurredOn: data.occurredOn.present
          ? data.occurredOn.value
          : this.occurredOn,
      fromAccountId: data.fromAccountId.present
          ? data.fromAccountId.value
          : this.fromAccountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      subcategoryId: data.subcategoryId.present
          ? data.subcategoryId.value
          : this.subcategoryId,
      budgetGroupId: data.budgetGroupId.present
          ? data.budgetGroupId.value
          : this.budgetGroupId,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('transactionId: $transactionId, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('budgetGroupId: $budgetGroupId, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    transactionId,
    kind,
    amount,
    occurredOn,
    fromAccountId,
    toAccountId,
    categoryId,
    subcategoryId,
    budgetGroupId,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.transactionId == this.transactionId &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.occurredOn == this.occurredOn &&
          other.fromAccountId == this.fromAccountId &&
          other.toAccountId == this.toAccountId &&
          other.categoryId == this.categoryId &&
          other.subcategoryId == this.subcategoryId &&
          other.budgetGroupId == this.budgetGroupId &&
          other.note == this.note);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> transactionId;
  final Value<TransactionKind> kind;
  final Value<int> amount;
  final Value<DateTime> occurredOn;
  final Value<int?> fromAccountId;
  final Value<int?> toAccountId;
  final Value<int?> categoryId;
  final Value<int?> subcategoryId;
  final Value<int?> budgetGroupId;
  final Value<String?> note;
  const TransactionsCompanion({
    this.transactionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.occurredOn = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subcategoryId = const Value.absent(),
    this.budgetGroupId = const Value.absent(),
    this.note = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.transactionId = const Value.absent(),
    required TransactionKind kind,
    required int amount,
    required DateTime occurredOn,
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subcategoryId = const Value.absent(),
    this.budgetGroupId = const Value.absent(),
    this.note = const Value.absent(),
  }) : kind = Value(kind),
       amount = Value(amount),
       occurredOn = Value(occurredOn);
  static Insertable<Transaction> custom({
    Expression<int>? transactionId,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<DateTime>? occurredOn,
    Expression<int>? fromAccountId,
    Expression<int>? toAccountId,
    Expression<int>? categoryId,
    Expression<int>? subcategoryId,
    Expression<int>? budgetGroupId,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (transactionId != null) 'transaction_id': transactionId,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (occurredOn != null) 'occurred_on': occurredOn,
      if (fromAccountId != null) 'from_account_id': fromAccountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (budgetGroupId != null) 'budget_group_id': budgetGroupId,
      if (note != null) 'note': note,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? transactionId,
    Value<TransactionKind>? kind,
    Value<int>? amount,
    Value<DateTime>? occurredOn,
    Value<int?>? fromAccountId,
    Value<int?>? toAccountId,
    Value<int?>? categoryId,
    Value<int?>? subcategoryId,
    Value<int?>? budgetGroupId,
    Value<String?>? note,
  }) {
    return TransactionsCompanion(
      transactionId: transactionId ?? this.transactionId,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      occurredOn: occurredOn ?? this.occurredOn,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      budgetGroupId: budgetGroupId ?? this.budgetGroupId,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $TransactionsTable.$converterkind.toSql(kind.value),
      );
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (occurredOn.present) {
      map['occurred_on'] = Variable<DateTime>(occurredOn.value);
    }
    if (fromAccountId.present) {
      map['from_account_id'] = Variable<int>(fromAccountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<int>(toAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (subcategoryId.present) {
      map['subcategory_id'] = Variable<int>(subcategoryId.value);
    }
    if (budgetGroupId.present) {
      map['budget_group_id'] = Variable<int>(budgetGroupId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('transactionId: $transactionId, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('budgetGroupId: $budgetGroupId, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $BudgetPeriodsTable extends BudgetPeriods
    with TableInfo<$BudgetPeriodsTable, BudgetPeriod> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetPeriodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _budgetPeriodIdMeta = const VerificationMeta(
    'budgetPeriodId',
  );
  @override
  late final GeneratedColumn<int> budgetPeriodId = GeneratedColumn<int>(
    'budget_period_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _budgetGroupIdMeta = const VerificationMeta(
    'budgetGroupId',
  );
  @override
  late final GeneratedColumn<int> budgetGroupId = GeneratedColumn<int>(
    'budget_group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES budget_groups (budget_group_id)',
    ),
  );
  static const VerificationMeta _startsOnMeta = const VerificationMeta(
    'startsOn',
  );
  @override
  late final GeneratedColumn<DateTime> startsOn = GeneratedColumn<DateTime>(
    'starts_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endsOnMeta = const VerificationMeta('endsOn');
  @override
  late final GeneratedColumn<DateTime> endsOn = GeneratedColumn<DateTime>(
    'ends_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    budgetPeriodId,
    budgetGroupId,
    startsOn,
    endsOn,
    amount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_periods';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetPeriod> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('budget_period_id')) {
      context.handle(
        _budgetPeriodIdMeta,
        budgetPeriodId.isAcceptableOrUnknown(
          data['budget_period_id']!,
          _budgetPeriodIdMeta,
        ),
      );
    }
    if (data.containsKey('budget_group_id')) {
      context.handle(
        _budgetGroupIdMeta,
        budgetGroupId.isAcceptableOrUnknown(
          data['budget_group_id']!,
          _budgetGroupIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_budgetGroupIdMeta);
    }
    if (data.containsKey('starts_on')) {
      context.handle(
        _startsOnMeta,
        startsOn.isAcceptableOrUnknown(data['starts_on']!, _startsOnMeta),
      );
    } else if (isInserting) {
      context.missing(_startsOnMeta);
    }
    if (data.containsKey('ends_on')) {
      context.handle(
        _endsOnMeta,
        endsOn.isAcceptableOrUnknown(data['ends_on']!, _endsOnMeta),
      );
    } else if (isInserting) {
      context.missing(_endsOnMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {budgetPeriodId};
  @override
  BudgetPeriod map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetPeriod(
      budgetPeriodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget_period_id'],
      )!,
      budgetGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget_group_id'],
      )!,
      startsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}starts_on'],
      )!,
      endsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ends_on'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
    );
  }

  @override
  $BudgetPeriodsTable createAlias(String alias) {
    return $BudgetPeriodsTable(attachedDatabase, alias);
  }
}

class BudgetPeriod extends DataClass implements Insertable<BudgetPeriod> {
  final int budgetPeriodId;
  final int budgetGroupId;
  final DateTime startsOn;
  final DateTime endsOn;

  /// Minor units of `Settings.currency`. Never a `double` — NFR-2.
  final int amount;
  const BudgetPeriod({
    required this.budgetPeriodId,
    required this.budgetGroupId,
    required this.startsOn,
    required this.endsOn,
    required this.amount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['budget_period_id'] = Variable<int>(budgetPeriodId);
    map['budget_group_id'] = Variable<int>(budgetGroupId);
    map['starts_on'] = Variable<DateTime>(startsOn);
    map['ends_on'] = Variable<DateTime>(endsOn);
    map['amount'] = Variable<int>(amount);
    return map;
  }

  BudgetPeriodsCompanion toCompanion(bool nullToAbsent) {
    return BudgetPeriodsCompanion(
      budgetPeriodId: Value(budgetPeriodId),
      budgetGroupId: Value(budgetGroupId),
      startsOn: Value(startsOn),
      endsOn: Value(endsOn),
      amount: Value(amount),
    );
  }

  factory BudgetPeriod.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetPeriod(
      budgetPeriodId: serializer.fromJson<int>(json['budgetPeriodId']),
      budgetGroupId: serializer.fromJson<int>(json['budgetGroupId']),
      startsOn: serializer.fromJson<DateTime>(json['startsOn']),
      endsOn: serializer.fromJson<DateTime>(json['endsOn']),
      amount: serializer.fromJson<int>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'budgetPeriodId': serializer.toJson<int>(budgetPeriodId),
      'budgetGroupId': serializer.toJson<int>(budgetGroupId),
      'startsOn': serializer.toJson<DateTime>(startsOn),
      'endsOn': serializer.toJson<DateTime>(endsOn),
      'amount': serializer.toJson<int>(amount),
    };
  }

  BudgetPeriod copyWith({
    int? budgetPeriodId,
    int? budgetGroupId,
    DateTime? startsOn,
    DateTime? endsOn,
    int? amount,
  }) => BudgetPeriod(
    budgetPeriodId: budgetPeriodId ?? this.budgetPeriodId,
    budgetGroupId: budgetGroupId ?? this.budgetGroupId,
    startsOn: startsOn ?? this.startsOn,
    endsOn: endsOn ?? this.endsOn,
    amount: amount ?? this.amount,
  );
  BudgetPeriod copyWithCompanion(BudgetPeriodsCompanion data) {
    return BudgetPeriod(
      budgetPeriodId: data.budgetPeriodId.present
          ? data.budgetPeriodId.value
          : this.budgetPeriodId,
      budgetGroupId: data.budgetGroupId.present
          ? data.budgetGroupId.value
          : this.budgetGroupId,
      startsOn: data.startsOn.present ? data.startsOn.value : this.startsOn,
      endsOn: data.endsOn.present ? data.endsOn.value : this.endsOn,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetPeriod(')
          ..write('budgetPeriodId: $budgetPeriodId, ')
          ..write('budgetGroupId: $budgetGroupId, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(budgetPeriodId, budgetGroupId, startsOn, endsOn, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetPeriod &&
          other.budgetPeriodId == this.budgetPeriodId &&
          other.budgetGroupId == this.budgetGroupId &&
          other.startsOn == this.startsOn &&
          other.endsOn == this.endsOn &&
          other.amount == this.amount);
}

class BudgetPeriodsCompanion extends UpdateCompanion<BudgetPeriod> {
  final Value<int> budgetPeriodId;
  final Value<int> budgetGroupId;
  final Value<DateTime> startsOn;
  final Value<DateTime> endsOn;
  final Value<int> amount;
  const BudgetPeriodsCompanion({
    this.budgetPeriodId = const Value.absent(),
    this.budgetGroupId = const Value.absent(),
    this.startsOn = const Value.absent(),
    this.endsOn = const Value.absent(),
    this.amount = const Value.absent(),
  });
  BudgetPeriodsCompanion.insert({
    this.budgetPeriodId = const Value.absent(),
    required int budgetGroupId,
    required DateTime startsOn,
    required DateTime endsOn,
    required int amount,
  }) : budgetGroupId = Value(budgetGroupId),
       startsOn = Value(startsOn),
       endsOn = Value(endsOn),
       amount = Value(amount);
  static Insertable<BudgetPeriod> custom({
    Expression<int>? budgetPeriodId,
    Expression<int>? budgetGroupId,
    Expression<DateTime>? startsOn,
    Expression<DateTime>? endsOn,
    Expression<int>? amount,
  }) {
    return RawValuesInsertable({
      if (budgetPeriodId != null) 'budget_period_id': budgetPeriodId,
      if (budgetGroupId != null) 'budget_group_id': budgetGroupId,
      if (startsOn != null) 'starts_on': startsOn,
      if (endsOn != null) 'ends_on': endsOn,
      if (amount != null) 'amount': amount,
    });
  }

  BudgetPeriodsCompanion copyWith({
    Value<int>? budgetPeriodId,
    Value<int>? budgetGroupId,
    Value<DateTime>? startsOn,
    Value<DateTime>? endsOn,
    Value<int>? amount,
  }) {
    return BudgetPeriodsCompanion(
      budgetPeriodId: budgetPeriodId ?? this.budgetPeriodId,
      budgetGroupId: budgetGroupId ?? this.budgetGroupId,
      startsOn: startsOn ?? this.startsOn,
      endsOn: endsOn ?? this.endsOn,
      amount: amount ?? this.amount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (budgetPeriodId.present) {
      map['budget_period_id'] = Variable<int>(budgetPeriodId.value);
    }
    if (budgetGroupId.present) {
      map['budget_group_id'] = Variable<int>(budgetGroupId.value);
    }
    if (startsOn.present) {
      map['starts_on'] = Variable<DateTime>(startsOn.value);
    }
    if (endsOn.present) {
      map['ends_on'] = Variable<DateTime>(endsOn.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetPeriodsCompanion(')
          ..write('budgetPeriodId: $budgetPeriodId, ')
          ..write('budgetGroupId: $budgetGroupId, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingsIdMeta = const VerificationMeta(
    'settingsId',
  );
  @override
  late final GeneratedColumn<int> settingsId = GeneratedColumn<int>(
    'settings_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Currency, String> currency =
      GeneratedColumn<String>(
        'currency',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Currency>($SettingsTable.$convertercurrency);
  @override
  List<GeneratedColumn> get $columns => [settingsId, currency];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('settings_id')) {
      context.handle(
        _settingsIdMeta,
        settingsId.isAcceptableOrUnknown(data['settings_id']!, _settingsIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingsId};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      settingsId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}settings_id'],
      )!,
      currency: $SettingsTable.$convertercurrency.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}currency'],
        )!,
      ),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Currency, String, String> $convertercurrency =
      const EnumNameConverter<Currency>(Currency.values);
}

class Setting extends DataClass implements Insertable<Setting> {
  final int settingsId;
  final Currency currency;
  const Setting({required this.settingsId, required this.currency});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['settings_id'] = Variable<int>(settingsId);
    {
      map['currency'] = Variable<String>(
        $SettingsTable.$convertercurrency.toSql(currency),
      );
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      settingsId: Value(settingsId),
      currency: Value(currency),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      settingsId: serializer.fromJson<int>(json['settingsId']),
      currency: $SettingsTable.$convertercurrency.fromJson(
        serializer.fromJson<String>(json['currency']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'settingsId': serializer.toJson<int>(settingsId),
      'currency': serializer.toJson<String>(
        $SettingsTable.$convertercurrency.toJson(currency),
      ),
    };
  }

  Setting copyWith({int? settingsId, Currency? currency}) => Setting(
    settingsId: settingsId ?? this.settingsId,
    currency: currency ?? this.currency,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      settingsId: data.settingsId.present
          ? data.settingsId.value
          : this.settingsId,
      currency: data.currency.present ? data.currency.value : this.currency,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('settingsId: $settingsId, ')
          ..write('currency: $currency')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingsId, currency);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.settingsId == this.settingsId &&
          other.currency == this.currency);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> settingsId;
  final Value<Currency> currency;
  const SettingsCompanion({
    this.settingsId = const Value.absent(),
    this.currency = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.settingsId = const Value.absent(),
    required Currency currency,
  }) : currency = Value(currency);
  static Insertable<Setting> custom({
    Expression<int>? settingsId,
    Expression<String>? currency,
  }) {
    return RawValuesInsertable({
      if (settingsId != null) 'settings_id': settingsId,
      if (currency != null) 'currency': currency,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? settingsId,
    Value<Currency>? currency,
  }) {
    return SettingsCompanion(
      settingsId: settingsId ?? this.settingsId,
      currency: currency ?? this.currency,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingsId.present) {
      map['settings_id'] = Variable<int>(settingsId.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(
        $SettingsTable.$convertercurrency.toSql(currency.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('settingsId: $settingsId, ')
          ..write('currency: $currency')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $SubcategoriesTable subcategories = $SubcategoriesTable(this);
  late final $BudgetGroupsTable budgetGroups = $BudgetGroupsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $BudgetPeriodsTable budgetPeriods = $BudgetPeriodsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    categories,
    subcategories,
    budgetGroups,
    transactions,
    budgetPeriods,
    settings,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> accountId,
  required String name,
  required AccountGroup group,
  required int openingAmount,
  Value<bool> settled,
  Value<DateTime?> settledAt,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> accountId,
  Value<String> name,
  Value<AccountGroup> group,
  Value<int> openingAmount,
  Value<bool> settled,
  Value<DateTime?> settledAt,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _outgoingTransactionsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'accounts__account_id__transactions__from_account_id',
  );

  $$TransactionsTableProcessedTableManager get outgoingTransactions {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter(
          (f) => f.fromAccountId.accountId.sqlEquals(
            $_itemColumn<int>('account_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _outgoingTransactionsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _incomingTransactionsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'accounts__account_id__transactions__to_account_id',
  );

  $$TransactionsTableProcessedTableManager get incomingTransactions {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter(
          (f) => f.toAccountId.accountId.sqlEquals(
            $_itemColumn<int>('account_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _incomingTransactionsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AccountGroup, AccountGroup, String>
  get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get openingAmount => $composableBuilder(
    column: $table.openingAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get settled => $composableBuilder(
    column: $table.settled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> outgoingTransactions(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.fromAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> incomingTransactions(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.toAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingAmount => $composableBuilder(
    column: $table.openingAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get settled => $composableBuilder(
    column: $table.settled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountGroup, String> get group =>
      $composableBuilder(column: $table.group, builder: (column) => column);

  GeneratedColumn<int> get openingAmount => $composableBuilder(
    column: $table.openingAmount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get settled =>
      $composableBuilder(column: $table.settled, builder: (column) => column);

  GeneratedColumn<DateTime> get settledAt =>
      $composableBuilder(column: $table.settledAt, builder: (column) => column);

  Expression<T> outgoingTransactions<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.fromAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> incomingTransactions<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.toAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({
            bool outgoingTransactions,
            bool incomingTransactions,
          })
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> accountId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<AccountGroup> group = const Value.absent(),
                Value<int> openingAmount = const Value.absent(),
                Value<bool> settled = const Value.absent(),
                Value<DateTime?> settledAt = const Value.absent(),
              }) => AccountsCompanion(
                accountId: accountId,
                name: name,
                group: group,
                openingAmount: openingAmount,
                settled: settled,
                settledAt: settledAt,
              ),
          createCompanionCallback:
              ({
                Value<int> accountId = const Value.absent(),
                required String name,
                required AccountGroup group,
                required int openingAmount,
                Value<bool> settled = const Value.absent(),
                Value<DateTime?> settledAt = const Value.absent(),
              }) => AccountsCompanion.insert(
                accountId: accountId,
                name: name,
                group: group,
                openingAmount: openingAmount,
                settled: settled,
                settledAt: settledAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({outgoingTransactions = false, incomingTransactions = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (outgoingTransactions) db.transactions,
                    if (incomingTransactions) db.transactions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (outgoingTransactions)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._outgoingTransactionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).outgoingTransactions,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fromAccountId == item.accountId,
                              ),
                          typedResults: items,
                        ),
                      if (incomingTransactions)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._incomingTransactionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).incomingTransactions,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.toAccountId == item.accountId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({
        bool outgoingTransactions,
        bool incomingTransactions,
      })
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> categoryId,
  required String name,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> categoryId,
  Value<String> name,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SubcategoriesTable, List<Subcategory>>
  _subcategoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.subcategories,
    aliasName: 'categories__category_id__subcategories__category_id',
  );

  $$SubcategoriesTableProcessedTableManager get subcategoriesRefs {
    final manager = $$SubcategoriesTableTableManager($_db, $_db.subcategories)
        .filter(
          (f) => f.categoryId.categoryId.sqlEquals(
            $_itemColumn<int>('category_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_subcategoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'categories__category_id__transactions__category_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter(
          (f) => f.categoryId.categoryId.sqlEquals(
            $_itemColumn<int>('category_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> subcategoriesRefs(
    Expression<bool> Function($$SubcategoriesTableFilterComposer f) f,
  ) {
    final $$SubcategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.subcategories,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubcategoriesTableFilterComposer(
            $db: $db,
            $table: $db.subcategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> subcategoriesRefs<T extends Object>(
    Expression<T> Function($$SubcategoriesTableAnnotationComposer a) f,
  ) {
    final $$SubcategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.subcategories,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubcategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.subcategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({
            bool subcategoriesRefs,
            bool transactionsRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> categoryId = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) => CategoriesCompanion(categoryId: categoryId, name: name),
          createCompanionCallback: ({
            Value<int> categoryId = const Value.absent(),
            required String name,
          }) => CategoriesCompanion.insert(categoryId: categoryId, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({subcategoriesRefs = false, transactionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (subcategoriesRefs) db.subcategories,
                    if (transactionsRefs) db.transactions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (subcategoriesRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Subcategory
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._subcategoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).subcategoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.categoryId,
                              ),
                          typedResults: items,
                        ),
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.categoryId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool subcategoriesRefs, bool transactionsRefs})
    >;
typedef $$SubcategoriesTableCreateCompanionBuilder =
    SubcategoriesCompanion Function({
      Value<int> subcategoryId,
      required int categoryId,
      required String name,
    });
typedef $$SubcategoriesTableUpdateCompanionBuilder =
    SubcategoriesCompanion Function({
      Value<int> subcategoryId,
      Value<int> categoryId,
      Value<String> name,
    });

final class $$SubcategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $SubcategoriesTable, Subcategory> {
  $$SubcategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) => db.categories
      .createAlias('subcategories__category_id__categories__category_id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.categoryId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'subcategories__subcategory_id__transactions__subcategory_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter(
          (f) => f.subcategoryId.subcategoryId.sqlEquals(
            $_itemColumn<int>('subcategory_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SubcategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $SubcategoriesTable> {
  $$SubcategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get subcategoryId => $composableBuilder(
    column: $table.subcategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subcategoryId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.subcategoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubcategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SubcategoriesTable> {
  $$SubcategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get subcategoryId => $composableBuilder(
    column: $table.subcategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubcategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubcategoriesTable> {
  $$SubcategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get subcategoryId => $composableBuilder(
    column: $table.subcategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subcategoryId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.subcategoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubcategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubcategoriesTable,
          Subcategory,
          $$SubcategoriesTableFilterComposer,
          $$SubcategoriesTableOrderingComposer,
          $$SubcategoriesTableAnnotationComposer,
          $$SubcategoriesTableCreateCompanionBuilder,
          $$SubcategoriesTableUpdateCompanionBuilder,
          (Subcategory, $$SubcategoriesTableReferences),
          Subcategory,
          PrefetchHooks Function({bool categoryId, bool transactionsRefs})
        > {
  $$SubcategoriesTableTableManager(_$AppDatabase db, $SubcategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubcategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubcategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubcategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> subcategoryId = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => SubcategoriesCompanion(
                subcategoryId: subcategoryId,
                categoryId: categoryId,
                name: name,
              ),
          createCompanionCallback:
              ({
                Value<int> subcategoryId = const Value.absent(),
                required int categoryId,
                required String name,
              }) => SubcategoriesCompanion.insert(
                subcategoryId: subcategoryId,
                categoryId: categoryId,
                name: name,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SubcategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoryId = false, transactionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$SubcategoriesTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$SubcategoriesTableReferences
                                ._categoryIdTable(db)
                                .categoryId,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          Subcategory,
                          $SubcategoriesTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$SubcategoriesTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SubcategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subcategoryId == item.subcategoryId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SubcategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubcategoriesTable,
      Subcategory,
      $$SubcategoriesTableFilterComposer,
      $$SubcategoriesTableOrderingComposer,
      $$SubcategoriesTableAnnotationComposer,
      $$SubcategoriesTableCreateCompanionBuilder,
      $$SubcategoriesTableUpdateCompanionBuilder,
      (Subcategory, $$SubcategoriesTableReferences),
      Subcategory,
      PrefetchHooks Function({bool categoryId, bool transactionsRefs})
    >;
typedef $$BudgetGroupsTableCreateCompanionBuilder =
    BudgetGroupsCompanion Function({
      Value<int> budgetGroupId,
      required String name,
    });
typedef $$BudgetGroupsTableUpdateCompanionBuilder =
    BudgetGroupsCompanion Function({
      Value<int> budgetGroupId,
      Value<String> name,
    });

final class $$BudgetGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetGroupsTable, BudgetGroup> {
  $$BudgetGroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'budget_groups__budget_group_id__transactions__budget_group_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter(
          (f) => f.budgetGroupId.budgetGroupId.sqlEquals(
            $_itemColumn<int>('budget_group_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetPeriodsTable, List<BudgetPeriod>>
  _budgetPeriodsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.budgetPeriods,
    aliasName:
        'budget_groups__budget_group_id__budget_periods__budget_group_id',
  );

  $$BudgetPeriodsTableProcessedTableManager get budgetPeriodsRefs {
    final manager = $$BudgetPeriodsTableTableManager($_db, $_db.budgetPeriods)
        .filter(
          (f) => f.budgetGroupId.budgetGroupId.sqlEquals(
            $_itemColumn<int>('budget_group_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_budgetPeriodsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BudgetGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetGroupsTable> {
  $$BudgetGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get budgetGroupId => $composableBuilder(
    column: $table.budgetGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetGroupId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.budgetGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetPeriodsRefs(
    Expression<bool> Function($$BudgetPeriodsTableFilterComposer f) f,
  ) {
    final $$BudgetPeriodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetGroupId,
      referencedTable: $db.budgetPeriods,
      getReferencedColumn: (t) => t.budgetGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetPeriodsTableFilterComposer(
            $db: $db,
            $table: $db.budgetPeriods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BudgetGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetGroupsTable> {
  $$BudgetGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get budgetGroupId => $composableBuilder(
    column: $table.budgetGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetGroupsTable> {
  $$BudgetGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get budgetGroupId => $composableBuilder(
    column: $table.budgetGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetGroupId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.budgetGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetPeriodsRefs<T extends Object>(
    Expression<T> Function($$BudgetPeriodsTableAnnotationComposer a) f,
  ) {
    final $$BudgetPeriodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetGroupId,
      referencedTable: $db.budgetPeriods,
      getReferencedColumn: (t) => t.budgetGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetPeriodsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgetPeriods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BudgetGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetGroupsTable,
          BudgetGroup,
          $$BudgetGroupsTableFilterComposer,
          $$BudgetGroupsTableOrderingComposer,
          $$BudgetGroupsTableAnnotationComposer,
          $$BudgetGroupsTableCreateCompanionBuilder,
          $$BudgetGroupsTableUpdateCompanionBuilder,
          (BudgetGroup, $$BudgetGroupsTableReferences),
          BudgetGroup,
          PrefetchHooks Function({
            bool transactionsRefs,
            bool budgetPeriodsRefs,
          })
        > {
  $$BudgetGroupsTableTableManager(_$AppDatabase db, $BudgetGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> budgetGroupId = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) => BudgetGroupsCompanion(budgetGroupId: budgetGroupId, name: name),
          createCompanionCallback:
              ({
                Value<int> budgetGroupId = const Value.absent(),
                required String name,
              }) => BudgetGroupsCompanion.insert(
                budgetGroupId: budgetGroupId,
                name: name,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BudgetGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({transactionsRefs = false, budgetPeriodsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                    if (budgetPeriodsRefs) db.budgetPeriods,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          BudgetGroup,
                          $BudgetGroupsTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$BudgetGroupsTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BudgetGroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.budgetGroupId == item.budgetGroupId,
                              ),
                          typedResults: items,
                        ),
                      if (budgetPeriodsRefs)
                        await $_getPrefetchedData<
                          BudgetGroup,
                          $BudgetGroupsTable,
                          BudgetPeriod
                        >(
                          currentTable: table,
                          referencedTable: $$BudgetGroupsTableReferences
                              ._budgetPeriodsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BudgetGroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetPeriodsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.budgetGroupId == item.budgetGroupId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BudgetGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetGroupsTable,
      BudgetGroup,
      $$BudgetGroupsTableFilterComposer,
      $$BudgetGroupsTableOrderingComposer,
      $$BudgetGroupsTableAnnotationComposer,
      $$BudgetGroupsTableCreateCompanionBuilder,
      $$BudgetGroupsTableUpdateCompanionBuilder,
      (BudgetGroup, $$BudgetGroupsTableReferences),
      BudgetGroup,
      PrefetchHooks Function({bool transactionsRefs, bool budgetPeriodsRefs})
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> transactionId,
      required TransactionKind kind,
      required int amount,
      required DateTime occurredOn,
      Value<int?> fromAccountId,
      Value<int?> toAccountId,
      Value<int?> categoryId,
      Value<int?> subcategoryId,
      Value<int?> budgetGroupId,
      Value<String?> note,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> transactionId,
      Value<TransactionKind> kind,
      Value<int> amount,
      Value<DateTime> occurredOn,
      Value<int?> fromAccountId,
      Value<int?> toAccountId,
      Value<int?> categoryId,
      Value<int?> subcategoryId,
      Value<int?> budgetGroupId,
      Value<String?> note,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _fromAccountIdTable(_$AppDatabase db) => db.accounts
      .createAlias('transactions__from_account_id__accounts__account_id');

  $$AccountsTableProcessedTableManager? get fromAccountId {
    final $_column = $_itemColumn<int>('from_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _toAccountIdTable(_$AppDatabase db) => db.accounts
      .createAlias('transactions__to_account_id__accounts__account_id');

  $$AccountsTableProcessedTableManager? get toAccountId {
    final $_column = $_itemColumn<int>('to_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) => db.categories
      .createAlias('transactions__category_id__categories__category_id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.categoryId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SubcategoriesTable _subcategoryIdTable(_$AppDatabase db) =>
      db.subcategories.createAlias(
        'transactions__subcategory_id__subcategories__subcategory_id',
      );

  $$SubcategoriesTableProcessedTableManager? get subcategoryId {
    final $_column = $_itemColumn<int>('subcategory_id');
    if ($_column == null) return null;
    final manager = $$SubcategoriesTableTableManager(
      $_db,
      $_db.subcategories,
    ).filter((f) => f.subcategoryId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subcategoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BudgetGroupsTable _budgetGroupIdTable(_$AppDatabase db) =>
      db.budgetGroups.createAlias(
        'transactions__budget_group_id__budget_groups__budget_group_id',
      );

  $$BudgetGroupsTableProcessedTableManager? get budgetGroupId {
    final $_column = $_itemColumn<int>('budget_group_id');
    if ($_column == null) return null;
    final manager = $$BudgetGroupsTableTableManager(
      $_db,
      $_db.budgetGroups,
    ).filter((f) => f.budgetGroupId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_budgetGroupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionKind, TransactionKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredOn => $composableBuilder(
    column: $table.occurredOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get fromAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get toAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubcategoriesTableFilterComposer get subcategoryId {
    final $$SubcategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subcategoryId,
      referencedTable: $db.subcategories,
      getReferencedColumn: (t) => t.subcategoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubcategoriesTableFilterComposer(
            $db: $db,
            $table: $db.subcategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BudgetGroupsTableFilterComposer get budgetGroupId {
    final $$BudgetGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetGroupId,
      referencedTable: $db.budgetGroups,
      getReferencedColumn: (t) => t.budgetGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetGroupsTableFilterComposer(
            $db: $db,
            $table: $db.budgetGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredOn => $composableBuilder(
    column: $table.occurredOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get fromAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get toAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubcategoriesTableOrderingComposer get subcategoryId {
    final $$SubcategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subcategoryId,
      referencedTable: $db.subcategories,
      getReferencedColumn: (t) => t.subcategoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubcategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.subcategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BudgetGroupsTableOrderingComposer get budgetGroupId {
    final $$BudgetGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetGroupId,
      referencedTable: $db.budgetGroups,
      getReferencedColumn: (t) => t.budgetGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.budgetGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TransactionKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredOn => $composableBuilder(
    column: $table.occurredOn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$AccountsTableAnnotationComposer get fromAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get toAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubcategoriesTableAnnotationComposer get subcategoryId {
    final $$SubcategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subcategoryId,
      referencedTable: $db.subcategories,
      getReferencedColumn: (t) => t.subcategoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubcategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.subcategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BudgetGroupsTableAnnotationComposer get budgetGroupId {
    final $$BudgetGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetGroupId,
      referencedTable: $db.budgetGroups,
      getReferencedColumn: (t) => t.budgetGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgetGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (Transaction, $$TransactionsTableReferences),
          Transaction,
          PrefetchHooks Function({
            bool fromAccountId,
            bool toAccountId,
            bool categoryId,
            bool subcategoryId,
            bool budgetGroupId,
          })
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> transactionId = const Value.absent(),
                Value<TransactionKind> kind = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<DateTime> occurredOn = const Value.absent(),
                Value<int?> fromAccountId = const Value.absent(),
                Value<int?> toAccountId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> subcategoryId = const Value.absent(),
                Value<int?> budgetGroupId = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => TransactionsCompanion(
                transactionId: transactionId,
                kind: kind,
                amount: amount,
                occurredOn: occurredOn,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
                subcategoryId: subcategoryId,
                budgetGroupId: budgetGroupId,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> transactionId = const Value.absent(),
                required TransactionKind kind,
                required int amount,
                required DateTime occurredOn,
                Value<int?> fromAccountId = const Value.absent(),
                Value<int?> toAccountId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> subcategoryId = const Value.absent(),
                Value<int?> budgetGroupId = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => TransactionsCompanion.insert(
                transactionId: transactionId,
                kind: kind,
                amount: amount,
                occurredOn: occurredOn,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
                subcategoryId: subcategoryId,
                budgetGroupId: budgetGroupId,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                fromAccountId = false,
                toAccountId = false,
                categoryId = false,
                subcategoryId = false,
                budgetGroupId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (fromAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.fromAccountId,
                            referencedTable: $$TransactionsTableReferences
                                ._fromAccountIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._fromAccountIdTable(db)
                                .accountId,
                          ) as T;
                        }
                        if (toAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.toAccountId,
                            referencedTable: $$TransactionsTableReferences
                                ._toAccountIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._toAccountIdTable(db)
                                .accountId,
                          ) as T;
                        }
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$TransactionsTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._categoryIdTable(db)
                                .categoryId,
                          ) as T;
                        }
                        if (subcategoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.subcategoryId,
                            referencedTable: $$TransactionsTableReferences
                                ._subcategoryIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._subcategoryIdTable(db)
                                .subcategoryId,
                          ) as T;
                        }
                        if (budgetGroupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.budgetGroupId,
                            referencedTable: $$TransactionsTableReferences
                                ._budgetGroupIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._budgetGroupIdTable(db)
                                .budgetGroupId,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Transaction, $$TransactionsTableReferences),
      Transaction,
      PrefetchHooks Function({
        bool fromAccountId,
        bool toAccountId,
        bool categoryId,
        bool subcategoryId,
        bool budgetGroupId,
      })
    >;
typedef $$BudgetPeriodsTableCreateCompanionBuilder =
    BudgetPeriodsCompanion Function({
      Value<int> budgetPeriodId,
      required int budgetGroupId,
      required DateTime startsOn,
      required DateTime endsOn,
      required int amount,
    });
typedef $$BudgetPeriodsTableUpdateCompanionBuilder =
    BudgetPeriodsCompanion Function({
      Value<int> budgetPeriodId,
      Value<int> budgetGroupId,
      Value<DateTime> startsOn,
      Value<DateTime> endsOn,
      Value<int> amount,
    });

final class $$BudgetPeriodsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetPeriodsTable, BudgetPeriod> {
  $$BudgetPeriodsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BudgetGroupsTable _budgetGroupIdTable(_$AppDatabase db) =>
      db.budgetGroups.createAlias(
        'budget_periods__budget_group_id__budget_groups__budget_group_id',
      );

  $$BudgetGroupsTableProcessedTableManager get budgetGroupId {
    final $_column = $_itemColumn<int>('budget_group_id')!;

    final manager = $$BudgetGroupsTableTableManager(
      $_db,
      $_db.budgetGroups,
    ).filter((f) => f.budgetGroupId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_budgetGroupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetPeriodsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetPeriodsTable> {
  $$BudgetPeriodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get budgetPeriodId => $composableBuilder(
    column: $table.budgetPeriodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startsOn => $composableBuilder(
    column: $table.startsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  $$BudgetGroupsTableFilterComposer get budgetGroupId {
    final $$BudgetGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetGroupId,
      referencedTable: $db.budgetGroups,
      getReferencedColumn: (t) => t.budgetGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetGroupsTableFilterComposer(
            $db: $db,
            $table: $db.budgetGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetPeriodsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetPeriodsTable> {
  $$BudgetPeriodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get budgetPeriodId => $composableBuilder(
    column: $table.budgetPeriodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startsOn => $composableBuilder(
    column: $table.startsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  $$BudgetGroupsTableOrderingComposer get budgetGroupId {
    final $$BudgetGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetGroupId,
      referencedTable: $db.budgetGroups,
      getReferencedColumn: (t) => t.budgetGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.budgetGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetPeriodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetPeriodsTable> {
  $$BudgetPeriodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get budgetPeriodId => $composableBuilder(
    column: $table.budgetPeriodId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startsOn =>
      $composableBuilder(column: $table.startsOn, builder: (column) => column);

  GeneratedColumn<DateTime> get endsOn =>
      $composableBuilder(column: $table.endsOn, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  $$BudgetGroupsTableAnnotationComposer get budgetGroupId {
    final $$BudgetGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetGroupId,
      referencedTable: $db.budgetGroups,
      getReferencedColumn: (t) => t.budgetGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgetGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetPeriodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetPeriodsTable,
          BudgetPeriod,
          $$BudgetPeriodsTableFilterComposer,
          $$BudgetPeriodsTableOrderingComposer,
          $$BudgetPeriodsTableAnnotationComposer,
          $$BudgetPeriodsTableCreateCompanionBuilder,
          $$BudgetPeriodsTableUpdateCompanionBuilder,
          (BudgetPeriod, $$BudgetPeriodsTableReferences),
          BudgetPeriod,
          PrefetchHooks Function({bool budgetGroupId})
        > {
  $$BudgetPeriodsTableTableManager(_$AppDatabase db, $BudgetPeriodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetPeriodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetPeriodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetPeriodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> budgetPeriodId = const Value.absent(),
                Value<int> budgetGroupId = const Value.absent(),
                Value<DateTime> startsOn = const Value.absent(),
                Value<DateTime> endsOn = const Value.absent(),
                Value<int> amount = const Value.absent(),
              }) => BudgetPeriodsCompanion(
                budgetPeriodId: budgetPeriodId,
                budgetGroupId: budgetGroupId,
                startsOn: startsOn,
                endsOn: endsOn,
                amount: amount,
              ),
          createCompanionCallback:
              ({
                Value<int> budgetPeriodId = const Value.absent(),
                required int budgetGroupId,
                required DateTime startsOn,
                required DateTime endsOn,
                required int amount,
              }) => BudgetPeriodsCompanion.insert(
                budgetPeriodId: budgetPeriodId,
                budgetGroupId: budgetGroupId,
                startsOn: startsOn,
                endsOn: endsOn,
                amount: amount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BudgetPeriodsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({budgetGroupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (budgetGroupId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.budgetGroupId,
                        referencedTable: $$BudgetPeriodsTableReferences
                            ._budgetGroupIdTable(db),
                        referencedColumn: $$BudgetPeriodsTableReferences
                            ._budgetGroupIdTable(db)
                            .budgetGroupId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BudgetPeriodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetPeriodsTable,
      BudgetPeriod,
      $$BudgetPeriodsTableFilterComposer,
      $$BudgetPeriodsTableOrderingComposer,
      $$BudgetPeriodsTableAnnotationComposer,
      $$BudgetPeriodsTableCreateCompanionBuilder,
      $$BudgetPeriodsTableUpdateCompanionBuilder,
      (BudgetPeriod, $$BudgetPeriodsTableReferences),
      BudgetPeriod,
      PrefetchHooks Function({bool budgetGroupId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> settingsId,
  required Currency currency,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> settingsId,
  Value<Currency> currency,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get settingsId => $composableBuilder(
    column: $table.settingsId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Currency, Currency, String> get currency =>
      $composableBuilder(
        column: $table.currency,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get settingsId => $composableBuilder(
    column: $table.settingsId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get settingsId => $composableBuilder(
    column: $table.settingsId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Currency, String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> settingsId = const Value.absent(),
            Value<Currency> currency = const Value.absent(),
          }) => SettingsCompanion(settingsId: settingsId, currency: currency),
          createCompanionCallback:
              ({
                Value<int> settingsId = const Value.absent(),
                required Currency currency,
              }) => SettingsCompanion.insert(
                settingsId: settingsId,
                currency: currency,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$SubcategoriesTableTableManager get subcategories =>
      $$SubcategoriesTableTableManager(_db, _db.subcategories);
  $$BudgetGroupsTableTableManager get budgetGroups =>
      $$BudgetGroupsTableTableManager(_db, _db.budgetGroups);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$BudgetPeriodsTableTableManager get budgetPeriods =>
      $$BudgetPeriodsTableTableManager(_db, _db.budgetPeriods);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
