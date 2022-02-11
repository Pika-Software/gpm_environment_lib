local assert = assert
local type = type

module( "environment", package.seeall )

local environments = {}
local functions = {
    ["null"] = function() end
}

--[[-------------------------------------------------------------------------
    Functions Caching
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
    Environments
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

    end

end

do
    local table_Copy = table.Copy
    function getAll()
        return table_Copy( environments )
    end
end

function getName( env )
    if isEnvironment( env ) then
        return env:getName()
    end
end

function remove( any )
    environments[ any ] = nil
end