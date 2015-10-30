require 'waterlua'

local params = {...}

local sourcePath = params[1]
local otherPath = params[2]

assert(sourcePath, 'no sourceath')
assert(otherPath, 'no otherPath')

--[[for _, path in pairs(io.getFiles(otherPath)) do
	io.copyFile(path, sourcePath)
end]]

io.copyDir(otherPath, sourcePath)