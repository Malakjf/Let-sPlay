part of 'generated.dart';

class ListAvailableMatchesVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListAvailableMatchesVariablesBuilder(this._dataConnect, );
  Deserializer<ListAvailableMatchesData> dataDeserializer = (dynamic json)  => ListAvailableMatchesData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListAvailableMatchesData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListAvailableMatchesData, void> ref() {
    
    return _dataConnect.query("ListAvailableMatches", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListAvailableMatchesMatches {
  final String id;
  final String name;
  final Timestamp dateTime;
  final String description;
  final int? maxParticipants;
  final ListAvailableMatchesMatchesField? field;
  ListAvailableMatchesMatches.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  dateTime = Timestamp.fromJson(json['dateTime']),
  description = nativeFromJson<String>(json['description']),
  maxParticipants = json['maxParticipants'] == null ? null : nativeFromJson<int>(json['maxParticipants']),
  field = json['field'] == null ? null : ListAvailableMatchesMatchesField.fromJson(json['field']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAvailableMatchesMatches otherTyped = other as ListAvailableMatchesMatches;
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

  ListAvailableMatchesMatches({
    required this.id,
    required this.name,
    required this.dateTime,
    required this.description,
    this.maxParticipants,
    this.field,
  });
}

@immutable
class ListAvailableMatchesMatchesField {
  final String name;
  final String address;
  ListAvailableMatchesMatchesField.fromJson(dynamic json):
  
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

    final ListAvailableMatchesMatchesField otherTyped = other as ListAvailableMatchesMatchesField;
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

  ListAvailableMatchesMatchesField({
    required this.name,
    required this.address,
  });
}

@immutable
class ListAvailableMatchesData {
  final List<ListAvailableMatchesMatches> matches;
  ListAvailableMatchesData.fromJson(dynamic json):
  
  matches = (json['matches'] as List<dynamic>)
        .map((e) => ListAvailableMatchesMatches.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAvailableMatchesData otherTyped = other as ListAvailableMatchesData;
    return matches == otherTyped.matches;
    
  }
  @override
  int get hashCode => matches.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['matches'] = matches.map((e) => e.toJson()).toList();
    return json;
  }

  ListAvailableMatchesData({
    required this.matches,
  });
}

