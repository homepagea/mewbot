Fs       = require 'fs'
OptParse = require 'optparse'
Path     = require 'path'
MewBot   = require './mewbot.coffee'


Switches = [
    [ "-t", "--test testcase", "test case to run" ],
    [ "-r", "--role client", "role of this mewbot" ],
    [ "-h", "--help", "print help information" ],
]

Options = 
    adapter :     process.env.MEWBOT_ADAPTER or "shell"
    test    :     process.env.MEWBOT_TEST    or ""
    role    :     process.env.MEWBOT_ROLE    or "client"
    version :     false
    help    :     false

Parser = new OptParse.OptionParser(Switches)
Parser.banner = "Usage mewbot [options]"

Parser.on "test",(opt,value)->
    Options.test = value

Parser.on "role",(opt,value)->
    Options.role = value


Parser.on "help",(opt,value)->
    Options.help = true

Parser.parse process.argv

unless process.platform is "win32"
  process.on 'SIGTERM', ->
    process.exit 0

if Options.help
    console.log Parser.toString()
    process.exit 0

mewbot = new MewBot Options.adapter

if Options.test and Options.test.length
	if Options.test is "all"
		Fs.readdir Path.join(__dirname,"..","script"),(err,files)->
			if files and files.length
				testPathArray = []
				for file in files
					testPathArray.push Path.join(__dirname,"..","script",file)
				mewbot.test.runTest testPathArray,(err,result)->
					process.exit 0
			else
				console.log "there is no test"
				process.exit 0
	else
		testPath = Path.join(__dirname,"..","script","#{Options.test}.coffee")
		Fs.exists testPath,(exists)=>
			if exists
				mewbot.test.runTest [testPath],(err,result)->
					process.exit 0
			else
				console.log "target test does not exists"
				process.exit 0
else
	console.log "run mewbot"

