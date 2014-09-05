Fs       = require 'fs'
OptParse = require 'optparse'
Path     = require 'path'
MewBot   = require './mewbot.coffee'
Fse      = require 'fs.extra'


checkDirectory = (path)->
    dataFile = Path.join __dirname,"..",path
    if Fs.existsSync(dataFile) is false
        Fse.mkdirRecursiveSync dataFile

checkDirectory "/script"
checkDirectory "/testrc"
checkDirectory "/var"
checkDirectory "/var/run"
checkDirectory "/var/log"
checkDirectory "/var/data"

Switches = [
    [ "-t", "--test testcase", "test case to run" ],
    [ "-r", "--role client", "role of this mewbot" ],
    [ "-h", "--help", "print help information" ],
    [ "-p", "--profile profile", "config profile of this mewbot" ],
    [ "-u", "--update", "update mewbot" ]
]

Options = 
    adapter :     process.env.MEWBOT_ADAPTER or "shell"
    test    :     process.env.MEWBOT_TEST    or ""
    role    :     process.env.MEWBOT_ROLE    or "client"
    version :     false
    help    :     false
    update  :     false
    profile :     process.env.MEWBOT_PROFILE or "default"

Parser = new OptParse.OptionParser(Switches)
Parser.banner = "Usage mewbot [options]"

Parser.on "test",(opt,value)->
    Options.test = value

Parser.on "profile",(opt,value)->
    Options.profile = value

Parser.on "role",(opt,value)->
    Options.role = value

Parser.on "update",(opt,value)->
    Options.update = true

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

mewbot.init Options.profile,(err)->
    if Options.update
        console.log "update mewbot"
    else if Options.test and Options.test.length
        if Options.test is "all"
            Fs.readdir Path.join(__dirname,"..","testrc"),(err,files)->
                if files and files.length
                    testPathArray = []
                    files.sort (a,b)->
                        amatch = a.match /^\[(\d)\].+\.coffee$/
                        bmatch = b.match /^\[(\d)\].+\.coffee$/
                        if amatch and bmatch
                            return parseInt(amatch[1])-parseInt(bmatch[1])
                        else if amatch
                            return -1
                        else if bmatch
                            return 1
                        else
                            return 0
                    for file in files
                        if Path.extname(file) is ".coffee"
                            testPathArray.push Path.join(__dirname,"..","testrc",file)
                    mewbot.test.runTest testPathArray,(err,result)->
                        process.exit 0
                else
                    console.log "there is no test"
                    process.exit 0
        else
            testPath = Path.join(__dirname,"..","testrc","#{Options.test}.coffee")
            Fs.exists testPath,(exists)=>
                if exists
                    mewbot.test.runTest [testPath],(err,result)->
                        process.exit 0
                else
                    console.log "target test does not exists"
                    process.exit 0
    else
        console.log "mewbot start running"