local params = {...}

local scriptPath = params[1]
local outputPath = params[2]

assert(scriptPath, 'no scriptPath')
assert(outputPath, 'no outputPath')

require 'waterlua'

require 'wc3jass'

local script = wc3jass.create()

script:readFromFile(scriptPath)

local function createType(name, jassType)
	local func = script:createFunc(string.format('objForJass_read%s', name))

	func:setNative(true)

	func:addParam('objId', 'integer')
	func:addParam('field', 'integer')
	func:setReturnType(jassType)

	local func = script:createFunc(string.format('objForJass_read%sLv', name))

	func:setNative(true)

	func:addParam('objId', 'integer')
	func:addParam('field', 'integer')
	func:addParam('lv', 'integer')
	func:setReturnType(jassType)
end

createType('Bool', 'boolean')
createType('Int', 'integer')
createType('Real', 'real')
createType('String', 'string')

local func = script:createFunc(string.format('objForJass_init_autoRun', name))

func:setNative(true)

script:writeToFile(outputPath)

