require 'waterlua'

local params = {...}

local mapPath = params[1]

assert(mapPath, 'no map path')

mapPath = io.toAbsPath(mapPath)

local inputDir = io.local_dir()..[[Input\]]
local outputDir = io.local_dir()..[[Output\]]

require 'portLib'

io.removeDir(inputDir)

io.createDir(inputDir)

portLib.mpqExtract(mapPath, [[war3map.wpm]], inputDir)
portLib.mpqExtract(mapPath, [[war3map.w3r]], inputDir)
portLib.mpqExtract(mapPath, [[war3map.w3e]], inputDir)

local rectFile = io.open(inputDir..[[war3map.w3r]])

if (rectFile == nil) then
	return
end

rectFile:close()

require 'wc3env'

local terrain = wc3env.create()

terrain:readFromFile(inputDir..[[war3map.w3e]], true)

require 'wc3rect'

local rectFile = wc3rect.create()

rectFile:readFromFile(inputDir..[[war3map.w3r]])

local sourceRects = {}

require 'wc3wpm'

local wpm = wc3wpm.create()

wpm:readFromFile(inputDir..[[war3map.wpm]])

wpm:setBaseTerrain(terrain)

for i = 1, #rectFile.rects, 1 do
	local rect = rectFile.rects[i]

	local name = rect.name

	local type = name:match('wpm(%w)_') or name:match('wpm(%w) ')

	if (type ~= nil) then
		local minX, minY = wpm:getFromCoords(rect.minX, rect.minY)
		local maxX, maxY = wpm:getFromCoords(rect.maxX, rect.maxY)

		local newRect = {}

		newRect.minX = minX
		newRect.minY = minY
		newRect.maxX = maxX
		newRect.maxY = maxY

		if (type == 'a') then
			newRect.flags = wc3wpm.pathingTypes.FLAG_FLY + wc3wpm.pathingTypes.FLAG_BUILD
		elseif (type == 'g') then
			newRect.flags = wc3wpm.pathingTypes.FLAG_WALK + wc3wpm.pathingTypes.FLAG_UNKNOWN3
		elseif (type == 'b') then
			newRect.flags = wc3wpm.pathingTypes.FLAG_WALK + wc3wpm.pathingTypes.FLAG_FLY + wc3wpm.pathingTypes.FLAG_UNKNOWN3
		end

		sourceRects[#sourceRects + 1] = newRect
	end
end

local maxX = wpm.width - 1
local maxY = wpm.height - 1

local checked = {}

print('#sourceRects', #sourceRects)

local t = osLib.createTimer()

for i = 1, #sourceRects, 1 do
	local rect = sourceRects[i]

	local minX = rect.minX
	local minY = rect.minY
	local maxX = rect.maxX
	local maxY = rect.maxY

	for y = minY, maxY, 1 do
		for x = minX, maxX, 1 do
			wpm:addFlag(x, y, rect.flags)
		end
	end
end

print(string.format('painted in %s seconds', math.cutFloat(t:getElapsed())))

io.removeDir(outputDir)

io.createDir(outputDir)

wpm:writeToFile(outputDir..[[war3map.wpm]])

local impPort = portLib.createMpqPort()

impPort:addImport(outputDir..[[war3map.wpm]], [[war3map.wpm]])

impPort:commit(mapPath)