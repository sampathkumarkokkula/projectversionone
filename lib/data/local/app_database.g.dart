// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ChatsTable extends Chats with TableInfo<$ChatsTable, Chat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<String> peerId = GeneratedColumn<String>(
    'peer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerUsernameMeta = const VerificationMeta(
    'peerUsername',
  );
  @override
  late final GeneratedColumn<String> peerUsername = GeneratedColumn<String>(
    'peer_username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerIdentityKeyMeta = const VerificationMeta(
    'peerIdentityKey',
  );
  @override
  late final GeneratedColumn<String> peerIdentityKey = GeneratedColumn<String>(
    'peer_identity_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerSigningKeyMeta = const VerificationMeta(
    'peerSigningKey',
  );
  @override
  late final GeneratedColumn<String> peerSigningKey = GeneratedColumn<String>(
    'peer_signing_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timerSecondsMeta = const VerificationMeta(
    'timerSeconds',
  );
  @override
  late final GeneratedColumn<int> timerSeconds = GeneratedColumn<int>(
    'timer_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timerChangedAtMeta = const VerificationMeta(
    'timerChangedAt',
  );
  @override
  late final GeneratedColumn<int> timerChangedAt = GeneratedColumn<int>(
    'timer_changed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wipedBeforeMeta = const VerificationMeta(
    'wipedBefore',
  );
  @override
  late final GeneratedColumn<int> wipedBefore = GeneratedColumn<int>(
    'wiped_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastActivityAtMeta = const VerificationMeta(
    'lastActivityAt',
  );
  @override
  late final GeneratedColumn<int> lastActivityAt = GeneratedColumn<int>(
    'last_activity_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockedMeta = const VerificationMeta(
    'blocked',
  );
  @override
  late final GeneratedColumn<bool> blocked = GeneratedColumn<bool>(
    'blocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("blocked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _acceptedMeta = const VerificationMeta(
    'accepted',
  );
  @override
  late final GeneratedColumn<bool> accepted = GeneratedColumn<bool>(
    'accepted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("accepted" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _profileSentVersionMeta =
      const VerificationMeta('profileSentVersion');
  @override
  late final GeneratedColumn<int> profileSentVersion = GeneratedColumn<int>(
    'profile_sent_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _refreshProfileMeta = const VerificationMeta(
    'refreshProfile',
  );
  @override
  late final GeneratedColumn<bool> refreshProfile = GeneratedColumn<bool>(
    'refresh_profile',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("refresh_profile" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _directoryCheckedAtMeta =
      const VerificationMeta('directoryCheckedAt');
  @override
  late final GeneratedColumn<int> directoryCheckedAt = GeneratedColumn<int>(
    'directory_checked_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    peerId,
    peerUsername,
    peerIdentityKey,
    peerSigningKey,
    timerSeconds,
    timerChangedAt,
    wipedBefore,
    createdAt,
    lastActivityAt,
    blocked,
    accepted,
    profileSentVersion,
    refreshProfile,
    directoryCheckedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<Chat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('peer_id')) {
      context.handle(
        _peerIdMeta,
        peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_peerIdMeta);
    }
    if (data.containsKey('peer_username')) {
      context.handle(
        _peerUsernameMeta,
        peerUsername.isAcceptableOrUnknown(
          data['peer_username']!,
          _peerUsernameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerUsernameMeta);
    }
    if (data.containsKey('peer_identity_key')) {
      context.handle(
        _peerIdentityKeyMeta,
        peerIdentityKey.isAcceptableOrUnknown(
          data['peer_identity_key']!,
          _peerIdentityKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerIdentityKeyMeta);
    }
    if (data.containsKey('peer_signing_key')) {
      context.handle(
        _peerSigningKeyMeta,
        peerSigningKey.isAcceptableOrUnknown(
          data['peer_signing_key']!,
          _peerSigningKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerSigningKeyMeta);
    }
    if (data.containsKey('timer_seconds')) {
      context.handle(
        _timerSecondsMeta,
        timerSeconds.isAcceptableOrUnknown(
          data['timer_seconds']!,
          _timerSecondsMeta,
        ),
      );
    }
    if (data.containsKey('timer_changed_at')) {
      context.handle(
        _timerChangedAtMeta,
        timerChangedAt.isAcceptableOrUnknown(
          data['timer_changed_at']!,
          _timerChangedAtMeta,
        ),
      );
    }
    if (data.containsKey('wiped_before')) {
      context.handle(
        _wipedBeforeMeta,
        wipedBefore.isAcceptableOrUnknown(
          data['wiped_before']!,
          _wipedBeforeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_activity_at')) {
      context.handle(
        _lastActivityAtMeta,
        lastActivityAt.isAcceptableOrUnknown(
          data['last_activity_at']!,
          _lastActivityAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastActivityAtMeta);
    }
    if (data.containsKey('blocked')) {
      context.handle(
        _blockedMeta,
        blocked.isAcceptableOrUnknown(data['blocked']!, _blockedMeta),
      );
    }
    if (data.containsKey('accepted')) {
      context.handle(
        _acceptedMeta,
        accepted.isAcceptableOrUnknown(data['accepted']!, _acceptedMeta),
      );
    }
    if (data.containsKey('profile_sent_version')) {
      context.handle(
        _profileSentVersionMeta,
        profileSentVersion.isAcceptableOrUnknown(
          data['profile_sent_version']!,
          _profileSentVersionMeta,
        ),
      );
    }
    if (data.containsKey('refresh_profile')) {
      context.handle(
        _refreshProfileMeta,
        refreshProfile.isAcceptableOrUnknown(
          data['refresh_profile']!,
          _refreshProfileMeta,
        ),
      );
    }
    if (data.containsKey('directory_checked_at')) {
      context.handle(
        _directoryCheckedAtMeta,
        directoryCheckedAt.isAcceptableOrUnknown(
          data['directory_checked_at']!,
          _directoryCheckedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {peerId};
  @override
  Chat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chat(
      peerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_id'],
      )!,
      peerUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_username'],
      )!,
      peerIdentityKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_identity_key'],
      )!,
      peerSigningKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_signing_key'],
      )!,
      timerSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timer_seconds'],
      ),
      timerChangedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timer_changed_at'],
      )!,
      wipedBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wiped_before'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastActivityAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_activity_at'],
      )!,
      blocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}blocked'],
      )!,
      accepted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}accepted'],
      )!,
      profileSentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_sent_version'],
      )!,
      refreshProfile: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}refresh_profile'],
      )!,
      directoryCheckedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}directory_checked_at'],
      )!,
    );
  }

  @override
  $ChatsTable createAlias(String alias) {
    return $ChatsTable(attachedDatabase, alias);
  }
}

class Chat extends DataClass implements Insertable<Chat> {
  final String peerId;
  final String peerUsername;

  /// Pinned (trust-on-first-use) identity keys of the peer.
  final String peerIdentityKey;
  final String peerSigningKey;

  /// Auto-delete timer in seconds; null = off.
  final int? timerSeconds;
  final int timerChangedAt;

  /// Messages sent at or before this time are dropped if they arrive late
  /// (set by a wipe).
  final int? wipedBefore;
  final int createdAt;
  final int lastActivityAt;

  /// Blocked by this user (also enforced on the server).
  final bool blocked;

  /// False for a chat someone else started ("message request") until this
  /// user accepts or replies. No receipts and no profile picture go to a
  /// request.
  final bool accepted;

  /// Own profile version last sent to this peer.
  final int profileSentVersion;

  /// The peer announced a profile change; re-read their username.
  final bool refreshProfile;

  /// Last time the peer's username was checked against the directory.
  final int directoryCheckedAt;
  const Chat({
    required this.peerId,
    required this.peerUsername,
    required this.peerIdentityKey,
    required this.peerSigningKey,
    this.timerSeconds,
    required this.timerChangedAt,
    this.wipedBefore,
    required this.createdAt,
    required this.lastActivityAt,
    required this.blocked,
    required this.accepted,
    required this.profileSentVersion,
    required this.refreshProfile,
    required this.directoryCheckedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['peer_id'] = Variable<String>(peerId);
    map['peer_username'] = Variable<String>(peerUsername);
    map['peer_identity_key'] = Variable<String>(peerIdentityKey);
    map['peer_signing_key'] = Variable<String>(peerSigningKey);
    if (!nullToAbsent || timerSeconds != null) {
      map['timer_seconds'] = Variable<int>(timerSeconds);
    }
    map['timer_changed_at'] = Variable<int>(timerChangedAt);
    if (!nullToAbsent || wipedBefore != null) {
      map['wiped_before'] = Variable<int>(wipedBefore);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['last_activity_at'] = Variable<int>(lastActivityAt);
    map['blocked'] = Variable<bool>(blocked);
    map['accepted'] = Variable<bool>(accepted);
    map['profile_sent_version'] = Variable<int>(profileSentVersion);
    map['refresh_profile'] = Variable<bool>(refreshProfile);
    map['directory_checked_at'] = Variable<int>(directoryCheckedAt);
    return map;
  }

  ChatsCompanion toCompanion(bool nullToAbsent) {
    return ChatsCompanion(
      peerId: Value(peerId),
      peerUsername: Value(peerUsername),
      peerIdentityKey: Value(peerIdentityKey),
      peerSigningKey: Value(peerSigningKey),
      timerSeconds: timerSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(timerSeconds),
      timerChangedAt: Value(timerChangedAt),
      wipedBefore: wipedBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(wipedBefore),
      createdAt: Value(createdAt),
      lastActivityAt: Value(lastActivityAt),
      blocked: Value(blocked),
      accepted: Value(accepted),
      profileSentVersion: Value(profileSentVersion),
      refreshProfile: Value(refreshProfile),
      directoryCheckedAt: Value(directoryCheckedAt),
    );
  }

  factory Chat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chat(
      peerId: serializer.fromJson<String>(json['peerId']),
      peerUsername: serializer.fromJson<String>(json['peerUsername']),
      peerIdentityKey: serializer.fromJson<String>(json['peerIdentityKey']),
      peerSigningKey: serializer.fromJson<String>(json['peerSigningKey']),
      timerSeconds: serializer.fromJson<int?>(json['timerSeconds']),
      timerChangedAt: serializer.fromJson<int>(json['timerChangedAt']),
      wipedBefore: serializer.fromJson<int?>(json['wipedBefore']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastActivityAt: serializer.fromJson<int>(json['lastActivityAt']),
      blocked: serializer.fromJson<bool>(json['blocked']),
      accepted: serializer.fromJson<bool>(json['accepted']),
      profileSentVersion: serializer.fromJson<int>(json['profileSentVersion']),
      refreshProfile: serializer.fromJson<bool>(json['refreshProfile']),
      directoryCheckedAt: serializer.fromJson<int>(json['directoryCheckedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'peerId': serializer.toJson<String>(peerId),
      'peerUsername': serializer.toJson<String>(peerUsername),
      'peerIdentityKey': serializer.toJson<String>(peerIdentityKey),
      'peerSigningKey': serializer.toJson<String>(peerSigningKey),
      'timerSeconds': serializer.toJson<int?>(timerSeconds),
      'timerChangedAt': serializer.toJson<int>(timerChangedAt),
      'wipedBefore': serializer.toJson<int?>(wipedBefore),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastActivityAt': serializer.toJson<int>(lastActivityAt),
      'blocked': serializer.toJson<bool>(blocked),
      'accepted': serializer.toJson<bool>(accepted),
      'profileSentVersion': serializer.toJson<int>(profileSentVersion),
      'refreshProfile': serializer.toJson<bool>(refreshProfile),
      'directoryCheckedAt': serializer.toJson<int>(directoryCheckedAt),
    };
  }

  Chat copyWith({
    String? peerId,
    String? peerUsername,
    String? peerIdentityKey,
    String? peerSigningKey,
    Value<int?> timerSeconds = const Value.absent(),
    int? timerChangedAt,
    Value<int?> wipedBefore = const Value.absent(),
    int? createdAt,
    int? lastActivityAt,
    bool? blocked,
    bool? accepted,
    int? profileSentVersion,
    bool? refreshProfile,
    int? directoryCheckedAt,
  }) => Chat(
    peerId: peerId ?? this.peerId,
    peerUsername: peerUsername ?? this.peerUsername,
    peerIdentityKey: peerIdentityKey ?? this.peerIdentityKey,
    peerSigningKey: peerSigningKey ?? this.peerSigningKey,
    timerSeconds: timerSeconds.present ? timerSeconds.value : this.timerSeconds,
    timerChangedAt: timerChangedAt ?? this.timerChangedAt,
    wipedBefore: wipedBefore.present ? wipedBefore.value : this.wipedBefore,
    createdAt: createdAt ?? this.createdAt,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    blocked: blocked ?? this.blocked,
    accepted: accepted ?? this.accepted,
    profileSentVersion: profileSentVersion ?? this.profileSentVersion,
    refreshProfile: refreshProfile ?? this.refreshProfile,
    directoryCheckedAt: directoryCheckedAt ?? this.directoryCheckedAt,
  );
  Chat copyWithCompanion(ChatsCompanion data) {
    return Chat(
      peerId: data.peerId.present ? data.peerId.value : this.peerId,
      peerUsername: data.peerUsername.present
          ? data.peerUsername.value
          : this.peerUsername,
      peerIdentityKey: data.peerIdentityKey.present
          ? data.peerIdentityKey.value
          : this.peerIdentityKey,
      peerSigningKey: data.peerSigningKey.present
          ? data.peerSigningKey.value
          : this.peerSigningKey,
      timerSeconds: data.timerSeconds.present
          ? data.timerSeconds.value
          : this.timerSeconds,
      timerChangedAt: data.timerChangedAt.present
          ? data.timerChangedAt.value
          : this.timerChangedAt,
      wipedBefore: data.wipedBefore.present
          ? data.wipedBefore.value
          : this.wipedBefore,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastActivityAt: data.lastActivityAt.present
          ? data.lastActivityAt.value
          : this.lastActivityAt,
      blocked: data.blocked.present ? data.blocked.value : this.blocked,
      accepted: data.accepted.present ? data.accepted.value : this.accepted,
      profileSentVersion: data.profileSentVersion.present
          ? data.profileSentVersion.value
          : this.profileSentVersion,
      refreshProfile: data.refreshProfile.present
          ? data.refreshProfile.value
          : this.refreshProfile,
      directoryCheckedAt: data.directoryCheckedAt.present
          ? data.directoryCheckedAt.value
          : this.directoryCheckedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chat(')
          ..write('peerId: $peerId, ')
          ..write('peerUsername: $peerUsername, ')
          ..write('peerIdentityKey: $peerIdentityKey, ')
          ..write('peerSigningKey: $peerSigningKey, ')
          ..write('timerSeconds: $timerSeconds, ')
          ..write('timerChangedAt: $timerChangedAt, ')
          ..write('wipedBefore: $wipedBefore, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastActivityAt: $lastActivityAt, ')
          ..write('blocked: $blocked, ')
          ..write('accepted: $accepted, ')
          ..write('profileSentVersion: $profileSentVersion, ')
          ..write('refreshProfile: $refreshProfile, ')
          ..write('directoryCheckedAt: $directoryCheckedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    peerId,
    peerUsername,
    peerIdentityKey,
    peerSigningKey,
    timerSeconds,
    timerChangedAt,
    wipedBefore,
    createdAt,
    lastActivityAt,
    blocked,
    accepted,
    profileSentVersion,
    refreshProfile,
    directoryCheckedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chat &&
          other.peerId == this.peerId &&
          other.peerUsername == this.peerUsername &&
          other.peerIdentityKey == this.peerIdentityKey &&
          other.peerSigningKey == this.peerSigningKey &&
          other.timerSeconds == this.timerSeconds &&
          other.timerChangedAt == this.timerChangedAt &&
          other.wipedBefore == this.wipedBefore &&
          other.createdAt == this.createdAt &&
          other.lastActivityAt == this.lastActivityAt &&
          other.blocked == this.blocked &&
          other.accepted == this.accepted &&
          other.profileSentVersion == this.profileSentVersion &&
          other.refreshProfile == this.refreshProfile &&
          other.directoryCheckedAt == this.directoryCheckedAt);
}

class ChatsCompanion extends UpdateCompanion<Chat> {
  final Value<String> peerId;
  final Value<String> peerUsername;
  final Value<String> peerIdentityKey;
  final Value<String> peerSigningKey;
  final Value<int?> timerSeconds;
  final Value<int> timerChangedAt;
  final Value<int?> wipedBefore;
  final Value<int> createdAt;
  final Value<int> lastActivityAt;
  final Value<bool> blocked;
  final Value<bool> accepted;
  final Value<int> profileSentVersion;
  final Value<bool> refreshProfile;
  final Value<int> directoryCheckedAt;
  final Value<int> rowid;
  const ChatsCompanion({
    this.peerId = const Value.absent(),
    this.peerUsername = const Value.absent(),
    this.peerIdentityKey = const Value.absent(),
    this.peerSigningKey = const Value.absent(),
    this.timerSeconds = const Value.absent(),
    this.timerChangedAt = const Value.absent(),
    this.wipedBefore = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastActivityAt = const Value.absent(),
    this.blocked = const Value.absent(),
    this.accepted = const Value.absent(),
    this.profileSentVersion = const Value.absent(),
    this.refreshProfile = const Value.absent(),
    this.directoryCheckedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatsCompanion.insert({
    required String peerId,
    required String peerUsername,
    required String peerIdentityKey,
    required String peerSigningKey,
    this.timerSeconds = const Value.absent(),
    this.timerChangedAt = const Value.absent(),
    this.wipedBefore = const Value.absent(),
    required int createdAt,
    required int lastActivityAt,
    this.blocked = const Value.absent(),
    this.accepted = const Value.absent(),
    this.profileSentVersion = const Value.absent(),
    this.refreshProfile = const Value.absent(),
    this.directoryCheckedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : peerId = Value(peerId),
       peerUsername = Value(peerUsername),
       peerIdentityKey = Value(peerIdentityKey),
       peerSigningKey = Value(peerSigningKey),
       createdAt = Value(createdAt),
       lastActivityAt = Value(lastActivityAt);
  static Insertable<Chat> custom({
    Expression<String>? peerId,
    Expression<String>? peerUsername,
    Expression<String>? peerIdentityKey,
    Expression<String>? peerSigningKey,
    Expression<int>? timerSeconds,
    Expression<int>? timerChangedAt,
    Expression<int>? wipedBefore,
    Expression<int>? createdAt,
    Expression<int>? lastActivityAt,
    Expression<bool>? blocked,
    Expression<bool>? accepted,
    Expression<int>? profileSentVersion,
    Expression<bool>? refreshProfile,
    Expression<int>? directoryCheckedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (peerId != null) 'peer_id': peerId,
      if (peerUsername != null) 'peer_username': peerUsername,
      if (peerIdentityKey != null) 'peer_identity_key': peerIdentityKey,
      if (peerSigningKey != null) 'peer_signing_key': peerSigningKey,
      if (timerSeconds != null) 'timer_seconds': timerSeconds,
      if (timerChangedAt != null) 'timer_changed_at': timerChangedAt,
      if (wipedBefore != null) 'wiped_before': wipedBefore,
      if (createdAt != null) 'created_at': createdAt,
      if (lastActivityAt != null) 'last_activity_at': lastActivityAt,
      if (blocked != null) 'blocked': blocked,
      if (accepted != null) 'accepted': accepted,
      if (profileSentVersion != null)
        'profile_sent_version': profileSentVersion,
      if (refreshProfile != null) 'refresh_profile': refreshProfile,
      if (directoryCheckedAt != null)
        'directory_checked_at': directoryCheckedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatsCompanion copyWith({
    Value<String>? peerId,
    Value<String>? peerUsername,
    Value<String>? peerIdentityKey,
    Value<String>? peerSigningKey,
    Value<int?>? timerSeconds,
    Value<int>? timerChangedAt,
    Value<int?>? wipedBefore,
    Value<int>? createdAt,
    Value<int>? lastActivityAt,
    Value<bool>? blocked,
    Value<bool>? accepted,
    Value<int>? profileSentVersion,
    Value<bool>? refreshProfile,
    Value<int>? directoryCheckedAt,
    Value<int>? rowid,
  }) {
    return ChatsCompanion(
      peerId: peerId ?? this.peerId,
      peerUsername: peerUsername ?? this.peerUsername,
      peerIdentityKey: peerIdentityKey ?? this.peerIdentityKey,
      peerSigningKey: peerSigningKey ?? this.peerSigningKey,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      timerChangedAt: timerChangedAt ?? this.timerChangedAt,
      wipedBefore: wipedBefore ?? this.wipedBefore,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      blocked: blocked ?? this.blocked,
      accepted: accepted ?? this.accepted,
      profileSentVersion: profileSentVersion ?? this.profileSentVersion,
      refreshProfile: refreshProfile ?? this.refreshProfile,
      directoryCheckedAt: directoryCheckedAt ?? this.directoryCheckedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (peerId.present) {
      map['peer_id'] = Variable<String>(peerId.value);
    }
    if (peerUsername.present) {
      map['peer_username'] = Variable<String>(peerUsername.value);
    }
    if (peerIdentityKey.present) {
      map['peer_identity_key'] = Variable<String>(peerIdentityKey.value);
    }
    if (peerSigningKey.present) {
      map['peer_signing_key'] = Variable<String>(peerSigningKey.value);
    }
    if (timerSeconds.present) {
      map['timer_seconds'] = Variable<int>(timerSeconds.value);
    }
    if (timerChangedAt.present) {
      map['timer_changed_at'] = Variable<int>(timerChangedAt.value);
    }
    if (wipedBefore.present) {
      map['wiped_before'] = Variable<int>(wipedBefore.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastActivityAt.present) {
      map['last_activity_at'] = Variable<int>(lastActivityAt.value);
    }
    if (blocked.present) {
      map['blocked'] = Variable<bool>(blocked.value);
    }
    if (accepted.present) {
      map['accepted'] = Variable<bool>(accepted.value);
    }
    if (profileSentVersion.present) {
      map['profile_sent_version'] = Variable<int>(profileSentVersion.value);
    }
    if (refreshProfile.present) {
      map['refresh_profile'] = Variable<bool>(refreshProfile.value);
    }
    if (directoryCheckedAt.present) {
      map['directory_checked_at'] = Variable<int>(directoryCheckedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatsCompanion(')
          ..write('peerId: $peerId, ')
          ..write('peerUsername: $peerUsername, ')
          ..write('peerIdentityKey: $peerIdentityKey, ')
          ..write('peerSigningKey: $peerSigningKey, ')
          ..write('timerSeconds: $timerSeconds, ')
          ..write('timerChangedAt: $timerChangedAt, ')
          ..write('wipedBefore: $wipedBefore, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastActivityAt: $lastActivityAt, ')
          ..write('blocked: $blocked, ')
          ..write('accepted: $accepted, ')
          ..write('profileSentVersion: $profileSentVersion, ')
          ..write('refreshProfile: $refreshProfile, ')
          ..write('directoryCheckedAt: $directoryCheckedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chats (peer_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fromMeMeta = const VerificationMeta('fromMe');
  @override
  late final GeneratedColumn<bool> fromMe = GeneratedColumn<bool>(
    'from_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("from_me" IN (0, 1))',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<int> sentAt = GeneratedColumn<int>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localAtMeta = const VerificationMeta(
    'localAt',
  );
  @override
  late final GeneratedColumn<int> localAt = GeneratedColumn<int>(
    'local_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replyToMeta = const VerificationMeta(
    'replyTo',
  );
  @override
  late final GeneratedColumn<String> replyTo = GeneratedColumn<String>(
    'reply_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    chatId,
    fromMe,
    kind,
    body,
    sentAt,
    localAt,
    expiresAt,
    status,
    replyTo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('from_me')) {
      context.handle(
        _fromMeMeta,
        fromMe.isAcceptableOrUnknown(data['from_me']!, _fromMeMeta),
      );
    } else if (isInserting) {
      context.missing(_fromMeMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('local_at')) {
      context.handle(
        _localAtMeta,
        localAt.isAcceptableOrUnknown(data['local_at']!, _localAtMeta),
      );
    } else if (isInserting) {
      context.missing(_localAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('reply_to')) {
      context.handle(
        _replyToMeta,
        replyTo.isAcceptableOrUnknown(data['reply_to']!, _replyToMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      )!,
      fromMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}from_me'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_at'],
      )!,
      localAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      replyTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String id;
  final String chatId;
  final bool fromMe;

  /// [MessageKind] name.
  final String kind;
  final String body;

  /// Sender's clock.
  final int sentAt;

  /// This device's clock when the row was created (display order).
  final int localAt;

  /// When the auto-delete sweep removes the message; null = never.
  final int? expiresAt;

  /// [MessageStatus] name.
  final String status;

  /// Id of the message this one replies to (schema v2).
  final String? replyTo;
  const Message({
    required this.id,
    required this.chatId,
    required this.fromMe,
    required this.kind,
    required this.body,
    required this.sentAt,
    required this.localAt,
    this.expiresAt,
    required this.status,
    this.replyTo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chat_id'] = Variable<String>(chatId);
    map['from_me'] = Variable<bool>(fromMe);
    map['kind'] = Variable<String>(kind);
    map['body'] = Variable<String>(body);
    map['sent_at'] = Variable<int>(sentAt);
    map['local_at'] = Variable<int>(localAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<int>(expiresAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || replyTo != null) {
      map['reply_to'] = Variable<String>(replyTo);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      chatId: Value(chatId),
      fromMe: Value(fromMe),
      kind: Value(kind),
      body: Value(body),
      sentAt: Value(sentAt),
      localAt: Value(localAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      status: Value(status),
      replyTo: replyTo == null && nullToAbsent
          ? const Value.absent()
          : Value(replyTo),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<String>(json['id']),
      chatId: serializer.fromJson<String>(json['chatId']),
      fromMe: serializer.fromJson<bool>(json['fromMe']),
      kind: serializer.fromJson<String>(json['kind']),
      body: serializer.fromJson<String>(json['body']),
      sentAt: serializer.fromJson<int>(json['sentAt']),
      localAt: serializer.fromJson<int>(json['localAt']),
      expiresAt: serializer.fromJson<int?>(json['expiresAt']),
      status: serializer.fromJson<String>(json['status']),
      replyTo: serializer.fromJson<String?>(json['replyTo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chatId': serializer.toJson<String>(chatId),
      'fromMe': serializer.toJson<bool>(fromMe),
      'kind': serializer.toJson<String>(kind),
      'body': serializer.toJson<String>(body),
      'sentAt': serializer.toJson<int>(sentAt),
      'localAt': serializer.toJson<int>(localAt),
      'expiresAt': serializer.toJson<int?>(expiresAt),
      'status': serializer.toJson<String>(status),
      'replyTo': serializer.toJson<String?>(replyTo),
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    bool? fromMe,
    String? kind,
    String? body,
    int? sentAt,
    int? localAt,
    Value<int?> expiresAt = const Value.absent(),
    String? status,
    Value<String?> replyTo = const Value.absent(),
  }) => Message(
    id: id ?? this.id,
    chatId: chatId ?? this.chatId,
    fromMe: fromMe ?? this.fromMe,
    kind: kind ?? this.kind,
    body: body ?? this.body,
    sentAt: sentAt ?? this.sentAt,
    localAt: localAt ?? this.localAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    status: status ?? this.status,
    replyTo: replyTo.present ? replyTo.value : this.replyTo,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      fromMe: data.fromMe.present ? data.fromMe.value : this.fromMe,
      kind: data.kind.present ? data.kind.value : this.kind,
      body: data.body.present ? data.body.value : this.body,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      localAt: data.localAt.present ? data.localAt.value : this.localAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      status: data.status.present ? data.status.value : this.status,
      replyTo: data.replyTo.present ? data.replyTo.value : this.replyTo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('chatId: $chatId, ')
          ..write('fromMe: $fromMe, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt, ')
          ..write('localAt: $localAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('status: $status, ')
          ..write('replyTo: $replyTo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    chatId,
    fromMe,
    kind,
    body,
    sentAt,
    localAt,
    expiresAt,
    status,
    replyTo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.chatId == this.chatId &&
          other.fromMe == this.fromMe &&
          other.kind == this.kind &&
          other.body == this.body &&
          other.sentAt == this.sentAt &&
          other.localAt == this.localAt &&
          other.expiresAt == this.expiresAt &&
          other.status == this.status &&
          other.replyTo == this.replyTo);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> id;
  final Value<String> chatId;
  final Value<bool> fromMe;
  final Value<String> kind;
  final Value<String> body;
  final Value<int> sentAt;
  final Value<int> localAt;
  final Value<int?> expiresAt;
  final Value<String> status;
  final Value<String?> replyTo;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.chatId = const Value.absent(),
    this.fromMe = const Value.absent(),
    this.kind = const Value.absent(),
    this.body = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.localAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.status = const Value.absent(),
    this.replyTo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String chatId,
    required bool fromMe,
    required String kind,
    required String body,
    required int sentAt,
    required int localAt,
    this.expiresAt = const Value.absent(),
    required String status,
    this.replyTo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       chatId = Value(chatId),
       fromMe = Value(fromMe),
       kind = Value(kind),
       body = Value(body),
       sentAt = Value(sentAt),
       localAt = Value(localAt),
       status = Value(status);
  static Insertable<Message> custom({
    Expression<String>? id,
    Expression<String>? chatId,
    Expression<bool>? fromMe,
    Expression<String>? kind,
    Expression<String>? body,
    Expression<int>? sentAt,
    Expression<int>? localAt,
    Expression<int>? expiresAt,
    Expression<String>? status,
    Expression<String>? replyTo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chatId != null) 'chat_id': chatId,
      if (fromMe != null) 'from_me': fromMe,
      if (kind != null) 'kind': kind,
      if (body != null) 'body': body,
      if (sentAt != null) 'sent_at': sentAt,
      if (localAt != null) 'local_at': localAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (status != null) 'status': status,
      if (replyTo != null) 'reply_to': replyTo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? chatId,
    Value<bool>? fromMe,
    Value<String>? kind,
    Value<String>? body,
    Value<int>? sentAt,
    Value<int>? localAt,
    Value<int?>? expiresAt,
    Value<String>? status,
    Value<String?>? replyTo,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      fromMe: fromMe ?? this.fromMe,
      kind: kind ?? this.kind,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      localAt: localAt ?? this.localAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      replyTo: replyTo ?? this.replyTo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (fromMe.present) {
      map['from_me'] = Variable<bool>(fromMe.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<int>(sentAt.value);
    }
    if (localAt.present) {
      map['local_at'] = Variable<int>(localAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (replyTo.present) {
      map['reply_to'] = Variable<String>(replyTo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('chatId: $chatId, ')
          ..write('fromMe: $fromMe, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt, ')
          ..write('localAt: $localAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('status: $status, ')
          ..write('replyTo: $replyTo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaTable extends Media with TableInfo<$MediaTable, MediaItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES messages (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [messageId, bytes, width, height];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  MediaItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItem(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
    );
  }

  @override
  $MediaTable createAlias(String alias) {
    return $MediaTable(attachedDatabase, alias);
  }
}

class MediaItem extends DataClass implements Insertable<MediaItem> {
  final String messageId;
  final Uint8List bytes;
  final int width;
  final int height;
  const MediaItem({
    required this.messageId,
    required this.bytes,
    required this.width,
    required this.height,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['bytes'] = Variable<Uint8List>(bytes);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    return map;
  }

  MediaCompanion toCompanion(bool nullToAbsent) {
    return MediaCompanion(
      messageId: Value(messageId),
      bytes: Value(bytes),
      width: Value(width),
      height: Value(height),
    );
  }

  factory MediaItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaItem(
      messageId: serializer.fromJson<String>(json['messageId']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'bytes': serializer.toJson<Uint8List>(bytes),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
    };
  }

  MediaItem copyWith({
    String? messageId,
    Uint8List? bytes,
    int? width,
    int? height,
  }) => MediaItem(
    messageId: messageId ?? this.messageId,
    bytes: bytes ?? this.bytes,
    width: width ?? this.width,
    height: height ?? this.height,
  );
  MediaItem copyWithCompanion(MediaCompanion data) {
    return MediaItem(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaItem(')
          ..write('messageId: $messageId, ')
          ..write('bytes: $bytes, ')
          ..write('width: $width, ')
          ..write('height: $height')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(messageId, $driftBlobEquality.hash(bytes), width, height);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItem &&
          other.messageId == this.messageId &&
          $driftBlobEquality.equals(other.bytes, this.bytes) &&
          other.width == this.width &&
          other.height == this.height);
}

class MediaCompanion extends UpdateCompanion<MediaItem> {
  final Value<String> messageId;
  final Value<Uint8List> bytes;
  final Value<int> width;
  final Value<int> height;
  final Value<int> rowid;
  const MediaCompanion({
    this.messageId = const Value.absent(),
    this.bytes = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaCompanion.insert({
    required String messageId,
    required Uint8List bytes,
    required int width,
    required int height,
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       bytes = Value(bytes),
       width = Value(width),
       height = Value(height);
  static Insertable<MediaItem> custom({
    Expression<String>? messageId,
    Expression<Uint8List>? bytes,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (bytes != null) 'bytes': bytes,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaCompanion copyWith({
    Value<String>? messageId,
    Value<Uint8List>? bytes,
    Value<int>? width,
    Value<int>? height,
    Value<int>? rowid,
  }) {
    return MediaCompanion(
      messageId: messageId ?? this.messageId,
      bytes: bytes ?? this.bytes,
      width: width ?? this.width,
      height: height ?? this.height,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaCompanion(')
          ..write('messageId: $messageId, ')
          ..write('bytes: $bytes, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaPartsTable extends MediaParts
    with TableInfo<$MediaPartsTable, MediaPart> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaPartsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partMeta = const VerificationMeta('part');
  @override
  late final GeneratedColumn<int> part = GeneratedColumn<int>(
    'part',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<Uint8List> data = GeneratedColumn<Uint8List>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<int> sentAt = GeneratedColumn<int>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ttlSecondsMeta = const VerificationMeta(
    'ttlSeconds',
  );
  @override
  late final GeneratedColumn<int> ttlSeconds = GeneratedColumn<int>(
    'ttl_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replyToMeta = const VerificationMeta(
    'replyTo',
  );
  @override
  late final GeneratedColumn<String> replyTo = GeneratedColumn<String>(
    'reply_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    part,
    chatId,
    total,
    data,
    sentAt,
    ttlSeconds,
    width,
    height,
    sha256,
    replyTo,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_parts';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaPart> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('part')) {
      context.handle(
        _partMeta,
        part.isAcceptableOrUnknown(data['part']!, _partMeta),
      );
    } else if (isInserting) {
      context.missing(_partMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('ttl_seconds')) {
      context.handle(
        _ttlSecondsMeta,
        ttlSeconds.isAcceptableOrUnknown(data['ttl_seconds']!, _ttlSecondsMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('reply_to')) {
      context.handle(
        _replyToMeta,
        replyTo.isAcceptableOrUnknown(data['reply_to']!, _replyToMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, part};
  @override
  MediaPart map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaPart(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      part: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}data'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_at'],
      )!,
      ttlSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ttl_seconds'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      replyTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MediaPartsTable createAlias(String alias) {
    return $MediaPartsTable(attachedDatabase, alias);
  }
}

class MediaPart extends DataClass implements Insertable<MediaPart> {
  final String messageId;
  final int part;
  final String chatId;
  final int total;
  final Uint8List data;
  final int sentAt;
  final int? ttlSeconds;
  final int width;
  final int height;
  final String sha256;
  final String? replyTo;
  final int createdAt;
  const MediaPart({
    required this.messageId,
    required this.part,
    required this.chatId,
    required this.total,
    required this.data,
    required this.sentAt,
    this.ttlSeconds,
    required this.width,
    required this.height,
    required this.sha256,
    this.replyTo,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['part'] = Variable<int>(part);
    map['chat_id'] = Variable<String>(chatId);
    map['total'] = Variable<int>(total);
    map['data'] = Variable<Uint8List>(data);
    map['sent_at'] = Variable<int>(sentAt);
    if (!nullToAbsent || ttlSeconds != null) {
      map['ttl_seconds'] = Variable<int>(ttlSeconds);
    }
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['sha256'] = Variable<String>(sha256);
    if (!nullToAbsent || replyTo != null) {
      map['reply_to'] = Variable<String>(replyTo);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  MediaPartsCompanion toCompanion(bool nullToAbsent) {
    return MediaPartsCompanion(
      messageId: Value(messageId),
      part: Value(part),
      chatId: Value(chatId),
      total: Value(total),
      data: Value(data),
      sentAt: Value(sentAt),
      ttlSeconds: ttlSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(ttlSeconds),
      width: Value(width),
      height: Value(height),
      sha256: Value(sha256),
      replyTo: replyTo == null && nullToAbsent
          ? const Value.absent()
          : Value(replyTo),
      createdAt: Value(createdAt),
    );
  }

  factory MediaPart.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaPart(
      messageId: serializer.fromJson<String>(json['messageId']),
      part: serializer.fromJson<int>(json['part']),
      chatId: serializer.fromJson<String>(json['chatId']),
      total: serializer.fromJson<int>(json['total']),
      data: serializer.fromJson<Uint8List>(json['data']),
      sentAt: serializer.fromJson<int>(json['sentAt']),
      ttlSeconds: serializer.fromJson<int?>(json['ttlSeconds']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      sha256: serializer.fromJson<String>(json['sha256']),
      replyTo: serializer.fromJson<String?>(json['replyTo']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'part': serializer.toJson<int>(part),
      'chatId': serializer.toJson<String>(chatId),
      'total': serializer.toJson<int>(total),
      'data': serializer.toJson<Uint8List>(data),
      'sentAt': serializer.toJson<int>(sentAt),
      'ttlSeconds': serializer.toJson<int?>(ttlSeconds),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'sha256': serializer.toJson<String>(sha256),
      'replyTo': serializer.toJson<String?>(replyTo),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  MediaPart copyWith({
    String? messageId,
    int? part,
    String? chatId,
    int? total,
    Uint8List? data,
    int? sentAt,
    Value<int?> ttlSeconds = const Value.absent(),
    int? width,
    int? height,
    String? sha256,
    Value<String?> replyTo = const Value.absent(),
    int? createdAt,
  }) => MediaPart(
    messageId: messageId ?? this.messageId,
    part: part ?? this.part,
    chatId: chatId ?? this.chatId,
    total: total ?? this.total,
    data: data ?? this.data,
    sentAt: sentAt ?? this.sentAt,
    ttlSeconds: ttlSeconds.present ? ttlSeconds.value : this.ttlSeconds,
    width: width ?? this.width,
    height: height ?? this.height,
    sha256: sha256 ?? this.sha256,
    replyTo: replyTo.present ? replyTo.value : this.replyTo,
    createdAt: createdAt ?? this.createdAt,
  );
  MediaPart copyWithCompanion(MediaPartsCompanion data) {
    return MediaPart(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      part: data.part.present ? data.part.value : this.part,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      total: data.total.present ? data.total.value : this.total,
      data: data.data.present ? data.data.value : this.data,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      ttlSeconds: data.ttlSeconds.present
          ? data.ttlSeconds.value
          : this.ttlSeconds,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      replyTo: data.replyTo.present ? data.replyTo.value : this.replyTo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaPart(')
          ..write('messageId: $messageId, ')
          ..write('part: $part, ')
          ..write('chatId: $chatId, ')
          ..write('total: $total, ')
          ..write('data: $data, ')
          ..write('sentAt: $sentAt, ')
          ..write('ttlSeconds: $ttlSeconds, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sha256: $sha256, ')
          ..write('replyTo: $replyTo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    messageId,
    part,
    chatId,
    total,
    $driftBlobEquality.hash(data),
    sentAt,
    ttlSeconds,
    width,
    height,
    sha256,
    replyTo,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaPart &&
          other.messageId == this.messageId &&
          other.part == this.part &&
          other.chatId == this.chatId &&
          other.total == this.total &&
          $driftBlobEquality.equals(other.data, this.data) &&
          other.sentAt == this.sentAt &&
          other.ttlSeconds == this.ttlSeconds &&
          other.width == this.width &&
          other.height == this.height &&
          other.sha256 == this.sha256 &&
          other.replyTo == this.replyTo &&
          other.createdAt == this.createdAt);
}

class MediaPartsCompanion extends UpdateCompanion<MediaPart> {
  final Value<String> messageId;
  final Value<int> part;
  final Value<String> chatId;
  final Value<int> total;
  final Value<Uint8List> data;
  final Value<int> sentAt;
  final Value<int?> ttlSeconds;
  final Value<int> width;
  final Value<int> height;
  final Value<String> sha256;
  final Value<String?> replyTo;
  final Value<int> createdAt;
  final Value<int> rowid;
  const MediaPartsCompanion({
    this.messageId = const Value.absent(),
    this.part = const Value.absent(),
    this.chatId = const Value.absent(),
    this.total = const Value.absent(),
    this.data = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.ttlSeconds = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.replyTo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaPartsCompanion.insert({
    required String messageId,
    required int part,
    required String chatId,
    required int total,
    required Uint8List data,
    required int sentAt,
    this.ttlSeconds = const Value.absent(),
    required int width,
    required int height,
    required String sha256,
    this.replyTo = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       part = Value(part),
       chatId = Value(chatId),
       total = Value(total),
       data = Value(data),
       sentAt = Value(sentAt),
       width = Value(width),
       height = Value(height),
       sha256 = Value(sha256),
       createdAt = Value(createdAt);
  static Insertable<MediaPart> custom({
    Expression<String>? messageId,
    Expression<int>? part,
    Expression<String>? chatId,
    Expression<int>? total,
    Expression<Uint8List>? data,
    Expression<int>? sentAt,
    Expression<int>? ttlSeconds,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? sha256,
    Expression<String>? replyTo,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (part != null) 'part': part,
      if (chatId != null) 'chat_id': chatId,
      if (total != null) 'total': total,
      if (data != null) 'data': data,
      if (sentAt != null) 'sent_at': sentAt,
      if (ttlSeconds != null) 'ttl_seconds': ttlSeconds,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (sha256 != null) 'sha256': sha256,
      if (replyTo != null) 'reply_to': replyTo,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaPartsCompanion copyWith({
    Value<String>? messageId,
    Value<int>? part,
    Value<String>? chatId,
    Value<int>? total,
    Value<Uint8List>? data,
    Value<int>? sentAt,
    Value<int?>? ttlSeconds,
    Value<int>? width,
    Value<int>? height,
    Value<String>? sha256,
    Value<String?>? replyTo,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return MediaPartsCompanion(
      messageId: messageId ?? this.messageId,
      part: part ?? this.part,
      chatId: chatId ?? this.chatId,
      total: total ?? this.total,
      data: data ?? this.data,
      sentAt: sentAt ?? this.sentAt,
      ttlSeconds: ttlSeconds ?? this.ttlSeconds,
      width: width ?? this.width,
      height: height ?? this.height,
      sha256: sha256 ?? this.sha256,
      replyTo: replyTo ?? this.replyTo,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (part.present) {
      map['part'] = Variable<int>(part.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (data.present) {
      map['data'] = Variable<Uint8List>(data.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<int>(sentAt.value);
    }
    if (ttlSeconds.present) {
      map['ttl_seconds'] = Variable<int>(ttlSeconds.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (replyTo.present) {
      map['reply_to'] = Variable<String>(replyTo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaPartsCompanion(')
          ..write('messageId: $messageId, ')
          ..write('part: $part, ')
          ..write('chatId: $chatId, ')
          ..write('total: $total, ')
          ..write('data: $data, ')
          ..write('sentAt: $sentAt, ')
          ..write('ttlSeconds: $ttlSeconds, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sha256: $sha256, ')
          ..write('replyTo: $replyTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AvatarsTable extends Avatars with TableInfo<$AvatarsTable, Avatar> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AvatarsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [ownerId, bytes, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'avatars';
  @override
  VerificationContext validateIntegrity(
    Insertable<Avatar> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId};
  @override
  Avatar map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Avatar(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AvatarsTable createAlias(String alias) {
    return $AvatarsTable(attachedDatabase, alias);
  }
}

class Avatar extends DataClass implements Insertable<Avatar> {
  final String ownerId;
  final Uint8List bytes;
  final int updatedAt;
  const Avatar({
    required this.ownerId,
    required this.bytes,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['bytes'] = Variable<Uint8List>(bytes);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AvatarsCompanion toCompanion(bool nullToAbsent) {
    return AvatarsCompanion(
      ownerId: Value(ownerId),
      bytes: Value(bytes),
      updatedAt: Value(updatedAt),
    );
  }

  factory Avatar.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Avatar(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'bytes': serializer.toJson<Uint8List>(bytes),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Avatar copyWith({String? ownerId, Uint8List? bytes, int? updatedAt}) =>
      Avatar(
        ownerId: ownerId ?? this.ownerId,
        bytes: bytes ?? this.bytes,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Avatar copyWithCompanion(AvatarsCompanion data) {
    return Avatar(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Avatar(')
          ..write('ownerId: $ownerId, ')
          ..write('bytes: $bytes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(ownerId, $driftBlobEquality.hash(bytes), updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Avatar &&
          other.ownerId == this.ownerId &&
          $driftBlobEquality.equals(other.bytes, this.bytes) &&
          other.updatedAt == this.updatedAt);
}

class AvatarsCompanion extends UpdateCompanion<Avatar> {
  final Value<String> ownerId;
  final Value<Uint8List> bytes;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AvatarsCompanion({
    this.ownerId = const Value.absent(),
    this.bytes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AvatarsCompanion.insert({
    required String ownerId,
    required Uint8List bytes,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       bytes = Value(bytes),
       updatedAt = Value(updatedAt);
  static Insertable<Avatar> custom({
    Expression<String>? ownerId,
    Expression<Uint8List>? bytes,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (bytes != null) 'bytes': bytes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AvatarsCompanion copyWith({
    Value<String>? ownerId,
    Value<Uint8List>? bytes,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AvatarsCompanion(
      ownerId: ownerId ?? this.ownerId,
      bytes: bytes ?? this.bytes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AvatarsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('bytes: $bytes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OlmSessionsTable extends OlmSessions
    with TableInfo<$OlmSessionsTable, OlmSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OlmSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<String> peerId = GeneratedColumn<String>(
    'peer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pickleMeta = const VerificationMeta('pickle');
  @override
  late final GeneratedColumn<String> pickle = GeneratedColumn<String>(
    'pickle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<int> lastUsedAt = GeneratedColumn<int>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, peerId, pickle, lastUsedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'olm_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<OlmSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('peer_id')) {
      context.handle(
        _peerIdMeta,
        peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_peerIdMeta);
    }
    if (data.containsKey('pickle')) {
      context.handle(
        _pickleMeta,
        pickle.isAcceptableOrUnknown(data['pickle']!, _pickleMeta),
      );
    } else if (isInserting) {
      context.missing(_pickleMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  OlmSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OlmSession(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      peerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_id'],
      )!,
      pickle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pickle'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  $OlmSessionsTable createAlias(String alias) {
    return $OlmSessionsTable(attachedDatabase, alias);
  }
}

class OlmSession extends DataClass implements Insertable<OlmSession> {
  final String sessionId;
  final String peerId;
  final String pickle;
  final int lastUsedAt;
  const OlmSession({
    required this.sessionId,
    required this.peerId,
    required this.pickle,
    required this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['peer_id'] = Variable<String>(peerId);
    map['pickle'] = Variable<String>(pickle);
    map['last_used_at'] = Variable<int>(lastUsedAt);
    return map;
  }

  OlmSessionsCompanion toCompanion(bool nullToAbsent) {
    return OlmSessionsCompanion(
      sessionId: Value(sessionId),
      peerId: Value(peerId),
      pickle: Value(pickle),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory OlmSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OlmSession(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      peerId: serializer.fromJson<String>(json['peerId']),
      pickle: serializer.fromJson<String>(json['pickle']),
      lastUsedAt: serializer.fromJson<int>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'peerId': serializer.toJson<String>(peerId),
      'pickle': serializer.toJson<String>(pickle),
      'lastUsedAt': serializer.toJson<int>(lastUsedAt),
    };
  }

  OlmSession copyWith({
    String? sessionId,
    String? peerId,
    String? pickle,
    int? lastUsedAt,
  }) => OlmSession(
    sessionId: sessionId ?? this.sessionId,
    peerId: peerId ?? this.peerId,
    pickle: pickle ?? this.pickle,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
  OlmSession copyWithCompanion(OlmSessionsCompanion data) {
    return OlmSession(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      peerId: data.peerId.present ? data.peerId.value : this.peerId,
      pickle: data.pickle.present ? data.pickle.value : this.pickle,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OlmSession(')
          ..write('sessionId: $sessionId, ')
          ..write('peerId: $peerId, ')
          ..write('pickle: $pickle, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, peerId, pickle, lastUsedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OlmSession &&
          other.sessionId == this.sessionId &&
          other.peerId == this.peerId &&
          other.pickle == this.pickle &&
          other.lastUsedAt == this.lastUsedAt);
}

class OlmSessionsCompanion extends UpdateCompanion<OlmSession> {
  final Value<String> sessionId;
  final Value<String> peerId;
  final Value<String> pickle;
  final Value<int> lastUsedAt;
  final Value<int> rowid;
  const OlmSessionsCompanion({
    this.sessionId = const Value.absent(),
    this.peerId = const Value.absent(),
    this.pickle = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OlmSessionsCompanion.insert({
    required String sessionId,
    required String peerId,
    required String pickle,
    required int lastUsedAt,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       peerId = Value(peerId),
       pickle = Value(pickle),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<OlmSession> custom({
    Expression<String>? sessionId,
    Expression<String>? peerId,
    Expression<String>? pickle,
    Expression<int>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (peerId != null) 'peer_id': peerId,
      if (pickle != null) 'pickle': pickle,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OlmSessionsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? peerId,
    Value<String>? pickle,
    Value<int>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return OlmSessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      peerId: peerId ?? this.peerId,
      pickle: pickle ?? this.pickle,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (peerId.present) {
      map['peer_id'] = Variable<String>(peerId.value);
    }
    if (pickle.present) {
      map['pickle'] = Variable<String>(pickle.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<int>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OlmSessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('peerId: $peerId, ')
          ..write('pickle: $pickle, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipientIdMeta = const VerificationMeta(
    'recipientId',
  );
  @override
  late final GeneratedColumn<String> recipientId = GeneratedColumn<String>(
    'recipient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _envelopeMeta = const VerificationMeta(
    'envelope',
  );
  @override
  late final GeneratedColumn<String> envelope = GeneratedColumn<String>(
    'envelope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pushMeta = const VerificationMeta('push');
  @override
  late final GeneratedColumn<bool> push = GeneratedColumn<bool>(
    'push',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("push" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recipientId,
    type,
    envelope,
    expiresAt,
    messageId,
    push,
    createdAt,
    attempts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipient_id')) {
      context.handle(
        _recipientIdMeta,
        recipientId.isAcceptableOrUnknown(
          data['recipient_id']!,
          _recipientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('envelope')) {
      context.handle(
        _envelopeMeta,
        envelope.isAcceptableOrUnknown(data['envelope']!, _envelopeMeta),
      );
    } else if (isInserting) {
      context.missing(_envelopeMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    }
    if (data.containsKey('push')) {
      context.handle(
        _pushMeta,
        push.isAcceptableOrUnknown(data['push']!, _pushMeta),
      );
    } else if (isInserting) {
      context.missing(_pushMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recipientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      envelope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}envelope'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at'],
      ),
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      ),
      push: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}push'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxEntry extends DataClass implements Insertable<OutboxEntry> {
  /// Also the relay row id, which makes retries idempotent.
  final String id;
  final String recipientId;
  final String type;
  final String envelope;
  final int? expiresAt;
  final String? messageId;
  final bool push;
  final int createdAt;
  final int attempts;
  const OutboxEntry({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.envelope,
    this.expiresAt,
    this.messageId,
    required this.push,
    required this.createdAt,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipient_id'] = Variable<String>(recipientId);
    map['type'] = Variable<String>(type);
    map['envelope'] = Variable<String>(envelope);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<int>(expiresAt);
    }
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    map['push'] = Variable<bool>(push);
    map['created_at'] = Variable<int>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      id: Value(id),
      recipientId: Value(recipientId),
      type: Value(type),
      envelope: Value(envelope),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      push: Value(push),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
    );
  }

  factory OutboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntry(
      id: serializer.fromJson<String>(json['id']),
      recipientId: serializer.fromJson<String>(json['recipientId']),
      type: serializer.fromJson<String>(json['type']),
      envelope: serializer.fromJson<String>(json['envelope']),
      expiresAt: serializer.fromJson<int?>(json['expiresAt']),
      messageId: serializer.fromJson<String?>(json['messageId']),
      push: serializer.fromJson<bool>(json['push']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipientId': serializer.toJson<String>(recipientId),
      'type': serializer.toJson<String>(type),
      'envelope': serializer.toJson<String>(envelope),
      'expiresAt': serializer.toJson<int?>(expiresAt),
      'messageId': serializer.toJson<String?>(messageId),
      'push': serializer.toJson<bool>(push),
      'createdAt': serializer.toJson<int>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  OutboxEntry copyWith({
    String? id,
    String? recipientId,
    String? type,
    String? envelope,
    Value<int?> expiresAt = const Value.absent(),
    Value<String?> messageId = const Value.absent(),
    bool? push,
    int? createdAt,
    int? attempts,
  }) => OutboxEntry(
    id: id ?? this.id,
    recipientId: recipientId ?? this.recipientId,
    type: type ?? this.type,
    envelope: envelope ?? this.envelope,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    messageId: messageId.present ? messageId.value : this.messageId,
    push: push ?? this.push,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
  );
  OutboxEntry copyWithCompanion(OutboxCompanion data) {
    return OutboxEntry(
      id: data.id.present ? data.id.value : this.id,
      recipientId: data.recipientId.present
          ? data.recipientId.value
          : this.recipientId,
      type: data.type.present ? data.type.value : this.type,
      envelope: data.envelope.present ? data.envelope.value : this.envelope,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      push: data.push.present ? data.push.value : this.push,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntry(')
          ..write('id: $id, ')
          ..write('recipientId: $recipientId, ')
          ..write('type: $type, ')
          ..write('envelope: $envelope, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('messageId: $messageId, ')
          ..write('push: $push, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recipientId,
    type,
    envelope,
    expiresAt,
    messageId,
    push,
    createdAt,
    attempts,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntry &&
          other.id == this.id &&
          other.recipientId == this.recipientId &&
          other.type == this.type &&
          other.envelope == this.envelope &&
          other.expiresAt == this.expiresAt &&
          other.messageId == this.messageId &&
          other.push == this.push &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts);
}

class OutboxCompanion extends UpdateCompanion<OutboxEntry> {
  final Value<String> id;
  final Value<String> recipientId;
  final Value<String> type;
  final Value<String> envelope;
  final Value<int?> expiresAt;
  final Value<String?> messageId;
  final Value<bool> push;
  final Value<int> createdAt;
  final Value<int> attempts;
  final Value<int> rowid;
  const OutboxCompanion({
    this.id = const Value.absent(),
    this.recipientId = const Value.absent(),
    this.type = const Value.absent(),
    this.envelope = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.messageId = const Value.absent(),
    this.push = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String id,
    required String recipientId,
    required String type,
    required String envelope,
    this.expiresAt = const Value.absent(),
    this.messageId = const Value.absent(),
    required bool push,
    required int createdAt,
    this.attempts = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recipientId = Value(recipientId),
       type = Value(type),
       envelope = Value(envelope),
       push = Value(push),
       createdAt = Value(createdAt);
  static Insertable<OutboxEntry> custom({
    Expression<String>? id,
    Expression<String>? recipientId,
    Expression<String>? type,
    Expression<String>? envelope,
    Expression<int>? expiresAt,
    Expression<String>? messageId,
    Expression<bool>? push,
    Expression<int>? createdAt,
    Expression<int>? attempts,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipientId != null) 'recipient_id': recipientId,
      if (type != null) 'type': type,
      if (envelope != null) 'envelope': envelope,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (messageId != null) 'message_id': messageId,
      if (push != null) 'push': push,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? id,
    Value<String>? recipientId,
    Value<String>? type,
    Value<String>? envelope,
    Value<int?>? expiresAt,
    Value<String?>? messageId,
    Value<bool>? push,
    Value<int>? createdAt,
    Value<int>? attempts,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      envelope: envelope ?? this.envelope,
      expiresAt: expiresAt ?? this.expiresAt,
      messageId: messageId ?? this.messageId,
      push: push ?? this.push,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipientId.present) {
      map['recipient_id'] = Variable<String>(recipientId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (envelope.present) {
      map['envelope'] = Variable<String>(envelope.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (push.present) {
      map['push'] = Variable<bool>(push.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('recipientId: $recipientId, ')
          ..write('type: $type, ')
          ..write('envelope: $envelope, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('messageId: $messageId, ')
          ..write('push: $push, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingDeletesTable extends PendingDeletes
    with TableInfo<$PendingDeletesTable, PendingDelete> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingDeletesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [messageId, chatId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_deletes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingDelete> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  PendingDelete map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingDelete(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      )!,
    );
  }

  @override
  $PendingDeletesTable createAlias(String alias) {
    return $PendingDeletesTable(attachedDatabase, alias);
  }
}

class PendingDelete extends DataClass implements Insertable<PendingDelete> {
  final String messageId;
  final String chatId;
  const PendingDelete({required this.messageId, required this.chatId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['chat_id'] = Variable<String>(chatId);
    return map;
  }

  PendingDeletesCompanion toCompanion(bool nullToAbsent) {
    return PendingDeletesCompanion(
      messageId: Value(messageId),
      chatId: Value(chatId),
    );
  }

  factory PendingDelete.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingDelete(
      messageId: serializer.fromJson<String>(json['messageId']),
      chatId: serializer.fromJson<String>(json['chatId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'chatId': serializer.toJson<String>(chatId),
    };
  }

  PendingDelete copyWith({String? messageId, String? chatId}) => PendingDelete(
    messageId: messageId ?? this.messageId,
    chatId: chatId ?? this.chatId,
  );
  PendingDelete copyWithCompanion(PendingDeletesCompanion data) {
    return PendingDelete(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingDelete(')
          ..write('messageId: $messageId, ')
          ..write('chatId: $chatId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(messageId, chatId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingDelete &&
          other.messageId == this.messageId &&
          other.chatId == this.chatId);
}

class PendingDeletesCompanion extends UpdateCompanion<PendingDelete> {
  final Value<String> messageId;
  final Value<String> chatId;
  final Value<int> rowid;
  const PendingDeletesCompanion({
    this.messageId = const Value.absent(),
    this.chatId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingDeletesCompanion.insert({
    required String messageId,
    required String chatId,
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       chatId = Value(chatId);
  static Insertable<PendingDelete> custom({
    Expression<String>? messageId,
    Expression<String>? chatId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (chatId != null) 'chat_id': chatId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingDeletesCompanion copyWith({
    Value<String>? messageId,
    Value<String>? chatId,
    Value<int>? rowid,
  }) {
    return PendingDeletesCompanion(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingDeletesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('chatId: $chatId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProcessedEnvelopesTable extends ProcessedEnvelopes
    with TableInfo<$ProcessedEnvelopesTable, ProcessedEnvelope> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcessedEnvelopesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processedAtMeta = const VerificationMeta(
    'processedAt',
  );
  @override
  late final GeneratedColumn<int> processedAt = GeneratedColumn<int>(
    'processed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, processedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'processed_envelopes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProcessedEnvelope> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('processed_at')) {
      context.handle(
        _processedAtMeta,
        processedAt.isAcceptableOrUnknown(
          data['processed_at']!,
          _processedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcessedEnvelope map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessedEnvelope(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      processedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}processed_at'],
      )!,
    );
  }

  @override
  $ProcessedEnvelopesTable createAlias(String alias) {
    return $ProcessedEnvelopesTable(attachedDatabase, alias);
  }
}

class ProcessedEnvelope extends DataClass
    implements Insertable<ProcessedEnvelope> {
  final String id;
  final int processedAt;
  const ProcessedEnvelope({required this.id, required this.processedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['processed_at'] = Variable<int>(processedAt);
    return map;
  }

  ProcessedEnvelopesCompanion toCompanion(bool nullToAbsent) {
    return ProcessedEnvelopesCompanion(
      id: Value(id),
      processedAt: Value(processedAt),
    );
  }

  factory ProcessedEnvelope.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessedEnvelope(
      id: serializer.fromJson<String>(json['id']),
      processedAt: serializer.fromJson<int>(json['processedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'processedAt': serializer.toJson<int>(processedAt),
    };
  }

  ProcessedEnvelope copyWith({String? id, int? processedAt}) =>
      ProcessedEnvelope(
        id: id ?? this.id,
        processedAt: processedAt ?? this.processedAt,
      );
  ProcessedEnvelope copyWithCompanion(ProcessedEnvelopesCompanion data) {
    return ProcessedEnvelope(
      id: data.id.present ? data.id.value : this.id,
      processedAt: data.processedAt.present
          ? data.processedAt.value
          : this.processedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessedEnvelope(')
          ..write('id: $id, ')
          ..write('processedAt: $processedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, processedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessedEnvelope &&
          other.id == this.id &&
          other.processedAt == this.processedAt);
}

class ProcessedEnvelopesCompanion extends UpdateCompanion<ProcessedEnvelope> {
  final Value<String> id;
  final Value<int> processedAt;
  final Value<int> rowid;
  const ProcessedEnvelopesCompanion({
    this.id = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProcessedEnvelopesCompanion.insert({
    required String id,
    required int processedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       processedAt = Value(processedAt);
  static Insertable<ProcessedEnvelope> custom({
    Expression<String>? id,
    Expression<int>? processedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (processedAt != null) 'processed_at': processedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProcessedEnvelopesCompanion copyWith({
    Value<String>? id,
    Value<int>? processedAt,
    Value<int>? rowid,
  }) {
    return ProcessedEnvelopesCompanion(
      id: id ?? this.id,
      processedAt: processedAt ?? this.processedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<int>(processedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcessedEnvelopesCompanion(')
          ..write('id: $id, ')
          ..write('processedAt: $processedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValue(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final String value;
  const KeyValue({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValue(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValue copyWith({String? key, String? value}) =>
      KeyValue(key: key ?? this.key, value: value ?? this.value);
  KeyValue copyWithCompanion(KeyValuesCompanion data) {
    return KeyValue(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValue(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValue && other.key == this.key && other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValue> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValue> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChatsTable chats = $ChatsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MediaTable media = $MediaTable(this);
  late final $MediaPartsTable mediaParts = $MediaPartsTable(this);
  late final $AvatarsTable avatars = $AvatarsTable(this);
  late final $OlmSessionsTable olmSessions = $OlmSessionsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $PendingDeletesTable pendingDeletes = $PendingDeletesTable(this);
  late final $ProcessedEnvelopesTable processedEnvelopes =
      $ProcessedEnvelopesTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    chats,
    messages,
    media,
    mediaParts,
    avatars,
    olmSessions,
    outbox,
    pendingDeletes,
    processedEnvelopes,
    keyValues,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chats',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('messages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'messages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('media', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ChatsTableCreateCompanionBuilder = ChatsCompanion Function({
  required String peerId,
  required String peerUsername,
  required String peerIdentityKey,
  required String peerSigningKey,
  Value<int?> timerSeconds,
  Value<int> timerChangedAt,
  Value<int?> wipedBefore,
  required int createdAt,
  required int lastActivityAt,
  Value<bool> blocked,
  Value<bool> accepted,
  Value<int> profileSentVersion,
  Value<bool> refreshProfile,
  Value<int> directoryCheckedAt,
  Value<int> rowid,
});
typedef $$ChatsTableUpdateCompanionBuilder = ChatsCompanion Function({
  Value<String> peerId,
  Value<String> peerUsername,
  Value<String> peerIdentityKey,
  Value<String> peerSigningKey,
  Value<int?> timerSeconds,
  Value<int> timerChangedAt,
  Value<int?> wipedBefore,
  Value<int> createdAt,
  Value<int> lastActivityAt,
  Value<bool> blocked,
  Value<bool> accepted,
  Value<int> profileSentVersion,
  Value<bool> refreshProfile,
  Value<int> directoryCheckedAt,
  Value<int> rowid,
});

final class $$ChatsTableReferences
    extends BaseReferences<_$AppDatabase, $ChatsTable, Chat> {
  $$ChatsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: 'chats__peer_id__messages__chat_id',
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager($_db, $_db.messages).filter(
      (f) => f.chatId.peerId.sqlEquals($_itemColumn<String>('peer_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChatsTableFilterComposer extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get peerId => $composableBuilder(
    column: $table.peerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerUsername => $composableBuilder(
    column: $table.peerUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerIdentityKey => $composableBuilder(
    column: $table.peerIdentityKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerSigningKey => $composableBuilder(
    column: $table.peerSigningKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timerSeconds => $composableBuilder(
    column: $table.timerSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timerChangedAt => $composableBuilder(
    column: $table.timerChangedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wipedBefore => $composableBuilder(
    column: $table.wipedBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastActivityAt => $composableBuilder(
    column: $table.lastActivityAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blocked => $composableBuilder(
    column: $table.blocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get accepted => $composableBuilder(
    column: $table.accepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileSentVersion => $composableBuilder(
    column: $table.profileSentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get refreshProfile => $composableBuilder(
    column: $table.refreshProfile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get directoryCheckedAt => $composableBuilder(
    column: $table.directoryCheckedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.chatId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get peerId => $composableBuilder(
    column: $table.peerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerUsername => $composableBuilder(
    column: $table.peerUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerIdentityKey => $composableBuilder(
    column: $table.peerIdentityKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerSigningKey => $composableBuilder(
    column: $table.peerSigningKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timerSeconds => $composableBuilder(
    column: $table.timerSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timerChangedAt => $composableBuilder(
    column: $table.timerChangedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wipedBefore => $composableBuilder(
    column: $table.wipedBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastActivityAt => $composableBuilder(
    column: $table.lastActivityAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blocked => $composableBuilder(
    column: $table.blocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get accepted => $composableBuilder(
    column: $table.accepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileSentVersion => $composableBuilder(
    column: $table.profileSentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get refreshProfile => $composableBuilder(
    column: $table.refreshProfile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get directoryCheckedAt => $composableBuilder(
    column: $table.directoryCheckedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get peerId =>
      $composableBuilder(column: $table.peerId, builder: (column) => column);

  GeneratedColumn<String> get peerUsername => $composableBuilder(
    column: $table.peerUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerIdentityKey => $composableBuilder(
    column: $table.peerIdentityKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerSigningKey => $composableBuilder(
    column: $table.peerSigningKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timerSeconds => $composableBuilder(
    column: $table.timerSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timerChangedAt => $composableBuilder(
    column: $table.timerChangedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wipedBefore => $composableBuilder(
    column: $table.wipedBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastActivityAt => $composableBuilder(
    column: $table.lastActivityAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get blocked =>
      $composableBuilder(column: $table.blocked, builder: (column) => column);

  GeneratedColumn<bool> get accepted =>
      $composableBuilder(column: $table.accepted, builder: (column) => column);

  GeneratedColumn<int> get profileSentVersion => $composableBuilder(
    column: $table.profileSentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get refreshProfile => $composableBuilder(
    column: $table.refreshProfile,
    builder: (column) => column,
  );

  GeneratedColumn<int> get directoryCheckedAt => $composableBuilder(
    column: $table.directoryCheckedAt,
    builder: (column) => column,
  );

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.chatId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatsTable,
          Chat,
          $$ChatsTableFilterComposer,
          $$ChatsTableOrderingComposer,
          $$ChatsTableAnnotationComposer,
          $$ChatsTableCreateCompanionBuilder,
          $$ChatsTableUpdateCompanionBuilder,
          (Chat, $$ChatsTableReferences),
          Chat,
          PrefetchHooks Function({bool messagesRefs})
        > {
  $$ChatsTableTableManager(_$AppDatabase db, $ChatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> peerId = const Value.absent(),
                Value<String> peerUsername = const Value.absent(),
                Value<String> peerIdentityKey = const Value.absent(),
                Value<String> peerSigningKey = const Value.absent(),
                Value<int?> timerSeconds = const Value.absent(),
                Value<int> timerChangedAt = const Value.absent(),
                Value<int?> wipedBefore = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> lastActivityAt = const Value.absent(),
                Value<bool> blocked = const Value.absent(),
                Value<bool> accepted = const Value.absent(),
                Value<int> profileSentVersion = const Value.absent(),
                Value<bool> refreshProfile = const Value.absent(),
                Value<int> directoryCheckedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatsCompanion(
                peerId: peerId,
                peerUsername: peerUsername,
                peerIdentityKey: peerIdentityKey,
                peerSigningKey: peerSigningKey,
                timerSeconds: timerSeconds,
                timerChangedAt: timerChangedAt,
                wipedBefore: wipedBefore,
                createdAt: createdAt,
                lastActivityAt: lastActivityAt,
                blocked: blocked,
                accepted: accepted,
                profileSentVersion: profileSentVersion,
                refreshProfile: refreshProfile,
                directoryCheckedAt: directoryCheckedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String peerId,
                required String peerUsername,
                required String peerIdentityKey,
                required String peerSigningKey,
                Value<int?> timerSeconds = const Value.absent(),
                Value<int> timerChangedAt = const Value.absent(),
                Value<int?> wipedBefore = const Value.absent(),
                required int createdAt,
                required int lastActivityAt,
                Value<bool> blocked = const Value.absent(),
                Value<bool> accepted = const Value.absent(),
                Value<int> profileSentVersion = const Value.absent(),
                Value<bool> refreshProfile = const Value.absent(),
                Value<int> directoryCheckedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatsCompanion.insert(
                peerId: peerId,
                peerUsername: peerUsername,
                peerIdentityKey: peerIdentityKey,
                peerSigningKey: peerSigningKey,
                timerSeconds: timerSeconds,
                timerChangedAt: timerChangedAt,
                wipedBefore: wipedBefore,
                createdAt: createdAt,
                lastActivityAt: lastActivityAt,
                blocked: blocked,
                accepted: accepted,
                profileSentVersion: profileSentVersion,
                refreshProfile: refreshProfile,
                directoryCheckedAt: directoryCheckedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChatsTable, Chat>(table),
                  $$ChatsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({messagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (messagesRefs) db.messages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messagesRefs)
                    await $_getPrefetchedDataByColumns<
                      Chat,
                      $ChatsTable,
                      Message,
                      $MessagesTable
                    >(
                      currentTable: table,
                      referencedTable: $$ChatsTableReferences
                          ._messagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ChatsTableReferences(db, table, p0).messagesRefs,
                      currentColumn: 'peer_id',
                      referencedColumn: 'chat_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatsTable,
      Chat,
      $$ChatsTableFilterComposer,
      $$ChatsTableOrderingComposer,
      $$ChatsTableAnnotationComposer,
      $$ChatsTableCreateCompanionBuilder,
      $$ChatsTableUpdateCompanionBuilder,
      (Chat, $$ChatsTableReferences),
      Chat,
      PrefetchHooks Function({bool messagesRefs})
    >;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  required String id,
  required String chatId,
  required bool fromMe,
  required String kind,
  required String body,
  required int sentAt,
  required int localAt,
  Value<int?> expiresAt,
  required String status,
  Value<String?> replyTo,
  Value<int> rowid,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<String> id,
  Value<String> chatId,
  Value<bool> fromMe,
  Value<String> kind,
  Value<String> body,
  Value<int> sentAt,
  Value<int> localAt,
  Value<int?> expiresAt,
  Value<String> status,
  Value<String?> replyTo,
  Value<int> rowid,
});

final class $$MessagesTableReferences
    extends BaseReferences<_$AppDatabase, $MessagesTable, Message> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChatsTable _chatIdTable(_$AppDatabase db) =>
      db.chats.createAlias('messages__chat_id__chats__peer_id');

  $$ChatsTableProcessedTableManager get chatId {
    final $_column = $_itemColumn<String>('chat_id')!;

    final manager = $$ChatsTableTableManager(
      $_db,
      $_db.chats,
    ).filter((f) => f.peerId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chatIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MediaTable, List<MediaItem>> _mediaRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.media,
    aliasName: 'messages__id__media__message_id',
  );

  $$MediaTableProcessedTableManager get mediaRefs {
    final manager = $$MediaTableTableManager(
      $_db,
      $_db.media,
    ).filter((f) => f.messageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
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

  ColumnFilters<bool> get fromMe => $composableBuilder(
    column: $table.fromMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localAt => $composableBuilder(
    column: $table.localAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyTo => $composableBuilder(
    column: $table.replyTo,
    builder: (column) => ColumnFilters(column),
  );

  $$ChatsTableFilterComposer get chatId {
    final $$ChatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.peerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableFilterComposer(
            $db: $db,
            $table: $db.chats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> mediaRefs(
    Expression<bool> Function($$MediaTableFilterComposer f) f,
  ) {
    final $$MediaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableFilterComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
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

  ColumnOrderings<bool> get fromMe => $composableBuilder(
    column: $table.fromMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localAt => $composableBuilder(
    column: $table.localAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyTo => $composableBuilder(
    column: $table.replyTo,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChatsTableOrderingComposer get chatId {
    final $$ChatsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.peerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableOrderingComposer(
            $db: $db,
            $table: $db.chats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get fromMe =>
      $composableBuilder(column: $table.fromMe, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<int> get localAt =>
      $composableBuilder(column: $table.localAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get replyTo =>
      $composableBuilder(column: $table.replyTo, builder: (column) => column);

  $$ChatsTableAnnotationComposer get chatId {
    final $$ChatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.peerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableAnnotationComposer(
            $db: $db,
            $table: $db.chats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> mediaRefs<T extends Object>(
    Expression<T> Function($$MediaTableAnnotationComposer a) f,
  ) {
    final $$MediaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.media,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTableAnnotationComposer(
            $db: $db,
            $table: $db.media,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, $$MessagesTableReferences),
          Message,
          PrefetchHooks Function({bool chatId, bool mediaRefs})
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> chatId = const Value.absent(),
                Value<bool> fromMe = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> sentAt = const Value.absent(),
                Value<int> localAt = const Value.absent(),
                Value<int?> expiresAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> replyTo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                chatId: chatId,
                fromMe: fromMe,
                kind: kind,
                body: body,
                sentAt: sentAt,
                localAt: localAt,
                expiresAt: expiresAt,
                status: status,
                replyTo: replyTo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String chatId,
                required bool fromMe,
                required String kind,
                required String body,
                required int sentAt,
                required int localAt,
                Value<int?> expiresAt = const Value.absent(),
                required String status,
                Value<String?> replyTo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                chatId: chatId,
                fromMe: fromMe,
                kind: kind,
                body: body,
                sentAt: sentAt,
                localAt: localAt,
                expiresAt: expiresAt,
                status: status,
                replyTo: replyTo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MessagesTable, Message>(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chatId = false, mediaRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mediaRefs) db.media],
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
                    if (chatId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.chatId,
                        referencedTable: $$MessagesTableReferences._chatIdTable(
                          db,
                        ),
                        referencedColumn: $$MessagesTableReferences
                            ._chatIdTable(db)
                            .peerId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mediaRefs)
                    await $_getPrefetchedDataByColumns<
                      Message,
                      $MessagesTable,
                      MediaItem,
                      $MediaTable
                    >(
                      currentTable: table,
                      referencedTable: $$MessagesTableReferences
                          ._mediaRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MessagesTableReferences(db, table, p0).mediaRefs,
                      currentColumn: 'id',
                      referencedColumn: 'message_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, $$MessagesTableReferences),
      Message,
      PrefetchHooks Function({bool chatId, bool mediaRefs})
    >;
typedef $$MediaTableCreateCompanionBuilder = MediaCompanion Function({
  required String messageId,
  required Uint8List bytes,
  required int width,
  required int height,
  Value<int> rowid,
});
typedef $$MediaTableUpdateCompanionBuilder = MediaCompanion Function({
  Value<String> messageId,
  Value<Uint8List> bytes,
  Value<int> width,
  Value<int> height,
  Value<int> rowid,
});

final class $$MediaTableReferences
    extends BaseReferences<_$AppDatabase, $MediaTable, MediaItem> {
  $$MediaTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MessagesTable _messageIdTable(_$AppDatabase db) =>
      db.messages.createAlias('media__message_id__messages__id');

  $$MessagesTableProcessedTableManager get messageId {
    final $_column = $_itemColumn<String>('message_id')!;

    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MediaTableFilterComposer extends Composer<_$AppDatabase, $MediaTable> {
  $$MediaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  $$MessagesTableFilterComposer get messageId {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaTable> {
  $$MediaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  $$MessagesTableOrderingComposer get messageId {
    final $$MessagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableOrderingComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaTable> {
  $$MediaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  $$MessagesTableAnnotationComposer get messageId {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaTable,
          MediaItem,
          $$MediaTableFilterComposer,
          $$MediaTableOrderingComposer,
          $$MediaTableAnnotationComposer,
          $$MediaTableCreateCompanionBuilder,
          $$MediaTableUpdateCompanionBuilder,
          (MediaItem, $$MediaTableReferences),
          MediaItem,
          PrefetchHooks Function({bool messageId})
        > {
  $$MediaTableTableManager(_$AppDatabase db, $MediaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<Uint8List> bytes = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaCompanion(
                messageId: messageId,
                bytes: bytes,
                width: width,
                height: height,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required Uint8List bytes,
                required int width,
                required int height,
                Value<int> rowid = const Value.absent(),
              }) => MediaCompanion.insert(
                messageId: messageId,
                bytes: bytes,
                width: width,
                height: height,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaTable, MediaItem>(table),
                  $$MediaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({messageId = false}) {
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
                    if (messageId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.messageId,
                        referencedTable: $$MediaTableReferences._messageIdTable(
                          db,
                        ),
                        referencedColumn: $$MediaTableReferences
                            ._messageIdTable(db)
                            .id,
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

typedef $$MediaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaTable,
      MediaItem,
      $$MediaTableFilterComposer,
      $$MediaTableOrderingComposer,
      $$MediaTableAnnotationComposer,
      $$MediaTableCreateCompanionBuilder,
      $$MediaTableUpdateCompanionBuilder,
      (MediaItem, $$MediaTableReferences),
      MediaItem,
      PrefetchHooks Function({bool messageId})
    >;
typedef $$MediaPartsTableCreateCompanionBuilder = MediaPartsCompanion Function({
  required String messageId,
  required int part,
  required String chatId,
  required int total,
  required Uint8List data,
  required int sentAt,
  Value<int?> ttlSeconds,
  required int width,
  required int height,
  required String sha256,
  Value<String?> replyTo,
  required int createdAt,
  Value<int> rowid,
});
typedef $$MediaPartsTableUpdateCompanionBuilder = MediaPartsCompanion Function({
  Value<String> messageId,
  Value<int> part,
  Value<String> chatId,
  Value<int> total,
  Value<Uint8List> data,
  Value<int> sentAt,
  Value<int?> ttlSeconds,
  Value<int> width,
  Value<int> height,
  Value<String> sha256,
  Value<String?> replyTo,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$MediaPartsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaPartsTable> {
  $$MediaPartsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get part => $composableBuilder(
    column: $table.part,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ttlSeconds => $composableBuilder(
    column: $table.ttlSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyTo => $composableBuilder(
    column: $table.replyTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaPartsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaPartsTable> {
  $$MediaPartsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get part => $composableBuilder(
    column: $table.part,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ttlSeconds => $composableBuilder(
    column: $table.ttlSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyTo => $composableBuilder(
    column: $table.replyTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaPartsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaPartsTable> {
  $$MediaPartsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get part =>
      $composableBuilder(column: $table.part, builder: (column) => column);

  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<int> get ttlSeconds => $composableBuilder(
    column: $table.ttlSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get replyTo =>
      $composableBuilder(column: $table.replyTo, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MediaPartsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaPartsTable,
          MediaPart,
          $$MediaPartsTableFilterComposer,
          $$MediaPartsTableOrderingComposer,
          $$MediaPartsTableAnnotationComposer,
          $$MediaPartsTableCreateCompanionBuilder,
          $$MediaPartsTableUpdateCompanionBuilder,
          (
            MediaPart,
            BaseReferences<_$AppDatabase, $MediaPartsTable, MediaPart>,
          ),
          MediaPart,
          PrefetchHooks Function()
        > {
  $$MediaPartsTableTableManager(_$AppDatabase db, $MediaPartsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaPartsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaPartsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaPartsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<int> part = const Value.absent(),
                Value<String> chatId = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<Uint8List> data = const Value.absent(),
                Value<int> sentAt = const Value.absent(),
                Value<int?> ttlSeconds = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String?> replyTo = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaPartsCompanion(
                messageId: messageId,
                part: part,
                chatId: chatId,
                total: total,
                data: data,
                sentAt: sentAt,
                ttlSeconds: ttlSeconds,
                width: width,
                height: height,
                sha256: sha256,
                replyTo: replyTo,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required int part,
                required String chatId,
                required int total,
                required Uint8List data,
                required int sentAt,
                Value<int?> ttlSeconds = const Value.absent(),
                required int width,
                required int height,
                required String sha256,
                Value<String?> replyTo = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MediaPartsCompanion.insert(
                messageId: messageId,
                part: part,
                chatId: chatId,
                total: total,
                data: data,
                sentAt: sentAt,
                ttlSeconds: ttlSeconds,
                width: width,
                height: height,
                sha256: sha256,
                replyTo: replyTo,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaPartsTable, MediaPart>(table),
                  BaseReferences<_$AppDatabase, $MediaPartsTable, MediaPart>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaPartsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaPartsTable,
      MediaPart,
      $$MediaPartsTableFilterComposer,
      $$MediaPartsTableOrderingComposer,
      $$MediaPartsTableAnnotationComposer,
      $$MediaPartsTableCreateCompanionBuilder,
      $$MediaPartsTableUpdateCompanionBuilder,
      (MediaPart, BaseReferences<_$AppDatabase, $MediaPartsTable, MediaPart>),
      MediaPart,
      PrefetchHooks Function()
    >;
typedef $$AvatarsTableCreateCompanionBuilder = AvatarsCompanion Function({
  required String ownerId,
  required Uint8List bytes,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$AvatarsTableUpdateCompanionBuilder = AvatarsCompanion Function({
  Value<String> ownerId,
  Value<Uint8List> bytes,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$AvatarsTableFilterComposer
    extends Composer<_$AppDatabase, $AvatarsTable> {
  $$AvatarsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AvatarsTableOrderingComposer
    extends Composer<_$AppDatabase, $AvatarsTable> {
  $$AvatarsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AvatarsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AvatarsTable> {
  $$AvatarsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AvatarsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AvatarsTable,
          Avatar,
          $$AvatarsTableFilterComposer,
          $$AvatarsTableOrderingComposer,
          $$AvatarsTableAnnotationComposer,
          $$AvatarsTableCreateCompanionBuilder,
          $$AvatarsTableUpdateCompanionBuilder,
          (Avatar, BaseReferences<_$AppDatabase, $AvatarsTable, Avatar>),
          Avatar,
          PrefetchHooks Function()
        > {
  $$AvatarsTableTableManager(_$AppDatabase db, $AvatarsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AvatarsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AvatarsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AvatarsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<Uint8List> bytes = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AvatarsCompanion(
                ownerId: ownerId,
                bytes: bytes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required Uint8List bytes,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AvatarsCompanion.insert(
                ownerId: ownerId,
                bytes: bytes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AvatarsTable, Avatar>(table),
                  BaseReferences<_$AppDatabase, $AvatarsTable, Avatar>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AvatarsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AvatarsTable,
      Avatar,
      $$AvatarsTableFilterComposer,
      $$AvatarsTableOrderingComposer,
      $$AvatarsTableAnnotationComposer,
      $$AvatarsTableCreateCompanionBuilder,
      $$AvatarsTableUpdateCompanionBuilder,
      (Avatar, BaseReferences<_$AppDatabase, $AvatarsTable, Avatar>),
      Avatar,
      PrefetchHooks Function()
    >;
typedef $$OlmSessionsTableCreateCompanionBuilder =
    OlmSessionsCompanion Function({
      required String sessionId,
      required String peerId,
      required String pickle,
      required int lastUsedAt,
      Value<int> rowid,
    });
typedef $$OlmSessionsTableUpdateCompanionBuilder =
    OlmSessionsCompanion Function({
      Value<String> sessionId,
      Value<String> peerId,
      Value<String> pickle,
      Value<int> lastUsedAt,
      Value<int> rowid,
    });

class $$OlmSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $OlmSessionsTable> {
  $$OlmSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerId => $composableBuilder(
    column: $table.peerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pickle => $composableBuilder(
    column: $table.pickle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OlmSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $OlmSessionsTable> {
  $$OlmSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerId => $composableBuilder(
    column: $table.peerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pickle => $composableBuilder(
    column: $table.pickle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OlmSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OlmSessionsTable> {
  $$OlmSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get peerId =>
      $composableBuilder(column: $table.peerId, builder: (column) => column);

  GeneratedColumn<String> get pickle =>
      $composableBuilder(column: $table.pickle, builder: (column) => column);

  GeneratedColumn<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$OlmSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OlmSessionsTable,
          OlmSession,
          $$OlmSessionsTableFilterComposer,
          $$OlmSessionsTableOrderingComposer,
          $$OlmSessionsTableAnnotationComposer,
          $$OlmSessionsTableCreateCompanionBuilder,
          $$OlmSessionsTableUpdateCompanionBuilder,
          (
            OlmSession,
            BaseReferences<_$AppDatabase, $OlmSessionsTable, OlmSession>,
          ),
          OlmSession,
          PrefetchHooks Function()
        > {
  $$OlmSessionsTableTableManager(_$AppDatabase db, $OlmSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OlmSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OlmSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OlmSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> peerId = const Value.absent(),
                Value<String> pickle = const Value.absent(),
                Value<int> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OlmSessionsCompanion(
                sessionId: sessionId,
                peerId: peerId,
                pickle: pickle,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String peerId,
                required String pickle,
                required int lastUsedAt,
                Value<int> rowid = const Value.absent(),
              }) => OlmSessionsCompanion.insert(
                sessionId: sessionId,
                peerId: peerId,
                pickle: pickle,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OlmSessionsTable, OlmSession>(table),
                  BaseReferences<_$AppDatabase, $OlmSessionsTable, OlmSession>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OlmSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OlmSessionsTable,
      OlmSession,
      $$OlmSessionsTableFilterComposer,
      $$OlmSessionsTableOrderingComposer,
      $$OlmSessionsTableAnnotationComposer,
      $$OlmSessionsTableCreateCompanionBuilder,
      $$OlmSessionsTableUpdateCompanionBuilder,
      (
        OlmSession,
        BaseReferences<_$AppDatabase, $OlmSessionsTable, OlmSession>,
      ),
      OlmSession,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  required String id,
  required String recipientId,
  required String type,
  required String envelope,
  Value<int?> expiresAt,
  Value<String?> messageId,
  required bool push,
  required int createdAt,
  Value<int> attempts,
  Value<int> rowid,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<String> id,
  Value<String> recipientId,
  Value<String> type,
  Value<String> envelope,
  Value<int?> expiresAt,
  Value<String?> messageId,
  Value<bool> push,
  Value<int> createdAt,
  Value<int> attempts,
  Value<int> rowid,
});

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
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

  ColumnFilters<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get envelope => $composableBuilder(
    column: $table.envelope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get push => $composableBuilder(
    column: $table.push,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
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

  ColumnOrderings<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get envelope => $composableBuilder(
    column: $table.envelope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get push => $composableBuilder(
    column: $table.push,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get envelope =>
      $composableBuilder(column: $table.envelope, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<bool> get push =>
      $composableBuilder(column: $table.push, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxEntry,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (
            OutboxEntry,
            BaseReferences<_$AppDatabase, $OutboxTable, OutboxEntry>,
          ),
          OutboxEntry,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recipientId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> envelope = const Value.absent(),
                Value<int?> expiresAt = const Value.absent(),
                Value<String?> messageId = const Value.absent(),
                Value<bool> push = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                id: id,
                recipientId: recipientId,
                type: type,
                envelope: envelope,
                expiresAt: expiresAt,
                messageId: messageId,
                push: push,
                createdAt: createdAt,
                attempts: attempts,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recipientId,
                required String type,
                required String envelope,
                Value<int?> expiresAt = const Value.absent(),
                Value<String?> messageId = const Value.absent(),
                required bool push,
                required int createdAt,
                Value<int> attempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                id: id,
                recipientId: recipientId,
                type: type,
                envelope: envelope,
                expiresAt: expiresAt,
                messageId: messageId,
                push: push,
                createdAt: createdAt,
                attempts: attempts,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxEntry>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, OutboxEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxEntry,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxEntry, BaseReferences<_$AppDatabase, $OutboxTable, OutboxEntry>),
      OutboxEntry,
      PrefetchHooks Function()
    >;
typedef $$PendingDeletesTableCreateCompanionBuilder =
    PendingDeletesCompanion Function({
      required String messageId,
      required String chatId,
      Value<int> rowid,
    });
typedef $$PendingDeletesTableUpdateCompanionBuilder =
    PendingDeletesCompanion Function({
      Value<String> messageId,
      Value<String> chatId,
      Value<int> rowid,
    });

class $$PendingDeletesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingDeletesTable> {
  $$PendingDeletesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingDeletesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingDeletesTable> {
  $$PendingDeletesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingDeletesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingDeletesTable> {
  $$PendingDeletesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);
}

class $$PendingDeletesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingDeletesTable,
          PendingDelete,
          $$PendingDeletesTableFilterComposer,
          $$PendingDeletesTableOrderingComposer,
          $$PendingDeletesTableAnnotationComposer,
          $$PendingDeletesTableCreateCompanionBuilder,
          $$PendingDeletesTableUpdateCompanionBuilder,
          (
            PendingDelete,
            BaseReferences<_$AppDatabase, $PendingDeletesTable, PendingDelete>,
          ),
          PendingDelete,
          PrefetchHooks Function()
        > {
  $$PendingDeletesTableTableManager(
    _$AppDatabase db,
    $PendingDeletesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingDeletesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingDeletesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingDeletesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String> chatId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingDeletesCompanion(
                messageId: messageId,
                chatId: chatId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required String chatId,
                Value<int> rowid = const Value.absent(),
              }) => PendingDeletesCompanion.insert(
                messageId: messageId,
                chatId: chatId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingDeletesTable, PendingDelete>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingDeletesTable,
                    PendingDelete
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingDeletesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingDeletesTable,
      PendingDelete,
      $$PendingDeletesTableFilterComposer,
      $$PendingDeletesTableOrderingComposer,
      $$PendingDeletesTableAnnotationComposer,
      $$PendingDeletesTableCreateCompanionBuilder,
      $$PendingDeletesTableUpdateCompanionBuilder,
      (
        PendingDelete,
        BaseReferences<_$AppDatabase, $PendingDeletesTable, PendingDelete>,
      ),
      PendingDelete,
      PrefetchHooks Function()
    >;
typedef $$ProcessedEnvelopesTableCreateCompanionBuilder =
    ProcessedEnvelopesCompanion Function({
      required String id,
      required int processedAt,
      Value<int> rowid,
    });
typedef $$ProcessedEnvelopesTableUpdateCompanionBuilder =
    ProcessedEnvelopesCompanion Function({
      Value<String> id,
      Value<int> processedAt,
      Value<int> rowid,
    });

class $$ProcessedEnvelopesTableFilterComposer
    extends Composer<_$AppDatabase, $ProcessedEnvelopesTable> {
  $$ProcessedEnvelopesTableFilterComposer({
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

  ColumnFilters<int> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProcessedEnvelopesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProcessedEnvelopesTable> {
  $$ProcessedEnvelopesTableOrderingComposer({
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

  ColumnOrderings<int> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProcessedEnvelopesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProcessedEnvelopesTable> {
  $$ProcessedEnvelopesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => column,
  );
}

class $$ProcessedEnvelopesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProcessedEnvelopesTable,
          ProcessedEnvelope,
          $$ProcessedEnvelopesTableFilterComposer,
          $$ProcessedEnvelopesTableOrderingComposer,
          $$ProcessedEnvelopesTableAnnotationComposer,
          $$ProcessedEnvelopesTableCreateCompanionBuilder,
          $$ProcessedEnvelopesTableUpdateCompanionBuilder,
          (
            ProcessedEnvelope,
            BaseReferences<
              _$AppDatabase,
              $ProcessedEnvelopesTable,
              ProcessedEnvelope
            >,
          ),
          ProcessedEnvelope,
          PrefetchHooks Function()
        > {
  $$ProcessedEnvelopesTableTableManager(
    _$AppDatabase db,
    $ProcessedEnvelopesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProcessedEnvelopesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProcessedEnvelopesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProcessedEnvelopesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> processedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProcessedEnvelopesCompanion(
                id: id,
                processedAt: processedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int processedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProcessedEnvelopesCompanion.insert(
                id: id,
                processedAt: processedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProcessedEnvelopesTable, ProcessedEnvelope>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ProcessedEnvelopesTable,
                    ProcessedEnvelope
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProcessedEnvelopesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProcessedEnvelopesTable,
      ProcessedEnvelope,
      $$ProcessedEnvelopesTableFilterComposer,
      $$ProcessedEnvelopesTableOrderingComposer,
      $$ProcessedEnvelopesTableAnnotationComposer,
      $$ProcessedEnvelopesTableCreateCompanionBuilder,
      $$ProcessedEnvelopesTableUpdateCompanionBuilder,
      (
        ProcessedEnvelope,
        BaseReferences<
          _$AppDatabase,
          $ProcessedEnvelopesTable,
          ProcessedEnvelope
        >,
      ),
      ProcessedEnvelope,
      PrefetchHooks Function()
    >;
typedef $$KeyValuesTableCreateCompanionBuilder = KeyValuesCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KeyValuesTableUpdateCompanionBuilder = KeyValuesCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValue,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
          KeyValue,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValue>(table),
                  BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValue,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
      KeyValue,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChatsTableTableManager get chats =>
      $$ChatsTableTableManager(_db, _db.chats);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MediaTableTableManager get media =>
      $$MediaTableTableManager(_db, _db.media);
  $$MediaPartsTableTableManager get mediaParts =>
      $$MediaPartsTableTableManager(_db, _db.mediaParts);
  $$AvatarsTableTableManager get avatars =>
      $$AvatarsTableTableManager(_db, _db.avatars);
  $$OlmSessionsTableTableManager get olmSessions =>
      $$OlmSessionsTableTableManager(_db, _db.olmSessions);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$PendingDeletesTableTableManager get pendingDeletes =>
      $$PendingDeletesTableTableManager(_db, _db.pendingDeletes);
  $$ProcessedEnvelopesTableTableManager get processedEnvelopes =>
      $$ProcessedEnvelopesTableTableManager(_db, _db.processedEnvelopes);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
}
