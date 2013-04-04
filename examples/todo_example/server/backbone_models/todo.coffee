BaseModel = require('./base/base_model')
MemoryAdapter = require('../database_adapters/memory')

# grant create read and delete permissions for all fields
ss.api.acl.allow 'public', ['Todo','Todo.content','Todo.order','Todo.id', 'Todo.done'], ['read','create','delete'], ()->
# grant update permission for all fields except Todo.done
ss.api.acl.allow 'public', ['Todo','Todo.content','Todo.order','Todo.id'], ['update'], ()->
# add update permission to Todo.done
ss.api.acl.allow 'public', ['Todo.done'], ['update'], ()->
# grant all permissions in one go
# ss.api.acl.allow 'public', ['Todo','Todo.content','Todo.order','Todo.id', 'Todo.done'], ['read','create','delete','update'], ()->

module.exports = (req,res,ss)->
  BaseModelClass = BaseModel(req,res,ss)
  req.use('session')
  class TodoClass extends BaseModelClass
    modelName: "Todo"
    protectFields: true
    databaseAdapter: new MemoryAdapter() #(Todo)
  
  return new TodoClass()


