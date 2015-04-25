require 'waterlua'

local params = {...}

local mapPath = params[1]

assert(mapPath, 'no map path')

mapPath = io.toAbsPath(mapPath)

local inputDir = io.local_dir()..[[Input\]]
local outputDir = io.local_dir()..[[Output\]]

removeDir(inputDir)
removeDir(outputDir)

require 'portLib'

flushDir(inputDir)

createDir(inputDir)

mpqExtract(mapPath, [[war3map.wpm]], inputDir)
mpqExtract(mapPath, [[war3map.w3r]], inputDir)
mpqExtract(mapPath, [[war3map.w3e]], inputDir)

local rectFile = io.open(inputDir..[[war3map.w3r]])

if (rectFile == nil) then
	return
end

rectFile:close()

require 'wc3binaryFile'
require 'wc3binaryMaskFuncs'

local root = wc3binaryFile.create()

root:readFromFile(inputDir..[[war3map.w3e]], envMaskFuncOnlyHeader)

local centerX = root:getVal('centerX')
local centerY = root:getVal('centerY')

local root = wc3binaryFile.create()

root:readFromFile(inputDir..[[war3map.w3r]], rectMaskFunc)

local sourcePts = {}

for i = 1, root:getVal('rectsCount'), 1 do
	local rect = root:getSub('rect'..i)

	local name = rect:getVal('name')

	if ((name:sub(1, 4) == 'wpm_') or (name:sub(1, 4) == 'wpm ')) then
		local x = math.floor(((rect:getVal('minX') + rect:getVal('maxX')) / 2 - centerX) / 32)
		local y = math.floor(((rect:getVal('minY') + rect:getVal('maxY')) / 2 - centerY) / 32)

		local newPt = {}

		newPt.x = x
		newPt.y = y

		sourcePts[#sourcePts + 1] = newPt		
	end
end

require 'wc3wpm'

local wpm = createWpm()

wpm:readFromFile(inputDir..[[war3map.wpm]])

local maxX = wpm.width - 1
local maxY = wpm.height - 1

local checked = {}

local function fill(x, y)
	if wpm:isFlag(x, y, pathingTypes.FLAG_WALK) then
		return
	end

	local xStack = {}
	local yStack = {}

	local c = 0

	local function push(x, y)
		c = c + 1

		xStack[c] = x
		yStack[c] = y
	end

	push(x, y)

	local function next(x, y)
		if ((x < 0) or (x > maxX)) then
			return
		end
		if ((y < 0) or (y > maxY)) then
			return
		end

		if wpm:isFlag(x, y, pathingTypes.FLAG_WALK) then
			return
		end

		if (checked[x] == nil) then
			checked[x] = {}
		end

		if checked[x][y] then
			return
		end

		checked[x][y] = true

		push(x - 1, y)
		push(x + 1, y)
		push(x, y - 1)
		push(x, y + 1)
	end

	while (c > 0) do
		x = xStack[c]
		y = yStack[c]

		c = c - 1

		next(x, y)
	end
end

print('#sourcePts', #sourcePts)

local t = osLib.createTimer()

for i = 1, #sourcePts, 1 do
	local pt = sourcePts[i]

	print('pt', i, '->', pt.x, pt.y)
	fill(pt.x, pt.y)
end

print(string.format('filled in in %s seconds', math.cutFloat(t:getElapsed())))

local c = 0

local t = osLib.createTimer()

for y = 0, maxY, 1 do
	for x = 0, maxX, 1 do
		if ((checked[x] == nil) or not checked[x][y]) then
			wpm:addFlag(x, y, pathingTypes.FLAG_WALK + pathingTypes.FLAG_UNKNOWN3)

			c = c + 1
		end
	end
end

print(string.format('%i cells changed within %s seconds', c, math.cutFloat(t:getElapsed())))

flushDir(outputDir)

createDir(outputDir)

wpm:writeToFile(outputDir..[[war3map.wpm]])

local impPort = createMpqPort()

impPort:addImport(outputDir..[[war3map.wpm]], [[war3map.wpm]])

impPort:commit(mapPath)