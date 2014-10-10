Mew = require 'mew'
extend  = require 'extend'
Fs      = require 'fs'
Path    = require 'path'
Validator = require 'validator'
wildcard = require 'wildcard'
uuid     = require 'uuid'

class UserManager 
    constructor : (@mew)->
        @data = {}
    # Public: Get a User object given a unique identifier.
    #
    # Returns a User instance of the specified user.
    userForId: (adapterId,id, options) ->
        user = @data[adapterId].users[id]
        unless user
            user = new Mew.User id,options
            @data[adapterId].users[id] = user
        if options and options.room and (!user.room or user.room isnt options.room)
            user = new Mew.User id,options
            @data[adapterId].users[id] = user
        return user

    # Public: Get a User object given a name.
    #
    # Returns a User instance for the user with the specified name.
    userForName: (adapterId,name) ->
        result = null
        lowerName = name.toLowerCase()
        for k of (@data[adapterId].users or { })
            userName = @data[adapterId].users[k]['name']
        if userName? and userName.toLowerCase() is lowerName
            result = @data[adapterId].users[k]
        return result

module.exports=UserManager