#!/bin/bash -i
init_i # initialize settings for interactive scripts
kquitapp5 plasmashell || killall plasmashell && kstart5 plasmashell &
s_scream & xbindkeys & exit
