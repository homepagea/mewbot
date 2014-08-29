#!/bin/bash
PRG="$0"
PRGDIR=`dirname "$PRG"`
PATH=/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PRGDIR/../node_modules/.bin:$PRGDIR/../node_modules/other-hubot/node_modules/.bin:$PATH



$PRGDIR/../node_modules/.bin/coffee $PRGDIR/../core/startup.coffee $@