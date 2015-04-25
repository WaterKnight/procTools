package.path = [[D:\Warcraft III\Mapping\?\init.lua]]

require 'waterlua'

copyFileIfNewer([[D:\Warcraft III\war3.mpq]], io.local_dir()..'test.mpq')

local f = io.open([[D:\Warcraft III\war3.mpq]], 'r')

print(f)

print(lfs.lock(f, 'a'))

print(lfs.unlock(f))

f:close()