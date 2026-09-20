local W = dofile(ROOT .. "/tests/wow_stub.lua")
MF:Log("INFO", "t", "plain %d%%", 5)
MF:Log("WARN", "t", "no args 100%")
MF:Log("INFO", "t", "bad fmt %d", "x")
MF:Debug("t", "hidden")
MacroForgeLog.debug = true
local p = print; local echoed; print = function(s) echoed = s end
MF:Debug("t", "shown\nmultiline"); print = p
local L = MacroForgeLog.lines
assert(#L == 4, #L)
assert(L[1]:find("%[INFO%] t: plain 5%%"), L[1])
assert(L[2]:find("no args 100%%"), L[2])
assert(L[3]:find("bad fmt %%d x"), L[3])
assert(L[4]:find("shown \\n multiline", 1, true) and echoed, L[4])
MacroForgeLog.debug = nil
for i = 1, 2100 do MF:Log("INFO", "t", "x") end
assert(#MacroForgeLog.lines == 2000)
print("log ok")
