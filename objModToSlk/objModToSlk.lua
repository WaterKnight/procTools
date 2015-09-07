require 'waterlua'

local params = {...}

local mapPath = params[1]
local wc3path = params[2]

assert(mapPath, 'no mapPath')
assert(wc3path, 'no wc3path')

wc3path = io.toFolderPath(wc3path)

osLib.clearScreen()

--[[require 'wc3objMerge'

local objCon = objLib.createInstance()

objCon:readFromMap(mapPath, true, wc3path)

objCon:writeToMap(mapPath)

if true then
	return
end]]

local add = debug.getinfo(1, 'S').source:sub(2):match('(.*'..'\\'..')')..'?.lua'

package.path = package.path..';'..add

require 'objLib'

require 'portLib'

local inputDir = io.local_dir()..[[Input\]]

flushDir(inputDir)

createDir(inputDir)

local patchMpqPath = wc3path..'War3Patch.mpq'
local tftMpqPath = wc3path..'War3x.mpq'
local classicMpqPath = wc3path..'war3.mpq'

local mpqPaths = {mapPath, patchMpqPath, tftMpqPath, classicMpqPath}

local commonExtPort = portLib.createMpqPort()

local slkPaths = {
	[[Units\UnitAbilities.slk]],
	[[Units\UnitBalance.slk]],
	[[Units\UnitData.slk]],
	[[Units\unitUI.slk]],
	[[Units\UnitWeapons.slk]],

	[[Units\ItemData.slk]],
	[[Units\DestructableData.slk]],
	[[Units\AbilityData.slk]],
	[[Units\AbilityBuffData.slk]],
	[[Units\UpgradeData.slk]]
}

for _, path in pairs(slkPaths) do
	commonExtPort:addExtract(path, inputDir)
end

local profilePath = [[Units\CampaignUnitStrings.txt]]

commonExtPort:addExtract(profilePath, inputDir)

--commonExtPort:addExtract([[Units\HumanAbilityFunc.txt]], inputDir)
--commonExtPort:addExtract([[Units\HumanUnitStrings.txt]], inputDir)

commonExtPort:commit(mpqPaths)

local mapExtPort = portLib.createMpqPort()

local exts = {'w3u', 'w3t', 'w3b', 'w3d', 'w3a', 'w3h', 'w3q'}

for _, ext in pairs(exts) do
	mapExtPort:addExtract([[war3map.]]..ext, inputDir)
end

mapExtPort:addExtract([[war3map.wts]], inputDir)

mapExtPort:commit(mapPath)

local objContainer = objLib:createInstance(profilePath, inputDir..[[war3map.wts]])

objContainer:addFromDir(inputDir)

local outputDir = io.local_dir()..[[Output\]]

objContainer:output(outputDir)

local impPort = portLib.createMpqPort()

for _, ext in pairs(exts) do
	impPort:addDelete([[war3map.]]..ext)
end

for _, path in pairs(getFiles(outputDir, '*')) do
	local targetPath = path:sub(outputDir:len() + 1, path:len())

	impPort:addImport(path, targetPath)
end

impPort:commit(mapPath)