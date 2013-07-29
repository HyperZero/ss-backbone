registerModel = (model, modelname, id = undefined) ->
  modelID = id || model.cid
  modelRef = model
  unless ss.event.listeners("sync:#{modelname}:#{modelID}").length > 0
    console.log "registering model", modelname
    ss.event.on "sync:#{modelname}:#{modelID}", (msg) ->
      modelRef.trigger("backbone-sync-model", JSON.parse(msg))

registerCollection = (collection, modelname) ->
  collectionRef = collection
  console.log "registering collection", modelname
  ss.event.on "sync:#{modelname}", (msg) ->
    collectionRef.trigger("backbone-sync-collection", JSON.parse(msg))



window.syncedModel = Backbone.Model.extend
  sync: (method, model, options) ->
    modelname = @.constructor.modelname
    next = null
    next = options.next  if typeof options.next is "function"
    req = 
      modelname : modelname
      method : method
      model: model.toJSON()
      params: options.params
    if model.isNew()
      req.cid = model.cid
    console.log "Model upsync", req
    ss.backbone(req, next)

  initialize: (attrs={}) ->
    modelname = @.constructor.modelname
    if !modelname
      throw "Cannot sync. You must set the name of the modelname on the Model class"
      delete @
    model = @
    @.idAttribute = @.idAttribute || 'id'
    registerModel(model, modelname, attrs[@.idAttribute] || model.cid)
    deleted = false
    @on "backbone-sync-model", (res) ->
      console.log "Model triggered"
      if res.e
        console.log (res.e)
      else
        if res.method == "confirm"
          registerModel(model, modelname, res.model[@.idAttribute])
          @set(res.model)
        if res.method == "update"
          @set(res.model)
        if res.method == "delete"
          @trigger("destroy") if !deleted
          @collection.remove(@.idAttribute) if @collection
          deleted = true

window.syncedCollection = Backbone.Collection.extend
  sync: (method, model, options) ->
    modelname = @.constructor.modelname
    console.log("Collection sync")
    req = 
      modelname : modelname
      method : method
      model: model.toJSON()
      params: options.params
    ss.backbone(req)
  initialize: () ->
    modelname = @.constructor.modelname
    if !modelname
      throw "Cannot sync. You must set the name of the modelname on the Collection class"
      delete @
    else
      collection = @
      registerCollection(collection, modelname)
      @on "backbone-sync-collection", (msg) ->
        console.log("collection triggered")
        if msg.method == "create"
          @add(msg.model)
        if msg.method == "read"
          @add(msg.models, {merge:true})
        @trigger("change")
# window.Book = syncedModel.extend {},
#   modelname: "Book"

# window.Library = syncedCollection.extend {model: Book},
#   modelname: "Book"

# window.ipl = new Library

# ipl.create(author: "Shakespeare", title: "Othello")
