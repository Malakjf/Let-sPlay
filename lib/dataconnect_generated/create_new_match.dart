part of 'generated.dart';

class CreateNewMatchVariablesBuilder {
  String fieldId;
  Timestamp dateTime;
  String description;
  int maxParticipants;
  String name;
  String status;

  final FirebaseDataConnect _dataConnect;
  CreateNewMatchVariablesBuilder(this._dataConnect, {required  this.fieldId,required  this.dateTime,required  this.description,required  this.maxParticipants,required  this.name,required  this.status,});
  Deserializer<CreateNewMatchData> dataDeserializer = (dynamic json)  => CreateNewMatchData.fromJson(jsonDecode(json));
  Serializer<CreateNewMatchVariables> varsSerializer = (CreateNewMatchVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateNewMatchData, CreateNewMatchVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateNewMatchData, CreateNewMatchVariables> ref() {
    CreateNewMatchVariables vars= CreateNewMatchVariables(fieldId: fieldId,dateTime: dateTime,description: description,maxParticipants: maxParticipants,name: name,status: status,);
    return _dataConnect.mutation("CreateNewMatch", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateNewMatchMatchInsert {
  final String id;
  CreateNewMatchMatchInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateNewMatchMatchInsert otherTyped = other as CreateNewMatchMatchInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateNewMatchMatchInsert({
    required this.id,
  });
}

@immutable
class CreateNewMatchData {
  final CreateNewMatchMatchInsert match_insert;
  CreateNewMatchData.fromJson(dynamic json):
  
  match_insert = CreateNewMatchMatchInsert.fromJson(json['match_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateNewMatchData otherTyped = other as CreateNewMatchData;
    return match_insert == otherTyped.match_insert;
    
  }
  @override
  int get hashCode => match_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['match_insert'] = match_insert.toJson();
    return json;
  }

  CreateNewMatchData({
    required this.match_insert,
  });
}

@immutable
class CreateNewMatchVariables {
  final String fieldId;
  final Timestamp dateTime;
  final String description;
  final int maxParticipants;
  final String name;
  final String status;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateNewMatchVariables.fromJson(Map<String, dynamic> json):
  
  fieldId = nativeFromJson<String>(json['fieldId']),
  dateTime = Timestamp.fromJson(json['dateTime']),
  description = nativeFromJson<String>(json['description']),
  maxParticipants = nativeFromJson<int>(json['maxParticipants']),
  name = nativeFromJson<String>(json['name']),
  status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateNewMatchVariables otherTyped = other as CreateNewMatchVariables;
    return fieldId == otherTyped.fieldId && 
    dateTime == otherTyped.dateTime && 
    description == otherTyped.description && 
    maxParticipants == otherTyped.maxParticipants && 
    name == otherTyped.name && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([fieldId.hashCode, dateTime.hashCode, description.hashCode, maxParticipants.hashCode, name.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['fieldId'] = nativeToJson<String>(fieldId);
    json['dateTime'] = dateTime.toJson();
    json['description'] = nativeToJson<String>(description);
    json['maxParticipants'] = nativeToJson<int>(maxParticipants);
    json['name'] = nativeToJson<String>(name);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  CreateNewMatchVariables({
    required this.fieldId,
    required this.dateTime,
    required this.description,
    required this.maxParticipants,
    required this.name,
    required this.status,
  });
}

