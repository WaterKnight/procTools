require 'waterlua'

local params = {...}

local mapPath = params[1]
local wc3path = params[2]

assert(mapPath, 'no mapPath')
assert(wc3path, 'no wc3path')

wc3path = io.toFolderPath(wc3path)

osLib.clearScreen()

local inputDir = io.local_dir()..[[Input\]]

io.removeDir(inputDir)

io.createDir(inputDir)

require 'wc3objMerge'

local objCon = wc3objMerge.createMap()

objCon:readFromMap(mapPath, true, wc3path)

local t = {
	'war3map.w3u'
}

require 'portLib'

local port = portLib.createMpqPort()

for _, path in pairs(t) do
	port:addExtract(path, inputDir)
end

port:addExtract('war3map.wts', inputDir)

port:commit(mapPath)

require 'wc3objMod'

local objMods = {}

for _, path in pairs(t) do
	local objMod = wc3objMod.create()

	objMod:readFromFile(inputDir..path)

	objMods[path] = objMod
end

local function replace(val)
	local pos, posEnd, cap = val:find('(%b<>)')

	while (pos ~= nil) do
		local cut = val:sub(pos + 1, posEnd - 1)

		local objId, field = cut:match('(....)%,(.*)')

		local repVal

		if ((objId ~= nil) and (field ~= nil)) then
			local obj = objCon:getObj(objId)

			repVal = obj:getBySlk(field)
		end

		if (repVal ~= nil) then
			val = val:sub(1, pos - 1)..repVal..val:sub(posEnd + 1, val:len())
		else
			val = val:sub(1, pos - 1)..'$'..val:sub(pos + 1, posEnd - 1)..'$'..val:sub(posEnd + 1, val:len())				
		end

		pos, posEnd, cap = val:find('(%b<>)')
	end

	return val
end

for _, objMod in pairs(objMods) do
	for objId, obj in pairs(objMod.objs) do
		for field, fieldData in pairs(obj.fields) do
			for level, levelData in pairs(fieldData) do
				local val = levelData.val

				if (type(val) == 'string') then
					levelData.val = replace(val)
				end
			end
		end
	end
end

local wts

if (io.pathExists(inputDir..'war3map.wts')) then
	require 'wc3wts'

	wts = wc3wts.create()

	wts:readFromFile(inputDir..'war3map.wts')

	for key, val in pairs(wts.strings) do
		wts:addString(key, replace(val))
	end
end

local outputDir = io.local_dir()..[[Output\]]

io.removeDir(outputDir)

io.createDir(outputDir)

for path, objMod in pairs(objMods) do
	objMod:writeToFile(outputDir..path)
end

if (wts ~= nil) then
	wts:writeToFile(outputDir..'war3map.wts')
end

local port = portLib.createMpqPort()

for path in pairs(objMods) do
	port:addImport(outputDir..path, path)
end

if (wts ~= nil) then
	port:addImport(outputDir..'war3map.wts', 'war3map.wts')
end

port:commit(mapPath)