



module.exports = (callback)->
    mewto = @mew.module("mewto")
    instance  = mewto.newClientInstance "http://develop.mewmew.cn:8080/tripmew","homepagea@gmail.com","142857"
    instance.login (err)=>
        if err
            callback(err)
        else
            instance.mew.register {
                account     : "test@mewmew.cn",
                password    : "mewtest123",
                passwordrpt : "mewtest123",
                nickname    : "测试用户-#{new Date().getTime()}",
                deviceId    : "1111-2222-3333-4444-55",
                deviceType  : "ios" 
            },(r,e)=>
                console.log "-----------------------------"
                console.log "instance register complete : "
                console.log r
                console.log "-----------------------------"
                instance.mew.login {
                    account     : "test@mewmew.cn",
                    password    : "mewtest123",
                    deviceId    : "1111-2222-3333-4444-55",
                    deviceType  : "ios" 
                },(r,e)=>
                    console.log "-----------------------------"
                    console.log "instance login complete : "
                    console.log r
                    console.log "-----------------------------"
                    instance.mew.getContext {deviceId : "1111-2222-3333-4444-55" , deviceType : "ios"},(r,e)=>
                        instance.mew.getUserContext (r,e)=>
                            console.log "-----------------------------"
                            console.log "get user context success : "
                            console.log r
                            console.log "-----------------------------"
                        instance.mew.getDeviceInfo (r,e)->
                            console.log "-----------------------------"
                            console.log "get device info success : "
                            console.log r
                            console.log "-----------------------------"
                    instance.mew.updateDeviceParameter {
                        hello : "world"
                    },(r,e)=>
                        console.log "-----------------------------"
                        console.log "update device parameter success : "
                        console.log r
                        console.log "-----------------------------"
                        instance.mew.getDeviceInfo (r,e)=>
                            console.log "-----------------------------"
                            console.log "get device parameter success : "
                            console.log r
                            console.log "-----------------------------"
                    instance.mew.updatePassword ["mewtest123","mewtest345"],(r,e)=>
                        console.log "-----------------------------"
                        console.log "update password complete : "
                        console.log r
                        console.log "-----------------------------"
                    instance.mew.uploadIcon [@getTestFile("test_mewto_user_icon.png"),"png"],(r,e)=>
                        console.log "-----------------------------"
                        console.log "update user icon complete : "
                        console.log r
                        instance.mew.getUserInfo (r,e)->
                            console.log "get user info after icon upload complete : "
                            console.log r
                            console.log "-----------------------------"
                    instance.mew.makeFriendsByUserDomain ["10001","狗"],(rr,e)=>
                        console.log "-----------------------------"
                        console.log "make friend complete : "
                        console.log rr
                        instance.mew.getUserContext (r,e)->
                            console.log "user context after make friend complete : "
                            console.log r
                            console.log "-----------------------------"




