local params = {...}

local scriptPath = params[1]
local outputPath = params[2]

assert(scriptPath, 'no scriptPath')
assert(outputPath, 'no outputPath')

require 'waterlua'

require 'wc3jass'

local script = wc3jass.create()

script:readFromFile(scriptPath)

local debugFunc = script:createFunc('DebugMsg')

debugFunc:setNative(true)
debugFunc:addParam('s', 'string')

local infoExFunc = script:createFunc('InfoEx')

infoExFunc:setNative(true)
infoExFunc:addParam('s', 'string')

local debugExFunc = script:createFunc('DebugEx')

debugExFunc:setNative(true)
debugExFunc:addParam('s', 'string')

script:writeToFile(outputPath)

