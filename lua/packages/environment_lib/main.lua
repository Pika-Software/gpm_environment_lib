local assert = assert
local type = type

module( "environment", package.seeall )

local environments = {}
local functions = {
    ["null"] = function() end
}

--[[-------------------------------------------------------------------------
    Working on Functions
---------------------------------------------------------------------------]]

function saveFunc( name, func, override )
	assert( type( name ) == "string", "bad argument #1 (string expected)" )
    assert( name ~= "null", "You can't just go ahead and overwrite a 'null' function." )
    assert( type( func ) == "function", "bad argument #2 (function expected)" )

    if (functions[ name ] == nil) or (override == true) then
        functions[ name ] = func
    end

    return functions[ name ]
end

function loadFunc( name )
    return functions[ name ] or functions["null"]
end

function removeFunc( name )
	assert( type( name ) == "string", "bad argument #1 (string expected)" )
    assert( name ~= "null", "You can't just go ahead and remove a 'null' function." )
    functions[ name ] = nil
end

--[[-------------------------------------------------------------------------
    Working on Environments
---------------------------------------------------------------------------]]

function global()
    return _G
end

do

    local ENV = {}
    ENV["__index"] = ENV
    debug.getregistry().Environment = ENV

    do

        function ENV:getID()
            return self["__env"]["id"]
        end

        function ENV:getName()
            return self["__env"]["identifier"]
        end

        function ENV:__tostring()
            return "GLua Environment - " .. self:getName() .. " [" .. self:getID() .. "]"
        end

        function ENV:replace( name, func )
            assert( type( name ) == "string", "bad argument #1 (string expected)" )
            self[ name ] = func or functions["null"]
        end

    end

    do
        local getmetatable = getmetatable
        function isEnvironment( any )
            return getmetatable( any ) == ENV
        end
    end

    do

        local emptyTable = {}

        do

            local table_Count = table.Count
            local setmetatable = setmetatable

            function new( any, builder, override )
                assert( type( any ) == "string", "bad argument #1 (string expected)" )

                if (environments[ any ] == nil) or (override == true) then
                    local env = {}
                    if type( builder ) == "function" then
                        env = builder( any ) or env
                    elseif type( builder ) == "table" then
                        env = builder
                    end

                    if ( type( env ) == "table" ) then
                        env["__env"] = {
                            ["identifier"] = any,
                            ["id"] = table_Count( environments ) + 1
                        }

                        environments[ any ] = setmetatable( env, ENV )
                    end
                end

                return environments[ any ] or emptyTable
            end

        end

        function get( any )
            return environments[ any ] or emptyTable
        end

        function remove( any )
            environments[ any ] = nil
        end

    end

end

function getName( env )
    if isEnvironment( env ) then
        return env:getName()
    end

    return "GLua Environment"
end

do
    local table_Copy = table.Copy
    function getAll()
        return table_Copy( environments )
    end
end

do
    local runExtensions = {
        ["lua"] = true,
        ["dat"] = true,
        ["txt"] = true
    }

    function isIncludeExtension( ext )
        return runExtensions[ ext ] or false
    end
end

do

    local CompileFile = CompileFile
    local file_Exists = file.Exists
    local debug_setfenv = debug.setfenv

    function include( path, environment, gamePath )
        if file_Exists( path, gamePath or "GAME" ) and isIncludeExtension( path:GetExtensionFromFilename() ) then
            local func = nil

            local luaCode = file.Read( path, gamePath or "GAME" )
            if (luaCode == nil) or (luaCode == "") then
                func = CompileFile( path )
            else
                func = CompileString( luaCode, getName( environment ) .. ": " .. path )
            end

            assert( type( func ) == "function", "Lua code compilation failed! <nil>" )

            if isEnvironment( environment ) then
                debug_setfenv( func, environment )
            end

            local ok, data = pcall( func )
            return (ok == true) and data
        end
    end
end