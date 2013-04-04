ids = 1
class Memory
  models: {}
  create: (attributes, next) ->
    attributes.id = ids++
    @models[attributes.id] = attributes
    if typeof next == 'function'
      next(null, attributes)
  read: (conditions, next) ->
    model = @models[conditions.id]
    if typeof next == 'function'
      next(null,model)
  readAll: (conditions, next) ->
    models = []
    for id,model of @models
      models.push model
    if typeof next == 'function'
      next(null,models)
  update: (conditions, attributes, next) ->
    model = @models[conditions.id]
    for key,value of attributes
      model[key] = value
    if typeof next == 'function'
      next(null,model)
  delete: (conditions, next) ->
    success = delete @models[conditions.id]
    if typeof next == 'function'
      next(null,conditions)

module.exports = Memory