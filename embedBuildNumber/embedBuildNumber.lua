require 'waterlua'

local params = {...}

local map = params[1]
local newName = params[2]

assert(map, 'no map')

map = io.toAbsPath(map)

local inputDir = io.local_dir()..[[Input\]]
local outputDir = io.local_dir()..[[Output\]]

assert(map, 'no map')

require 'portLib'

io.removeDir(inputDir)

io.createDir(inputDir)

portLib.mpqExtract(map, [[war3map.w3i]], inputDir)
portLib.mpqExtract(map, [[war3map.wts]], inputDir)

require 'wc3info'

local info = wc3info.create()

info:readFromFile(inputDir..[[war3map.w3i]])

require 'wc3wts'

local wts = wc3wts.create()

wts:readFromFile(inputDir..[[war3map.wts]])

local mapName = wts:translate(info.mapName)
local buildNum = info.savesAmount

if (newName == nil) then
	newName = mapName..' Build '..buildNum
else
	newName = newName:gsub('%%name%%', mapName)
	newName = newName:gsub('%%buildNum%%', buildNum)
end

io.removeDir(outputDir)

io.createDir(outputDir)

info:setMapName(newName)

info:writeToFile(outputDir..[[war3map.w3i]], infoFileMaskFunc)

local impPort = portLib.createMpqPort()

impPort:addImport(outputDir..[[war3map.w3i]], [[war3map.w3i]])
impPort:addImport(outputDir..[[war3map.wts]], [[war3map.wts]])

impPort:commit(map)