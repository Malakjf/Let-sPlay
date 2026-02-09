import { ConnectorConfig, DataConnect, OperationOptions, ExecuteOperationResponse } from 'firebase-admin/data-connect';

export const connectorConfig: ConnectorConfig;

export type TimestampString = string;
export type UUIDString = string;
export type Int64String = string;
export type DateString = string;


export interface CreateNewMatchData {
  match_insert: {
    id: UUIDString;
  };
}

export interface CreateNewMatchVariables {
  fieldId: UUIDString;
  dateTime: TimestampString;
  description: string;
  maxParticipants: number;
  name: string;
  status: string;
}

export interface Field_Key {
  id: UUIDString;
  __typename?: 'Field_Key';
}

export interface JoinMatchData {
  matchJoin_insert: {
    userId: UUIDString;
    matchId: UUIDString;
  };
}

export interface JoinMatchVariables {
  matchId: UUIDString;
}

export interface ListAvailableMatchesData {
  matches: ({
    id: UUIDString;
    name: string;
    dateTime: TimestampString;
    description: string;
    maxParticipants?: number | null;
    field?: {
      name: string;
      address: string;
    };
  } & Match_Key)[];
}

export interface ListMyJoinedMatchesData {
  matchJoins: ({
    match: {
      id: UUIDString;
      name: string;
      dateTime: TimestampString;
      description: string;
      maxParticipants?: number | null;
      field?: {
        name: string;
        address: string;
      };
    } & Match_Key;
      joinedAt: TimestampString;
      role?: string | null;
  })[];
}

export interface MatchJoin_Key {
  userId: UUIDString;
  matchId: UUIDString;
  __typename?: 'MatchJoin_Key';
}

export interface MatchRequest_Key {
  userId: UUIDString;
  matchId: UUIDString;
  __typename?: 'MatchRequest_Key';
}

export interface Match_Key {
  id: UUIDString;
  __typename?: 'Match_Key';
}

export interface User_Key {
  id: UUIDString;
  __typename?: 'User_Key';
}

/** Generated Node Admin SDK operation action function for the 'CreateNewMatch' Mutation. Allow users to execute without passing in DataConnect. */
export function createNewMatch(dc: DataConnect, vars: CreateNewMatchVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateNewMatchData>>;
/** Generated Node Admin SDK operation action function for the 'CreateNewMatch' Mutation. Allow users to pass in custom DataConnect instances. */
export function createNewMatch(vars: CreateNewMatchVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateNewMatchData>>;

/** Generated Node Admin SDK operation action function for the 'ListAvailableMatches' Query. Allow users to execute without passing in DataConnect. */
export function listAvailableMatches(dc: DataConnect, options?: OperationOptions): Promise<ExecuteOperationResponse<ListAvailableMatchesData>>;
/** Generated Node Admin SDK operation action function for the 'ListAvailableMatches' Query. Allow users to pass in custom DataConnect instances. */
export function listAvailableMatches(options?: OperationOptions): Promise<ExecuteOperationResponse<ListAvailableMatchesData>>;

/** Generated Node Admin SDK operation action function for the 'JoinMatch' Mutation. Allow users to execute without passing in DataConnect. */
export function joinMatch(dc: DataConnect, vars: JoinMatchVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<JoinMatchData>>;
/** Generated Node Admin SDK operation action function for the 'JoinMatch' Mutation. Allow users to pass in custom DataConnect instances. */
export function joinMatch(vars: JoinMatchVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<JoinMatchData>>;

/** Generated Node Admin SDK operation action function for the 'ListMyJoinedMatches' Query. Allow users to execute without passing in DataConnect. */
export function listMyJoinedMatches(dc: DataConnect, options?: OperationOptions): Promise<ExecuteOperationResponse<ListMyJoinedMatchesData>>;
/** Generated Node Admin SDK operation action function for the 'ListMyJoinedMatches' Query. Allow users to pass in custom DataConnect instances. */
export function listMyJoinedMatches(options?: OperationOptions): Promise<ExecuteOperationResponse<ListMyJoinedMatchesData>>;

