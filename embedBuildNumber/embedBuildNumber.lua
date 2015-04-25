require 'waterlua'

local params = {...}

local map = params[1]
local newName = params[2]

assert(map, 'no map')

map = io.toAbsPath(map)

local inputDir = io.local_dir()..[[Input\]]
local outputDir = io.local_dir()..[[Output\]]

removeDir(inputDir)
removeDir(outputDir)

assert(map, 'no map')

osLib.clearScreen()

require 'portLib'

flushDir(inputDir)
createDir(inputDir)

mpqExtract(map, [[war3map.w3i]], inputDir)
mpqExtract(map, [[war3map.wts]], inputDir)

flushDir(outputDir)
createDir(outputDir)

require 'wc3binaryFile'
require 'wc3binaryMaskFuncs'
require 'wtsParser'

local root = wc3binaryFile.create()

root:readFromFile(inputDir..[[war3map.w3i]], infoFileMaskFunc)

local wtsTable = wtsParser.parse(inputDir..[[war3map.wts]])

local mapName = wtsParser.translateString(wtsTable, root:getVal('mapName'))
local buildNum = root:getVal('savesAmount')

if (newName == nil) then
	newName = mapName..' Build '..buildNum
else
	newName = newName:gsub('%%name%%', mapName)
	newName = newName:gsub('%%buildNum%%', buildNum)
end

root:setVal('mapName', newName)

root:writeToFile(outputDir..[[war3map.w3i]], infoFileMaskFunc)

--require 'wc3info'

--local info = wc3info.create()

--info:readFromFile(inputDir..[[war3map.w3i]])

--info:setName(info:getName()..' Build '..info:getSavesAmount())

--info:writeToFile(outputDir..[[war3map.w3i]])

local impPort = createMpqPort()

impPort:addImport(outputDir..[[war3map.w3i]], [[war3map.w3i]])
impPort:addImport(outputDir..[[war3map.wts]], [[war3map.wts]])

impPort:commit(map)