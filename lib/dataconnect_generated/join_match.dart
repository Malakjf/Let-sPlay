part of 'generated.dart';

class JoinMatchVariablesBuilder {
  String matchId;

  final FirebaseDataConnect _dataConnect;
  JoinMatchVariablesBuilder(this._dataConnect, {required  this.matchId,});
  Deserializer<JoinMatchData> dataDeserializer = (dynamic json)  => JoinMatchData.fromJson(jsonDecode(json));
  Serializer<JoinMatchVariables> varsSerializer = (JoinMatchVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<JoinMatchData, JoinMatchVariables>> execute() {
    return ref().execute();
  }

  MutationRef<JoinMatchData, JoinMatchVariables> ref() {
    JoinMatchVariables vars= JoinMatchVariables(matchId: matchId,);
    return _dataConnect.mutation("JoinMatch", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class JoinMatchMatchJoinInsert {
  final String userId;
  final String matchId;
  JoinMatchMatchJoinInsert.fromJson(dynamic json):
  
  userId = nativeFromJson<String>(json['userId']),
  matchId = nativeFromJson<String>(json['matchId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final JoinMatchMatchJoinInsert otherTyped = other as JoinMatchMatchJoinInsert;
    return userId == otherTyped.userId && 
    matchId == otherTyped.matchId;
    
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, matchId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['matchId'] = nativeToJson<String>(matchId);
    return json;
  }

  JoinMatchMatchJoinInsert({
    required this.userId,
    required this.matchId,
  });
}

@immutable
class JoinMatchData {
  final JoinMatchMatchJoinInsert matchJoin_insert;
  JoinMatchData.fromJson(dynamic json):
  
  matchJoin_insert = JoinMatchMatchJoinInsert.fromJson(json['matchJoin_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final JoinMatchData otherTyped = other as JoinMatchData;
    return matchJoin_insert == otherTyped.matchJoin_insert;
    
  }
  @override
  int get hashCode => matchJoin_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['matchJoin_insert'] = matchJoin_insert.toJson();
    return json;
  }

  JoinMatchData({
    required this.matchJoin_insert,
  });
}

@immutable
class JoinMatchVariables {
  final String matchId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  JoinMatchVariables.fromJson(Map<String, dynamic> json):
  
  matchId = nativeFromJson<String>(json['matchId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final JoinMatchVariables otherTyped = other as JoinMatchVariables;
    return matchId == otherTyped.matchId;
    
  }
  @override
  int get hashCode => matchId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['matchId'] = nativeToJson<String>(matchId);
    return json;
  }

  JoinMatchVariables({
    required this.matchId,
  });
}

