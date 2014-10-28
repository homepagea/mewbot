Mew            = require 'mew'
extend         = require 'extend'
Fs             = require 'fs'
Path           = require 'path'
Validator      = require 'validator'
wildcard       = require 'wildcard'
uuid           = require 'uuid'
RPCManager     = require './rpc.coffee'
AdapterManager = require './adapter.coffee'
RuleManager    = require './rule.coffee'
UserManager    = require './user.coffee'
ServiceManager = require './service.coffee'
Response       = (require './rule.coffee').Response
HttpServer     = require './http.coffee'
Moment         = require 'moment'
{EventEmitter} = require 'events'

rebotRules     = [
    "1. A robot may not injure a human being or, through inaction, allow a human being to come to harm.",
    "2. A robot must obey any orders given to it by human beings, except where such orders would conflict with the First Law.",
    "3. A robot must protect its own existence as long as such protection does not conflict with the First or Second Law."
]

isRegex = (value)->
    return Object.prototype.toString.call(value) is '[object RegExp]';

class Brain extends EventEmitter
    constructor : (@mew)->
        @adapterManager = new AdapterManager @mew
        @userManager    = new UserManager @mew
        @ruleManager    = new RuleManager @mew,@
        @serviceManager = new ServiceManager @mew,@
        @rpcManager     = new RPCManager @mew,@
        @httpManager    = new HttpServer @mew,@
        

    addTextRespond : (rule,adpaterMatchRule,callback)->
        if callback and rule and isRegex(rule) and (typeof callback is 'function')
            @ruleManager.addTextRespond rule,adpaterMatchRule,callback

    sendText : (adapterMatchRule,messages ...)->
        for adapter in @adapterManager.findAdapters adapterMatchRule
            adapter.sendText adapter.getBroadcastUser(),messages

    receive : (msgObject)->
        @emit "mew.message.received",msgObject
        if msgObject.message instanceof Mew.Message.TextMessage
            @mew.logger.debug "Received Text Message : #{JSON.stringify(msgObject.message.text)}"
            @emit "mew.message.text.received",msgObject
            matchPart = @ruleManager.getTextMatchPart msgObject.message.text
            if matchPart
                @emit "mew.message.text.matched",msgObject,matchPart
                for ruleKey of @ruleManager.mewTextListenerPool
                    listener = @ruleManager.mewTextListenerPool[ruleKey]
                    matchResult = matchPart.match listener.rule
                    if matchResult

                        if msgObject.message.done is false
                            response = new Response @mew,msgObject,listener,matchResult
                            try
                                listener.callback(response)
                                @emit "mew.message.text.response",response
                            catch ex
                                @mew.logger.error "#{ex.stack}"
                                @mew.logger.error ex
                                
    run : ->
        @httpManager.run()
        @adapterManager.initAdapters @mew.options.adapter,(err)=>
            if err
                @mew.logger.error err
            @adapterManager.run()

        @ruleManager.run()
        @rpcManager.run()
        @serviceManager.run()

        @addTextRespond /^ping$/i,"",(response)=>
            response.replyText "PONG"

        @addTextRespond /^ECHO (.*)$/i,"*",(response)=>
            if response.match[1] and response.match[1].length
                response.respondText response.match[1]

        @addTextRespond /^TIME$/i,"",(response)=>
            response.replyText "Server time is: #{new Moment().format()}"

        @addTextRespond /^MEWBOT DIE$/i,"",(response)=>
            response.replyText "Goodbye, curel world"
            setTimeout ->
                process.exit 0
            ,1000

        @addTextRespond /(what are )?the (three |3 )?(rules|laws)/i,"",(response)=>
            response.replyText rebotRules

        



module.exports = Brain
