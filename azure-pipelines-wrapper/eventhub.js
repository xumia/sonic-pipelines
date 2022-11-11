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
    //await producer.sendBatch(batch);
    
    //await producer.close();
}

function init(app)
{
    app.log.info('t1');
    app.onAny(async (context) => {
        app.log.info({timestamp: new Date().toISOString(), event: context.name, action: context.payload.action });
        var eventDatas = [];
        var eventData = {
            body: {"timeStamp": "11/10/2022 11:17:44 AM", "name": "name 78", "metric": 79, "source": "EventHubMessage3"}
        };
        //eventDatas.push(eventData);
        var eventData2 = {
            body: {"Timestamp": new Date().toISOString(), "Name": context.name, "Action": context.payload.action, "Payload": context.payload}
        };
        eventDatas.push(eventData2);
        await sendEventBatch(eventDatas);
        app.log({timestamp: new Date().toISOString(), event: context.name, action: context.payload.action})
      });
}

module.exports = Object.freeze({
    init: init,
});