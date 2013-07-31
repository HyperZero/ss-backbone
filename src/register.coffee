ss = undefined
ss = require("socketstream")
cbStack = {}
numRequests = 0
defaultCallback = (x) ->
  console.log x

module.exports = (responderId, config, send) ->
  ss.registerApi "backbone", (req, cb) ->
    
    # console.log("ss-backbone register", req, cb);
    msg = undefined
    req.id = ++numRequests
    cb = defaultCallback  if typeof cb isnt "function"
    cbStack[numRequests] = cb
    msg = JSON.stringify(req)
    send msg
    undefined

  ss.message.on responderId, (msg, meta) ->
    obj = JSON.parse(msg)
    console.log "responded", msg, obj
    if obj.id and cbStack[obj.id]
      if obj.e
        console.error "SS-Backbone server error:", obj.e.message
      else
        cbStack[obj.id].apply cbStack[obj.id], obj.p
      delete cbStack[obj.id]
