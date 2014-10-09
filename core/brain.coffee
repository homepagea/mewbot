Mew = require 'mew'
extend  = require 'extend'
Fs      = require 'fs'
Path    = require 'path'
Validator = require 'validator'
wildcard = require 'wildcard'

isRegex = (value)->
    return Object.prototype.toString.call(value) is '[object RegExp]';

checkAdapterInstance = (brain,name,profileName,adapterInstance,callback)->
    if adapterInstance instanceof Mew.Adapter or adapterInstance instanceof Mew.Adapter.MultiAdapter
        if typeof brain.adapterPool[name] is 'undefined'
            brain.adapterPool[name] = {}
        else 
            if (adapterInstance instanceof Mew.Adapter.MultiAdapter) isnt true
                return callback("Not a MultiAdapter","#{name}[#{profileName}]")
        brain.adapterPool[name][profileName]=adapterInstance
        brain.adapterIndex[adapterInstance.uuid]=adapterInstance
        callback(null,"#{name}[#{profileName}]")
    else
        callback("Not a MewAdapter","#{name}[#{profileName}]")

class AdapterManager
    constructor : (@mew)->
        @adapters = []
        @adapterPool = {}
        @adapterIndex = {}

    findAdapters : (adapterRule) ->
        if isRegex(adapterRule)
            adapters = []
            for adpaterUUID of @adapterPool
                adapter = @adapterPool[adpaterUUID]
                if adapterRule.test "#{adapter.name}[#{adapter.profileName}]"
                   adapters.push adapter
            return adapters
        else if Validator.isUUID(adapterRule)
            if @adapterIndex[adapterRule]
                return [@adapterIndex[adapterRule]]
            else
                return null
        else if typeof adapterRule is "string"
            if @adapterPool[adapterRule]
                adapters = []
                for adpaterProfile of @adapterPool[adapterRule]
                    adapters.push @adapterPool[adapterRule][adpaterProfile]
                return adapters
            else
                adapters = []
                for adpaterUUID of @adapterIndex
                    adapter = @adapterIndex[adpaterUUID]
                    if wildcard(adapterRule,"#{adapter.name}[#{adapter.profileName}]").length
                        adapters.push adapter
                return adapters
        else
            return []


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
                    adapterInstance = new adapterClass @mew,profileName,profile
                    checkAdapterInstance @,adapter,profileName,adapterInstance,callback
                else
                    callback("adapter is not function","#{adapter}[#{profileName}]")
            else
                adapterModuleFolder = Path.join __dirname,"..","mew_modules","@#{adapter}"
                Fs.exists adapterModuleFolder,(exists)=>
                    if exists
                        adapterClass = require adapterModuleFolder
                        if typeof adapterClass is 'function'
                            adapterInstance = new adapterClass @mew,profileName,profile
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

    initAdapters : (the_adapters,callback)->
        @adapters = the_adapters
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

class TextListener
    constructor : (@rule,@adapterMatchRule,@callback)->

class Response
    constructor : (@mew,@msgObject,@listener,@match)->
        
    replyText : (text ...)->
        @mew.brain.adapterManager.adapterIndex[@msgObject.adapterId].sendText @msgObject.message.user,text

    respondText : (text ...)->
        adapters = @mew.brain.adapterManager.findAdapters @listener.adapterMatchRule
        if adapters.length
            for adapter in adapters
                try
                    adapter.sendText @msgObject.message.user,text
                catch ex
                    @mew.logger.error ex
        else
            @replyText text


class RuleManager
    constructor : (@mew)->
        @buildResponderTestRegex()
        @mewTextListenerPool = {}

    buildResponderTestRegex : ->
        @mewNameAtResponser = eval("/^@#{@mew.name} (.*)$/")
        @mewNamePointResponser = eval("/^#{@mew.name}:(.*)$/")
        testString = "/^("
        charArray = []
        for char in @mew.name
            if char not in charArray
                charArray.push char
        for char in charArray
            testString = "#{testString}#{char}|"
        testString = "#{testString}\\*|\\?)+:(.*)$/"
        @mewNameWCResponser = eval(testString)

    addTextRespond : (rule,adpaterMatchRule,callback)->
        ruleKey = rule.toString()
        if @mewTextListenerPool[ruleKey]
            delete @mewTextListenerPool[ruleKey]
        @mewTextListenerPool[ruleKey]=new TextListener rule,adpaterMatchRule,callback

    removeTextRespond : (rule)->
        ruleKey = rule.toString()
        if @mewTextListenerPool[ruleKey]
            delete @mewTextListenerPool[ruleKey]

    getTextMatchPart : (text)->
        if text 
            atRespondMatch = text.match(@mewNameAtResponser)
            if atRespondMatch
                return atRespondMatch[1].replace(/(^\s*)|(\s*$)/g,"")
            else
                nameRespondMatch = text.match @mewNamePointResponser
                if nameRespondMatch
                    return nameRespondMatch[1].replace(/(^\s*)|(\s*$)/g,"")
                else
                    matches  = text.match @mewNameWCResponser 
                    if matches
                        if wildcard(matches[1],@mew.name).length
                            return matches[2].replace(/(^\s*)|(\s*$)/g,"")
                        else
                            return null
                    else
                        return null
        else
            return null

class Brain
    constructor : (@mew)->
        @adapterManager = new AdapterManager @mew
        @userManager    = new UserManager @mew
        @ruleManager    = new RuleManager @mew

    addTextRespond : (rule,adpaterMatchRule,callback)->
        if callback and rule and isRegex(rule) and (typeof callback is 'function')
            @ruleManager.addTextRespond rule,adpaterMatchRule,callback

    sendText : (adapterMatchRule,envelop,messages ...)->
        for adapter in @adapterManager.findAdapters adapterMatchRule
            adapter.sendText envelop,messages

    receive : (msgObject)->
        if msgObject.message instanceof Mew.Message.TextMessage
            @mew.logger.debug "Received Text Message #{JSON.stringify(msgObject)} "
            matchPart = @ruleManager.getTextMatchPart msgObject.message.text
            if matchPart
                for ruleKey of @ruleManager.mewTextListenerPool
                    listener = @ruleManager.mewTextListenerPool[ruleKey]
                    matchResult = matchPart.match listener.rule
                    if matchResult
                        if msgObject.message.done is false
                            response = new Response @mew,msgObject,listener,matchResult
                            try
                                listener.callback(response)
                            catch ex
                                @mew.logger.error ex
                                
    run : ->
        @adapterManager.run()




module.exports = Brain
