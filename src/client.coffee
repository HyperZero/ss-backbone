registerModel = (model, modelConnectionId, id = undefined) ->
  modelID = id || model.cid
  modelRef = model
  unless ss.event.listeners("sync:#{modelConnectionId}:#{modelID}").length > 0
    console.log "registering modelConnectionId", modelConnectionId
    ss.event.on "sync:#{modelConnectionId}:#{modelID}", (msg) ->
      modelRef.trigger("backbone-sync-model", JSON.parse(msg))

registerCollection = (collection, modelConnectionId) ->
  collectionRef = collection
  console.log "registering collection", modelConnectionId
  ss.event.on "sync:#{modelConnectionId}", (msg) ->
    collectionRef.trigger("backbone-sync-collection", JSON.parse(msg))

window.syncedModel = Backbone.Model.extend
  sync: (method, model, options) ->
    modelname = @.constructor.modelname   
    modelConnectionId = @.constructor.modelConnectionId || modelname
    next = null
    next = options.next  if typeof options.next is "function"
    req = 
      modelname : modelname
      modelConnectionId : modelConnectionId
      method : method
      model: model.toJSON()
      params: options.params
    if model.isNew()
      req.cid = model.cid
    console.log "Model upsync", req
    ss.backbone(req, next)

  initialize: (attrs={}) ->
    modelname = @.constructor.modelname
    modelConnectionId = @.constructor.modelConnectionId || modelname
    if !modelname
      throw "Cannot sync. You must set the name of the modelname on the Model class"
      delete @
    model = @
    @.idAttribute = @.idAttribute || 'id'
    registerModel(model, modelConnectionId, attrs[@.idAttribute] || model.cid)
    deleted = false
    @on "backbone-sync-model", (res) ->
      console.log "Model downsync", modelname, res
      if res.e
        console.log (res.e)
      else
        if res.method == "confirm"
          registerModel(model, modelConnectionId, res.model[@.idAttribute])
          @set(res.model)
        if res.method == "update"
          @set(res.model)
        if res.method == "delete"
          @trigger("destroy") if !deleted
          @collection.remove(@.idAttribute) if @collection
          deleted = true

window.syncedCollection = Backbone.Collection.extend
  sync: (method, model, options) ->
    next = null
    next = options.next  if typeof options.next is "function"
    modelname = @.constructor.modelname
    modelConnectionId = @.constructor.modelConnectionId || modelname
    req = 
      modelname : modelname
      modelConnectionId : modelConnectionId
      method : method
      model: model.toJSON()
      params: options.params
    console.log "Collection upsync", modelname, req, next
    ss.backbone(req, next)
  fetchWhere: (attributes, options) ->
    attributes = attributes or {}
    options = (if options then _.clone(options) else {})
    options.parse = true  if options.parse is undefined
    success = options.success
    collection = this
    options.success = (resp) ->
      method = (if options.reset then "reset" else "set")
      collection[method] resp, options
      success collection, resp, options  if success
      collection.trigger "sync", collection, resp, options
    
    wrapError this, options
    model = new @model(attributes)
    @sync "read", model, options    
  initialize: () ->
    modelname = @.constructor.modelname
    modelConnectionId = @.constructor.modelConnectionId || modelname
    if !modelname
      throw "Cannot sync. You must set the name of the modelname on the Collection class"
      delete @
    else
      collection = @
      registerCollection(collection, modelConnectionId)
      @on "backbone-sync-collection", (msg) ->
        console.log "collection downsync", modelname, msg
        if msg.method == "create"
          @add(msg.model)
        if msg.method == "read"
          @add(msg.models, {parse:true, merge:true})
        @trigger("change")
        
wrapError = (model, options) ->
  error = options.error
  options.error = (resp) ->
    error model, resp, options  if error
    model.trigger "error", model, resp, options
# window.Book = syncedModel.extend {},
#   modelname: "Book"

# window.Library = syncedCollection.extend {model: Book},
#   modelname: "Book"

# window.ipl = new Library

# ipl.create(author: "Shakespeare", title: "Othello")
