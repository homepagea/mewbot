Path  = require 'path'
Fs    = require 'fs'
Fse   = require 'fs.extra'

class TestInstance
    constructor :(@mew)->

    getTestFile : (pathPrefix)->
        return Path.join __dirname,"..","testrc",pathPrefix


class TestManager
    constructor : (@mewbot)->
        
    runTest : (testScriptArray,callback)->
        testExecResult = { testcase : {} , success : 0 ,error : 0 , failed : 0}
        runTestCallback = =>
            testScript = testScriptArray.shift()
            if testScript

                resolvedName = require.resolve(testScript)

                if require.cache[resolvedName]
                    delete require.cache[resolvedName]
                testName = Path.basename(testScript).replace(Path.extname(testScript),"")
                console.log "running test : #{testName}"
                try
                    testScriptInstance = require resolvedName
                    if typeof testScriptInstance is 'function'
                        testcase = new TestInstance @mewbot
                        try
                            testScriptInstance.call testcase,(err)->
                                if err
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
                    console.log "#{ex.stack}"
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
        stdin = process.openStdin()
        runTestCallback()

module.exports = TestManager    