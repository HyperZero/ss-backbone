// Generated by CoffeeScript 1.6.3
var fs, pathlib;

fs = require('fs');

pathlib = require('path');

module.exports = function(responderId, config, ss) {
  var backbone, backboneSync, client_api_registration, name, underscore;
  name = config && config.name || 'backbone';
  if (!config.dontSendLibs) {
    underscore = fs.readFileSync(__dirname + '/../vendor/lib/underscore-min.js', 'utf8');
    backbone = fs.readFileSync(__dirname + '/../vendor/lib/backbone-min.js', 'utf8');
    ss.client.send('code', 'init', underscore);
    ss.client.send('code', 'init', backbone);
  }
  backboneSync = fs.readFileSync(__dirname + '/client.' + (process.env['SS_DEV'] && 'coffee' || 'js'), 'utf8');
  ss.client.send('code', 'init', backboneSync, {
    coffee: process.env['SS_DEV']
  });
  client_api_registration = fs.readFileSync(__dirname + '/register.' + (process.env['SS_DEV'] && 'coffee' || 'js'), 'utf8');
  ss.client.send('mod', 'ss-backbone', client_api_registration, {
    coffee: process.env['SS_DEV']
  });
  ss.client.send('code', 'init', "require('ss-backbone')(" + responderId + ", {}, require('socketstream').send(" + responderId + "));");
  return {
    name: name,
    interfaces: function(middleware) {
      return {
        websocket: function(msg, meta, send) {
          var e, handleError, model, req, request;
          request = require('./request')(ss, middleware, config);
          msg = JSON.parse(msg);
          model = msg.model;
          req = {
            modelName: msg.modelname,
            modelConnectionId: msg.modelConnectionId,
            cid: msg.cid,
            method: msg.method,
            params: msg.params,
            socketId: meta.socketId,
            clientIp: meta.clientIp,
            sessionId: meta.sessionId,
            transport: meta.transport,
            receivedAt: Date.now()
          };
          if (req.params && req.params.modelToReq) {
            req.model = model;
          }
          handleError = function(e) {
            var message, obj;
            message = (meta.clientIp === '127.0.0.1') && e.stack || 'See server-side logs';
            obj = {
              id: req.id,
              e: {
                message: message
              }
            };
            ss.log('↩'.red, req.method, e.message.red);
            if (e.stack) {
              ss.log(e.stack.split("\n").splice(1).join("\n"));
            }
            return send(JSON.stringify(obj));
          };
          try {
            return request(model, req, function(err, response) {
              var timeTaken;
              if (err) {
                return handleError(err);
              }
              timeTaken = Date.now() - req.receivedAt;
              ss.log('↩'.green, req.method, ("(" + timeTaken + "ms)").grey);
              return send(JSON.stringify(response));
            });
          } catch (_error) {
            e = _error;
            return handleError(e);
          }
        }
      };
    }
  };
};
