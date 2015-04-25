require 'waterlua'

objLib = {}

function objLib:createInstance(profilePath, wtsPath)
	assert(profilePath, 'no profilePath (arg1)')
	assert(wtsPath, 'no wtsPath (arg2)')

	local this = {}

	local headerSlksFolder = io.local_dir()..[[HeaderData\]]

	local headerSlks = {}

	require 'slkLib'

	for _, path in pairs(getFiles(headerSlksFolder, '*.slk')) do
		local folder = getFolder(path)
		local fileNameNoExt = getFileName(path, true)

		local pathNoExt = folder..fileNameNoExt

		local slk = readSlk(pathNoExt)

		headerSlks[#headerSlks + 1] = slk
	end

	local outSlks = {}

	for i = 1, #headerSlks, 1 do
		local slk = headerSlks[i]

		local path = slk.path

		local outSlk = createSlk(path:sub(headerSlksFolder:len() + 1, path:len()))

		for field in pairs(slk.fields) do
			outSlk:addField(field)
		end

		outSlk.pivotField = slk.pivotField

		outSlks[getFileName(path, true):lower()] = outSlk
	end

	function this:addSlk(path)
		assert(path, 'no path')

		require 'slkLib'

		local folder = getFolder(path)
		local fileNameNoExt = getFileName(path, true)

		local outSlk = outSlks[fileNameNoExt:lower()]

		outSlk:merge(readSlk(path))
	end

	local metaSlksFolder = io.local_dir()..[[MetaData\]]
	local metaData = createSlk('')

	for _, path in pairs(getFiles(metaSlksFolder, '*.slk')) do
		local folder = getFolder(path)
		local fileNameNoExt = getFileName(path, true)

		local pathNoExt = folder..fileNameNoExt

		local slk = readSlk(pathNoExt)

		metaData:merge(slk)
	end

	require 'wc3profile'

	local outProfile = createProfile(wtsPath)

	function this:addProfile(path)
		assert(path, 'no path')

		local profile = createProfile()

		profile:readFromFile(path)

		outProfile:merge(profile)
	end

	local outObjMods = {}

	function this:addObjMod(path)
		assert(path, 'no path')

		local ext = getFileExtension(path)

		require 'wc3objMod'

		local objMod = createObjMod()

		objMod:readFromFile(path)

		local objTypeTable = {
			w3u = 'unit',
			w3t = 'item',
			w3b = 'destructable',
			w3d = 'doodad',
			w3a = 'ability',
			w3h = 'buff',
			w3q = 'upgrade'
		}

		for objId, objData in pairs(objMod.objs) do
			local baseId = objData.base

			if baseId then
				for outSlkName, outSlk in pairs(outSlks) do
					if outSlk.objs[baseId] then
						if (outSlk.objs[objId] == nil) then
							outSlk:addObj(objId)
						end

						outSlk:objMerge(objId, baseId)
					end
				end

				if outProfile.objs[baseId] then
					if (outProfile.objs[objId] == nil) then
						outProfile:addObj(objId)
					end

					outProfile:objMerge(objId, baseId)
				end
			end

			for field, fieldData in pairs(objData.fields) do
				for level, levelData in pairs(fieldData) do
					local metaObj = metaData.objs[field]

						local deleteFromObjMod = false

					if metaObj then
						local slkName = metaObj.vals['slk']

						local slkField = metaObj.vals['field']

						if (slkName == 'Profile') then
							if (outProfile.objs[objId] == nil) then
								outProfile:addObj(objId)
							end

							local val = levelData.val

							local index = level

							if (metaObj.vals['index'] > 0) then
								level = level + metaObj.vals['index']
							end

							outProfile:objSetVal(objId, slkField, val, index)

							deleteFromObjMod = true
						else
							local outSlk = outSlks[slkName:lower()]

							assert(outSlk, 'slk '..tostring(metaObj.vals['slk'])..' missing')

							local val = levelData.val

							if (metaObj.vals['field'] == 'Data') then
								slkField = slkField..string.char(string.byte('A') + levelData.dataPointer - 1)
							end

							if ((metaObj.vals['repeat'] ~= nil) and (metaObj.vals['repeat'] > 0)) then
								slkField = slkField..tonumber(level)
							end

							if outSlk.fields[slkField] then
								if (outSlk.objs[objId] == nil) then
									outSlk:addObj(objId)
								end

								outSlk:objSetField(objId, slkField, val)

								deleteFromObjMod = true
							end
						end
					end

						if deleteFromObjMod or field=='wurs' then
							objMod:objDeleteVal(objId, field, level)

							if (getTableSize(objMod.objs[objId].fields) == 0) then
								objMod:deleteObj(objId)
							end
						else
							--print('cannot delete', field, level)
						end
				end
			end
		end

		if (outObjMods[ext] == nil) then
			outObjMods[ext] = createObjMod()

			outObjMods[ext].type = ext
		end

		outObjMods[ext]:merge(objMod)
	end

	function this:addFromDir(dir)
		assert(dir, 'no dir')

		for _, path in pairs(getFiles(dir, '*.slk')) do
			this:addSlk(path)
		end

		for _, path in pairs(getFiles(dir, '*.txt')) do
			this:addProfile(path)
		end

		for _, path in pairs(getFiles(dir, '*.w3*')) do
			this:addObjMod(path)
		end
	end

	function this:print()
		for i = 1, #objs, 1 do
			local obj = objs[i]

			print(obj.id)

			for field, val in pairs(obj.vals) do
				print('\t', field, '->', val)
			end
		end
	end

	function this:output(outDir)
		flushDir(outDir)

		createDir(outDir)

		for _, slk in pairs(outSlks) do
			if (getTableSize(slk.objs) > 0) then
				slk:write(outDir..slk.path)
			end
		end

		--outProfile:write(outDir..[[Units\HumanAbilityFunc.txt]])
		outProfile:write(outDir..profilePath)

		for ext, objMod in pairs(outObjMods) do
			if (getTableSize(objMod.objs) > 0) then
				objMod:write(outDir..'war3map.'..ext)
			end
		end
	end

	return this
end