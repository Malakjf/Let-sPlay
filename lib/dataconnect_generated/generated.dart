library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_new_match.dart';

part 'list_available_matches.dart';

part 'join_match.dart';

part 'list_my_joined_matches.dart';







class ExampleConnector {
  
  
  CreateNewMatchVariablesBuilder createNewMatch ({required String fieldId, required Timestamp dateTime, required String description, required int maxParticipants, required String name, required String status, }) {
    return CreateNewMatchVariablesBuilder(dataConnect, fieldId: fieldId,dateTime: dateTime,description: description,maxParticipants: maxParticipants,name: name,status: status,);
  }
  
  
  ListAvailableMatchesVariablesBuilder listAvailableMatches () {
    return ListAvailableMatchesVariablesBuilder(dataConnect, );
  }
  
  
  JoinMatchVariablesBuilder joinMatch ({required String matchId, }) {
    return JoinMatchVariablesBuilder(dataConnect, matchId: matchId,);
  }
  
  
  ListMyJoinedMatchesVariablesBuilder listMyJoinedMatches () {
    return ListMyJoinedMatchesVariablesBuilder(dataConnect, );
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east4',
    'example',
    'letsplay',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
