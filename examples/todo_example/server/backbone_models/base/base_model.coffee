module.exports = (req,res,ss)->
  class BaseModelClass
    # model: null
    modelName: null
    databaseAdapter: null
    protectFields: false
    userId: ()-> # used by ACL
      if req.session?.user?.id
        return req.session.user.id
      else
        return "anonymous"

    create: (attributes)=>
      ss.acl.isAllowed @userId(), @modelName, 'create', (err, allowed)=>
        throw err  if err
        if allowed
          @beforeCreate attributes, (attributes)=>
            @databaseAdapter.create attributes, (err, instance)=>
              @afterCreate instance, (instance)=>
                @propogateAfterCreate(instance)
    beforeCreate: (attributes, next)->
      @stripUnallowedFields attributes,'create',(attributes)->
        next attributes
    afterCreate: (instance, next)->
      @stripUnallowedFields instance,'read',(instance)->
        next instance
    propogateAfterCreate: (attributes)=>
      cid = req.cid
      responseData =
        cid: cid
        model: attributes
        method: "confirm"
        modelname: @modelName
      ss.publish.socketId req.socketId, "sync:"+@modelName+":" + cid, JSON.stringify(responseData)
      delete responseData.cid
      responseData.method = "create"
      ss.publish.all "sync:"+@modelName, JSON.stringify(responseData)

    read:(attributes)=>
      ss.acl.isAllowed @userId(), @modelName, 'read', (err, allowed)=>
        throw err  if err
        if allowed
          @beforeRead attributes, (attributes)=>
            @databaseAdapter.read attributes, (err, instance)=>
              @afterRead instance, (instance)=>
                @propogateAfterRead(instance)
    beforeRead: (attributes, next)->
      next attributes
    afterRead: (instance, next)->
      @stripUnallowedFields instance,'read',(instance)->
        next instance
    propogateAfterRead:(instance)=>
      responseData =
        model: instance
        method: "read"
        modelname: @modelName

      ss.publish.socketId req.socketId, "sync:"+@modelName+":"+instance.id, JSON.stringify(responseData)

    readAll:(attributes)=>
      ss.acl.isAllowed @userId(), @modelName, 'read', (err, allowed)=>
        throw err  if err
        if allowed
          @beforeReadAll attributes, (attributes)=>
            @databaseAdapter.readAll attributes, (err, instances)=>
              @afterReadAll instances, (instances)=>
                @propogateAfterReadAll(instances)
    beforeReadAll: (attributes, next)->
      next attributes
    afterReadAll: (instances, next)->
      @stripUnallowedFields instances,'read',(instances)->
        next instances
    propogateAfterReadAll:(instances)=>
      responseData =
        models: instances
        method: "read"
        modelname: @modelName
      ss.publish.socketId req.socketId, "sync:"+@modelName, JSON.stringify(responseData)

    update:(attributes)=>
      ss.acl.isAllowed @userId(), @modelName, 'update', (err, allowed)=>
        throw err  if err
        if allowed
          conditions = {id: attributes.id}
          @beforeUpdate attributes, (attributes)=>
            @databaseAdapter.update conditions, attributes, (err, instance)=>
              @afterUpdate instance, (instance)=>
                @propogateAfterUpdate(instance)
    beforeUpdate: (attributes, next)->
      @stripUnallowedFields attributes,'update',(attributes)->
        next attributes
    afterUpdate: (instance, next)->
      @stripUnallowedFields instance,'read',(instances)->
        next instance
    propogateAfterUpdate:(instance)=>
      responseData =
        model: instance
        method: "update"
        modelname: @modelName
      ss.publish.all "sync:"+@modelName+":"+instance.id, JSON.stringify(responseData)

    delete: (conditions) =>
      ss.acl.isAllowed @userId(), @modelName, 'read', (err, allowed)=>
        throw err  if err
        if allowed
          @beforeDelete conditions, (conditions)=>
            @databaseAdapter.delete conditions, (err, instance)=>
              @afterDelete instance, ()=>
                @propogateAfterDelete(instance)
    beforeDelete: (conditions, next)->
      next conditions
    afterDelete: (conditions, next)->
      next()
    propogateAfterDelete:(conditions)=>
      responseData =
        model: conditions
        method: "delete"
        modelname: @modelName
      ss.publish.all "sync:"+@modelName+":"+conditions.id, JSON.stringify(responseData)

    stripUnallowedFields: (instances, permission, next)=>
      if @protectFields
        isArray = Array.isArray(instances)
        unless isArray
          instances = [instances]
        resources = []
        for key,value of instances[0]
          resources.push @modelName+'.'+key
        ss.acl.allowedPermissions @userId(), resources, (err, permissions)->
          throw err if err
          strippedInstances = []
          for oInstance in instances
            # clone to protect original model
            instance = {}
            for i, value of oInstance
              if oInstance.hasOwnProperty(i)
                instance[i] = oInstance[i]
            for r in resources
              key = r.split('.')[1]
              unless permissions[r].indexOf(permission) > -1
                delete instance[key]
            strippedInstances.push instance
          unless isArray
            strippedInstances = strippedInstances[0]
          next(strippedInstances)
      else
        next(instances)

