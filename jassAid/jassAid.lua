local params = {...}

local mapPath = params[1]
local wc3path = params[2]
local commonJPath = params[3]
local blizzardJPath = params[4]
local logId = params[5]

local doTracebacks = true

assert(mapPath, 'no mapPath')
assert(wc3path, 'no wc3path')
assert(commonJPath, 'no commonJPath')
assert(blizzardJPath, 'no blizzardJPath')

require 'waterlua'

require 'portLib'

local inputDir = io.local_dir()..[[Input\]]

io.removeDir(inputDir)

io.createDir(inputDir)

portLib.mpqExtract(mapPath, 'war3map.j', inputDir..'war3map.j')

require 'wc3jass'

if (commonJPath == nil) then
	commonJPath = inputDir..[[Scripts\common.j]]

	portLib.mpqExtractLatest(mapPath, [[Scripts\common.j]], inputDir, wc3path)
else
	commonJPath = io.toAbsPath(commonJPath, io.curDir())

	io.copyFile(commonJPath, inputDir..[[Scripts\common.j]])

	commonJPath = inputDir..[[Scripts\common.j]]
end

local natives = wc3jass.getNatives(commonJPath)

local blizzardJass = wc3jass.create()

if (blizzardJPath == nil) then
	blizzardJPath = inputDir..[[Scripts\blizzard.j]]

	portLib.mpqExtractLatest(mapPath, [[Scripts\blizzard.j]], inputDir, wc3path)
else
	blizzardJPath = io.toAbsPath(blizzardJPath, io.curDir())

	io.copyFile(blizzardJPath, inputDir..[[Scripts\blizzard.j]])

	blizzardJPath = inputDir..[[Scripts\blizzard.j]]
end

blizzardJass:readFromFile(blizzardJPath)

local jass = wc3jass.create()

--wc3jass.syntaxCheck({commonJPath, blizzardJPath, inputDir..'war3map.j'}, true)

jass:readFromFile(inputDir..'war3map.j')

local debugJass = wc3jass.create()

wc3jass.syntaxCheck({commonJPath, blizzardJPath, io.local_dir()..'debug.j'}, true)

debugJass:readFromFile(io.local_dir()..'debug.j')

local wrapperJass = wc3jass.create()

wc3jass.syntaxCheck({commonJPath, blizzardJPath, io.local_dir()..'wrapperFuncs.j'}, true)

wrapperJass:readFromFile(io.local_dir()..'wrapperFuncs.j')

debugJass:merge(wrapperJass)

jass:merge(blizzardJass)
jass:merge(debugJass)

local prevGlobalsC = #jass.globals
local prevFuncsC = #jass.funcs

local autoRuns = {}
local autoExecs = {}
local structLinks = {}

local AUTO_EXEC_TRIG_PREFIX = 'autoExecTrig_'

local outError = io.open('errors.txt', 'w+')

identifierSymbols = {}

for i = string.byte('A'), string.byte('Z'), 1 do
	identifierSymbols[string.char(i)] = true
end

for i = string.byte('a'), string.byte('z'), 1 do
	identifierSymbols[string.char(i)] = true
end

for i = string.byte('0'), string.byte('9'), 1 do
	identifierSymbols[string.char(i)] = true
end

identifierSymbols['_'] = true

local function isIdentifierChar(char)
	if char then
		return identifierSymbols[char]
	end

	return false
end

--identifierPat = '[A-Za-z0-9_$]'
identifierPat = '[A-Za-z_$][A-Za-z0-9_$]*'
identifierNegPat = '[^A-Za-z0-9_$]'

string.outstrikeStringLiterals = function(line)
	assert(line, 'no line')

	line = line:gsub([[\\]], [[##]])

	line = line:gsub([[\"]], [[##]])

	local pos, posEnd, cap = line:find([[("[^%"]*")]])

	while pos do
		line = line:sub(1, pos - 1)..string.rep('#', cap:len())..line:sub(posEnd + 1)

		pos, posEnd, cap = line:find([[("[^%"]*")]])
	end

	return line
end

string.readIdentifier = function(line, posStart)
	line = line:outstrikeStringLiterals()

	posStart = line:find(identifierPat, posStart)

	if (posStart == nil) then
		return nil
	end

	local posEnd = line:find(identifierNegPat, posStart)

	if posEnd then
		posEnd = posEnd - 1
	else
		posEnd = line:len()
	end

	return line:sub(posStart, posEnd), posStart, posEnd
end

string.reverseReadIdentifier = function(line, pos)
	local len = line:len()

	line, posStart, posEnd = line:reverse():readIdentifier(len - pos + 1)

	return line:reverse(), len - posEnd + 1, len - posStart + 1
end

local function extendGlobal(glob)
	assert(glob, 'no glob')

	glob.reqs = {}

	function glob:addReq(reqName)
		assert(reqName, 'no req')

		if glob.reqs[reqName] then
			return
		end

		if (glob.name == reqName) then
			return
		end

		glob.reqs[reqName] = reqName
		glob.reqs[#glob.reqs + 1] = reqName
	end

	function glob:removeReq(reqName)
		assert(reqName, 'no req')

		glob.reqs[reqName] = nil

		for i = 1, #glob.reqs, 1 do 
			if (glob.reqs[i] == reqName) then
				table.remove(glob.reqs, i)
			end
		end
	end
end

for _, glob in pairs(jass.globals) do
	extendGlobal(glob)
end

local function createGlobal(name, type, isArray, val, isConst)
	local global = jass:createGlobal(name, type, isArray, val, isConst)

	extendGlobal(global)

	return global
end

local function extendFunc(func)
	assert(func, 'no func')

	func.reqs = {}

	function func:addReq(reqName)
		assert(reqName, 'no req')

		if func.reqs[reqName] then
			return
		end

		if (func.name == reqName) then
			return
		end

		func.reqs[reqName] = reqName
		func.reqs[#func.reqs + 1] = reqName
	end

	function func:removeReq(reqName)
		assert(reqName, 'no req')

		func.reqs[reqName] = nil

		for i = 1, #func.reqs, 1 do 
			if (func.reqs[i] == reqName) then
				table.remove(func.reqs, i)
			end
		end
	end

	function func:setAsEvalFunc()
		func.isEvalFunc = true
	end
end

for _, func in pairs(jass.funcs) do
	extendFunc(func)
end

local function createFunc(name)
	local func = jass:createFunc(name)

	extendFunc(func)

	return func
end

string.findEndBracket = function(line, pos, startBracket, endBracket)
	local endBracketPos, endBracketPosEnd = line:find(endBracket, pos, true)

	if (endBracketPos == nil) then
		return line:len(), line:len()
	end

	local remaining = 1

	while ((remaining > 0) and endBracketPos) do
		pos, posEnd = line:find(startBracket, pos, true)

		while (pos and (pos < endBracketPos)) do
			pos, posEnd = line:find(startBracket, posEnd + 1, true)
			remaining = remaining + 1
		end

		pos, posEnd = endBracketPosEnd + 1
		remaining = remaining - 1

		if (remaining > 0) then
			endBracketPos, endBracketPosEnd = line:find(endBracket, endBracketPosEnd + 1, true)
		end
	end

	return endBracketPos, endBracketPosEnd
end

local replaceNativeMap = {}

local function replaceNative(name, f)
	assert(name, 'no name')
	assert(f, 'no func')

	if (type(f) == 'string') then
		local targetName = f

		f = jass:getFuncByName(targetName)

		assert(f, 'no func '..targetName)
	end

	replaceNativeMap[name] = f
end

local t = {
	DebugMsg = 'gg__debugMsg',
	InfoEx = 'gg__info',
	Player = 'gg__Player'
}

if doTracebacks then
	table.merge(t, {		
		DebugEx = 'gg__debugEx',

		Preloader = 'gg__Preloader',

		TriggerEvaluate = 'gg__TriggerEvaluate',
		TriggerExecute = 'gg__TriggerExecute',
		EnableTrigger = 'gg__EnableTrigger',
		DisableTrigger = 'gg__DisableTrigger',
		DestroyTrigger, 'gg__DestroyTrigger',
		TriggerSleepAction = 'gg__TriggerSleepAction',
		TriggerAddAction = 'gg__TriggerAddAction',
		ExecuteFunc = 'gg__ExecuteFunc',

		Condition = 'gg__Condition',
		Filter = 'gg__Filter',
		EnumDestructablesInRect = 'gg__EnumDestructablesInRect',
		EnumItemsInRect = 'gg__EnumItemsInRect',
		TimerStart = 'gg__TimerStart',
		DestroyTimer = 'gg__DestroyTimer',

		DestroyBoolExpr = 'gg__DestroyBoolExpr',
		DestroyCondition = 'gg__DestroyCondition',
		DestroyFilter = 'gg__DestroyFilter',

		TriggerRegisterPlayerEvent = 'gg__TriggerRegisterPlayerEvent',
		TriggerRegisterDeathEvent = 'gg__TriggerRegisterDeathEvent',
		TriggerRegisterDialogButtonEvent = 'gg__TriggerRegisterDialogButtonEvent',
		TriggerRegisterDialogEvent = 'gg__TriggerRegisterDialogEvent',
		TriggerRegisterEnterRegion = 'gg__TriggerRegisterEnterRegion',
		TriggerRegisterFilterUnitEvent = 'gg__TriggerRegisterFilterUnitEvent',
		TriggerRegisterGameEvent = 'gg__TriggerRegisterGameEvent',
		TriggerRegisterGameStateEvent = 'gg__TriggerRegisterGameStateEvent',
		TriggerRegisterLeaveRegion = 'gg__TriggerRegisterLeaveRegion',
		TriggerRegisterPlayerAllianceChange = 'gg__TriggerRegisterPlayerAllianceChange',
		TriggerRegisterPlayerChatEvent = 'gg__TriggerRegisterPlayerChatEvent',
		TriggerRegisterPlayerEvent = 'gg__TriggerRegisterPlayerEvent',
		TriggerRegisterPlayerStateEvent = 'gg__TriggerRegisterPlayerStateEvent',
		TriggerRegisterPlayerUnitEvent = 'gg__TriggerRegisterPlayerUnitEvent',
		TriggerRegisterTimerEvent = 'gg__TriggerRegisterTimerEvent',
		TriggerRegisterTimerExpireEvent = 'gg__TriggerRegisterTimerExpireEvent',
		TriggerRegisterTrackableHitEvent = 'gg__TriggerRegisterTrackableHitEvent',
		TriggerRegisterTrackableTrackEvent = 'gg__TriggerRegisterTrackableTrackEvent',
		TriggerRegisterUnitEvent = 'gg__TriggerRegisterUnitEvent',
		TriggerRegisterUnitInRange = 'gg__TriggerRegisterUnitInRange',
		TriggerRegisterUnitStateEvent = 'gg__TriggerRegisterUnitStateEvent',
		TriggerRegisterVariableEvent = 'gg__TriggerRegisterVariableEvent'
	})
end

for source, target in pairs(t) do
	replaceNative(source, target)
end

if removeJasshelperStuff then
	for _, func in pairs(jass.funcs) do
		local name = func.name

		if (name:sub(1, 4) == 'sa__') or (name:sub(1, 4) == 'sc__') then
			func:remove()
		else
			for _, line in pairs(func.lines) do
				line = line:gsub('sc__', 's__')

				local stPos, stPosEnd = line:find('TriggerEvaluate(st__', 1, true)

				if stPos then
					local endBracketPos = line:findEndBracket(stPosEnd, '(', ')')

					local newLine = line:sub(1, stPos - 1)..'s__'..line:sub(stPosEnd + 1, endBracketPos - 1)..'()'

					line = newLine
				end
			end
		end
	end

				if (line:find('st___prototype', 1, true) or line:find('sa___prototype', 1, true)) then
				elseif line:find('call ExecuteFunc') then
					regFunc()
				end

	for _, glob in pairs(jass.globals) do
		local name = glob.name

		if ((name:find('st__', 1, true) == 1) or (name:find('si__', 1, true) == 1)) then
			glob:remove()
		end
	end
end

local function regFunc(func)
	assert(func, 'no func')

	for _, line in pairs(func.lines) do
		if (line == [[autoExec]]) then
			local name = curFunc.name

			curFunc:rename(name..'_autoExec_final')

			local evalFunc = createFunc(name)
			local evalTargetFunc = createFunc(name..'_autoExec_evalTarget')

			evalFunc:addReq(evalTargetFunc.name)
			evalTargetFunc:addReq(curFunc.name)

			evalFunc.params = curFunc.params
			evalFunc.returnType = curFunc.returnType

			local typeC = {}
			local paramsT = {}

			for i = 1, #curFunc.params, 1 do
				local param = curFunc.params[i]

				local type = curFunc.params[i].type

				if typeC[type] then
					typeC[type] = typeC[type] + 1
				else
					typeC[type] = 0
				end

				local varName = 'autoExec_arg_'..type..typeC[type]

				local var = getGlobalByName(varName)

				if (var == nil) then
					var = createGlobal(varName, type)

					evalFunc:addReq(varName)
					evalTargetFunc:addReq(varName)
				end

				evalFunc:addLine([[set ]]..var.name..[[ = ]]..param.name)

				paramsT[#paramsT + 1] = varName
			end

			autoExecs[#autoExecs + 1] = evalTargetFunc

			local trigName = AUTO_EXEC_TRIG_PREFIX..evalTargetFunc.name

			createGlobal(trigName, [[trigger]])
			evalFunc:addReq(trigName)

			evalFunc:addLine([[call IncStack(GetHandleId(Condition(function ]]..evalTargetFunc.name..[[)))]])

			evalFunc:addLine([[call TriggerEvaluate(]]..trigName..[[)]])

			evalFunc:addLine([[call DecStack()]])

			if curFunc.returnType then
				local varName = 'autoExec_result_'..curFunc.returnType

				local var = getGlobalByName(varName)

				if (var == nil) then
					var = createGlobal(varName, curFunc.returnType)

					evalFunc:addReq(varName)
					evalTargetFunc:addReq(varName)
				end

				evalTargetFunc:addLine([[set ]]..var.name..[[ = ]]..curFunc.name..[[(]]..table.concat(paramsT, ', ')..[[)]])

				evalFunc:addLine([[return ]]..var.name)
			else
				evalTargetFunc:addLine([[call ]]..curFunc.name..[[(]]..table.concat(paramsT, ', ')..[[)]])
			end
		else
			local name = line:match([[ExecuteFunc%([%s%"]*(]]..identifierPat..[[)[%s%"]*%)]])

			if (name ~= nil) then
				func:addReq(name)
			end

			local name, pos, posEnd = line:readIdentifier()

			while (name ~= nil) do
				func:addReq(name)

				name, pos, posEnd = line:readIdentifier(posEnd + 1)
			end
		end
	end
end

for _, func in pairs(jass.funcs) do
	local name = func.name

	if name:match('_autoRun$') then
		autoRuns[#autoRuns + 1] = func
	elseif name:match('_debugInit$') then
		debugInit = func
	end

	regFunc(func)
end

--for i = 1, #inputLines, 1 do
--	local line = inputLines[i]
--
--	line = line:gsub([[//autoExec]], [[autoExec]])
--end

for _, func in pairs(jass.funcs) do
	for i2 = #func.reqs, 1, -1 do
		local req = func.reqs[i2]

		if (((jass:getFuncByName(req) == nil) or (jass:getFuncByName(req) == func)) and (jass:getGlobalByName(req) == nil)) then
			func:removeReq(req)
		end
	end
end

for _, glob in pairs(jass.globals) do
	if glob.val then
		local line = glob.val

		local name, pos, posEnd = line:readIdentifier()

		while (name ~= nil) do
			if jass:getGlobalByName(name) then
				glob:addReq(name)
			end

			name, pos, posEnd = line:readIdentifier(posEnd + 1)
		end
	end
end

local runProtFunc = jass:getFuncByName('gg__runProt')

local evalsInitFunc = createFunc('evalsInitFunc')
local autoRunsFunc = createFunc('autoRunsFunc')
local autoExecsInitFunc = createFunc('autoExecsInitFunc')

local sortedFuncs = {}

local function sortInFunc(func)
	sortedFuncs[#sortedFuncs + 1] = func
end

local sortedGlobals = {}

local function sortInGlobal(global)
	if (global == nil) then
		return
	end

	sortedGlobals[#sortedGlobals + 1] = global
end

local EVAL_FUNC_SOURCE_PREFIX = 'eval_'
local EVAL_FUNC_TARGET_PREFIX = 'evalTarget_'
local EVAL_TRIG_PREFIX = 'evalTrig_'
local EVAL_VAR_ARG_PREFIX = 'evalArg_'
local EVAL_VAR_RESULT_PREFIX = 'evalResult_'

local function createEvalFunc(parentFunc)
	assert(parentFunc, 'no parentFunc')

	local parentFuncName = parentFunc.name

	local sourceFuncName = EVAL_FUNC_SOURCE_PREFIX..parentFuncName

	local sourceFunc = jass:getFuncByName(sourceFuncName)

	if (sourceFunc ~= nil) then
		return sourceFunc
	end

	local sourceFunc = createFunc(sourceFuncName)

	--parentFunc:addReq(evalFuncName)
	--sortIn

	local argTypeAmount = {}
	local paramsLineTable = {}

	for i = 1, #parentFunc.params, 1 do
		local param = parentFunc.params[i]

		local name = param.name
		local type = param.type

		if argTypeAmount[type] then
			argTypeAmount[type] = argTypeAmount[type] + 1
		else
			argTypeAmount[type] = 1
		end

		local globalVarName = EVAL_VAR_ARG_PREFIX..type..argTypeAmount[type]

		sortInGlobal(createGlobal(globalVarName, type))

		sourceFunc:addLine('set '..globalVarName..' = '..name)

		--sourceFunc:addReq(globalVarName)

		paramsLineTable[#paramsLineTable + 1] = globalVarName

		sourceFunc:addParam(name, type)
	end
	sourceFunc:setReturnType(parentFunc.returnType)

	sourceFunc:addLine('call TriggerEvaluate('..EVAL_TRIG_PREFIX..parentFuncName..')')

	local globalReturnVar
	local returnType = parentFunc.returnType

	if returnType then
		globalReturnVar = EVAL_VAR_RESULT_PREFIX..returnType

		sortInGlobal(createGlobal(globalReturnVar, returnType))

		--sourceFunc:addReq(globalReturnVar)
	end

	if (globalReturnVar ~= nil) then
		sourceFunc:addLine('return '..globalReturnVar)
	end

	sortInFunc(sourceFunc)

	local evalTargetFuncName = EVAL_FUNC_TARGET_PREFIX..parentFunc.name

	local targetFunc = createFunc(evalTargetFuncName)

	local paramsLine = table.concat(paramsLineTable, ', ') or ''

	if (globalReturnVar ~= nil) then
		targetFunc:addLine('set '..globalReturnVar..' = '..parentFunc.name..'('..paramsLine..')')
	else
		targetFunc:addLine('call '..parentFunc.name..'('..paramsLine..')')
	end

	sortInGlobal(createGlobal(EVAL_TRIG_PREFIX..parentFunc.name, 'trigger'))

	evalsInitFunc:addLine('set '..EVAL_TRIG_PREFIX..parentFunc.name..' = CreateTrigger()')
	evalsInitFunc:addLine('call TriggerAddCondition('..EVAL_TRIG_PREFIX..parentFunc.name..', Condition(function '..evalTargetFuncName..'))')

	evalsInitFunc:addReq(evalTargetFuncName)

	return sourceFunc
end

local funcPtrMap = {}

local function regFuncPtr(name)
	if (funcPtrMap[name] ~= nil) then
		return
	end

	local func = jass:getFuncByName(name)

	funcPtrMap[name] = func

	if doTracebacks then
		func:addReq('gg__func_startString')
		func:addReq('gg__func_endString')
	end
end

local function inspectLine(line)
end

for _, global in pairs(jass.globals) do
	local val = global.val

	if (val ~= nil) then
		local line = val

		line = line:outstrikeStringLiterals()

		local name, pos, posEnd = line:readIdentifier()
		local lastName = nil

		while pos do
			if (replaceNativeMap[name] ~= nil) then
				val = global.val:sub(1, pos - 1)..replaceNativeMap[name].name..global.val:sub(posEnd + 1)

				global:removeReq(name)
				global:addReq(replaceNativeMap[name].name)

				line = val
				line = line:outstrikeStringLiterals()
				posEnd = posEnd + replaceNativeMap[name].name:len() - name:len()

				name = replaceNativeMap[name].name
			end

			if (lastName == 'function') then
				regFuncPtr(name)
			end

			lastName = name
		
			name, pos, posEnd = line:readIdentifier(posEnd + 1)
		end
	end
end

for _, func in pairs(jass.funcs) do
	if not func.name:match('^gg__') then
		for lineIndex, line in pairs(func.lines) do
			line = line:outstrikeStringLiterals()

			local name, pos, posEnd = line:readIdentifier()
			local lastName = nil

			while pos do
				if (replaceNativeMap[name] ~= nil) then
					func.lines[lineIndex] = func.lines[lineIndex]:sub(1, pos - 1)..replaceNativeMap[name].name..func.lines[lineIndex]:sub(posEnd + 1)

					func:removeReq(name)
					func:addReq(replaceNativeMap[name].name)

					line = func.lines[lineIndex]
					line = line:outstrikeStringLiterals()
					posEnd = posEnd + replaceNativeMap[name].name:len() - name:len()

					name = replaceNativeMap[name].name
				end

				if (lastName == 'function') then
					regFuncPtr(name)
				end

				lastName = name
			
				name, pos, posEnd = line:readIdentifier(posEnd + 1)
			end
		end
	end
end

--for ExecuteFunc
for _, func in pairs(jass.funcs) do
	if ((#func.params == 0) and (func.returnType == nil)) then
		regFuncPtr(func.name)
	end
end

local function replaceCalls(func, call)
	assert(func, 'no func')
	assert(call, 'no call to replace')
--print('replace calls of '..func.name)
	for i = 1, #func.lines, 1 do
		local line = func.lines[i]

		line = line:outstrikeStringLiterals()

		local name, pos, posEnd = line:readIdentifier()

		while (name ~= nil) do
			if (name == call) then
				local functionWord, pos2, pos2End = line:reverseReadIdentifier(pos - 1)

				if (functionWord == 'function') then
					local codeVar = 'code__'..call

					createGlobal(codeVar, 'code')

					if (call ~= 'main') then
						evalsInitFunc:addLine('set '..codeVar..' = function '..call)
					end

					func.lines[i] = func.lines[i]:sub(1, pos2 - 1)..codeVar..func.lines[i]:sub(posEnd + 1)

					posEnd = pos + codeVar:len() - 1
				else
					local eval = createEvalFunc(jass:getFuncByName(call)).name

					func.lines[i] = func.lines[i]:sub(1, pos - 1)..eval..func.lines[i]:sub(posEnd + 1)

					posEnd = pos + eval:len() - 1
				end

				line = func.lines[i]
				line = line:outstrikeStringLiterals()
			end

			name, pos, posEnd = line:readIdentifier(posEnd + 1)
		end

		--func.lines[i] = line
	end
end

local outCycles = {}
local outCyclesC = 0

local function outCyclesWrite(s)
	outCyclesC = outCyclesC + 1
	outCycles[outCyclesC] = s
end

local outFuncsC = 0
local outFuncs = {}

local function outFuncsWrite(s)
	outFuncsC = outFuncsC + 1
	outFuncs[outFuncsC] = s
end

local function copyTable(t)
	local result = {}

	for k, v in pairs(t) do
		result[k] = v
	end

	return result
end

local isGlobalReg = {}

local function regGlobal(global, localTable)
	assert(global, 'no glob')

	if isGlobalReg[global] then
		return
	end

	if (localTable == nil) then
		localTable = {}
	end

	isGlobalReg[global] = true
	localTable[global.name] = global

	for i = 1, #global.reqs, 1 do
		local req = global.reqs[i]

		regGlobal(jass:getGlobalByName(req), copyTable(localTable))
	end

	sortInGlobal(global)
end

local isFuncReg = {}

local function regFunc(func, localTable, level)
	assert(func, 'no func')

	--print('reg '..func.name)

	if isFuncReg[func] then
		return
	end

	if (level == nil) then
		level = 0
	end
	if (localTable == nil) then
		localTable = {}
	end

	local indent = string.rep('\t', level)

	local reqS = {0, 0, 0, 0, 0, 0, 0, 0, 0}
	local reqSC = 0
	isFuncReg[func] = true
	localTable[func.name] = func
--print('regB '..func.name, #func.reqs)
	for i = 1, #func.reqs, 1 do
		local req = func.reqs[i]
--print('\treq: '..req)
		if (jass:getFuncByName(req) ~= nil) then
			if (localTable[req] ~= nil) then
				outFuncsWrite(indent..'cycle between '..func.name..' and '..req)
				outCyclesWrite(indent..func.name..' and '..req)
				outCyclesWrite(indent..'eval from '..func.name..' to '..req)
	
				replaceCalls(func, req)
			--elseif (req.isEvalFunc) then
				--replaceCalls(func, req)
			else
				regFunc(jass:getFuncByName(req), copyTable(localTable), level + 1)
			end
		elseif (jass:getGlobalByName(req) ~= nil) then
			regGlobal(jass:getGlobalByName(req), copyTable(localTable))
		end

		reqSC = reqSC + 1
		reqS[reqSC] = req
	end

	sortInFunc(func)
	outFuncsWrite(indent..func.name)

	if (reqSC > 0) then
		outFuncsWrite(indent..'\tRequires: '..table.concat(reqS, ','))
	end
end

local main = jass:getFuncByName('main')

assert(main, 'main function missing')

local mainSub = main

mainSub:rename('mainSub')

local main = createFunc('main')

main.notListedInFuncsTableInit = true
evalsInitFunc.notListedInFuncsTableInit = true
autoRunsFunc.notListedInFuncsTableInit = true
autoExecsInitFunc.notListedInFuncsTableInit = true

autoRunsFunc:addReq(runProtFunc.name)

--jass:getFuncByName('gg__debugMsg'):setAsEvalFunc()

for _, func in pairs(autoRuns) do
	runProtFunc:addReq(func.name)
	func:setAsEvalFunc()

	autoRunsFunc:addReq(func.name)

	autoRunsFunc:addLine([[call ]]..runProtFunc.name..[[(function ]]..func.name..[[, ]]..func.name:sub(1, 1):quote()..[[+]]..func.name:sub(2):quote()..[[)]])
end

for _, func in pairs(autoExecs) do
	autoExecsInitFunc:addReq(func.name)

	autoExecsInitFunc:addLine([[
		set ]]..AUTO_EXEC_TRIG_PREFIX..func.name..[[ = CreateTrigger()
		call TriggerAddCondition(]]..AUTO_EXEC_TRIG_PREFIX..func.name..[[, Condition(function ]]..func.name..[[))
	]])
end

local debugInit = jass:getFuncByName('gg__init_debugInit')

local t = {
	debugInit,
	--funcsTableInitFunc,
	evalsInitFunc,
	autoRunsFunc,
	autoExecsInitFunc,

	mainSub
}

local t2 = {}

for i = 1, #t, 1 do
	local func = t[i]

	t2[#t2 + 1] = [[call ]]..runProtFunc.name..[[(function ]]..func.name..[[, ]]..func.name:quote()..[[)]]

	main:addReq(func.name)

	func:setAsEvalFunc()
end

main:addLine(table.concat(t2, '\n'), 1)

main:addReq('gg__info')
main:addLine([[call gg__info("init ok")]])

main:addReq(runProtFunc.name)

local config = jass:getFuncByName('config')

assert(config, 'config function missing')

for _, func in pairs(funcPtrMap) do
	func:addReq('gg__getCodeId')
	func:addReq('gg__ret_bool')
end

main:removeReq(evalsInitFunc.name)
main:addReq(evalsInitFunc.name)

regFunc(config)
regFunc(main)

if (logId ~= nil) then
	jass:getGlobalByName('gg__LOG_ID').val = string.format('%q', logId)
end

--local funcsTableGlobal = createGlobal('FUNCS_TABLE', 'hashtable')
local funcsTableGlobal = jass:getGlobalByName('FUNCS_TABLE')
local funcsTableInitFunc = createFunc('funcsTableInitFunc')

funcsTableInitFunc:setAsEvalFunc()

funcsTableInitFunc:addReq(funcsTableGlobal.name)
funcsTableInitFunc:addLine([[set ]]..funcsTableGlobal.name..[[ = InitHashtable()]])

for i = 1, #sortedFuncs, 1 do
	local func = sortedFuncs[i]

	local name = func.name

	if (not func.notListedInFuncsTableInit and not name:match('^gg__') and (#func.params == 0) and ((func.returnType == nil) or (func.returnType == 'boolean'))) then
		func:setAsEvalFunc()

		funcsTableInitFunc:addReq(name)
		funcsTableInitFunc:addLine([[call SaveStr(]]..funcsTableGlobal.name..[[, GetHandleId(Condition(function ]]..name..[[)), 0, ]]..name:sub(1, 1):quote()..[[+]]..name:sub(2):quote()..[[)]])

		if doTracebacks then
			if (funcPtrMap[name] ~= nil) then
				func.returnType = 'boolean'

				--func:addLine('local boolean gg__funcStartDummyBool = gg__func_start(gg__getCodeId(function '..func.name..'))', 1)
				func:addLine(string.format('local boolean gg__funcStartDummyBool = gg__func_startString(%q)', func.name), 1)
				func:addLine('return false')

				for index, line in pairs(func.lines) do
					if line:match('^return%s') or line:match('^return$') then
						local expr = line:match('^return%s(.*)')

						if (expr ~= nil) then
							--func.lines[index] = 'set gg__ret_bool = '..expr..'\n'..'call gg__func_end()'..'\n'..'return false'
							func.lines[index] = 'set gg__ret_bool = '..expr..'\n'..'call gg__func_endString()'..'\n'..'return false'
						else
							--func.lines[index] = 'call gg__func_end()'..'\n'..'return false'
							func.lines[index] = 'call gg__func_endString()'..'\n'..'return false'
						end
					end
				end
			end
		end
	end
end

table.insert(sortedGlobals, funcsTableGlobal)
table.insert(sortedFuncs, #sortedFuncs - 1, funcsTableInitFunc)

main:addLine([[call ]]..runProtFunc.name..[[(function ]]..funcsTableInitFunc.name..[[, ]]..(funcsTableInitFunc.name..'test'):quote()..[[)]], 1)

--output
jass.globals = sortedGlobals
jass.funcs = sortedFuncs

for _, func in pairs(jass.funcs) do
	if func.isEvalFunc then
		func.params = {}

	end
end

for _, func in pairs(jass.funcs) do
	if func.isEvalFunc then
		func.params = {}
		func.returnType = 'boolean'

		for index, line in pairs(func.lines) do
			if (line == 'return') then
				func.lines[index] = 'return true'
			end
		end

		func:addLine('return true')
	end
end

print(#jass.globals..' globals, before '..prevGlobalsC)
print(#jass.funcs..' functions, before '..prevFuncsC)

outError:close()

--writeTable('outFuncs.txt', outFuncs)
--writeTable('outCycles.txt', outCycles)
--writeTable('output.j', output)

local outputDir = io.local_dir()..[[Output\]]

io.removeDir(outputDir)

io.createDir(outputDir)

jass:writeToFile(outputDir..'war3map.j')
wc3jass.create():writeToFile(outputDir..'blizzard.j')

wc3jass.syntaxCheck({commonJPath, outputDir..'war3map.j'}, true)

portLib.mpqImport(mapPath, outputDir..'war3map.j', 'war3map.j')
portLib.mpqImport(mapPath, outputDir..[[blizzard.j]], [[Scripts\blizzard.j]])