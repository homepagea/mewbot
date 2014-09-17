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
        		text = new Mew.Message.TextMessage "shell","shell"
        		text.setText buffer.toString()
        		@receive text
        	catch e
        		@mew.logger.error e
        	@repl.prompt()

        @repl.setPrompt "#{@mew.name}> "
        @repl.prompt()

module.exports = ShellAdapter   