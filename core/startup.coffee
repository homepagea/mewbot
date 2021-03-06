Fs       = require 'fs'
OptParse = require 'optparse'
Path     = require 'path'
MewBot   = require './mewbot.coffee'
Fse      = require 'fs.extra'
Cps      = require 'child_process'
Moment   = require 'moment'
Coffee   = require 'coffee-script'
UUID     = require 'uuid'

checkDirectory = (path)->
    dataFile = Path.join __dirname,"..",path
    if Fs.existsSync(dataFile) is false
        Fse.mkdirRecursiveSync dataFile

getMewbotName = ->
    return mewbot.name

checkDirectory "/script"
checkDirectory "/testrc"
checkDirectory "/var"
checkDirectory "/var/run"
checkDirectory "/var/log"
checkDirectory "/var/data"
checkDirectory "/var/conf"
checkDirectory "/mew_modules"

Switches = [
    [ "-n" , "--name name", "name of this mewbot" ],
    [ "-t" , "--test testcase", "test case to run" ],
    [ "-r" , "--role client|consumer|broker", "role of this mewbot" ],
    [ "-h" , "--help", "print help information" ],
    [ "-p" , "--profile profile", "config profile of this mewbot" ],
    [ "-c" , "--config config", "config this mewbot with config specified" ],
    [ "--port port", "config port of this mewbot" ],
    [ "--update", "update mewbot" ],
    [ "-B" , "--build", "build mewbot" ],
    [ "-D" , "--debug", "debug mewbot" ],
    [ "-a" , "--adapter adapter", "set adapter of this mewbot" ],
    [ "-s" , "--service service", "add service on startup" ],
    [ "-A" , "--archive pack", "archive mewbot" ],
    [ "--archive-module pack", "archive mewbot module" ],
    [ "--archive-data pack", "archive mewbot data" ],
    [ "-m" , "--module module", "check or get module from remote server" ],
    [ "--env kvp", "config enviorment key value pair using : <key>=<value>" ]
    [ "--deploy deployLocation", "deploy mewbot to target location" ]
    [ "--deploy-config deployConfig", "deploy config file location" ]
    [ "--deploy-exclude-forver", "exclude forever from deploy" ]
]

Options = 
    adapter           :     [] 
    test              :     process.env.MEWBOT_TEST    or ""
    role              :     process.env.MEWBOT_ROLE    or "client"
    version           :     false
    help              :     false
    update            :     false
    module            :     ""
    archive           :     ""
    archiveModule     :     ""
    archiveData       :     ""
    name              :     process.env.MEWBOT_NAME    or Path.basename(Path.join(__dirname,".."))
    nameDefined       :     false
    services          :     []
    profile           :     process.env.MEWBOT_PROFILE or "default"
    build             :     false
    port              :     0
    deploy            :     ""
    deployConfig      :     ""
    deployExclude     :     []
    config            :     ""

Parser = new OptParse.OptionParser(Switches)
Parser.banner = "Usage mewbot [options]"

Parser.on "test",(opt,value)->
    if value and value.length
        Options.test = value
    else
        Options.test = "all"

Parser.on "port",(opt,value)->
    if value and value.length and /^[0-9]+$/.test(value)
        Options.port = parseInt(value)

Parser.on "env",(opt,value)->
    if value
        idxOfEqual = value.indexOf("=")
        if idxOfEqual > 0
            key = value.substr(0,idxOfEqual)
            value = value.substr(idxOfEqual+1)
            if key and value
                key = key.replace(/(^\s*)|(\s*$)/g,"")
                value = value.replace(/(^\s*)|(\s*$)/g,"")
                if key and value
                    process.env[key]=value

Parser.on "profile",(opt,value)->
    if value and value.length and /^[a-zA-Z0-9]+$/.test(value)
        Options.profile = value

Parser.on "config",(opt,value)->
    if value
        Options.config = value

Parser.on "deploy-config",(opt,value)->
    if value
        Options.deployConfig = value

Parser.on "role",(opt,value)->
    if value and value.length
        if value is "server" or value is "client"
            Options.role = value

Parser.on "update",(opt,value)->
    Options.update = true

Parser.on "build",(opt,value)->
    Options.build = true

Parser.on "help",(opt,value)->
    Options.help = true

Parser.on "module",(opt,value)->
    if value and value.length
        Options.module = value

Parser.on "debug",(opt,value)->
    process.env.MEWBOT_LOG_LEVEL="debug"

Parser.on "adapter",(opt,value)->
    if value 
        Options.adapter.push value

Parser.on "service",(opt,value)->
    if value 
        Options.services.push value

Parser.on "archive",(opt,value)->
    if value
        Options.archive = value
    else
        Options.archive = "#{Options.name}-#{new Moment().format()}"

Parser.on "archive-module",(opt,value)->
    if value
        Options.archiveModule = value
    else
        Options.archiveModule = "#{Options.name}-module-#{new Moment().format()}"

Parser.on "archive-data",(opt,value)->
    if value
        Options.archiveData = value
    else
        Options.archiveData = "#{Options.name}-data-#{new Moment().format()}"

Parser.on "name",(opt,value)->
    if value 
        Options.name = value
        Options.nameDefined = true

Parser.on "deploy",(opt,value)->
    if value 
        Options.deploy=value
    else
        Options.deploy=process.cwd()

Parser.on "deploy-exclude-forver",(opt,value)->
    if value 
        Options.deployExclude.push value

Parser.on "role",(opt,value)->
    if value
        Options.role = value

Parser.parse process.argv

unless process.platform is "win32"
  process.on 'SIGTERM', ->
    process.exit 0

if Options.help
    console.log Parser.toString()
    process.exit 0

mewbot = new MewBot Options
console.log "==================================================================================="

mewbot.init Options.profile,(err)->
    mewbot.logger.debug "#{mewbot.name} init complete with option : #{JSON.stringify(mewbot.options,null,4)}"

    if process.env.MEWBOT_DEPLOY_DATE
        mewbot.logger.debug "#{mewbot.name} instance deploy version : #{process.env.MEWBOT_DEPLOY_DATE}"

    if Options.update and process.platform isnt "win32"
        ###
        handle update argument
        ###
        mewbot.logger.info "#{mewbot.name} update start ... "
        mewbot.updater.executeUpdate (err)->
            if err
                mewbot.logger.info "#{mewbot.name} update failed : "
                mewbot.logger.error err
            else
                mewbot.logger.info "#{mewbot.name} update success"
            process.exit 0
        stdin = process.openStdin()
    else if Options.build
        ###
        handle build argument
        ###
        mew_modules_dir = Path.join __dirname,"..","mew_modules"
        Fs.readdir mew_modules_dir,(err,modules)->
            if err
                mewbot.logger.error err
                process.exit 0
            else
                moduleBuildCallback = ->
                    module = modules.shift()
                    if module
                        if module is ".git" or module is ".gitignore"
                            moduleBuildCallback()
                        else
                            mewbot.logger.info "#{mewbot.name} build #{module} ..."
                            module_dir = Path.join __dirname,"..","mew_modules",module
                            Cps.exec "cd '#{module_dir}' && npm rebuild --build-from-source",(err,stdout,stderr)->
                                if err
                                    mewbot.logger.error "#{mewbot.name} build #{module} error : #{err}"
                                else
                                    mewbot.logger.info "#{mewbot.name} build #{module} success"
                                moduleBuildCallback()
                    else
                        mewbot.logger.info "#{mewbot.name} build success"
                        process.exit 0
                moduleBuildCallback()
        stdin = process.openStdin()
    else if Options.archive
        ###
        handle archive argument
        ###
        archiver = mewbot.module("archiver")
        packFile = mewbot.getTmpFile Options.archive
        if Options.archive.indexOf(".zip") < 0
            packFile = "#{packFile}.zip"
        mewbot.logger.info "#{mewbot.name} start archive at #{packFile}"
        archiver.zipFolder packFile,Path.join(__dirname,".."),(err,pointer)->
            mewbot.logger.info "mewbot archive complete at #{packFile}"
            process.exit 0
    else if Options.archiveModule
        ###
        handle archive-module argument
        ###
        archiver = mewbot.module("archiver")
        packFile = mewbot.getTmpFile Options.archiveModule
        if Options.archiveModule.indexOf(".zip") < 0
            packFile = "#{packFile}.zip"
        mewbot.logger.info "#{mewbot.name} start archive module at #{packFile}"
        archiver.zipFolder packFile,Path.join(__dirname,"..","mew_modules"),(err,pointer)->
            mewbot.logger.info "#{mewbot.name} archive module complete at #{packFile}"
            process.exit 0
    else if Options.archiveData
        ###
        handle archive-module argument
        ###
        archiver = mewbot.module("archiver")
        packFile = mewbot.getTmpFile Options.archiveData
        if Options.archiveData.indexOf(".zip") < 0
            packFile = "#{packFile}.zip"
        mewbot.logger.info "#{mewbot.name} start archive data at #{packFile}"
        archiver.zipFolder packFile,Path.join(__dirname,"..","var"),(err,pointer)->
            mewbot.logger.info "#{mewbot.name} archive data complete at #{packFile}"
            process.exit 0
    else if Options.deploy
        zipped = false
        deployFolder = Options.deploy
        if Path.extname(Options.deploy) is ".zip"
            zipped = true
            deployFolder = mewbot.makeTmpDir("/module/deploy/#{UUID.v1()}")
        Fs.exists deployFolder,(exists)->
            if exists is false
                Fse.mkdirRecursiveSync Options.deploy
            Fs.exists deployFolder,(exists)->
                if exists
                    Fs.stat deployFolder,(err,stat)->
                        if err
                            mewbot.logger.error "#{mewbot.name} deploy error : #{err}"
                            process.exit 1
                        else
                            if stat.isDirectory()
                                Fs.readdir deployFolder,(err,items)->
                                    if err
                                        mewbot.logger.error "#{mewbot.name} deploy error : #{err}"
                                        process.exit 1
                                    else if items and items.length
                                        mewbot.logger.error "#{mewbot.name} deploy error : target location [#{Options.deploy}] is not empty"
                                        process.exit 1
                                    else
                                        if Options.deployConfig
                                            Fs.readFile Options.deployConfig,(err,data)->
                                                if err
                                                    mewbot.logger.error "#{mewbot.name} deploy at : #{Options.deploy} failed : #{err.toString()}"
                                                else
                                                    deployConfig = {}
                                                    try
                                                        switch Path.extname(Options.deployConfig)
                                                            when ".coffee"
                                                                deployConfig = Coffee.eval(data.toString())
                                                            when ".js"
                                                                 eval("deployConfig = #{data.toString()}")
                                                            when ".json"
                                                                deployConfig = JSON.parse(data.toString())
                                                            else
                                                                throw new Error("type not supported")
                                                    catch e
                                                        mewbot.logger.error "#{mewbot.name} deploy at : #{Options.deploy} failed : #{e.toString()}"
                                                        process.exit(1)
                                                    mewbot.logger.info "#{mewbot.name} start to deploy at : #{Options.deploy} , with config : #{JSON.stringify(deployConfig,null,4)}"
                                                    mewbot.deployer.deployTo deployFolder,deployConfig,(err)->
                                                        if err
                                                            mewbot.logger.error "#{mewbot.name} deploy error : #{err}"
                                                        else
                                                            if zipped
                                                                archiver = mewbot.module("archiver")
                                                                packFile = Options.deploy
                                                                archiver.zipFolder packFile,deployFolder,(err,pointer)->
                                                                    mewbot.logger.info "#{mewbot.name} deploy at : #{Options.deploy} success"
                                                                    process.exit 0
                                                            else
                                                                mewbot.logger.info "#{mewbot.name} deploy at : #{Options.deploy} success"
                                        else
                                            mewbot.logger.info "#{mewbot.name} start to deploy at : #{Options.deploy}"
                                            mewbot.deployer.deployTo deployFolder,(err)->
                                                if zipped
                                                    archiver = mewbot.module("archiver")
                                                    packFile = Options.deploy
                                                    archiver.zipFolder packFile,deployFolder,(err,pointer)->
                                                        mewbot.logger.info "#{mewbot.name} deploy at : #{Options.deploy} success"
                                                        process.exit 0
                                                else
                                                    mewbot.logger.info "#{mewbot.name} deploy at : #{Options.deploy} success"
                            else
                                mewbot.logger.error "#{mewbot.name} deploy error : target location [#{Options.deploy}] is not a directory"
                                process.exit 1
                else
                    mewbot.logger.error "#{mewbot.name} deploy error : permission error"
                    process.exit 1
    else if Options.config
        afterConfigCallback = (err)->
            if err
                mewbot.logger.error "#{mewbot.name} config error : #{err}"
                process.exit 1
            else
                mewbot.logger.info "#{mewbot.name} config success"
                process.exit 0
        Fs.exists Options.config,(exists)->
            if exists
                try
                    mewbot.module("config").readAndConfig Options.config,afterConfigCallback
                catch ex
                    mewbot.logger.error "#{mewbot.name} config error : #{ex.stack}"
                    process.exist 1
            else
                pwdConfigFile = Path.join(process.pwd,Options.config)
                Fs.exists pwdConfigFile,(exists)->
                    if exists
                        try
                            mewbot.module("config").readAndConfig pwdConfigFile,afterConfigCallback
                        catch ex
                            mewbot.logger.error "#{mewbot.name} config error : #{ex.stack}"
                            process.exist 1    
                    else
                        mewbot.logger.error "#{mewbot.name} config error : config file not found"
                        process.exist 1
    else if Options.test
        ###
        handle test argument
        ###
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
                    mewbot.logger.info "there is no test"
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
        stdin = process.openStdin()
    else
        ###
        if no special argument is included, start run mewbot
        ###
        mewbot.logger.info "mewbot start running on : #{new Moment().format()}"
        console.log "==================================================================================="
        mewbot.brain.run()