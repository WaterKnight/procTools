require 'waterlua'

local params = {...}

local mapPath = params[1]
local wc3path = params[2]

assert(mapPath, 'no mapPath')
assert(wc3path, 'no wc3path')

require 'wc3objMerge'

local objCon = wc3objMerge.createMap()

objCon:readFromMap(mapPath, true, wc3path)

objCon:writeToMap(mapPath)