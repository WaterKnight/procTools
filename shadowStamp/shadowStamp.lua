require 'waterlua'

local params = {...}

local mapPath = params[1]
local scriptPath = params[2]

assert(mapPath, 'no mapPath')
assert(scriptPath, 'no scriptPath')

local inputDir = io.local_dir()..[[Input\]]
local outputDir = io.local_dir()..[[Output\]]

removeDir(inputDir)
removeDir(outputDir)

createDir(inputDir)

require 'portLib'

mpqExtract(mapPath, [[war3map.doo]], inputDir)
mpqExtract(mapPath, [[war3mapUnits.doo]], inputDir)
mpqExtract(mapPath, [[war3map.shd]], inputDir)
mpqExtract(mapPath, [[war3map.w3e]], inputDir)

require 'wc3shd'

local shd = createShd()

shd:readFromPath(inputDir..[[war3map.doo]])

require 'wc3terrain'

local w3e = createW3e()

w3e:readFromPath(inputDir..[[war3map.w3e]], true)

shd:setDimensions((w3e.width - 1) * 4, (w3e.height - 1) * 4)

require 'wc3doo'
require 'wc3dooUnits'

local doo = createDoo()
local dooUnits = createDooUnits()

doo:readFromPath(inputDir..[[war3map.doo]])
dooUnits:readFromPath(inputDir..[[war3mapUnits.doo]])

local success, errorMsg = syntaxCheck(scriptPath)

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

createDir(outputDir)

shd:writeToPath(outputDir..[[war3map.shd]])

mpqImport(mapPath, outputDir..[[war3map.shd]], [[war3map.shd]])