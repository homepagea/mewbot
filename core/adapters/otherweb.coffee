Mew      = require 'mew'
Extend   = require 'extend'
util     = require 'util'

mbus_functions = [
    "receiveText"
]

class OTHERWebAdapter extends Mew.Adapter.MultiAdapter 
    constructor : (@mew,@profileName,@externOpts)->
        super @mew,"otherweb",@profileName
        @connected = false
        
    sendText : (envelop,strings ...)->
        if @connected
            @client.mbus.receiveText strings

    run : ->
        @options =
            username: process.env.OTHERWEB_ADAPTER_USERNAME
            password: "********"
            rooturl: process.env.OTHERWEB_ADAPTER_ROOTURL,
            keepaliveInterval: 30000 # ms interval to ping otherweb
            useragent : process.env.OTHERWEB_ADAPTER_UA || process.env.MEWBOT_DEFAULT_UA || "mewbot"

        if @externOpts
            @options = Extend(@options,@externOpts)
            @options.password = '"********"'
        @mew.logger.debug util.inspect(@options)
        if @options.username and @options.password and @options.rooturl and @options.useragent
            if @externOpts
                @options.password = @externOpts.password
            else
                @options.password = process.env.OTHERWEB_ADAPTER_PASSWORD
            @client = new Mew.OTHERWebInstance @options.useragent,@options.rooturl,@options.username,@options.password
            @client.login (err,login_result)=>
                if err
                    @mew.logger.error "OTHERWeb Adapter Error : #{error}"
                    @emit "error","OTHERWeb Login Error : #{error}"
                else
                    @connected = true
                    @client.compileObject "mbus",mbus_functions
                    @client.keepalive @options.keepaliveInterval
                    @mew.logger.debug "OTHERWeb Adapter Connected : #{JSON.stringify(login_result)}"
                    @timeline = @client.timeline()
                    @timeline.on "error",(error)=>
                        @emit "error",error

                    @timeline.on "data",(data)=>

                        @mew.logger.debug "Received data from #{@options.rooturl} : #{JSON.stringify(data,null,4)}"
                        user = @userForId @options.username
                        user.room = @options.rooturl
                        @receive new Mew.Message.TextMessage(user,data.text)
        else
            throw new Error("otherweb option definition error")


module.exports = OTHERWebAdapter