local params = {...}

local t = params[1]

local out = t['outJass']
local objCon = t['objCon']
local objs = t['objs']

local fieldOccuredValCount = {}

for objId, objData in pairs(objs) do
	for field, val in pairs(objData.vals) do
		if (fieldOccuredValCount[field] == nil) then
			fieldOccuredValCount[field] = {}
		end

		if (type(val) == 'table') then
			for level, val in pairs(val) do
				if (fieldOccuredValCount[field][val] == nil) then
					fieldOccuredValCount[field][val] = 0
				end

				fieldOccuredValCount[field][val] = fieldOccuredValCount[field][val] + 1
			end
		else
			if (fieldOccuredValCount[field][val] == nil) then
				fieldOccuredValCount[field][val] = 0
			end

			fieldOccuredValCount[field][val] = fieldOccuredValCount[field][val] + 1
		end
	end
end

local fieldValOccuredMax = {}

for field, fieldData in pairs(fieldOccuredValCount) do
	local max = 0
	local maxVal

	for val, count in pairs(fieldData) do
		if (count > max) then
			max = count
			maxVal = val
		end
	end

	fieldValOccuredMax[field] = maxVal
end

--[[local f = io.open(io.local_dir()..'out.txt', 'w+')

for field, val in pairs(fieldValOccuredMax) do
	f:write('max\t', field, '\t', val, '\n')
end

for objId, objData in pairs(objs) do
	f:write(objId, '\n')

	for field, val in pairs(objData.vals) do
		if (type(val) == 'table') then
			for level, val in pairs(val) do
				if (val ~= fieldValOccuredMax[field]) then
					f:write('\t', field, '\t', level, '\t', val, '\n')
				end
			end
		else
			if (val ~= fieldValOccuredMax[field]) then
				f:write('\t', field, '\t', val, '\n')
			end
		end
	end
end

f:close()]]

out:createGlobal('hashtable OBJ_TABLE = InitHashtable()')
out:createGlobal('hashtable OBJ_BASE_TABLE = InitHashtable()')
out:createGlobal('hashtable OBJ_LEVEL_TABLE = InitHashtable()')

local topInitFunc = out:createFunc('objForJass_init_autoRun')
local c = 0

local curInitFunc

local function addLine(s)
	if ((c % 10000) == 0) then
		curInitFunc = out:createFunc(string.format('objForJass_init%i', c / 10000))

		topInitFunc:addLine([[call ExecuteFunc(]]..curInitFunc.name:quote()..[[)]])
	end

	c = c + 1
	curInitFunc:addLine(s)
end

for field, val in pairs(fieldValOccuredMax) do
	local fieldType = objCon.metaData.objs[field].vals['type']

	field = string.rep('0', 4 - field:len())..field

	if (fieldType == 'bool') then
		if (val == 0) then
			addLine(string.format([[call SaveBoolean(OBJ_LEVEL_TABLE, %s, '%s', %s)]], 0, field, 'false'))
		else
			addLine(string.format([[call SaveBoolean(OBJ_LEVEL_TABLE, %s, '%s', %s)]], 0, field, 'true'))
		end
	elseif (fieldType == 'int') then
		addLine(string.format([[call SaveInteger(OBJ_LEVEL_TABLE, %s, '%s', %s)]], 0, field, val))
	elseif ((fieldType == 'real') or (fieldType == 'unreal')) then
		addLine(string.format([[call SaveReal(OBJ_LEVEL_TABLE, %s, '%s', %s)]], 0, field, val))
	else
		addLine(string.format([[call SaveStr(OBJ_LEVEL_TABLE, %s, '%s', %q)]], 0, field, val))
	end
end

local levelIndex = 0

for objId, objData in pairs(objs) do
	if (objData.baseId ~= nil) then
		addLine(string.format([[call SaveInteger(OBJ_BASE_TABLE, '%s', 0, '%s')]], objId, objData.baseId))
	end

	for field, val in pairs(objData.vals) do
		local fieldType = objCon.metaData.objs[field].vals['type']

		field = string.rep('0', 4 - field:len())..field

		if (type(val) == 'table') then
			levelIndex = levelIndex + 1

			addLine(string.format([[call SaveInteger(OBJ_TABLE, '%s', '%s', %s)]], objId, field, levelIndex))

			for level, val in pairs(val) do
				if (fieldType == 'bool') then
					if (val == 0) then
						addLine(string.format([[call SaveBoolean(OBJ_LEVEL_TABLE, %s, %s, %s)]], levelIndex, level, 'false'))
					else
						addLine(string.format([[call SaveBoolean(OBJ_LEVEL_TABLE, %s, %s, %s)]], levelIndex, level, 'true'))
					end
				elseif (fieldType == 'int') then
					addLine(string.format([[call SaveInteger(OBJ_LEVEL_TABLE, %s, %s, %s)]], levelIndex, level, val))
				elseif ((fieldType == 'real') or (fieldType == 'unreal')) then
					addLine(string.format([[call SaveReal(OBJ_LEVEL_TABLE, %s, %s, %s)]], levelIndex, level, val))
				else
					addLine(string.format([[call SaveStr(OBJ_LEVEL_TABLE, %s, %s, %q)]], levelIndex, level, val))
				end
			end
		else
			if (fieldType == 'bool') then
				if (val == 0) then
					addLine(string.format([[call SaveBoolean(OBJ_TABLE, '%s', '%s', %s)]], objId, field, 'false'))
				else
					addLine(string.format([[call SaveBoolean(OBJ_TABLE, '%s', '%s', %s)]], objId, field, 'true'))
				end
			elseif (fieldType == 'int') then
				addLine(string.format([[call SaveInteger(OBJ_TABLE, '%s', '%s', %s)]], objId, field, val))
			elseif ((fieldType == 'real') or (fieldType == 'unreal')) then
				addLine(string.format([[call SaveReal(OBJ_TABLE, '%s', '%s', %s)]], objId, field, val))
			else
				addLine(string.format([[call SaveStr(OBJ_TABLE, '%s', '%s', %q)]], objId, field, val))
			end
		end
	end
end

local function createReadFuncs(funcSuffix, returnType, containsFuncSuffix, loadFuncSuffix)
	local readFunc = out:createFunc('objForJass_read'..funcSuffix)

	readFunc:addParam('objId', 'integer')
	readFunc:addParam('field', 'integer')
	readFunc:setReturnType(returnType)

	readFunc:addLine([[
		if not HaveSaved]]..containsFuncSuffix..[[(OBJ_TABLE, objId, field) then
			//return Load]]..loadFuncSuffix..[[(OBJ_TABLE, 0, field)

			if HaveSavedInteger(OBJ_BASE_TABLE, objId, 0) then
				return objForJass_read]]..funcSuffix..[[(LoadInteger(OBJ_BASE_TABLE, objId, 0), field)
			endif
		endif

		return Load]]..loadFuncSuffix..[[(OBJ_TABLE, objId, field)
	]])

	local readLvFunc = out:createFunc(string.format('objForJass_read%sLv', funcSuffix))

	readLvFunc:addParam('objId', 'integer')
	readLvFunc:addParam('field', 'integer')
	readLvFunc:addParam('lv', 'integer')
	readLvFunc:setReturnType(returnType)

	readLvFunc:addLine([[
		local integer levelIndex = LoadInteger(OBJ_TABLE, objId, field)

		if not HaveSaved]]..containsFuncSuffix..[[(OBJ_LEVEL_TABLE, levelIndex, lv) then
			//return Load]]..loadFuncSuffix..[[(OBJ_TABLE, 0, field)

			if HaveSavedInteger(OBJ_BASE_TABLE, objId, 0) then
				return objForJass_read]]..funcSuffix..[[Lv(LoadInteger(OBJ_BASE_TABLE, objId, 0), field, lv)
			endif

		endif

		return Load]]..loadFuncSuffix..[[(OBJ_LEVEL_TABLE, levelIndex, lv)
	]])
end

createReadFuncs('Bool', 'boolean', 'Boolean', 'Boolean')
createReadFuncs('Int', 'integer', 'Integer', 'Integer')
createReadFuncs('Real', 'real', 'Real', 'Real')
createReadFuncs('String', 'string', 'String', 'Str')