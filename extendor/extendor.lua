local params = {...}

local inputPath = params[1]

local outputPath = params[2]

assert(inputPath, 'no inputPath')

if (outputPath == nil) then
	outputPath = inputPath
end

function ltrim(s)
  return (s:gsub("^%s*", ""))
end
function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end
file = io.input(inputPath)

startcode = "extendor"
endcode = "endextendor"
runcode = "runextendor"
extendor = {}
extendorcode = {}
output = {}
nested = false
extendorname = ""
curpriority = 0
for line in file:lines() do
	local int = 1
	local token = {}
	for i in string.gmatch(line, "%-?%w+") do
  		token[int] = i
  		int = int + 1
	end
	if nested == true then
		if token[1] == endcode then
			nested = false
		else
			if extendorcode[extendorname] == nil then
				extendorcode[extendorname] = {}
				--extendorcode[extendorname] = ""
			end
			if extendorcode[extendorname][curpriority] == nil then
				extendorcode[extendorname][curpriority] = ltrim(line):sub(3)
			else
				extendorcode[extendorname][curpriority] = extendorcode[extendorname][curpriority].."\n"..ltrim(line):sub(3)
			end
			
		end
	else
		if token[1] == startcode then
			extendor[token[2]] = token[2]
			nested = true
			extendorname = token[2]
			if token[3] == nil then
				curpriority = 0
			else
				curpriority = tonumber(token[3])
			end
		elseif token[1] == runcode then
			table.insert(output,line)
		else
			table.insert(output,line)
		end
	end
end
file:close()
outputstring = ""
file2 = io.open(outputPath,"w")
for line,value in pairs(output) do
	outputstring = outputstring..value.."\n"
end
outputextendor = {}
for line,value in pairs(extendor) do
	if outputextendor[line] == nil then
		outputextendor[line] = ""
	end
	for i,v in spairs(extendorcode[line]) do
		outputextendor[line] = outputextendor[line]..extendorcode[line][i]
	end
end
for line,value in pairs(extendor) do
	outputstring = outputstring:gsub("//#".." "..runcode.." "..extendor[value],outputextendor[line])
end
--outputstring = outputstring:gsub("#/#/##s"..runcode.."%.+","")
file2:write(outputstring)
file2:close()
