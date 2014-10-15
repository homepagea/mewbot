Mew = require 'mew'
extend  = require 'extend'
Fs      = require 'fs'
Path    = require 'path'
Validator = require 'validator'
wildcard = require 'wildcard'
uuid     = require 'uuid'

isRegex = (value)->
    return Object.prototype.toString.call(value) is '[object RegExp]';


class TextListener
    constructor : (@rule,@adapterMatchRule,@callback)->

class Response
    constructor : (@mew,@msgObject,@listener,@match)->
        @envelop=@msgObject.message.user

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
        @mewTextListenerPool = {}

    run : ->
        @buildResponderTestRegex()

    buildResponderTestRegex : ->
        @mewNameAtResponser = eval("/^@#{@mew.name} (.*)$/")
        @mewNamePointResponser = eval("/^#{@mew.name}:(.*)$/")
        testString = "/^("
        charArray = []
        for char in @mew.name
            if char not in charArray
                if char is '.'
                    charArray.push "\\."
                else if char is '*'
                    charArray.push "\\*"
                else if char is '|'
                    charArray.push "\\|"
                else 
                    charArray.push "#{char}"
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

module.exports=RuleManager
module.exports.Response=Response