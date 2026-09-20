local W = dofile(ROOT .. "/tests/wow_stub.lua")
dofile(ROOT .. "/Profiles.lua")
local P = MF.Profiles
local function run(sorted)
  W.reset(); W.sorted = sorted
  CreateMacro("Boom", 1, "/cast Fireball", true)
  CreateMacro("Aoe", 1, "/cast Flamestrike", true)
  CreateMacro("FireOnly", 1, "/cast Combustion", true)
  CreateMacro("Acct", 1, "/say hi", false)
  -- bars: find indexes by name
  for i = 121, 123 do W.place(GetMacroInfo(i), i) end
  local ok, n, st = P:WriteCharacterMacros({
    { name = "Boom", icon = 2, body = "/cast Frostbolt" },
    { name = "Aoe", icon = 1, body = "/cast Flamestrike" },
    { name = "Zeta", icon = 1, body = "/cast Blizzard" },
    { name = "Boom", icon = 3, body = "/cast Ice Lance" },
  })
  assert(ok and n == 4, "count " .. tostring(n))
  assert(st.kept == 2 and st.edited == 1 and st.created == 2 and st.deleted == 1, "stats")
  assert(W.barName("Boom") == "Boom" and W.bars.Boom.body == "/cast Frostbolt", "Boom bar lost")
  assert(W.barName("Aoe") == "Aoe", "Aoe bar lost")
  assert(W.bars.FireOnly == nil, "FireOnly should be gone")
  assert(W.names(false) == "Acct", "account touched")
  local _, c = GetNumMacros(); assert(c == 4, "char count " .. c)
  -- empty list refused
  assert(P:WriteCharacterMacros({}) == false)
  print("swap ok sorted=" .. tostring(sorted), W.names(true))
end
run(false); run(true)
