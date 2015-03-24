Mew      = require 'mew'
Extend   = require 'extend'
util     = require 'util'
Jxm      = require 'jxm'


class JXMAdapter extends Mew.Adapter.MultiAdapter
	constructor : (@mew,@profileName,@externOpts)->
        @connected = false

    run : ->
    	@options =
            username: process.env.JXM_ADAPTER_USERNAME
            password: "********"
            host: process.env.JXM_ADAPTER_HOST
            port: process.env.JXM_ADAPTER_PORT || "8000"
            keepaliveInterval: 30000 # ms interval to send whitespace to xmpp server
            useSSL: process.env.JXM_ADAPTER_SSL

        if @externOpts
            @options = Extend(@options,@externOpts)
            @options.password = '"********"'

        @mew.logger.debug util.inspect(@options)
        if @options.username and @options.password and @options.host
        	if @externOpts
                @options.password = @externOpts.password
            else
                @options.password = process.env.JXM_ADAPTER_PASSWORD

            if @externOpts and @externOpts.rooms
                @options.rooms = @externOpts.rooms.split(',')
            else if process.env.XMPP_ADAPTER_ROOM
                @options.rooms = process.env.XMPP_ADAPTER_ROOM.split(',')
            else
            	@options.rooms = []

            if @options.useSSL
            	@options.useSSL = true
            else
            	@options.useSSL = false
            @instance = Jxm.createClient  @mew,@options.username,@options.password,@options.host,parseInt(@options.port),@options.useSSL
            
            @instance.Connect()
        else
            throw new Error("jxm option definition error")
	

module.exports = JXMAdapter