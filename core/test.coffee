Path  = require 'path'
Fs    = require 'fs'
Fse   = require 'fs.extra'

class TestInstance
    constructor :(@mew)->
        
    getTestFile : (pathPrefix)->
        return Path.join __dirname,"..","testrc",pathPrefix


class TestManager
    constructor : (@mewbot)->

    listAvaliableTests : (callback)->
        Fs.readdir Path.join(__dirname,"..","testrc"),(err,files)=>
            if err
                callback(err)
            else
                testsAvailable = []
                testFileShiftCallback = =>
                    file = files.shift()
                    if file
                        if Path.extname(file) is ".coffee"
                            Fs.stat Path.join(__dirname,"..","testrc",file),(err,stat)=>
                                if stat.isDirectory() is false
                                    testsAvailable.push file.replace(/\.coffee/g,"")
                                testFileShiftCallback()
                        else
                            testFileShiftCallback()
                    else
                        callback(null,testsAvailable)
                testFileShiftCallback()


    runTest : (testScriptArray,callback)->
        testExecResult = { testcase : {} , success : 0 ,error : 0 , failed : 0}
        runTestCallback = =>
            testScript = testScriptArray.shift()
            if testScript
                resolvedName = require.resolve(testScript)
                if require.cache[resolvedName]
                    delete require.cache[resolvedName]
                testName = Path.basename(testScript).replace(Path.extname(testScript),"")
                @mewbot.logger.info "running test : #{testName}"
                try
                    testScriptInstance = require resolvedName
                    if typeof testScriptInstance is 'function'
                        testcase = new TestInstance @mewbot
                        try
                            testScriptInstance.call testcase,(err)=>
                                if err
                                    if typeof err is 'string'
                                        @mewbot.logger.error err
                                    else if err.stack
                                        @mewbot.logger.error "#{err.stack}"
                                    else
                                        @mewbot.logger.error JSON.stringify(err)
                                    testExecResult.testcase[testName] = {
                                        result : "failed",
                                        error  : err
                                    }
                                    testExecResult.failed = testExecResult.failed + 1
                                else
                                    testExecResult.testcase[testName] = {
                                        result : "success"
                                    }
                                    testExecResult.success = testExecResult.success + 1
                                runTestCallback()
                        catch ex
                            @mewbot.logger.error "#{ex.stack}"
                            testExecResult.testcase[testName] = {
                                result : "failed",
                                error  : ex
                            }
                            testExecResult.error = testExecResult.error + 1
                            runTestCallback()
                     else
                        testExecResult.testcase[testName] = {
                            result : "error",
                            error  : ex
                        }
                        testExecResult.error = testExecResult.error + 1
                        runTestCallback()
                catch ex
                    @mewbot.logger.error "#{ex.stack}"
                    testExecResult.testcase[testName] = {
                        result : "error",
                        error  : ex
                    }
                    testExecResult.error = testExecResult.error + 1
                    runTestCallback()

            else
                console.log "test running finished : "
                console.log "total   : #{testExecResult.error+testExecResult.success+testExecResult.failed}"
                console.log "success : #{testExecResult.success}"
                console.log "failed  : #{testExecResult.failed}"
                console.log "error   : #{testExecResult.error}"
                console.log "detail  :"
                console.log JSON.stringify(testExecResult,null,4)
                callback(testExecResult)
        runTestCallback()

module.exports = TestManager    