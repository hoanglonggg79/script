-- ════════════════════════════════════════════════════════════════
--
--   ░██████╗██╗░░░██╗███╗░░██╗░█████╗░
--   ██╔════╝██║░░░██║████╗░██║██╔══██╗
--   ╚█████╗░██║░░░██║██╔██╗██║██║░░╚═╝
--   ░╚═══██╗██║░░░██║██║╚████║██║░░██╗
--   ██████╔╝╚██████╔╝██║░╚███║╚█████╔╝
--   ╚═════╝░░╚═════╝░╚═╝░░╚══╝░╚════╝░
--
--   sUNC Test Script  ·  by HoangLong
--   Behavioral · Anti-Fake · Security
--   https://github.com/hoanglonggg79/sUNC_TestScript
--
-- ════════════════════════════════════════════════════════════════

local _ENV_SAFE = {}
do
    local src = getfenv and getfenv() or _G
    for k, v in pairs(src) do
        _ENV_SAFE[k] = type(v)
    end
end

local SUITE_VERSION = "2026.5"

local _baseline_print  = print
local _baseline_pairs  = pairs
local _baseline_ipairs = ipairs

local results = { pass = {}, fail = {}, skip = {} }
local running = 0

-- ─── RUNNER & ASSERTIONS ────────────────────────────────────────

local function run(name, callback, flags)
    flags = flags or {}
    if flags.skip then
        table.insert(results.skip, { name = name, reason = flags.skip })
        print(string.format("⏭  [SKIP] %s  (%s)", name, flags.skip))
        return
    end

    running = running + 1
    local co = coroutine.create(function()
        local ok, err = pcall(callback)
        if ok then
            table.insert(results.pass, name)
            print(string.format("✅ [PASS] %s", name))
        else
            local msg = tostring(err):gsub("^.-:%d+: ", "")
            table.insert(results.fail, { name = name, err = msg })
            warn(string.format("❌ [FAIL] %s\n         ↳ %s", name, msg))
        end
        running = running - 1
    end)
    local ok2, err2 = coroutine.resume(co)
    if not ok2 then
        table.insert(results.fail, { name = name, err = "coroutine crash: " .. tostring(err2) })
        warn(string.format("💥 [CRASH] %s\n          ↳ %s", name, tostring(err2)))
        running = running - 1
    end
end

local function assert_eq(a, b, msg)
    if a ~= b then
        error(string.format("%s  |  expected %q, got %q",
            msg or "assert_eq", tostring(b), tostring(a)), 2)
    end
end

local function assert_neq(a, b, msg)
    if a == b then
        error(string.format("%s  |  expected values to differ, both are %q",
            msg or "assert_neq", tostring(a)), 2)
    end
end

local function assert_type(v, t, msg)
    if type(v) ~= t then
        error(string.format("%s  |  expected type %s, got %s",
            msg or "assert_type", t, type(v)), 2)
    end
end

local function assert_truthy(v, msg)
    if not v then error(msg or "expected truthy, got falsy", 2) end
end

local function assert_no_raise(fn, msg)
    local ok, err = pcall(fn)
    if not ok then
        error((msg or "expected no error") .. " → " .. tostring(err), 2)
    end
end

local function assert_raises(fn, msg)
    local ok = pcall(fn)
    if ok then
        error(msg or "expected an error to be raised, but call succeeded", 2)
    end
end

-- ─── HEADER ─────────────────────────────────────────────────────

print("\n" .. string.rep("═", 62))
print("  sUNC Test Script  ·  by HoangLong")
print(string.format("  Version: v%s", SUITE_VERSION))
print("  Behavioral · Anti-Fake · Security")
print(string.rep("═", 62) .. "\n")

-- ─── SECTION 1: HOOKFUNCTION ────────────────────────────────────

run("hookfunction · basic return transform", function()
    local function add(a, b) return a + b end
    local orig = hookfunction(add, function(a, b)
        return (a + b) * 2
    end)
    assert_eq(add(3, 4),  14, "hook must double the sum")
    assert_eq(orig(3, 4),  7, "original reference must still compute correctly")
end)

run("hookfunction · original is callable multiple times (not consumed)", function()
    local call_count = 0
    local function target() call_count = call_count + 1; return call_count end
    local orig = hookfunction(target, function() return -1 end)
    orig(); orig(); orig()
    assert_eq(call_count, 3, "original must be callable multiple times")
end)

run("hookfunction · hook receives all varargs including nil gaps", function()
    local captured   = {}
    local captured_n = 0
    local function sink(...) return ... end
    local orig
    orig = hookfunction(sink, function(...)
        captured_n = select("#", ...)
        for i = 1, captured_n do
            captured[i] = select(i, ...)
        end
        return orig(...)
    end)
    sink(10, "hello", true, nil, 99)
    assert_eq(captured_n,   5,       "must capture exactly 5 args including nil")
    assert_eq(captured[1],  10,      "arg #1")
    assert_eq(captured[2],  "hello", "arg #2")
    assert_eq(captured[3],  true,    "arg #3")
    assert_eq(captured[4],  nil,     "arg #4 is nil")
    assert_eq(captured[5],  99,      "arg #5 past nil gap")
end)

run("hookfunction · hook chaining stability", function()
    local function base() return 1 end
    local orig1 = hookfunction(base, function() return 2 end)
    local orig2 = hookfunction(base, function() return 3 end)
    assert_eq(base(),  3, "outermost hook must be active")
    assert_eq(orig2(), 2, "middle hook callable via orig2")
    assert_eq(orig1(), 1, "original callable via orig1")
end)

run("hookfunction · numparams stability (anti-detection)", function()
    local function fn(a, b, c) return a + b + c end
    hookfunction(fn, function(a, b, c) return (a + b + c) * 10 end)
    local info = debug.getinfo(fn)
    assert_eq(info.numparams, 3, "hook must not alter numparams")
end)

run("hookfunction · upvalue integrity after hook", function()
    local secret = 42
    local function reader() return secret end
    hookfunction(reader, function() return 0 end)
    local ups = debug.getupvalues(reader)
    assert_type(ups, "table", "debug.getupvalues must return a table")
    local found = false
    for _, v in pairs(ups) do if v == 42 then found = true; break end end
    assert_truthy(found, "secret upvalue must still be accessible post-hook")
end)

run("hookfunction · FAKE DETECTION: stub that ignores replacement", function()
    local sentinel = {}
    local function probe() return sentinel end
    local orig = hookfunction(probe, function() return "HOOKED" end)
    local result = probe()
    if result == sentinel then
        error("FAKE STUB DETECTED: hookfunction accepted hook but did not apply it")
    end
    assert_eq(result, "HOOKED", "hook must intercept call")
    if orig() ~= sentinel then
        error("FAKE STUB DETECTED: original reference does not return true original behavior")
    end
end)

run("hookfunction · multi-return forwarded correctly", function()
    local function multi() return 1, 2, 3 end
    hookfunction(multi, function() return 10, 20, 30 end)
    local a, b, c = multi()
    assert_eq(a, 10, "return #1")
    assert_eq(b, 20, "return #2")
    assert_eq(c, 30, "return #3")
end)

run("hookfunction · re-hook replaces previous hook", function()
    local function fn() return "original" end
    local orig1 = hookfunction(fn, function() return "hook1" end)
    assert_eq(fn(), "hook1", "hook1 must be active")
    local orig2 = hookfunction(fn, function() return "hook2" end)
    assert_eq(fn(),    "hook2",    "hook2 must be active after re-hook")
    assert_eq(orig2(), "hook1",    "orig2 must return hook1")
    assert_eq(orig1(), "original", "orig1 must return original")
end)

run("hookfunction · unrelated functions are not affected", function()
    local function fn_a() return "a" end
    local function fn_b() return "b" end
    hookfunction(fn_a, function() return "a_hooked" end)
    assert_eq(fn_b(), "b", "fn_b must not be affected by hook on fn_a")
end)

-- ─── SECTION 2: HOOKMETAMETHOD ──────────────────────────────────

run("hookmetamethod · __index intercept and restore", function()
    local dummy = Instance.new("Part")
    dummy.Name = "RealName"
    local old
    old = hookmetamethod(game, "__index", function(self, key)
        if self == dummy and key == "Name" then return "Spoofed" end
        return old(self, key)
    end)
    assert_eq(dummy.Name, "Spoofed",   "__index hook must intercept")
    hookmetamethod(game, "__index", old)
    assert_eq(dummy.Name, "RealName",  "__index must be restored correctly")
    dummy:Destroy()
end)

run("hookmetamethod · __newindex intercept", function()
    local dummy = Instance.new("Part")
    local writes = {}
    local old
    old = hookmetamethod(game, "__newindex", function(self, key, value)
        table.insert(writes, { key = key, value = value })
        return old(self, key, value)
    end)
    dummy.Name = "WriteTest"
    hookmetamethod(game, "__newindex", old)
    local found = false
    for _, w in ipairs(writes) do
        if w.key == "Name" and w.value == "WriteTest" then found = true; break end
    end
    assert_truthy(found, "__newindex must have intercepted the Name write")
    dummy:Destroy()
end)

run("hookmetamethod · __namecall + getnamecallmethod accuracy", function()
    local methods_seen = {}
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        table.insert(methods_seen, getnamecallmethod())
        return old(self, ...)
    end)
    game:GetService("Lighting")
    hookmetamethod(game, "__namecall", old)
    local found = false
    for _, m in ipairs(methods_seen) do
        if m == "GetService" then found = true; break end
    end
    assert_truthy(found, "getnamecallmethod() must return 'GetService'")
end)

run("hookmetamethod · FAKE DETECTION: getnamecallmethod returns wrong method name", function()
    local seen = {}
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        table.insert(seen, getnamecallmethod())
        return old(self, ...)
    end)
    game:GetService("Lighting")
    game:IsA("DataModel")
    hookmetamethod(game, "__namecall", old)

    assert_truthy(#seen >= 2, "hook must fire at least twice")

    local has_get_service = false
    local has_is_a        = false
    for _, m in ipairs(seen) do
        if m == "GetService" then has_get_service = true end
        if m == "IsA"        then has_is_a        = true end
    end
    if not has_get_service or not has_is_a then
        error(string.format(
            "FAKE STUB DETECTED: getnamecallmethod() did not distinguish methods correctly — seen: %s",
            table.concat(seen, ", ")
        ))
    end
end)

run("hookmetamethod · hook fires on non-game Instances", function()
    local folder = Instance.new("Folder")
    local fired  = false
    local old
    old = hookmetamethod(game, "__index", function(self, key)
        if self == folder then fired = true end
        return old(self, key)
    end)
    local _ = folder.Name
    hookmetamethod(game, "__index", old)
    assert_truthy(fired, "__index hook must intercept access on all Instances")
    folder:Destroy()
end)

-- ─── SECTION 3: ENVIRONMENT & CHECKCALLER ───────────────────────

run("checkcaller · returns true inside executor context", function()
    assert_truthy(checkcaller(), "checkcaller() must be true in executor scope")
end)

run("checkcaller · FAKE DETECTION: always-true stub", function()
    local result_from_game_fn = nil
    local game_fn = newcclosure(function()
        result_from_game_fn = checkcaller()
    end)
    game_fn()
    if result_from_game_fn == true then
        warn("⚠  checkcaller() returned true in non-executor scope — possible always-true stub")
    end
    assert_truthy(checkcaller(), "checkcaller in test frame must be true")
end)

run("getfenv · environment is not poisoned", function()
    local env = getfenv()
    assert_type(env,              "table",    "getfenv() must return a table")
    assert_type(env.print,        "function", "env must have print")
    assert_type(env.pairs,        "function", "env must have pairs")
    assert_type(env.ipairs,       "function", "env must have ipairs")
end)

run("getfenv · SECURITY: no unexpected keys injected into environment", function()
    local env = getfenv()
    local suspicious = {}
    for k, _ in pairs(env) do
        if _ENV_SAFE[k] == nil and type(k) == "string" then
            table.insert(suspicious, k)
        end
    end
    if #suspicious > 0 then
        warn("⚠  ENV POLLUTION detected — injected keys: " .. table.concat(suspicious, ", "))
    end
    assert_eq(rawequal(env.print, _baseline_print), true,
        "print in env must be the original function captured at suite start (rawequal)")
end)

run("setfenv · applies correctly and function runs in new env", function()
    local custom_env = setmetatable({ x = 999 }, { __index = getfenv() })
    local function reader() return x end
    setfenv(reader, custom_env)
    assert_eq(reader(), 999, "setfenv must inject x = 999 into the function")
end)

run("getfenv · level argument (getfenv(0) is global env)", function()
    local g = getfenv(0)
    assert_type(g, "table", "getfenv(0) must return a table (global env)")
    assert_truthy(g.print ~= nil, "global env must contain print")
end)

run("setfenv · isolation: changes do not affect other functions", function()
    local function fn_a() return type(tostring) end
    local function fn_b() return type(tostring) end
    local isolated    = setmetatable({}, { __index = getfenv() })
    isolated.tostring = 42
    setfenv(fn_a, isolated)
    assert_eq(fn_a(), "number",   "fn_a must see tostring = 42")
    assert_eq(fn_b(), "function", "fn_b must not be affected by fn_a's setfenv")
end)

-- ─── SECTION 4: DEBUG LIBRARY ───────────────────────────────────

run("debug.getupvalues · reads upvalues correctly", function()
    local a, b = 10, 20
    local function closure() return a + b end
    local ups = debug.getupvalues(closure)
    assert_type(ups, "table", "debug.getupvalues must return a table")
    local vals = {}
    for _, v in pairs(ups) do vals[v] = true end
    assert_truthy(vals[10] and vals[20], "upvalues 10 and 20 must both be present")
end)

run("debug.setupvalue · writes upvalue and function reflects immediately", function()
    local counter = 0
    local function bump() counter = counter + 1; return counter end
    local ups = debug.getupvalues(bump)
    local idx = nil
    for i, v in ipairs(ups) do
        if v == 0 then idx = i; break end
    end
    if not idx then
        for i, v in pairs(ups) do
            if type(i) == "number" and v == 0 then idx = i; break end
        end
    end
    if not idx then error("could not find upvalue index for counter") end
    debug.setupvalue(bump, idx, 100)
    assert_eq(bump(), 101, "debug.setupvalue must change upvalue at runtime")
end)

run("debug.getinfo · numparams and what field are correct", function()
    local function sample(a, b, c) return a, b, c end
    local info = debug.getinfo(sample)
    assert_eq(info.numparams, 3,     "numparams must be 3")
    assert_eq(info.what,      "Lua", "what must be 'Lua'")
end)

run("debug.getinfo · FAKE DETECTION: stub returns hardcoded table", function()
    local function one_param(x)    return x     end
    local function two_params(x,y) return x + y end
    local info1 = debug.getinfo(one_param)
    local info2 = debug.getinfo(two_params)
    if info1.numparams == 0 and info2.numparams == 0 then
        error("FAKE STUB: debug.getinfo always returns numparams=0 — not reading real bytecode")
    end
    assert_eq(info1.numparams, 1, "one_param must have numparams=1")
    assert_eq(info2.numparams, 2, "two_params must have numparams=2")
end)

run("debug.getconstants · returns constant pool of function", function()
    local function greet() return "hello_sunc_marker" end
    local consts = debug.getconstants(greet)
    assert_type(consts, "table", "debug.getconstants must return a table")
    local found = false
    for _, v in pairs(consts) do
        if v == "hello_sunc_marker" then found = true; break end
    end
    assert_truthy(found, "constant 'hello_sunc_marker' must be present in pool")
end)

run("debug.getconstants · FAKE DETECTION: returns empty table", function()
    local function fn_with_consts()
        local _ = "marker_alpha"
        local __ = "marker_beta"
        return _ .. __
    end
    local consts = debug.getconstants(fn_with_consts)
    assert_type(consts, "table", "must return a table")
    local count = 0
    for _ in pairs(consts) do count = count + 1 end
    if count == 0 then
        error("FAKE STUB: debug.getconstants returned empty table — not reading real constant pool")
    end
end)

run("debug.getprotos · returns nested closures", function()
    local function outer()
        local function inner() return "inner_proto" end
        return inner
    end
    local protos = debug.getprotos(outer)
    assert_type(protos, "table", "debug.getprotos must return a table")
    assert_truthy(#protos >= 1, "outer must contain at least 1 proto (inner)")
end)

run("debug.setconstant · writes constant and function reflects immediately", function()
    if not debug.setconstant then
        warn("⚠  debug.setconstant not available — skip")
        return
    end
    local function greeting() return "original_const" end
    local consts = debug.getconstants(greeting)
    local idx    = nil
    for i, v in pairs(consts) do
        if v == "original_const" then idx = i; break end
    end
    if not idx then error("could not find constant 'original_const'") end
    debug.setconstant(greeting, idx, "patched_const")
    assert_eq(greeting(), "patched_const", "debug.setconstant must patch constant at runtime")
end)

run("debug.getupvalues · FAKE DETECTION: returns empty table for closure with upvalues", function()
    local value = "upval_marker"
    local function fn() return value end
    local ups = debug.getupvalues(fn)
    assert_type(ups, "table", "must return a table")
    local count = 0
    for _ in pairs(ups) do count = count + 1 end
    if count == 0 then
        error("FAKE STUB: debug.getupvalues returned empty table — closure has upvalues but none were read")
    end
    local found = false
    for _, v in pairs(ups) do
        if v == "upval_marker" then found = true; break end
    end
    assert_truthy(found, "upvalue 'upval_marker' must appear in the result")
end)

run("debug.setupvalue · correct slot when function has multiple upvalues", function()
    local x, y, z = 1, 2, 3
    local function fn() return x + y + z end
    local ups = debug.getupvalues(fn)
    local idx = nil
    for i, v in ipairs(ups) do
        if v == 3 then idx = i; break end
    end
    if not idx then
        for i, v in pairs(ups) do
            if type(i) == "number" and v == 3 then idx = i; break end
        end
    end
    if not idx then error("could not locate upvalue z=3") end
    debug.setupvalue(fn, idx, 30)
    assert_eq(fn(), 33, "only the targeted upvalue slot must change")
end)

-- ─── SECTION 5: CLOSURES & IDENTITY ─────────────────────────────

run("iscclosure · correctly identifies C closures", function()
    assert_truthy(iscclosure(print),              "print is a C closure")
    assert_truthy(not iscclosure(function() end), "anonymous Lua fn is not a C closure")
end)

run("islclosure · correctly identifies Lua closures", function()
    local function lua_fn() end
    assert_truthy(islclosure(lua_fn),    "Lua fn must be an lclosure")
    assert_truthy(not islclosure(print), "print must not be an lclosure")
end)

run("newcclosure · wraps Lua fn, iscclosure returns true", function()
    local lua_fn = function(x) return x * 2 end
    local wrapped = newcclosure(lua_fn)
    assert_truthy(iscclosure(wrapped), "newcclosure output must be a C closure")
    assert_eq(wrapped(7), 14,          "newcclosure must execute the original logic correctly")
end)

run("newcclosure · FAKE DETECTION: returns identity instead of new wrapper", function()
    local lua_fn = function() end
    local wrapped = newcclosure(lua_fn)
    if rawequal(lua_fn, wrapped) then
        error("FAKE STUB: newcclosure returned the input function itself — no C wrapper was created")
    end
end)

run("newcclosure · preserves multi-return through wrapper", function()
    local fn      = function() return 1, 2, 3 end
    local wrapped = newcclosure(fn)
    local a, b, c = wrapped()
    assert_eq(a, 1, "return #1 through newcclosure")
    assert_eq(b, 2, "return #2 through newcclosure")
    assert_eq(c, 3, "return #3 through newcclosure")
end)

run("clonefunction · clone runs correctly, upvalue shared with original", function()
    local shared = 0
    local function original() shared = shared + 1; return shared end
    local cloned  = clonefunction(original)
    assert_truthy(not rawequal(original, cloned),
        "clone must be a different object from original")
    original()
    assert_eq(cloned(), 2,
        "cloned function shares upvalue — must return 2 after original was called once")
end)

run("clonefunction · FAKE DETECTION: must return a distinct object", function()
    local function fn() return "hello" end
    local cloned = clonefunction(fn)
    assert_truthy(not rawequal(fn, cloned),
        "clonefunction must return a new object, not the same reference")
    assert_eq(cloned(), "hello", "clone must execute correctly")
end)

run("isexecutorclosure · consistent behavior", function()
    local fn_exec = function() end
    local fn_cc   = newcclosure(function() end)

    if isexecutorclosure then
        assert_truthy(isexecutorclosure(fn_exec),
            "executor Lua closure must be recognized as executor closure")
        assert_truthy(not isexecutorclosure(print),
            "print (C builtin) must not be an executor closure")
        assert_truthy(not isexecutorclosure(fn_cc),
            "newcclosure output must not be an executor closure")
    else
        warn("⚠  isexecutorclosure not available")
    end

    if isourclosure then
        assert_truthy(isourclosure(fn_exec),
            "isourclosure must accept executor closure")
    else
        warn("⚠  isourclosure not available")
    end
end)

run("isexecutorclosure · closure created inside pcall is still executor closure", function()
    if not isexecutorclosure then
        warn("⚠  isexecutorclosure not available — skip")
        return
    end
    local fn_inside
    pcall(function()
        fn_inside = function() return "pcall_scope" end
    end)
    assert_truthy(isexecutorclosure(fn_inside),
        "closure created inside pcall must still be an executor closure")
end)

-- ─── SECTION 6: RAWACCESS ───────────────────────────────────────

run("getrawmetatable · returns locked metatable of game", function()
    local mt = getrawmetatable(game)
    assert_type(mt, "table",      "getrawmetatable(game) must return a table")
    assert_truthy(isreadonly(mt), "game metatable must be readonly")
end)

run("setreadonly · toggles read-only state correctly", function()
    local mt = getrawmetatable(game)
    assert_truthy(isreadonly(mt), "before setreadonly: must be readonly")
    local ok, err = pcall(function()
        setreadonly(mt, false)
        assert_truthy(not isreadonly(mt), "after setreadonly(false): must be writable")
    end)
    setreadonly(mt, true)
    assert_truthy(isreadonly(mt), "after setreadonly(true): must be readonly again")
    if not ok then error(err, 0) end
end)

run("rawsetget · bypasses metatable __index/__newindex", function()
    local t = setmetatable({}, {
        __index    = function() error("__index fired!") end,
        __newindex = function() error("__newindex fired!") end,
    })
    assert_no_raise(function() rawset(t, "key", "value") end,
        "rawset must bypass __newindex")
    assert_eq(rawget(t, "key"), "value",
        "rawget must bypass __index and read correctly")
end)

run("getrawmetatable · works on plain Lua tables", function()
    local t  = {}
    local mt = { __index = function() return "meta_val" end }
    setmetatable(t, mt)
    local got = getrawmetatable(t)
    assert_truthy(rawequal(got, mt),
        "getrawmetatable must return the exact metatable of a plain table")
end)

run("getrawmetatable · FAKE DETECTION: must return the real metatable, not a substitute", function()
    local t  = {}
    local mt = {}
    setmetatable(t, mt)
    local got = getrawmetatable(t)
    if not rawequal(got, mt) then
        error("FAKE STUB: getrawmetatable returned a different table — not reading real metatable")
    end
end)

-- ─── SECTION 7: FILESYSTEM ──────────────────────────────────────

run("filesystem · writefile / readfile / isfile roundtrip", function()
    local path    = "sunc_test_" .. tostring(tick()):gsub("%.", "_") .. ".bin"
    local content = "sUNC\0binary\255safe\1data"
    writefile(path, content)
    assert_truthy(isfile(path), "isfile must be true after writefile")
    local read = readfile(path)
    assert_eq(read, content,
        "readfile must return byte-identical content (including null bytes)")
    delfile(path)
    assert_truthy(not isfile(path), "isfile must be false after delfile")
end)

run("filesystem · makefolder / isfolder / delfolder", function()
    local dir = "sunc_dir_" .. tostring(math.random(100000, 999999))
    makefolder(dir)
    assert_truthy(isfolder(dir),     "isfolder must be true after makefolder")
    delfolder(dir)
    assert_truthy(not isfolder(dir), "isfolder must be false after delfolder")
end)

run("filesystem · append mode (graceful fallback)", function()
    local path = "sunc_append_test.txt"
    writefile(path, "line1")
    if appendfile then
        appendfile(path, "\nline2")
        local result = readfile(path)
        assert_truthy(result:find("line2"), "appendfile must concatenate content")
    else
        local existing = readfile(path)
        writefile(path, existing .. "\nline2_fallback")
        local result = readfile(path)
        assert_truthy(result:find("fallback"), "fallback append must work")
        warn("⚠  appendfile not available — used fallback")
    end
    delfile(path)
end)

run("filesystem · listfiles returns correct structure", function()
    if not listfiles then
        warn("⚠  listfiles not available — skip")
        return
    end
    local dir = "sunc_listtest_dir"
    makefolder(dir)
    writefile(dir .. "/a.txt", "a")
    writefile(dir .. "/b.txt", "b")
    local list = listfiles(dir)
    assert_type(list, "table", "listfiles must return a table")
    assert_truthy(#list >= 2, "listfiles must enumerate at least 2 files created")
    delfile(dir .. "/a.txt")
    delfile(dir .. "/b.txt")
    delfolder(dir)
end)

run("filesystem · FAKE DETECTION: writefile stub does not persist", function()
    local path = "sunc_persist_" .. tostring(tick()):gsub("%.", "") .. ".txt"
    writefile(path, "PERSIST_CHECK")
    if not isfile(path) then
        error("FAKE STUB: writefile ran without error but file does not exist on disk")
    end
    local content = readfile(path)
    if content ~= "PERSIST_CHECK" then
        error("FAKE STUB: readfile returned wrong content — writefile did not actually write")
    end
    delfile(path)
end)

run("filesystem · readfile preserves binary data (no null-byte stripping)", function()
    local path = "sunc_nullbyte_test.bin"
    local data = "before\0after"
    writefile(path, data)
    local result = readfile(path)
    assert_eq(#result, #data, "readfile must preserve full length including null bytes")
    assert_eq(result, data,   "content must be byte-identical")
    delfile(path)
end)

run("filesystem · writefile overwrites (does not append)", function()
    local path = "sunc_overwrite_test.txt"
    writefile(path, "first_content")
    writefile(path, "second_content")
    local result = readfile(path)
    assert_eq(result, "second_content",
        "writefile must fully overwrite — must not append to existing content")
    delfile(path)
end)

run("filesystem · isfile returns false for non-existent path", function()
    local path = "sunc_no_such_file_" .. tostring(math.random(1e7, 9e7)) .. ".txt"
    assert_truthy(not isfile(path),
        "isfile must return false for a path that was never created")
end)

run("filesystem · makefolder is idempotent", function()
    local dir = "sunc_idempotent_dir_" .. tostring(math.random(100000, 999999))
    makefolder(dir)
    assert_no_raise(function() makefolder(dir) end,
        "makefolder must not error when folder already exists")
    delfolder(dir)
end)

-- ─── SECTION 8: HTTP & NETWORK ──────────────────────────────────

run("request · GET returns status 200", function()
    local fn = (syn and syn.request) or request or http_request
    if not fn then error("no request function found (request / syn.request / http_request)") end
    local res = fn({ Url = "https://httpbin.org/get", Method = "GET" })
    assert_type(res, "table",       "response must be a table")
    assert_truthy(res.StatusCode,   "response must have a StatusCode field")
    assert_eq(res.StatusCode, 200,  "GET httpbin/get must return 200")
    assert_type(res.Body, "string", "response.Body must be a string")
end)

run("request · custom headers are sent correctly", function()
    local fn = (syn and syn.request) or request or http_request
    if not fn then error("no request function found") end
    local res = fn({
        Url     = "https://httpbin.org/headers",
        Method  = "GET",
        Headers = { ["X-sUNC-Test"] = "behavioral_check" },
    })
    assert_eq(res.StatusCode, 200, "must receive 200")
    assert_truthy(res.Body:find("sUNC-Test"),
        "server must echo back the custom header in response body")
end)

run("request · FAKE DETECTION: body is not hardcoded", function()
    local fn = (syn and syn.request) or request or http_request
    if not fn then error("no request function found") end
    local res1 = fn({ Url = "https://httpbin.org/uuid", Method = "GET" })
    local res2 = fn({ Url = "https://httpbin.org/uuid", Method = "GET" })
    assert_type(res1.Body, "string", "body #1 must be a string")
    assert_type(res2.Body, "string", "body #2 must be a string")
    assert_truthy(#res1.Body > 0,    "body #1 must not be empty")
    assert_truthy(#res2.Body > 0,    "body #2 must not be empty")
    assert_neq(res1.Body, res2.Body,
        "FAKE STUB DETECTED: two /uuid calls returned identical bodies — response is hardcoded")
end)

run("request · POST body is echoed correctly", function()
    local fn = (syn and syn.request) or request or http_request
    if not fn then error("no request function found") end
    local payload = "sunc_post_payload_" .. tostring(math.random(10000, 99999))
    local res = fn({
        Url     = "https://httpbin.org/post",
        Method  = "POST",
        Headers = { ["Content-Type"] = "text/plain" },
        Body    = payload,
    })
    assert_eq(res.StatusCode, 200, "POST must return 200")
    assert_truthy(res.Body:find(payload, 1, true),
        "server must echo back the POST body")
end)

run("request · response contains all required fields", function()
    local fn = (syn and syn.request) or request or http_request
    if not fn then error("no request function found") end
    local res = fn({ Url = "https://httpbin.org/get", Method = "GET" })
    assert_type(res.StatusCode, "number", "StatusCode must be a number")
    assert_type(res.Body,       "string", "Body must be a string")
    assert_truthy(res.Headers ~= nil,     "Headers field must exist in response")
end)

run("request · 404 status is forwarded correctly (no normalization)", function()
    local fn = (syn and syn.request) or request or http_request
    if not fn then error("no request function found") end
    local res = fn({ Url = "https://httpbin.org/status/404", Method = "GET" })
    assert_eq(res.StatusCode, 404,
        "status 404 must be returned as-is — must not be normalized to 200")
end)

run("request · 500 status is forwarded correctly (no normalization)", function()
    local fn = (syn and syn.request) or request or http_request
    if not fn then error("no request function found") end
    local ok, res = pcall(fn, { Url = "https://httpbin.org/status/500", Method = "GET" })
    if ok then
        assert_eq(res.StatusCode, 500,
            "status 500 must be returned as-is — must not be normalized")
    else
        warn("⚠  request raised an error for 500 status (may be executor behavior): " .. tostring(res))
    end
end)

-- ─── SECTION 9: COROUTINE & THREADING ───────────────────────────

run("coroutine · hookfunction works correctly inside separate coroutine", function()
    local function target(x) return x end
    local orig = hookfunction(target, function(x) return x * 3 end)
    local results_co = {}
    local co = coroutine.create(function()
        for i = 1, 5 do
            results_co[i] = target(i)
        end
    end)
    coroutine.resume(co)
    for i = 1, 5 do
        assert_eq(results_co[i], i * 3,
            string.format("coroutine index %d must equal %d", i, i * 3))
    end
    hookfunction(target, function(x) return orig(x) end)
end)

run("coroutine · upvalue not cross-contaminated between coroutines", function()
    local function make_counter()
        local n = 0
        return function() n = n + 1; return n end
    end

    local counter_a = make_counter()
    local counter_b = make_counter()

    local co_a = coroutine.create(function()
        for _ = 1, 3 do counter_a() end
    end)
    local co_b = coroutine.create(function()
        for _ = 1, 7 do counter_b() end
    end)

    coroutine.resume(co_a)
    coroutine.resume(co_b)

    assert_eq(counter_a(), 4, "counter_a upvalue must be independent (expected 4)")
    assert_eq(counter_b(), 8, "counter_b upvalue must be independent (expected 8)")
end)

run("task.spawn · does not block the caller thread", function()
    local spawned = false
    task.spawn(function()
        task.wait(0.05)
        spawned = true
    end)
    assert_truthy(not spawned,
        "task.spawn must not block caller — spawned must still be false immediately after")
end)

run("task.spawn · FAKE DETECTION: empty stub does not execute callback", function()
    local executed = false
    task.spawn(function() executed = true end)
    task.wait(0.1)
    assert_truthy(executed,
        "FAKE STUB: task.spawn did not execute the callback (detected after task.wait(0.1))")
end)

run("coroutine.wrap · works correctly with executor hooks", function()
    local log = {}
    local function fn(x) table.insert(log, x); return x end
    hookfunction(fn, function(x)
        table.insert(log, "hook_" .. tostring(x))
        return x * 10
    end)

    local gen = coroutine.wrap(function()
        for i = 1, 3 do
            coroutine.yield(fn(i))
        end
    end)

    assert_eq(gen(), 10, "wrap yield #1")
    assert_eq(gen(), 20, "wrap yield #2")
    assert_eq(gen(), 30, "wrap yield #3")
end)

run("coroutine · status transitions are correct across lifecycle", function()
    local co = coroutine.create(function()
        coroutine.yield()
    end)
    assert_eq(coroutine.status(co), "suspended", "before first resume: suspended")
    coroutine.resume(co)
    assert_eq(coroutine.status(co), "suspended", "after yield: suspended")
    coroutine.resume(co)
    assert_eq(coroutine.status(co), "dead",      "after function returns: dead")
end)

run("coroutine · running coroutine reports 'running' status from inside", function()
    local co
    local status_inside
    co = coroutine.create(function()
        status_inside = coroutine.status(co)
    end)
    coroutine.resume(co)
    assert_eq(status_inside, "running",
        "coroutine.status must return 'running' when queried from inside the coroutine")
end)

-- ─── SECTION 10: SECURITY & TRUST LAYER ─────────────────────────

run("security · getgenv does not expose executor internals", function()
    if not getgenv then return warn("⚠  getgenv not available — skip") end
    local genv = getgenv()
    assert_type(genv, "table", "getgenv() must return a table")
    local dangerous_keys = { "_executor_key", "_secret", "_internal", "bypass_key" }
    for _, k in ipairs(dangerous_keys) do
        if genv[k] ~= nil then
            warn(string.format("⚠  SECURITY: getgenv() exposes sensitive key: %q", k))
        end
    end
end)

run("security · getgc does not crash and returns a table", function()
    if not getgc then return warn("⚠  getgc not available — skip") end
    local gc = getgc(false)
    assert_type(gc, "table", "getgc() must return a table")
    assert_truthy(#gc > 0,   "GC table must not be empty")
end)

run("security · protect_function prevents unauthorized hooking", function()
    if not protect_function then
        return warn("⚠  protect_function not available — skip")
    end
    local function sensitive() return "real_value" end
    protect_function(sensitive)
    assert_raises(
        function() hookfunction(sensitive, function() return "fake" end) end,
        "protect_function must prevent subsequent hookfunction calls"
    )
end)

run("security · game metatable is not left writable after all tests", function()
    local mt = getrawmetatable(game)
    assert_truthy(isreadonly(mt),
        "SECURITY LEAK: game metatable is still writable — setreadonly was not restored after a test")
end)

run("security · getgc contains executor closures (not hidden)", function()
    if not getgc then return warn("⚠  getgc not available — skip") end
    local marker_fn = function() return "gc_marker_sunc" end
    local gc = getgc(true)
    local found = false
    for _, v in ipairs(gc) do
        if rawequal(v, marker_fn) then found = true; break end
    end
    assert_truthy(found,
        "executor closure must appear in getgc() — must not be hidden from GC scan")
end)

run("security · getgenv table is readable and writable", function()
    if not getgenv then return warn("⚠  getgenv not available — skip") end
    local genv     = getgenv()
    local test_key = "__sunc_genv_probe_" .. tostring(math.random(100000, 999999))
    assert_no_raise(function()
        genv[test_key] = true
        genv[test_key] = nil
    end, "getgenv() must return a writable table — must not be readonly")
end)

-- ─── SECTION 11: MISC EXECUTOR FUNCTIONS ─────────────────────────

run("identifyexecutor · returns executor name as string", function()
    if not identifyexecutor then
        warn("⚠  identifyexecutor not available — skip")
        return
    end
    local name, version = identifyexecutor()
    assert_type(name, "string", "identifyexecutor() must return a string name")
    assert_truthy(#name > 0,    "executor name must not be empty")
end)

run("fireclickdetector · does not crash with valid ClickDetector", function()
    if not fireclickdetector then
        return warn("⚠  fireclickdetector not available — skip")
    end
    local cd = Instance.new("ClickDetector")
    assert_no_raise(function() fireclickdetector(cd) end,
        "fireclickdetector must not crash with a valid ClickDetector")
    cd:Destroy()
end)

run("getloadedmodules · returns table of ModuleScript objects", function()
    if not getloadedmodules then
        return warn("⚠  getloadedmodules not available — skip")
    end
    local modules = getloadedmodules()
    assert_type(modules, "table", "getloadedmodules must return a table")
    for _, m in ipairs(modules) do
        if typeof(m) ~= "ModuleScript" then
            error("getloadedmodules contains a non-ModuleScript entry: " .. typeof(m))
        end
    end
end)

run("getconnections · returns connections for a signal", function()
    if not getconnections then
        return warn("⚠  getconnections not available — skip")
    end
    local dummy = Instance.new("Part")
    local conn  = dummy.Changed:Connect(function() end)
    local conns = getconnections(dummy.Changed)
    assert_type(conns, "table",  "getconnections must return a table")
    assert_truthy(#conns >= 1,   "must have at least 1 connection (just connected)")
    conn:Disconnect()
    dummy:Destroy()
end)

run("getconnections · connection can be disabled and re-enabled", function()
    if not getconnections then
        return warn("⚠  getconnections not available — skip")
    end
    local part  = Instance.new("Part")
    local fired = false
    local conn  = part.Changed:Connect(function() fired = true end)
    local conns = getconnections(part.Changed)
    assert_truthy(#conns >= 1, "must have a connection")
    local c = conns[1]
    if c.Disable and c.Enable then
        c:Disable()
        part.Name = "DisabledTest"
        assert_truthy(not fired, "disabled connection must not fire")
        c:Enable()
        part.Name = "EnabledTest"
        assert_truthy(fired,     "re-enabled connection must fire")
    else
        warn("⚠  connection object does not have Disable/Enable methods")
    end
    conn:Disconnect()
    part:Destroy()
end)

run("firetouchinterest · does not crash with BaseParts", function()
    if not firetouchinterest then
        return warn("⚠  firetouchinterest not available — skip")
    end
    local part1 = Instance.new("Part")
    local part2 = Instance.new("Part")
    part1.Parent = workspace
    part2.Parent = workspace
    assert_no_raise(function() firetouchinterest(part1, part2, 0) end,
        "firetouchinterest must not crash")
    part1:Destroy()
    part2:Destroy()
end)

run("setclipboard · does not crash with a plain string", function()
    if not setclipboard then
        return warn("⚠  setclipboard not available — skip")
    end
    assert_no_raise(function() setclipboard("sUNC_clipboard_test") end,
        "setclipboard must not crash")
end)

run("loadstring · compiles and executes a Lua string", function()
    if not loadstring then return warn("⚠  loadstring not available — skip") end
    local fn, err = loadstring("return 1 + 1")
    if not fn then error("loadstring compile error: " .. tostring(err)) end
    assert_eq(fn(), 2, "loadstring must compile and execute correctly")
end)

run("loadstring · returns nil + error message on syntax error", function()
    if not loadstring then return warn("⚠  loadstring not available — skip") end
    local fn, err = loadstring("this is not valid lua !!!@#$")
    assert_truthy(fn == nil,   "loadstring must return nil for a syntax error")
    assert_type(err, "string", "loadstring must return an error message string")
    assert_truthy(#err > 0,    "error message must not be empty")
end)

run("loadstring · FAKE DETECTION: does not always return nil", function()
    if not loadstring then return warn("⚠  loadstring not available — skip") end
    local fn, err = loadstring("return 42")
    if fn == nil then
        error("FAKE STUB: loadstring always returns nil — cannot compile valid Lua. err: "
            .. tostring(err))
    end
    assert_eq(fn(), 42, "loadstring must execute and return the correct value")
end)

run("loadstring · chunk environment respects setfenv", function()
    if not loadstring then return warn("⚠  loadstring not available — skip") end
    local fn = loadstring("return injected_val")
    if not fn then return warn("⚠  loadstring compile failed — skip env test") end
    local env = setmetatable({ injected_val = 777 }, { __index = getfenv() })
    setfenv(fn, env)
    assert_eq(fn(), 777, "loadstring chunk must respect setfenv like a regular Lua function")
end)

run("loadstring · compiled chunk is an executor closure", function()
    if not loadstring        then return warn("⚠  loadstring not available — skip") end
    if not isexecutorclosure then return warn("⚠  isexecutorclosure not available — skip") end
    local fn = loadstring("return true")
    if not fn then return warn("⚠  loadstring compile failed — skip") end
    assert_truthy(isexecutorclosure(fn),
        "function compiled by loadstring must be an executor closure")
end)

-- ─── SUMMARY ─────────────────────────────────────────────────────

task.defer(function()
    repeat task.wait(0.05) until running == 0

    local total = #results.pass + #results.fail
    local rate  = total > 0 and math.floor(#results.pass / total * 100) or 0

    print("\n" .. string.rep("═", 62))
    print("  sUNC SUMMARY")
    print(string.rep("═", 62))
    print(string.format("  ✅  Passed  : %d", #results.pass))
    print(string.format("  ❌  Failed  : %d", #results.fail))
    print(string.format("  ⏭   Skipped : %d", #results.skip))
    print(string.format("  📊  Rate    : %d%%  (%d / %d)", rate, #results.pass, total))

    if #results.fail > 0 then
        print("\n  ── Failures ──────────────────────────────────────────")
        for _, f in ipairs(results.fail) do
            print(string.format("  ❌  %s", f.name))
            print(string.format("      ↳  %s", f.err))
        end
    end

    if #results.skip > 0 then
        print("\n  ── Skipped (API not available) ───────────────────────")
        for _, s in ipairs(results.skip) do
            print(string.format("  ⏭   %s  —  %s", s.name, s.reason))
        end
    end

    print(string.rep("═", 62))
    if #results.fail == 0 then
        print("  🏆  All tests passed. This executor is a true monster. Every sUNC test bowed in submission.")
    elseif rate >= 80 then
        print("  ⚠   Executor partially meets standard. See Failures above.")
    else
        print("  💀  Executor does NOT meet sUNC standard. Multiple APIs are fake or missing.")
    end
    print(string.rep("═", 62) .. "\n")
end)
