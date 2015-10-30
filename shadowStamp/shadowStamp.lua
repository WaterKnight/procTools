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
portLib.mpqExtract(mapPath, [[war3mapUnits.doo]], inputDir)
portLib.mpqExtract(mapPath, [[war3map.shd]], inputDir)
portLib.mpqExtract(mapPath, [[war3map.w3e]], inputDir)

require 'wc3shd'

local shd = wc3shd.create()

shd:readFromFile(inputDir..[[war3map.doo]])

require 'wc3env'

local w3e = wc3env.create()

w3e:readFromFile(inputDir..[[war3map.w3e]], true)

shd:setDimensions((w3e.width - 1) * 4, (w3e.height - 1) * 4)

require 'wc3doo'
require 'wc3dooUnits'

local doo = wc3doo.create()
local dooUnits = wc3dooUnits.create()

doo:readFromFile(inputDir..[[war3map.doo]])
dooUnits:readFromFile(inputDir..[[war3mapUnits.doo]])

local success, errorMsg = io.syntaxCheck(scriptPath)

assert(success, errorMsg)

local function setXY(x, y, flag)
	assert(x, 'no x')
	assert(y, 'no y')
	assert((flag ~= nil), 'no flag')

	x = math.floor((x - w3e.centerX) / 32)
	y = math.floor((y - w3e.centerY) / 32)

	shd:setDot(shd:dotIndexByXY(x, y), flag)
end

for i = 0, 1000, 1 do
	--shd:setDot(i, true)
end

setXY(0, 0, true)
setXY(32, 0, true)
setXY(32, 32, true)
setXY(0, 32, true)

_G['doo'] = doo
_G['dooUnits'] = dooUnits
_G['shd'] = shd
_G['setXY'] = setXY

loadfile(scriptPath)()

io.removeDir(outputDir)

io.createDir(outputDir)

shd:writeToFile(outputDir..[[war3map.shd]])

portLib.mpqImport(mapPath, outputDir..[[war3map.shd]], [[war3map.shd]])