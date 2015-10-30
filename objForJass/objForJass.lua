require 'waterlua'

local params = {...}

local mapPath = params[1]
local wc3path = params[2]
local scriptPath = params[3]

assert(mapPath, 'no mapPath')
assert(wc3path, 'no wc3path')

wc3path = io.toFolderPath(wc3path)

require 'wc3objMerge'

local objCon = wc3objMerge.createMap()

objCon:readFromMap(mapPath, true, wc3path)

local function fieldMatchVal(field, val)
	local fieldType = objCon.metaData.objs[field].vals['type']

	if ((fieldType == 'bool') or (fieldType == 'int')) then
		if (type(val) ~= 'number') then
			return false
		end
		if (tostring(math.floor(val)) ~= tostring(val)) then
			return false
		end
	end
	if ((fieldType == 'real') or (fieldType == 'unreal')) then
		if (type(val) ~= 'number') then
			return false
		end
	end

	return true
end

local objs = {}

--[[for slkName, slk in pairs(objCon.outSlks) do
	for objId, objData in pairs(slk.objs) do
		if (objs[objId] == nil) then
			objs[objId] = {}

			objs[objId].vals = {}
		end

		for field, val in pairs(objData.vals) do
			if (field ~= slk.pivotField) then
				if ((val == '') or (val == '-') or (val == ' - ') or (val == '_') or (tonumber(val) == 0)) then
					val = nil
				end

				if (val ~= nil) then
					local level = field:match('(%d+)$')

					if (level ~= nil) then
						field = field:match('^([a-zA-Z]*)')

						field = pureNameToMetaName(field, slkName, objData.vals['code'])

						if ((field ~= nil) and fieldMatchVal(field, val)) then
							if (objs[objId].vals[field] == nil) then
								objs[objId].vals[field] = {}
							end

							objs[objId].vals[field][level] = val
						end
					else
						field = pureNameToMetaName(field, slkName)

						if ((field ~= nil) and fieldMatchVal(field, val)) then
							objs[objId].vals[field] = val
						end
					end
				end
			end
		end
	end
end]]

for objId, objData in pairs(objCon.objs) do
	if (objs[objId] == nil) then
		objs[objId] = {}

		objs[objId].baseId = objData.baseId
		objs[objId].vals = {}
	end

	for field, fieldData in pairs(objData.fields) do
		for level, levelData in pairs(fieldData) do
			local val = levelData.val

			if ((val == '') or (val == '-') or (val == ' - ') or (val == '_') or (tonumber(val) == 0)) then
				val = nil
			end

			if (val ~= nil) then
				if (level == 0) then
					objs[objId].vals[field] = val
				else
					if (objs[objId].vals[field] == nil) then
						objs[objId].vals[field] = {}
					end

					objs[objId].vals[field][level] = val
				end
			end
		end
	end
end

require 'wc3jass'

local out = wc3jass.create()

if (scriptPath == nil) then
	scriptPath = io.local_dir()..'stdScript.lua'
end

if (scriptPath ~= nil) then
	local f = loadfile(scriptPath)

	if (f == nil) then
		error('cannot load script '..tostring(scriptPath))
	end

	local function useStd()
		local f = loadfile(io.local_dir()..'stdScript.lua')

		assert(f, string.format('cannot load script %s', scriptPath))

		f({pause = osLib.pause, objCon = objCon, objs = objs, outJass = out})
	end

	local params = {pause = osLib.pause, objCon = objCon, objs = objs, outJass = out, useStd = useStd}

	local function doScript2()
		local f = loadfile(scriptPath)

		assert(f, string.format('cannot load script %s', scriptPath))

		local t = {error = error, tostring = tostring, print = print, pairs = pairs, string = string, io = io, type = type}

		for k, v in pairs(params) do
			t[k] = v
		end

		setfenv(f, t)

		f(params)
	end

	local function doScript()
		local ring = rings.new()

		local s = [[
			local f = loadfile(%q)

			assert(f, 'cannot load script %s')

			local t = {...}

			local out = t[1]

			--f()

			local s = 'return 4'

			local res, out = remotedostring(s)
			error(tostring(res)..';'..tostring(out))
		]]

		local t = {out}

		local res, msg, trace = ring:dostring(string.format(s, scriptPath, scriptPath), {})

		if not res then
			error(msg)
		end
	end

	doScript2()
end

out:writeToFile(io.local_dir()..'out.j')

portLib.mpqExtract(mapPath, 'war3map.j', io.local_dir())

local j = wc3jass.create()

j:readFromFile(io.local_dir()..'war3map.j')

out:merge(j)

out:writeToFile(io.local_dir()..'war3map.j')

portLib.mpqImport(mapPath, io.local_dir()..'war3map.j', 'war3map.j')