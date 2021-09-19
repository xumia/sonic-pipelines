import azdev=require("azure-devops-node-api");
import azTask = require('azure-pipelines-task-lib/task');
import azBuild = require("azure-devops-node-api/BuildApi");
import fs = require('fs');

async function getconnection(){
    const accessToken = azTask.getEndpointAuthorizationParameter('SystemVssConnection', 'AccessToken', false);
    const collectionUri = azTask.getVariable('System.TeamFoundationCollectionUri');
    const buildId = azTask.getVariable('Build.BuildId');
    const projectId = azTask.getVariable('System.TeamProjectId');
    if (collectionUri == undefined){
        console.error(`The collectionUri is empty.`);
        return undefined;
    }

    if (accessToken == undefined){
        console.error(`The AccessToken is empty.`);
        return undefined;
    }

    var authHandler = azdev.getPersonalAccessTokenHandler(accessToken);
    var connection = new azdev.WebApi(collectionUri, authHandler);
    return connection;
}

async function run() {
    try {
        const properties: string | undefined = azTask.getInput('properties');
        const inputFile: string | undefined = azTask.getInput('inputFile');
        const accessToken = azTask.getEndpointAuthorizationParameter('SystemVssConnection', 'AccessToken', false);
        const collectionUri = azTask.getVariable('System.TeamFoundationCollectionUri');
        const buildId = azTask.getVariable('Build.BuildId');
        const projectId = azTask.getVariable('System.TeamProjectId');

        if (!properties && !inputFile){
            console.info(`Skipped for no properties or inputFile set`);
            return;
        }

        var jsonProperties = {};
        if (properties){
            jsonProperties = JSON.parse(properties);
        }
        else{
            jsonProperties = JSON.parse(fs.readFileSync(inputFile!, 'utf8'));
        }

        if (buildId == undefined){
            console.error(`The buildId is empty.`);
            return undefined;
        }

        if (projectId == undefined){
            console.error(`The projectId is empty.`);
            return undefined;
        }

        var buildNumber = Number(buildId);

        var connection = await getconnection();
        if (connection == undefined){
            azTask.setResult(azTask.TaskResult.Failed, "Failed to create connection.");
            return;
        }

        var build = await connection.getBuildApi();
        await build.updateBuildProperties(null, jsonProperties, projectId, buildNumber);
        console.log(`Update the build properties sucessfully.`);
    }
    catch (err) {
        azTask.setResult(azTask.TaskResult.Failed, err.message);
    }
}

run();