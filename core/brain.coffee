Mew = require 'mew'
extend  = require 'extend'
Fs      = require 'fs'
Path    = require 'path'

checkAdapterInstance = (brain,name,profileName,adapterInstance,callback)->
    if adapterInstance instanceof Mew.Adapter or adapterInstance instanceof Mew.Adapter.MultiAdapter
        if typeof brain.adapterPool[name] is 'undefined'
            brain.adapterPool[name] = {}
        else 
            if (adapterInstance instanceof Mew.Adapter.MultiAdapter) isnt true
                return callback("Not a MultiAdapter","#{name}[#{profileName}]")
        brain.adapterPool[name][profileName]=adapterInstance
        callback(null,"#{name}[#{profileName}]")
    else
        callback("Not a MewAdapter","#{name}[#{profileName}]")

class AdapterManager
    constructor : (@mew,@adapters)->
        @adapterPool = {}

    addAdapter : (adapter,profileName,profile,callback) ->
        if @adapterPool[adapter]
            if @adapterPool[adapter][profileName]
                callback("same adapter with same profile already defined",adapter)
                return
        defaultAdapterPath = Path.join __dirname,"adapters","#{adapter}.coffee"
        Fs.exists defaultAdapterPath,(exists)=>
            if exists
                adapterClass = require defaultAdapterPath
                if typeof adapterClass is 'function'
                    adapterInstance = new adapterClass @mew,profile
                    checkAdapterInstance @,adapter,profileName,adapterInstance,callback
                else
                    callback("adapter is not function","#{adapter}[#{profileName}]")
            else
                adapterModuleFolder = Path.join __dirname,"..","mew_modules","@#{adapter}"
                Fs.exists adapterModuleFolder,(exists)=>
                    if exists
                        adapterClass = require adapterModuleFolder
                        if typeof adapterClass is 'function'
                            adapterInstance = new adapterClass @mew,profile
                            checkAdapterInstance @,adapter,profileName,adapterInstance,callback
                        else
                            callback("adapter is not function","#{adapter}[#{profileName}]")
                    else
                        callback("adapter not found","#{adapter}[#{profileName}]")


    readAdapterConf : (profileName,callback)->
        confFile = @mew.getConfFile "@#{profileName}"
        Fs.exists confFile,(exists)=>
            if exists
                Fs.readFile confFile,(err,content)=>
                    fileContent = content.toString()
                    if fileContent and fileContent.length
                        externOptions = {}
                        for confLine in fileContent.split("\n")
                            if confLine.indexOf("=")  > 0
                                conEntrys = confLine.split("=")
                                externOptions[conEntrys[0].replace(/(^\s*)|(\s*$)/g,"")]=conEntrys[1].replace(/(^\s*)|(\s*$)/g,"")
                        callback(externOptions)
                    else
                        callback(null)
            else
                callback(null)

    initAdapters : (callback)->
        adapterInitCallback = (err,result)=>
            if result
                if err
                    @mew.logger.error "mew adapter <#{result}> init failed : #{err.toString()}"
                else
                    @mew.logger.info "mew adapter <#{result}> init complete"
            adapter = @adapters.shift()
            if adapter
                profileName = "default"
                optionTest = /^(\S+)\[(\S+)\]$/
                adapterMatch = adapter.match optionTest
                if adapterMatch
                    adapter = adapterMatch[1]
                    profileName = adapterMatch[2]
                    @readAdapterConf profileName,(option)=>
                        if option
                            console.log option
                            @addAdapter adapter,profileName,option,adapterInitCallback
                        else
                            @addAdapter adapter,"default",option,adapterInitCallback
                else
                    @addAdapter adapter,profileName,null,adapterInitCallback
            else
                callback()
        adapterInitCallback()

    run : ->
        for adapter of @adapterPool
            do (adapter)=>
                for profile of @adapterPool[adapter]
                    do (profile)=>
                        if typeof @adapterPool[adapter][profile].run is 'function'
                            try
                                @adapterPool[adapter][profile].run()
                                @adapterPool[adapter][profile].on "error",(e)=>
                                    @mew.logger.info "mew adapter <#{adapter}[#{profile}]> run error  : #{e}"
                                    delete @adapterPool[adapter][profile]
                            catch e
                                @mew.logger.info "mew adapter <#{adapter}[#{profile}]> run error  : #{e}"
                                delete @adapterPool[adapter][profile]

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

class Brain
    constructor : (@mew,adapters)->
        @adapterManager = new AdapterManager @mew,adapters
        @userManager    = new UserManager @mew

    receive : (envelop)->
        console.log envelop

    run : ->
        @adapterManager.run()




module.exports = Brain
