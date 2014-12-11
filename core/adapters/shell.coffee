Readline = require 'readline'
Mew      = require 'mew'

class ShellAdapter extends Mew.Adapter 
    constructor : (@mew,@externOpts)->
        
    sendText : (envelop,strings ...)->
        unless process.platform is 'win32'
            console.log "\x1b[01;32m#{str}\x1b[0m" for str in strings
        else
            console.log "#{str}" for str in strings
          @repl.prompt()
          
    run : ->
        stdin = process.openStdin()
        stdout = process.stdout
        @repl = Readline.createInterface stdin, stdout
        @repl.on 'line', (buffer) =>
            try
                if buffer and buffer.length
                    @receive new Mew.Message.TextMessage @userForId("shell"),buffer.toString()
            catch e
                @mew.logger.error e
            @repl.prompt()
            
        @repl.setPrompt "#{@mew.name}> "
        @repl.prompt()

module.exports = ShellAdapter   