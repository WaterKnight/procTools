local params = {...}

local mapPath = params[1]
local filePath = params[2]
local targetPath = params[3]

assert(mapPath, 'no mapPath')
assert(filePath, 'no filePath')
assert(targetPath, 'no targetPath')

require 'portLib'

mpqExtract(mapPath, filePath, targetPath)