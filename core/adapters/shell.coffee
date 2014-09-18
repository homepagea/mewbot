Readline = require 'readline'
Mew      = require 'mew'

class ShellAdapter extends Mew.Adapter 
    constructor : (@mew,@externOpts)->
        super @mew,"shell"
        
    run : ->
        stdin = process.openStdin()
        stdout = process.stdout
        @repl = Readline.createInterface stdin, stdout
        @repl.on 'line', (buffer) =>
        	try
                @receive new Mew.Message.TextMessage "shell",buffer.toString()
        	catch e
        		@mew.logger.error e
        	@repl.prompt()

        @repl.setPrompt "#{@mew.name}> "
        @repl.prompt()

module.exports = ShellAdapter   