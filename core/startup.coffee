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
checkDirectory "/mew_modules"

Switches = [
    [ "-n", "--name name", "name of this mewbot" ],
    [ "-t", "--test testcase", "test case to run" ],
    [ "-r", "--role client", "role of this mewbot" ],
    [ "-h", "--help", "print help information" ],
    [ "-p", "--profile profile", "config profile of this mewbot" ],
    [ "-u", "--update", "update mewbot" ],
    [ "-P", "--pack pack", "pack mewbot" ],
    [ "-m", "--module module", "check or get module from remote server" ]
]

Options = 
    adapter    :     process.env.MEWBOT_ADAPTER or "shell"
    test       :     process.env.MEWBOT_TEST    or ""
    role       :     process.env.MEWBOT_ROLE    or "client"
    version    :     false
    help       :     false
    update     :     false
    module     :     ""
    pack       :     ""
    name       :     "mewbot"
    profile    :     process.env.MEWBOT_PROFILE or "default"

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

Parser.on "module",(opt,value)->
    Options.module = value

Parser.on "pack",(opt,value)->
    Options.pack = value

Parser.on "name",(opt,value)->
    Options.name = value

Parser.parse process.argv

unless process.platform is "win32"
  process.on 'SIGTERM', ->
    process.exit 0

if Options.help
    console.log Parser.toString()
    process.exit 0

mewbot = new MewBot Options.name,Options.adapter

mewbot.init Options.profile,(err)->
    if Options.update
        console.log "update mewbot"
    else if Options.pack.length
        archiver = mewbot.module("archiver")
        packFile = mewbot.getTmpFile Options.pack
        if Options.pack.indexOf(".zip") < 0
            packFile = "#{packFile}.zip"
        mewbot.logger.info "mewbot start pack at #{packFile}"
        archiver.zipFolder packFile,Path.join(__dirname,".."),(err,pointer)->
            mewbot.logger.info "mewbot complete at #{packFile}"
            process.exit 0
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