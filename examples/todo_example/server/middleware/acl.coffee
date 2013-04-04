acl = require('acl')
ss.api.acl = new acl(new acl.memoryBackend())

ss.api.acl.addUserRoles 'anonymous', 'public', ()->
