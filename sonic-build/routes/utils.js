const util = require('util');
const request = require('request');

function _request_internal(options) {
    return new Promise((resolve, reject) => {
        request(options, (error, response, body) => {
            if (error) {
                console.error(error);
                reject(error);
            }
            if (response.statusCode != 200) {
                console.error(response.statusCode);
                reject('Invalid status code <' + response.statusCode + '>');
            }
            resolve(body);
        });
    });
}

async function _request(method, url, options=null) {
    try{
        if (options == null){
            options = {}
        }
        options['url'] = url;
        options['method'] = method;

        return _request_internal(options);
    }
    catch(error)
    {
        console.error(util.format("failed to %s request to %s", method, url));
        return "";
    }
}

module.exports = Object.freeze({
    request: _request,
});