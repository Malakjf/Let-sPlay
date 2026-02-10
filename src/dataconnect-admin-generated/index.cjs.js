const { validateAdminArgs } = require('firebase-admin/data-connect');

const connectorConfig = {
  connector: 'example',
  serviceId: 'letsplay',
  location: 'us-east4'
};
exports.connectorConfig = connectorConfig;

function createNewMatch(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('CreateNewMatch', inputVars, inputOpts);
}
exports.createNewMatch = createNewMatch;

function listAvailableMatches(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrOptions, options, undefined);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListAvailableMatches', undefined, inputOpts);
}
exports.listAvailableMatches = listAvailableMatches;

function joinMatch(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('JoinMatch', inputVars, inputOpts);
}
exports.joinMatch = joinMatch;

function listMyJoinedMatches(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrOptions, options, undefined);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListMyJoinedMatches', undefined, inputOpts);
}
exports.listMyJoinedMatches = listMyJoinedMatches;

