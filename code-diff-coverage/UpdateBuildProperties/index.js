"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const azdev = require("azure-devops-node-api");
const azTask = require("azure-pipelines-task-lib/task");
const fs = require("fs");
function getconnection() {
    return __awaiter(this, void 0, void 0, function* () {
        const accessToken = azTask.getEndpointAuthorizationParameter('SystemVssConnection', 'AccessToken', false);
        const collectionUri = azTask.getVariable('System.TeamFoundationCollectionUri');
        const buildId = azTask.getVariable('Build.BuildId');
        const projectId = azTask.getVariable('System.TeamProjectId');
        if (collectionUri == undefined) {
            console.error(`The collectionUri is empty.`);
            return undefined;
        }
        if (accessToken == undefined) {
            console.error(`The AccessToken is empty.`);
            return undefined;
        }
        var authHandler = azdev.getPersonalAccessTokenHandler(accessToken);
        var connection = new azdev.WebApi(collectionUri, authHandler);
        return connection;
    });
}
function run() {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            const properties = azTask.getInput('properties');
            const inputFile = azTask.getInput('inputFile');
            const accessToken = azTask.getEndpointAuthorizationParameter('SystemVssConnection', 'AccessToken', false);
            const collectionUri = azTask.getVariable('System.TeamFoundationCollectionUri');
            const buildId = azTask.getVariable('Build.BuildId');
            const projectId = azTask.getVariable('System.TeamProjectId');
            if (!properties && !inputFile) {
                console.info(`Skipped for no properties or inputFile set`);
                return;
            }
            var jsonProperties = {};
            if (properties) {
                jsonProperties = JSON.parse(properties);
            }
            else {
                jsonProperties = JSON.parse(fs.readFileSync(inputFile, 'utf8'));
            }
            if (buildId == undefined) {
                console.error(`The buildId is empty.`);
                return undefined;
            }
            if (projectId == undefined) {
                console.error(`The projectId is empty.`);
                return undefined;
            }
            var buildNumber = Number(buildId);
            var connection = yield getconnection();
            if (connection == undefined) {
                azTask.setResult(azTask.TaskResult.Failed, "Failed to create connection.");
                return;
            }
            var build = yield connection.getBuildApi();
            yield build.updateBuildProperties(null, jsonProperties, projectId, buildNumber);
            console.log(`Update the build properties sucessfully.`);
        }
        catch (err) {
            azTask.setResult(azTask.TaskResult.Failed, err.message);
        }
    });
}
run();
