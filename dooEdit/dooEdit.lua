require 'waterlua'

local params = {...}

local mapPath = params[1]
local scriptPath = params[2]

assert(mapPath, 'no mapPath')
assert(scriptPath, 'no scriptPath')

local inputDir = io.local_dir()..[[Input\]]
local outputDir = io.local_dir()..[[Output\]]

io.removeDir(inputDir)

io.createDir(inputDir)

require 'portLib'

portLib.mpqExtract(mapPath, [[war3map.doo]], inputDir)

require 'wc3doo'

local doo = wc3doo.create()

doo:readFromFile(inputDir..[[war3map.doo]])

local success, errorMsg = io.syntaxCheck(scriptPath)

assert(success, errorMsg)

_G['doo'] = doo

loadfile(scriptPath)()

io.removeDir(outputDir)

io.createDir(outputDir)

doo:writeToFile(outputDir..[[war3map.doo]])

portLib.mpqImport(mapPath, outputDir..[[war3map.doo]], [[war3map.doo]])