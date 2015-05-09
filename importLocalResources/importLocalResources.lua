local params = {...}

local mapPath = params[1]
local lookupPath = params[2]

assert(mapPath, 'no mapPath')
assert(lookupPath, 'no lookupPath')

require 'waterlua'

lookupPath = io.toFolderPath(lookupPath)

osLib.clearScreen()

local modelPaths = {}

require 'wc3objMerge'

local objCon = objLib.createInstance()

objCon:readFromMap(mapPath, false)

for objId, objData in pairs(objCon.objs) do
	for field, fieldData in pairs(objData.fields) do
		for level, levelData in pairs(fieldData) do
			local val = levelData.val

			if (type(val) == 'string') then
				modelPaths[val] = val
			end
		end
	end
end

require 'portLib'

local extPort = createMpqPort()

extPort:addExtract('war3map.wts', 'war3map.wts')
extPort:addExtract('war3map.j', 'war3map.j')

extPort:commit(mapPath)

require 'wc3jass'

local j = createJass()

j:readFromPath('war3map.j')

local function searchJassLine(line)
	line = line:gsub([[\\]], string.char(1))
	line = line:gsub([[\"]], string.char(2))

	local lits = line:gmatch([[%"(.-)%"]])

	for lit in lits do
		lit = lit:gsub(string.char(1), [[\]])
		lit = lit:gsub(string.char(2), [["]])

		modelPaths[lit] = lit
	end
end

for _, glob in pairs(j.globals) do
	if (glob.val ~= nil) then
		searchJassLine(glob.val)
	end
end

for _, func in pairs(j.funcs) do
	for _, line in pairs(func.lines) do
		searchJassLine(line)
	end
end

require 'wtsParser'

local parseTable = wtsParser.parse('war3map.wts')

local t = copyTable(modelPaths)

for path in pairs(t) do
	modelPaths[path] = nil

	path = wtsParser.translateString(parseTable, path)

	if path:match([[^Local\]]) then
		modelPaths[path] = path
	end
end

local impPort = createMpqPort()

for _, path in pairs(modelPaths) do
	local diskPath = io.toAbsPath(path, lookupPath)

	if io.pathExists(diskPath) then
		print('import', diskPath, 'to', path)
		require 'mdxLib'

		local mdx = createMdx()

		mdx:readFromPath(diskPath)

		for _, tex in pairs(mdx.texs) do
			if tex.hasPath then
				local texDiskPath = io.toAbsPath(tex.path, io.toAbsPath(getFolder(path), lookupPath))
				local texTargetPath = getFolder(path)..tex.path

				print('\tadd skin:', texDiskPath, 'to', texTargetPath)
				impPort:addImport(texDiskPath, texTargetPath)
			end
		end

		impPort:addImport(diskPath, path)
	else
		print(path, 'not found')
	end
end

impPort:commit(mapPath)