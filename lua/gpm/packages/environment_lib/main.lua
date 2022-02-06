local assert = assert
local type = type

environment = environment or {
    ["Environments"] = {},
    ["Functions"] = {
        ["Null"] = function()end
    }
}

function environment.saveFunc( name, func, override )
	assert( type( name ) == "string", "bad argument #1 (string expected)" )
    assert( name != "Null", "You can't just go ahead and overwrite a 'Null' function." )
    assert( type( func ) == "function", "bad argument #2 (function expected)" )

    if (environment["Functions"][name] == nil) or (override == true) then
        environment["Functions"][name] = func
    end

    return environment["Functions"][name]
end

function environment.loadFunc( name )
    return environment["Functions"][name] or environment["Functions"]["Null"]
end

function environment.new( name, builder, override )
	assert( type( name ) == "string", "bad argument #1 (string expected)" )

    local env = {}
    if type( builder ) == "function" then
        env = builder( name )
    end

    env["__environmentName"] = name

    if ((environment["Environments"][name] == nil) and type( env ) == "table") or (override == true) then
        environment["Environments"][name] = env
    end

    return environment["Environments"][name] or {}
end

function environment.load( name )
    return environment["Environments"][name] or {}
end

function environment.getName( env )
    return type( env ) == "table" and env["__environmentName"] or nil
end

function isEnvironment( any )
    return type( any ) == "table" and (any["__environmentName"] != nil)
end

function environment.global()
    return _G
end