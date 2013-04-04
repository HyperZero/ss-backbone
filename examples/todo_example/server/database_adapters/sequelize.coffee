Sequelize = require("sequelize")
module.exports = new Sequelize ss.config.mysql.database, ss.config.mysql.username, ss.config.mysql.password,
  host: ss.config.mysql.host
  port: ss.config.mysql.port
  define: 
    freezeTableName: true
    underscored: true


        # update
          # @model.find({ where: {id: id} })
          # .error (err)->
          #   throw err  if err
          # .success (instance)=>
          #   if instance
          #     throw err  if err
          #     instance.updateAttributes(attributes)
          #     .error (err)=>
          #       throw err  if err
          #     .success (updatedInstance)=>
        # delete
         # @model.find({ where: {id: attributes.id} })
         #  .error (err)->
         #    throw err  if err
         #  .success (instance)=>
         #    if instance
         #      instance.destroy()
         #      .error (err)=>
         #        throw err  if err
         #      .success (instance)=>

