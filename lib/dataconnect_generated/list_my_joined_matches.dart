part of 'generated.dart';

class ListMyJoinedMatchesVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListMyJoinedMatchesVariablesBuilder(this._dataConnect, );
  Deserializer<ListMyJoinedMatchesData> dataDeserializer = (dynamic json)  => ListMyJoinedMatchesData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListMyJoinedMatchesData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListMyJoinedMatchesData, void> ref() {
    
    return _dataConnect.query("ListMyJoinedMatches", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListMyJoinedMatchesMatchJoins {
  final ListMyJoinedMatchesMatchJoinsMatch match;
  final Timestamp joinedAt;
  final String? role;
  ListMyJoinedMatchesMatchJoins.fromJson(dynamic json):
  
  match = ListMyJoinedMatchesMatchJoinsMatch.fromJson(json['match']),
  joinedAt = Timestamp.fromJson(json['joinedAt']),
  role = json['role'] == null ? null : nativeFromJson<String>(json['role']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyJoinedMatchesMatchJoins otherTyped = other as ListMyJoinedMatchesMatchJoins;
    return match == otherTyped.match && 
    joinedAt == otherTyped.joinedAt && 
    role == otherTyped.role;
    
  }
  @override
  int get hashCode => Object.hashAll([match.hashCode, joinedAt.hashCode, role.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['match'] = match.toJson();
    json['joinedAt'] = joinedAt.toJson();
    if (role != null) {
      json['role'] = nativeToJson<String?>(role);
    }
    return json;
  }

  ListMyJoinedMatchesMatchJoins({
    required this.match,
    required this.joinedAt,
    this.role,
  });
}

@immutable
class ListMyJoinedMatchesMatchJoinsMatch {
  final String id;
  final String name;
  final Timestamp dateTime;
  final String description;
  final int? maxParticipants;
  final ListMyJoinedMatchesMatchJoinsMatchField? field;
  ListMyJoinedMatchesMatchJoinsMatch.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  dateTime = Timestamp.fromJson(json['dateTime']),
  description = nativeFromJson<String>(json['description']),
  maxParticipants = json['maxParticipants'] == null ? null : nativeFromJson<int>(json['maxParticipants']),
  field = json['field'] == null ? null : ListMyJoinedMatchesMatchJoinsMatchField.fromJson(json['field']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyJoinedMatchesMatchJoinsMatch otherTyped = other as ListMyJoinedMatchesMatchJoinsMatch;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    dateTime == otherTyped.dateTime && 
    description == otherTyped.description && 
    maxParticipants == otherTyped.maxParticipants && 
    field == otherTyped.field;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, dateTime.hashCode, description.hashCode, maxParticipants.hashCode, field.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['dateTime'] = dateTime.toJson();
    json['description'] = nativeToJson<String>(description);
    if (maxParticipants != null) {
      json['maxParticipants'] = nativeToJson<int?>(maxParticipants);
    }
    if (field != null) {
      json['field'] = field!.toJson();
    }
    return json;
  }

  ListMyJoinedMatchesMatchJoinsMatch({
    required this.id,
    required this.name,
    required this.dateTime,
    required this.description,
    this.maxParticipants,
    this.field,
  });
}

@immutable
class ListMyJoinedMatchesMatchJoinsMatchField {
  final String name;
  final String address;
  ListMyJoinedMatchesMatchJoinsMatchField.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']),
  address = nativeFromJson<String>(json['address']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyJoinedMatchesMatchJoinsMatchField otherTyped = other as ListMyJoinedMatchesMatchJoinsMatchField;
    return name == otherTyped.name && 
    address == otherTyped.address;
    
  }
  @override
  int get hashCode => Object.hashAll([name.hashCode, address.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    json['address'] = nativeToJson<String>(address);
    return json;
  }

  ListMyJoinedMatchesMatchJoinsMatchField({
    required this.name,
    required this.address,
  });
}

@immutable
class ListMyJoinedMatchesData {
  final List<ListMyJoinedMatchesMatchJoins> matchJoins;
  ListMyJoinedMatchesData.fromJson(dynamic json):
  
  matchJoins = (json['matchJoins'] as List<dynamic>)
        .map((e) => ListMyJoinedMatchesMatchJoins.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyJoinedMatchesData otherTyped = other as ListMyJoinedMatchesData;
    return matchJoins == otherTyped.matchJoins;
    
  }
  @override
  int get hashCode => matchJoins.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['matchJoins'] = matchJoins.map((e) => e.toJson()).toList();
    return json;
  }

  ListMyJoinedMatchesData({
    required this.matchJoins,
  });
}

