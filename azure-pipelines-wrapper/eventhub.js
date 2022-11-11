const { EventHubProducerClient } = require("@azure/event-hubs");
const { ApprovalType } = require("azure-devops-node-api/interfaces/ReleaseInterfaces");

require('dotenv').config();


const akv = require('./keyvault');
const eventHubName = process.env["EVENTHUB_NAME"];
var producer = null;
var count = 100;

async function getProducer(){
    
    if (producer == null){
        const connectionString = await akv.getEventhubConnectionstring();
        producer = new EventHubProducerClient(connectionString, eventHubName);
    };

    return producer;
}

async function sendEventBatch(eventDatas)
{
    if (producer == null){
        const connectionString = await akv.getEventhubConnectionstring();
        producer = new EventHubProducerClient(connectionString, eventHubName);
    };

    const batch = await producer.createBatch();
    eventDatas.forEach(eventData => {
        if (!batch.tryAdd(eventData)){
            app.log.error("Failed to add eventData");
        }
    });
    await producer.sendBatch(batch);
}

function init(app)
{
    app.log.info('eventhub init');
    app.onAny(async (context) => {
        app.log.info({timestamp: new Date().toISOString(), event: context.name, action: context.payload.action });
        console.log(`Log event ${context.name} ${context.payload.action} to event hubs`);
        var eventDatas = [];
        var eventData = {
            body: {"Timestamp": new Date().toISOString(), "Name": context.name, "Action": context.payload.action, "Payload": context.payload}
        };
        eventDatas.push(eventData);
        await sendEventBatch(eventDatas);
      });
}

module.exports = Object.freeze({
    init: init,
});