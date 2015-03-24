Mew      = require 'mew'
Extend   = require 'extend'
util     = require 'util'
Jxm      = require 'jxm'

class OTHERWebAdapter extends Mew.Adapter.MultiAdapter
	constructor : (@mew,@profileName,@externOpts)->
        @connected = false

    run : ->
