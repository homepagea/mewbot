OTHERWebInstance = require 'otherweb.coffee'

class MewToModule 
    constructor : (@mewbot)->
        @mew_functions=[
            "logout",
            "login",
            "getUserContext",
            "getContext",
            "register",
            "login",
            "getDeviceInfo",
            "updateDeviceParameter",
            "updatePassword",
            "!uploadIcon",
            "getUserInfo",
            "getFriendshipByUserId",
            "makeFriendsByUserDomain",
            "updateFriendshipStatusById",
            "updateFriendshipStatusByUserId",
            "updateFriendGroupStatusById",
            "makeFriendGroup",
            "!mew",
            "getNewFansList",
            "findMewScriptVendorInfo",
            "saveMewTask",
            "findMewTaskToGroupById",
            "findMewTaskToFriendshipById",
            "findMewTaskFromVendorById",
            "updateDeviceSessionId",
            "updateUserPrivacy",
            "updateMyName",
            "updateFriendshipAlias"
        ]
        
    newClientInstance: (rootURL,username,password)->
        userAgent = process.env.AINETWORK_DEFAULT_UA || "otherbot/crawler"
        instance  = new OTHERWebInstance userAgent,rootURL,username,password
        instance.compileObject "mew",@mew_functions
        return instance

module.exports = MewToModule        