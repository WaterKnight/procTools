globals
	constant integer ARRAY_MAX = 8191
	constant integer ARRAY_MIN = 0
	constant integer ARRAY_SIZE = 8192
	constant boolean DEBUG = true

	constant integer ARRAY_EMPTY = ARRAY_MIN - 1

    boolean gg__LOG_ON = true
    integer gg__LINES_COUNT = 0
    integer gg__LINES_MAX_PER_FILE = 500
    integer gg__CUR_PRELOADED_LINES_COUNT = -1
    string array gg__CUR_PRELOADED_LINES
    timer gg__GAMETIME_TIMER = CreateTimer()
    integer gg__SESSION_ID = -1

	constant string gg__LOG_ID = "Temp"

	constant string gg__LOG_DIR = "Logs\\" + gg__LOG_ID
	constant string gg__LOG_INDEX_PATH = "Logs\\" + gg__LOG_ID + "\\index.ini"
	constant string gg__LOG_SIGNAL_PATH = "Logs\\logTracker_signal.ini"
	constant string gg__LOG_SESSION_DIR = "Logs\\" + gg__LOG_ID + "\\Session"

	string array gg__LINES_BUFFER
    integer gg__LINES_BUFFER_COUNT = ARRAY_EMPTY
    integer gg__LINES_BUFFER_NESTING = 0

	boolean gg__DEBUG_INITED = false

	constant string CHAR_BREAK = "\n"
	constant string CHAR_TAB = "\t"

	hashtable FUNCS_TABLE

	boolean gg__ret_bool = false
	integer gg__func_start_count = ARRAY_EMPTY
	integer array gg__func_start_stack_count
	integer array gg__func_start_stack
	string array gg__func_start_stackString

	hashtable TRIGGER_TABLE = InitHashtable()
	hashtable STACK_TABLE = InitHashtable()
	integer gg__currentStack = 0
	integer array gg__stackRecycle
	integer gg__stackInstanceCount = 0
	integer gg__stackInstanceMax = 0
	boolean array gg__hasFirstWait
	boolean gg__newThread = false
	integer gg__currentStackLevel = ARRAY_EMPTY
	timer gg__stackTimer = CreateTimer()
	integer gg__stackTimerLevel = ARRAY_EMPTY
	integer gg__threadDepth = 0
	constant integer gg__threadDepthLimit = 100

	integer gg__stackChecksCount = ARRAY_EMPTY
	integer array gg__stackChecks
	integer gg__enumTriggersCount = ARRAY_EMPTY
	integer gg__enumTriggersMax = ARRAY_EMPTY
	trigger array gg__enumTriggers

	trigger gg__tempTrigger
	boolean gg__currentThreadCanWait = true
endglobals

function gg__getCodeId takes code self returns integer
	return GetHandleId(Condition(self))
endfunction

function gg__getCodeName takes code self returns string
	return LoadStr(FUNCS_TABLE, gg__getCodeId(self), 0)
endfunction

function gg__getCodeNameById takes integer id returns string
	return LoadStr(FUNCS_TABLE, id, 0)
endfunction

function gg__getTriggerName takes trigger t returns string
	return ""
endfunction

function gg__msg takes string s returns nothing
    call DisplayTimedTextToPlayer(GetLocalPlayer(), 0., 0., 10., s)
endfunction

function gg__GetDebugTime takes nothing returns real
    return TimerGetElapsed(gg__GAMETIME_TIMER)
endfunction

function gg__getStackCount takes nothing returns integer
	if (gg__currentStack == 0) then
		return gg__func_start_count
	endif

	return gg__func_start_stack_count[gg__currentStack]
endfunction

function gg__getStack takes integer level returns integer
	if (gg__currentStack == 0) then
		return gg__func_start_stack[level]
	endif

	return LoadInteger(STACK_TABLE, gg__currentStack, level)
endfunction

function gg__getStackString takes integer level returns string
	if (gg__currentStack == 0) then
		return gg__func_start_stackString[level]
	endif

	return LoadStr(STACK_TABLE, gg__currentStack, level)
endfunction

function gg__peekStack takes nothing returns integer
	return gg__getStack(gg__getStackCount())
endfunction

function gg__peekStackString takes nothing returns string
	return gg__getStackString(gg__getStackCount())
endfunction

function gg__addToBuffer takes string s returns nothing
    set gg__LINES_BUFFER_COUNT = gg__LINES_BUFFER_COUNT + 1
    set gg__LINES_BUFFER[gg__LINES_BUFFER_COUNT] = s
endfunction

function gg__outputLine takes string s returns nothing
	local string s2

	local integer length
	local integer c
	local integer i

	if not gg__DEBUG_INITED then
		call gg__addToBuffer(s)

		return
	endif

    set gg__LINES_COUNT = gg__LINES_COUNT + 1

    if ((gg__LINES_COUNT / gg__LINES_MAX_PER_FILE) != ((gg__LINES_COUNT - 1) / gg__LINES_MAX_PER_FILE)) then
        call PreloadGenClear()
        set gg__CUR_PRELOADED_LINES_COUNT = 0
    endif

    set s = "#" + I2S(gg__LINES_COUNT) + " (" + R2S(gg__GetDebugTime()) + "): " + s

    set s2 = "\")" + s

    if (StringLength(s2) > 259) then
        set length = StringLength(s)

        set c = length / 257 + 1
        set i = 1

        call Preload("\")" + ":cmd mergeLines=" + I2S(c))

        loop
            exitwhen (i > c)

            if (i == c) then
                set s2 = "\")" + SubString(s, (i - 1) * 257, length)

                set gg__CUR_PRELOADED_LINES_COUNT = gg__CUR_PRELOADED_LINES_COUNT + 1
                set gg__CUR_PRELOADED_LINES[gg__CUR_PRELOADED_LINES_COUNT] = s2
                //call Preload(s2)
            else
		set s2 = "\")" + SubString(s, (i - 1) * 257, i * 257 + 1)

                set gg__CUR_PRELOADED_LINES_COUNT = gg__CUR_PRELOADED_LINES_COUNT + 1
                set gg__CUR_PRELOADED_LINES[gg__CUR_PRELOADED_LINES_COUNT] = s2
                //call Preload(s2)
            endif

            set i = i + 1
        endloop
    else
        set gg__CUR_PRELOADED_LINES_COUNT = gg__CUR_PRELOADED_LINES_COUNT + 1
        set gg__CUR_PRELOADED_LINES[gg__CUR_PRELOADED_LINES_COUNT] = s2
        //call Preload(s2)
    endif

    call PreloadGenClear()

    set i = 0

    loop
        exitwhen (i > gg__CUR_PRELOADED_LINES_COUNT)

        call Preload(gg__CUR_PRELOADED_LINES[i])

        set i = i + 1
    endloop

    call PreloadGenEnd(gg__LOG_SESSION_DIR + I2S(gg__SESSION_ID) + "\\log_" + I2S(gg__LINES_COUNT / gg__LINES_MAX_PER_FILE) + ".txt")

	//call BJDebugMsg(s)
endfunction

function gg__info takes string s returns nothing
    local boolean isDebugPlayer = true//(GetPlayerName(GetLocalPlayer()) == "WaterKnight") or (GetPlayerName(GetLocalPlayer()) == "WaterServant") or (GetLocalPlayer() == Player(0))

    if (s == null) then
        set s = "null"
    endif

    if not isDebugPlayer then
        return
    endif

    call gg__outputLine("[INFO] " + s)
endfunction

function gg__debugMsg takes string s returns nothing
    local boolean isDebugPlayer = true//(GetPlayerName(GetLocalPlayer()) == "WaterKnight") or (GetPlayerName(GetLocalPlayer()) == "WaterServant") or (GetLocalPlayer() == Player(0))

    if (s == null) then
        set s = "null"
    endif

    //call SetPlayerState(GetLocalPlayer(), PLAYER_STATE_RESOURCE_FOOD_USED, gg__LINES_COUNT)

    if isDebugPlayer then
        //call gg__msg(s)
    endif

    //if Nullboard.LOG_INITED then
        //call Nullboard.WriteLogLine(s)
    //endif

    if not isDebugPlayer then
        return
    endif

    call gg__outputLine("[DEBUG] " + s)
endfunction

function gg__flushBuffer takes boolean merge returns nothing
    local integer i = gg__LINES_BUFFER_COUNT - 1
    local string s

	if not gg__DEBUG_INITED then
		return
	endif

    set gg__LINES_BUFFER_NESTING = gg__LINES_BUFFER_NESTING - 1

    if (gg__LINES_BUFFER_NESTING > 0) then
        return
    endif

    if (gg__LINES_BUFFER_COUNT < ARRAY_MIN) then
        return
    endif

	if merge then
		set s = gg__LINES_BUFFER[gg__LINES_BUFFER_COUNT]

		set gg__LINES_BUFFER_COUNT = ARRAY_EMPTY

		loop
			exitwhen (i < ARRAY_MIN)

			set s = gg__LINES_BUFFER[i] + CHAR_BREAK + CHAR_TAB + s

			set i = i - 1
		endloop

		call gg__debugMsg(s)
	else
		set i = ARRAY_MIN

		loop
			exitwhen (i > gg__LINES_BUFFER_COUNT)

			call gg__debugMsg(gg__LINES_BUFFER[i])

			set i = i + 1
		endloop

		set gg__LINES_BUFFER_COUNT = ARRAY_EMPTY
	endif
endfunction

function gg__startBuffer takes nothing returns nothing
    //call gg__flushBuffer(true)
    set gg__LINES_BUFFER_NESTING = gg__LINES_BUFFER_NESTING + 1
endfunction

function gg__debugFile takes string path, string s returns nothing
    local boolean isDebugPlayer = true//(GetPlayerName(GetLocalPlayer()) == "WaterKnight") or (GetPlayerName(GetLocalPlayer()) == "WaterServant") or (GetLocalPlayer() == Player(0))

    if (s == null) then
        set s = "null"
    endif

    if isDebugPlayer then
        //call gg__msg(s)
    endif

    //if Nullboard.LOG_INITED then
        //call Nullboard.WriteLogLine(s)
    //endif

    if not isDebugPlayer then
        return
    endif

//call PreloadGenClear()

//call PreloadGenStart()

    set gg__LINES_COUNT = gg__LINES_COUNT + 1

    call Preload("#" + I2S(gg__LINES_COUNT) + " (" + R2S(TimerGetElapsed(gg__GAMETIME_TIMER)) + "): " + s)

    call PreloadGenEnd(path)
endfunction

function gg__preloadBatLine takes string s returns nothing
    call Preload("\")\n" + s + "\nREM (\"")
endfunction

function gg__getExpiredTimerSafe takes nothing returns timer
	if (GetTriggerEventId() != null) then
		return null
	endif

	return GetExpiredTimer()
endfunction

function gg__mergeStackString takes nothing returns string
    local string result = ""

    local integer i = gg__getStackCount()

    if (gg__getExpiredTimerSafe() != null) then
        //set result = "-> " + Timer.GetFromSelf(gg__getExpiredTimerSafe()).GetName()
    endif

    loop
        exitwhen (i < ARRAY_MIN)

        if (result == "") then
            //set result = "-> " + gg__getCodeNameById(gg__getStack(i))
			set result = "-> " + gg__getStackString(i)
        else
            //set result = result + CHAR_BREAK + "-> " + gg__getCodeNameById(gg__getStack(i))
			set result = result + CHAR_BREAK + "-> " + gg__getStackString(i)
        endif

        set i = i - 1
    endloop

    return "stack trace:" + CHAR_BREAK + result
endfunction

function gg__addStackToBuffer takes nothing returns nothing
    local integer i = gg__getStackCount()

    call gg__addToBuffer("stack trace:")

    //if (gg__getExpiredTimerSafe() != null) then
        //call gg__addToBuffer("-> " + Timer.GetFromSelf(gg__getExpiredTimerSafe()).GetName())
    //endif

    loop
        exitwhen (i < ARRAY_MIN)

        //call gg__addToBuffer(I2S(i)+ "-> " + gg__getCodeNameById(gg__getStack(i)))
		call gg__addToBuffer(I2S(i)+ "-> " + gg__getStackString(i))

        set i = i - 1
    endloop
endfunction

function gg__debugEx takes string source, string line, string s returns nothing
    call gg__startBuffer()

    call gg__addToBuffer("---/")

    if (s != null) then
        call gg__addToBuffer(s)
    endif

    call gg__addToBuffer("")

    if (source != null) then
        call gg__addToBuffer("in ->" + source)
    endif
    if (line != null) then
        call gg__addToBuffer("line ->" + line)
    endif

    call gg__addToBuffer("")

    call gg__addStackToBuffer()

    call gg__addToBuffer("/---")

    call gg__flushBuffer(true)
endfunction

function gg__printStack takes nothing returns nothing
    call gg__debugEx(null, null, null)
endfunction

function gg__init_debugInit takes nothing returns nothing
    local string prevToDScale = GetPlayerName(GetLocalPlayer())

    call TimerStart(gg__GAMETIME_TIMER, 99999, true, null)

    call SetPlayerName(GetLocalPlayer(), I2S(gg__SESSION_ID))

    call PreloadGenClear()
    call Preloader(gg__LOG_INDEX_PATH)

    set gg__SESSION_ID = S2I(GetPlayerName(GetLocalPlayer())) + 1

    call PreloadGenClear()
    call PreloadGenStart()

    call Preload("\")\n" + "call SetPlayerName(GetLocalPlayer(), \"" + I2S(gg__SESSION_ID) + "\")" + "\ncall Preload(\"")

    call SetPlayerName(GetLocalPlayer(), prevToDScale)

    call PreloadGenEnd(gg__LOG_INDEX_PATH)

	call PreloadGenClear()

	call Preload("\")" + gg__LOG_DIR)

    call PreloadGenEnd(gg__LOG_SIGNAL_PATH)

    call PreloadGenClear()

    call gg__preloadBatLine("DEL \"logs.txt\"")

    call gg__preloadBatLine("DEL takeFile.bat")

    call gg__preloadBatLine("echo   set file=%%~1>>takeFile.bat")
    call gg__preloadBatLine("echo   echo %%file%%>>takeFile.bat")
    call gg__preloadBatLine("echo   for /f \"tokens=*\" %%%%A in (%%file%%) do (call takeLine.bat \"%%%%A\")>>takeFile.bat")
    call gg__preloadBatLine("REM echo   DEL %%file%%>>takeFile.bat")

    call gg__preloadBatLine("DEL takeLine.bat")

    call gg__preloadBatLine("echo   set txt=%%1>>takeLine.bat")
    call gg__preloadBatLine("echo   set txt=%%txt:call Preload( ^\"^\")=%%>>takeLine.bat")

    call gg__preloadBatLine("echo   IF %%txt%%==%%1 goto :eof>>takeLine.bat")

    call gg__preloadBatLine("echo   set txt=%%txt:^\" )=%%>>takeLine.bat")

    call gg__preloadBatLine("echo   set txt=%%txt:^|=^^^^^^^|%%>>takeLine.bat")
    call gg__preloadBatLine("echo   set txt=%%txt:^>=^^^^^^^>%%>>takeLine.bat")
    call gg__preloadBatLine("echo   set txt=%%txt:^\"='%%>>takeLine.bat")

    call gg__preloadBatLine("echo   IF \"%%txt%%\"==\"\" goto :eof>>takeLine.bat")

    call gg__preloadBatLine("echo   echo %%txt%%^>^>logs.txt>>takeLine.bat")

    call gg__preloadBatLine("pause")

    call gg__preloadBatLine("for /f %%f in ('dir /b /od \"log_*.txt\"') do (call takeFile.bat \"%%f\")")

    call gg__preloadBatLine("DEL takeFile.bat")
    call gg__preloadBatLine("DEL takeLine.bat")

    call PreloadGenEnd(gg__LOG_SESSION_DIR + I2S(gg__SESSION_ID) + "\\mergeLogs.bat")

    call PreloadGenClear()

    call gg__info("private session "+I2S(gg__SESSION_ID))

	set gg__DEBUG_INITED = true
	call gg__flushBuffer(false)
endfunction

function gg__DecStack takes integer stackLevel returns nothing
//call gg__info("decA cur "+I2S(gg__getStackCount())+" reset "+I2S(stackLevel))
	if (gg__getStackCount() > stackLevel) then
		call gg__debugEx(null, null, "thread break")
//call gg__info("revert level from "+I2S(gg__getStackCount())+" to "+I2S(stackLevel)+" in "+I2S(gg__currentStack))
		if (gg__currentStack == 0) then
			set gg__func_start_count = stackLevel
		else
			set gg__func_start_stack_count[gg__currentStack] = stackLevel
		endif
	endif
//call gg__info("decB")
endfunction

function gg__IncStack takes nothing returns integer
	return gg__getStackCount()
endfunction

function gg__DecStackChecks takes nothing returns nothing
	call gg__DecStack(gg__stackChecks[gg__stackChecksCount])

	set gg__stackChecksCount = gg__stackChecksCount - 1
endfunction

function gg__IncStackChecks takes nothing returns nothing
	set gg__stackChecksCount = gg__stackChecksCount + 1
	set gg__stackChecks[gg__stackChecksCount] = gg__getStackCount()
endfunction

function gg__deleteStack takes integer stack returns nothing
//call gg__info("delete stack "+I2S(stack))
	call FlushChildHashtable(STACK_TABLE, stack)

	set gg__stackRecycle[stack] = gg__stackRecycle[0]
	set gg__stackRecycle[0] = stack

	set gg__hasFirstWait[stack] = false
	set gg__stackInstanceCount = gg__stackInstanceCount - 1
endfunction

function gg__copyStack takes nothing returns integer
	local integer source = gg__currentStack
	local integer i

	local integer target

	if (gg__stackRecycle[0] == 0) then
		set gg__stackInstanceMax = gg__stackInstanceMax + 1
		set target = gg__stackInstanceMax
	else
		set target = gg__stackRecycle[0]
		set gg__stackRecycle[0] = gg__stackRecycle[gg__stackRecycle[0]]
	endif

//call gg__info("new stack "+I2S(target))
	set gg__hasFirstWait[target] = false
	set gg__stackInstanceCount = gg__stackInstanceCount + 1

	if (gg__currentStack == 0) then
		set i = gg__func_start_count

		set gg__func_start_stack_count[target] = i

		loop
			exitwhen (i < ARRAY_MIN)

			//call SaveInteger(STACK_TABLE, target, i, gg__func_start_stack[i])
			call SaveStr(STACK_TABLE, target, i, gg__func_start_stackString[i])

			set i = i - 1
		endloop
	else
		set i = gg__func_start_stack_count[source]

		set gg__func_start_stack_count[target] = i

		loop
			exitwhen (i < 0)

			//call SaveInteger(STACK_TABLE, target, i, LoadInteger(STACK_TABLE, source, i))
			call SaveStr(STACK_TABLE, target, i, LoadStr(STACK_TABLE, source, i))

			set i = i - 1
		endloop
	endif

	return target
endfunction

function gg__stackTimer_timeout takes nothing returns nothing
//call gg__info("timeout "+I2S(gg__currentStackLevel))
	call gg__DecStack(gg__currentStackLevel)

	call gg__deleteStack(gg__currentStack)
//call gg__info("remaining stacks "+I2S(gg__stackInstanceCount))
endfunction

function gg__func_start takes integer codeId returns boolean
	if (gg__currentStack == 0) then
		set gg__func_start_count = gg__func_start_count + 1
		set gg__func_start_stack[gg__func_start_count] = codeId
	else
		set gg__func_start_stack_count[gg__currentStack] = gg__func_start_stack_count[gg__currentStack] + 1
		call SaveInteger(STACK_TABLE, gg__currentStack, gg__func_start_stack_count[gg__currentStack], codeId)
	endif
//call gg__info("push "+LoadStr(FUNCS_TABLE, codeId, 0)+" to stack "+I2S(gg__currentStack)+" now count "+I2S(gg__getStackCount()))

	return true
endfunction

function gg__func_startString takes string name returns boolean
	if (gg__currentStack == 0) then
		set gg__func_start_count = gg__func_start_count + 1
		set gg__func_start_stackString[gg__func_start_count] = name
	else
		set gg__func_start_stack_count[gg__currentStack] = gg__func_start_stack_count[gg__currentStack] + 1
		call SaveStr(STACK_TABLE, gg__currentStack, gg__func_start_stack_count[gg__currentStack], name)
	endif
//call gg__info("push "+name+" to stack "+I2S(gg__currentStack)+" now count "+I2S(gg__getStackCount()))

	return true
endfunction

function gg__func_end takes nothing returns nothing
local integer peek=gg__peekStack()
	if (gg__currentStack == 0) then
		set gg__func_start_count = gg__func_start_count - 1
	else
		set gg__func_start_stack_count[gg__currentStack] = gg__func_start_stack_count[gg__currentStack] - 1
	endif
//call gg__info("pop "+LoadStr(FUNCS_TABLE, peek, 0)+" from stack "+I2S(gg__currentStack)+" now count "+I2S(gg__getStackCount()))
endfunction

function gg__func_endString takes nothing returns nothing
local string peek=gg__peekStackString()
	if (gg__currentStack == 0) then
		set gg__func_start_count = gg__func_start_count - 1
	else
		set gg__func_start_stack_count[gg__currentStack] = gg__func_start_stack_count[gg__currentStack] - 1
	endif
//call gg__info("pop "+peek+" from stack "+I2S(gg__currentStack)+" now count "+I2S(gg__getStackCount()))
endfunction

function gg__runProt takes code c, string name returns boolean
	local trigger t = CreateTrigger()
	local boolean result

	call TriggerAddCondition(t, Condition(c))

	call gg__IncStackChecks()

	set result = TriggerEvaluate(t)

	call gg__DecStackChecks()

	if not result then
		call gg__debugEx(null, "runProtFunc", "compilefunc " + name + " has been broken")
	endif

	set t = null

	return result
endfunction

function gg__killThread takes nothing returns nothing
	call R2I(1/0)
endfunction

function gg__TriggerSleepAction takes real timeout returns nothing
	local integer stack
	local integer stackLevel
	//local integer codeId
	local string name

	if not gg__currentThreadCanWait then
		call gg__killThread()

		return
	endif

	//set codeId = gg__peekStack()
	set name = gg__peekStackString()
	set stackLevel = gg__currentStackLevel

	call gg__func_end()

	if ((gg__currentStack == 0) or gg__newThread or not gg__hasFirstWait[gg__currentStack]) then
		set stack = gg__copyStack()
		set gg__hasFirstWait[stack] = true
		set gg__newThread = false
	else
		set stack = gg__currentStack

	//call gg__info("compare "+I2S(gg__getStackCount())+" to "+I2S(gg__stackTimerLevel))
		if (gg__getStackCount() + 1 == gg__stackTimerLevel) then
		//call gg__info("pause stackTimer")
			set gg__stackTimerLevel = ARRAY_EMPTY
			call PauseTimer(gg__stackTimer)
		endif
	endif

//call gg__info("save stack "+I2S(stack)+" level "+I2S(stackLevel)+" count "+I2S(gg__getStackCount()))
	call TriggerSleepAction(timeout)
//call gg__info("restore stack "+I2S(stack)+" level "+I2S(stackLevel)+" count "+I2S(gg__getStackCount()))

	set gg__currentStack = stack
	set gg__currentStackLevel = stackLevel

	//call gg__func_start(codeId)
	call gg__func_startString(name)
//call gg__info("start stackTimer level "+I2S(gg__currentStackLevel))
	set gg__stackTimerLevel = gg__getStackCount()
	call TimerStart(gg__stackTimer, 0, false, function gg__stackTimer_timeout)
endfunction

function gg__TriggerSyncStart takes nothing returns nothing
	local integer stack
	local integer stackLevel
	//local integer codeId
	local string name

	if not gg__currentThreadCanWait then
		call gg__killThread()

		return
	endif

	//set codeId = gg__peekStack()
	set name = gg__peekStackString()
	set stackLevel = gg__currentStackLevel

	//call gg__func_end()
	call gg__func_endString()

	if ((gg__currentStack == 0) or gg__newThread or not gg__hasFirstWait[gg__currentStack]) then
		set stack = gg__copyStack()
		set gg__hasFirstWait[stack] = true
		set gg__newThread = false
	else
		set stack = gg__currentStack

	//call gg__info("compare "+I2S(gg__getStackCount())+" to "+I2S(gg__stackTimerLevel))
		if (gg__getStackCount() + 1 == gg__stackTimerLevel) then
		//call gg__info("pause stackTimer")
			set gg__stackTimerLevel = ARRAY_EMPTY
			call PauseTimer(gg__stackTimer)
		endif
	endif

//call gg__info("save stack "+I2S(stack)+" level "+I2S(stackLevel)+" count "+I2S(gg__getStackCount()))
	call TriggerSyncStart()
//call gg__info("restore stack "+I2S(stack)+" level "+I2S(stackLevel)+" count "+I2S(gg__getStackCount()))

	set gg__currentStack = stack
	set gg__currentStackLevel = stackLevel

	//call gg__func_start(codeId)
	call gg__func_startString(name)
//call gg__info("start stackTimer level "+I2S(gg__currentStackLevel))
	set gg__stackTimerLevel = gg__getStackCount()
	call TimerStart(gg__stackTimer, 0, false, function gg__stackTimer_timeout)
endfunction

function gg__TriggerSyncReady takes nothing returns nothing
	local integer stack
	local integer stackLevel
	//local integer codeId
	local string name

	if not gg__currentThreadCanWait then
		call gg__killThread()

		return
	endif

	//set codeId = gg__peekStack()
	set name = gg__peekStackString()
	set stackLevel = gg__currentStackLevel

	//call gg__func_end()
	call gg__func_endString()

	if ((gg__currentStack == 0) or gg__newThread or not gg__hasFirstWait[gg__currentStack]) then
		set stack = gg__copyStack()
		set gg__hasFirstWait[stack] = true
		set gg__newThread = false
	else
		set stack = gg__currentStack

	//call gg__info("compare "+I2S(gg__getStackCount())+" to "+I2S(gg__stackTimerLevel))
		if (gg__getStackCount() + 1 == gg__stackTimerLevel) then
		//call gg__info("pause stackTimer")
			set gg__stackTimerLevel = ARRAY_EMPTY
			call PauseTimer(gg__stackTimer)
		endif
	endif

//call gg__info("save stack "+I2S(stack)+" level "+I2S(stackLevel)+" count "+I2S(gg__getStackCount()))
	call TriggerSyncReady()
//call gg__info("restore stack "+I2S(stack)+" level "+I2S(stackLevel)+" count "+I2S(gg__getStackCount()))

	set gg__currentStack = stack
	set gg__currentStackLevel = stackLevel

	//call gg__func_start(codeId)
	call gg__func_startString(name)
//call gg__info("start stackTimer level "+I2S(gg__currentStackLevel))
	set gg__stackTimerLevel = gg__getStackCount()
	call TimerStart(gg__stackTimer, 0, false, function gg__stackTimer_timeout)
endfunction

function gg__onAfterTriggerAction takes nothing returns nothing
//call BJDebugMsg("after")
	if (gg__currentStack != 0) then
	//call BJDebugMsg("afterB "+I2S(gg__currentStack)+";"+I2S(gg__currentStackLevel)+";"+I2S(gg__getStackCount()))
		call gg__DecStack(gg__currentStackLevel)
//call BJDebugMsg("afterC "+I2S(gg__currentStack)+";"+I2S(gg__currentStackLevel))
		call gg__deleteStack(gg__currentStack)
		set gg__currentStack = 0

		//call gg__info("after reset to 0")
	endif
endfunction

function gg__TriggerAddAction takes trigger t, code c returns triggeraction
	local triggeraction ta = TriggerAddAction(t, c)

	//call TriggerAddAction(t, function gg__onAfterTriggerAction)

	return ta
endfunction

function gg__TriggerEvaluate takes trigger t returns boolean
	//local integer stack = gg__currentStack

	local boolean ret = false

	set gg__threadDepth = gg__threadDepth + 1

	if (gg__threadDepth > gg__threadDepthLimit) then
		set gg__threadDepth = gg__threadDepth - 1

		call gg__debugEx(null, null, "thread nesting depth exceeded " + I2S(gg__threadDepthLimit) + ", force return")

		return false
	endif

	call gg__IncStackChecks()

	set ret = TriggerEvaluate(t)

	call gg__DecStackChecks()

	set gg__threadDepth = gg__threadDepth - 1

//call gg__info("evaluate reset to "+I2S(stack))
	//set gg__currentStack = stack

	return ret
endfunction

function gg__TriggerExecute takes trigger t returns nothing
	call gg__IncStackChecks()

	//local integer stack = gg__currentStack

	//set gg__hasFirstWait = false
	//set gg__currentStackLevel = stackLevel
//call gg__info("triggerexec "+I2S(stackLevel)+";"+I2S(gg__func_start_count))

	set gg__newThread = true
	set gg__currentThreadCanWait = true

	call TriggerExecute(t)

	set gg__newThread = false

	call gg__DecStackChecks()
//call gg__info("exec reset to "+I2S(stack))
	//set gg__currentStack = stack
endfunction

function gg__DestroyTrigger takes trigger t returns nothing
	local trigger buddy = LoadTriggerHandle(TRIGGER_TABLE, GetHandleId(t), 0)

	if (buddy != null) then
		call RemoveSavedHandle(TRIGGER_TABLE, GetHandleId(buddy), 0)
		call RemoveSavedHandle(TRIGGER_TABLE, GetHandleId(t), 0)
	endif

	call RemoveSavedHandle(TRIGGER_TABLE, GetHandleId(t), 0)
endfunction

function gg__EnableTrigger takes trigger t returns nothing
	local trigger buddy = LoadTriggerHandle(TRIGGER_TABLE, GetHandleId(t), 0)

	if (buddy != null) then
		call EnableTrigger(buddy)
	endif
endfunction

function gg__DisableTrigger takes trigger t returns nothing
	local trigger buddy = LoadTriggerHandle(TRIGGER_TABLE, GetHandleId(t), 0)

	if (buddy != null) then
		call DisableTrigger(buddy)
	endif
endfunction

function gg__onTriggerEvent takes nothing returns boolean
	local trigger t = LoadTriggerHandle(TRIGGER_TABLE, GetHandleId(GetTriggeringTrigger()), 0)
//call gg__info("onTrigger")
	if gg__TriggerEvaluate(t) then
		call gg__TriggerExecute(t)
	endif

	set t = null

	return false
endfunction

function gg__getTriggerBuddy takes trigger t returns trigger
	local trigger buddy = LoadTriggerHandle(TRIGGER_TABLE, GetHandleId(t), 0)

	if not HaveSavedHandle(TRIGGER_TABLE, GetHandleId(t), 0) then
		set buddy = CreateTrigger()

		call SaveTriggerHandle(TRIGGER_TABLE, GetHandleId(buddy), 0, t)
		call SaveTriggerHandle(TRIGGER_TABLE, GetHandleId(t), 0, buddy)
		call TriggerAddCondition(buddy, Condition(function gg__onTriggerEvent))
	endif

	set gg__tempTrigger = buddy

	return gg__tempTrigger
endfunction

function gg__dummyOr_Start takes nothing returns boolean
//call gg__info("dummyOr start")
	set gg__currentThreadCanWait = false
	call gg__IncStackChecks()

	return false
endfunction

function gg__B2S takes boolean b returns string
	if b then
		return "true"
	endif

	return "false"
endfunction

function gg__DestroyBoolExpr takes boolexpr e returns nothing
	if (e == null) then
		return
	endif

	if LoadBoolean(TRIGGER_TABLE, GetHandleId(e), 0) then
		return
	endif

	call DestroyBoolExpr(e)
endfunction

function gg__DestroyCondition takes conditionfunc c returns nothing
	call gg__DestroyBoolExpr(c)
endfunction

function gg__DestroyFilter takes filterfunc f returns nothing
	call gg__DestroyBoolExpr(f)
endfunction

function gg__dummyOr_End takes nothing returns boolean
//call gg__info("dummyOr end "+gg__B2S(gg__ret_bool))
	call gg__DecStackChecks()

	return gg__ret_bool
endfunction

function gg__Condition takes code c returns boolexpr
	call SaveBoolean(TRIGGER_TABLE, GetHandleId(Condition(c)), 0, true)

	return Or(Or(Condition(function gg__dummyOr_Start), Condition(c)), Condition(function gg__dummyOr_End))
endfunction

function gg__Filter takes code c returns boolexpr
	call SaveBoolean(TRIGGER_TABLE, GetHandleId(Condition(c)), 0, true)

	return Or(Or(Filter(function gg__dummyOr_Start), Filter(c)), Filter(function gg__dummyOr_End))
endfunction

function gg__enum_callback takes nothing returns nothing
	call gg__IncStackChecks()

	call TriggerEvaluate(gg__enumTriggers[gg__enumTriggersCount])

	call gg__DecStackChecks()
endfunction

function gg__enum_pushTrigger takes code callback returns nothing
	if (callback != null) then
		set gg__enumTriggersCount = gg__enumTriggersCount + 1

		if (gg__enumTriggersCount > gg__enumTriggersMax) then
			set gg__enumTriggers[gg__enumTriggersCount] = CreateTrigger()
		else
			call TriggerClearConditions(gg__enumTriggers[gg__enumTriggersCount])
		endif

		call TriggerAddCondition(gg__enumTriggers[gg__enumTriggersCount], Condition(callback))
	endif
endfunction

function gg__enum_popTrigger takes code callback returns nothing
	if (callback != null) then
		set gg__enumTriggersCount = gg__enumTriggersCount - 1
	endif
endfunction

function gg__EnumDestructablesInRect takes rect r, boolexpr filter, code actionFunc returns nothing
	call gg__enum_pushTrigger(actionFunc)

	call EnumDestructablesInRect(r, filter, function gg__enum_callback)

	call gg__enum_popTrigger(actionFunc)
endfunction

function gg__EnumItemsInRect takes rect r, boolexpr filter, code actionFunc returns nothing
	call gg__enum_pushTrigger(actionFunc)

	call EnumItemsInRect(r, filter, function gg__enum_callback)

	call gg__enum_popTrigger(actionFunc)
endfunction

function gg__ForForce takes force whichForce, code callback returns nothing
	call gg__enum_pushTrigger(callback)

	call ForForce(whichForce, function gg__enum_callback)

	call gg__enum_popTrigger(callback)
endfunction

function gg__ForGroup takes group whichGroup, code callback returns nothing
	call gg__enum_pushTrigger(callback)

	call ForGroup(whichGroup, function gg__enum_callback)

	call gg__enum_popTrigger(callback)
endfunction

function gg__TimerStart_callback takes nothing returns nothing
	call TriggerEvaluate(LoadTriggerHandle(TRIGGER_TABLE, GetHandleId(GetExpiredTimer()), 0))

	call gg__DecStack(gg__currentStackLevel)
endfunction

function gg__DestroyTimer takes timer whichTimer returns nothing
	call FlushChildHashtable(TRIGGER_TABLE, GetHandleId(whichTimer))

	call PauseTimer(whichTimer)
	call DestroyTimer(whichTimer)
endfunction

function gg__TimerStart takes timer whichTimer, real timeout, boolean periodic, code handlerFunc returns nothing
	local trigger trig = LoadTriggerHandle(TRIGGER_TABLE, GetHandleId(whichTimer), 0)

	if (trig == null) then
		set trig = CreateTrigger()

		call SaveTriggerHandle(TRIGGER_TABLE, GetHandleId(whichTimer), 0, trig)
	else
		call TriggerClearConditions(trig)
	endif

	call TriggerAddCondition(trig, Condition(handlerFunc))

	set trig = null

	call TimerStart(whichTimer, timeout, periodic, function gg__TimerStart_callback)
endfunction

function gg__TriggerRegisterDeathEvent takes trigger whichTrigger, widget whichWidget returns event
	return TriggerRegisterDeathEvent(gg__getTriggerBuddy(whichTrigger), whichWidget)
endfunction

function gg__TriggerRegisterDialogButtonEvent takes trigger whichTrigger, button whichButton returns event
	return TriggerRegisterDialogButtonEvent(gg__getTriggerBuddy(whichTrigger), whichButton)
endfunction

function gg__TriggerRegisterDialogEvent takes trigger whichTrigger, dialog whichDialog returns event
	return TriggerRegisterDialogEvent(gg__getTriggerBuddy(whichTrigger), whichDialog)
endfunction

function gg__TriggerRegisterEnterRegion takes trigger whichTrigger, region whichRegion, boolexpr filter returns event
	return TriggerRegisterEnterRegion(gg__getTriggerBuddy(whichTrigger), whichRegion, filter)
endfunction

function gg__TriggerRegisterFilterUnitEvent takes trigger whichTrigger, unit whichUnit, unitevent whichEvent, boolexpr filter returns event
	return TriggerRegisterFilterUnitEvent(gg__getTriggerBuddy(whichTrigger), whichUnit, whichEvent, filter)
endfunction

function gg__TriggerRegisterGameEvent takes trigger whichTrigger, gameevent whichGameEvent returns event
	return TriggerRegisterGameEvent(gg__getTriggerBuddy(whichTrigger), whichGameEvent)
endfunction

function gg__TriggerRegisterGameStateEvent takes trigger whichTrigger, gamestate whichState, limitop opcode, real limitval returns event
	return TriggerRegisterGameStateEvent(gg__getTriggerBuddy(whichTrigger), whichState, opcode, limitval)
endfunction

function gg__TriggerRegisterLeaveRegion takes trigger whichTrigger, region whichRegion, boolexpr filter returns event
	return TriggerRegisterLeaveRegion(gg__getTriggerBuddy(whichTrigger), whichRegion, filter)
endfunction

function gg__TriggerRegisterPlayerAllianceChange takes trigger whichTrigger, player whichPlayer, alliancetype whichAlliance returns event
	return TriggerRegisterPlayerAllianceChange(gg__getTriggerBuddy(whichTrigger), whichPlayer, whichAlliance)
endfunction

function gg__TriggerRegisterPlayerChatEvent takes trigger whichTrigger, player whichPlayer, string chatMessageToDetect, boolean exactMatchOnly returns event
	return TriggerRegisterPlayerChatEvent(gg__getTriggerBuddy(whichTrigger), whichPlayer, chatMessageToDetect, exactMatchOnly)
endfunction

function gg__TriggerRegisterPlayerEvent takes trigger whichTrigger, player whichPlayer, playerevent whichPlayerEvent returns event
	return TriggerRegisterPlayerEvent(gg__getTriggerBuddy(whichTrigger), whichPlayer, whichPlayerEvent)
endfunction

function gg__TriggerRegisterPlayerStateEvent takes trigger whichTrigger, player whichPlayer, playerstate whichState, limitop opcode, real limitval returns event
	return TriggerRegisterPlayerStateEvent(gg__getTriggerBuddy(whichTrigger), whichPlayer, whichState, opcode, limitval)
endfunction

function gg__TriggerRegisterPlayerUnitEvent takes trigger whichTrigger, player whichPlayer, playerunitevent whichPlayerUnitEvent, boolexpr filter returns event
	return TriggerRegisterPlayerUnitEvent(gg__getTriggerBuddy(whichTrigger), whichPlayer, whichPlayerUnitEvent, filter)
endfunction

function gg__TriggerRegisterTimerEvent takes trigger whichTrigger, real timeout, boolean periodic returns event
	return TriggerRegisterTimerEvent(gg__getTriggerBuddy(whichTrigger), timeout, periodic)
endfunction

function gg__TriggerRegisterTimerExpireEvent takes trigger whichTrigger, timer t returns event
	return TriggerRegisterTimerExpireEvent(gg__getTriggerBuddy(whichTrigger), t)
endfunction

function gg__TriggerRegisterTrackableHitEvent takes trigger whichTrigger, trackable t returns event
	return TriggerRegisterTrackableHitEvent(gg__getTriggerBuddy(whichTrigger), t)
endfunction

function gg__TriggerRegisterTrackableTrackEvent takes trigger whichTrigger, trackable t returns event
	return TriggerRegisterTrackableTrackEvent(gg__getTriggerBuddy(whichTrigger), t)
endfunction

function gg__TriggerRegisterUnitEvent takes trigger whichTrigger, unit whichUnit, unitevent whichEvent returns event
	return TriggerRegisterUnitEvent(gg__getTriggerBuddy(whichTrigger), whichUnit, whichEvent)
endfunction

function gg__TriggerRegisterUnitInRange takes trigger whichTrigger, unit whichUnit, real range, boolexpr filter returns event
	return TriggerRegisterUnitInRange(gg__getTriggerBuddy(whichTrigger), whichUnit, range, filter)
endfunction

function gg__TriggerRegisterUnitStateEvent takes trigger whichTrigger, unit whichUnit, unitstate whichState, limitop opcode, real limitval returns event
	return TriggerRegisterUnitStateEvent(gg__getTriggerBuddy(whichTrigger), whichUnit, whichState, opcode, limitval)
endfunction

function gg__TriggerRegisterVariableEvent takes trigger whichTrigger, string varName, limitop opcode, real limitval returns event
	return TriggerRegisterVariableEvent(gg__getTriggerBuddy(whichTrigger), varName, opcode, limitval)
endfunction

function gg__ExecuteFunc takes string s returns nothing
	call gg__IncStackChecks()

	call ExecuteFunc(s)

	call gg__DecStackChecks()
endfunction

function gg__Player takes integer number returns player
	if ((number < 0) or (number > 15)) then
		call gg__debugEx(null, null, "Called Player with index out of bounds (" + I2S(number) + ")")

		return null
	endif

	return Player(number)
endfunction

function gg__Preloader takes string s returns nothing
	call Preloader(s)
endfunction