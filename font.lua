--- === hs._asm.text.font ===
---
--- Get information about fonts for use with Hammerspoon.

local module      = require("hs._asm.text.fontC")

-- private variables and methods -----------------------------------------

local _kMetaTable = {}
_kMetaTable._k = {}
_kMetaTable.__index = function(obj, key)
        if _kMetaTable._k[obj] then
            if _kMetaTable._k[obj][key] then
                return _kMetaTable._k[obj][key]
            else
                for k,v in pairs(_kMetaTable._k[obj]) do
                    if v == key then return k end
                end
            end
        end
        return nil
    end
_kMetaTable.__newindex = function(obj, key, value)
        error("attempt to modify a table of constants",2)
        return nil
    end
_kMetaTable.__pairs = function(obj) return pairs(_kMetaTable._k[obj]) end
_kMetaTable.__tostring = function(obj)
        local result = ""
        if _kMetaTable._k[obj] then
            local width = 0
            for k,v in pairs(_kMetaTable._k[obj]) do width = width < #k and #k or width end
            for k,v in require("hs.fnutils").sortByKeys(_kMetaTable._k[obj]) do
                result = result..string.format("%-"..tostring(width).."s %s\n", k, tostring(v))
            end
        else
            result = "constants table missing"
        end
        return result
    end
_kMetaTable.__metatable = _kMetaTable -- go ahead and look, but don't unset this

local _makeConstantsTable = function(theTable)
    local results = setmetatable({}, _kMetaTable)
    _kMetaTable._k[results] = theTable
    return results
end

local _arrayWrapper = function(results)
    return setmetatable(results, { __tostring=function(_)
        local results = ""
        for i,v in ipairs(_) do results = results..v.."\n" end
        return results
    end})
end

local _tableWrapper = function(results)
    local __tableWrapperFunction
    __tableWrapperFunction = function(_)
        local result = ""
        local width = 0
        for k,v in pairs(_) do width = width < #k and #k or width end
        for k,v in require("hs.fnutils").sortByKeys(_) do
            result = result..string.format("%-"..tostring(width).."s ", k)
            if type(v) == "table" then
                result = result..__tableWrapperFunction(v):gsub("[ \n]", {[" "] = "=", ["\n"] = " "}).."\n"
            else
                result = result..tostring(v).."\n"
            end
        end
        return result
    end

    return setmetatable(results, { __tostring=__tableWrapperFunction })
end

-- make a copy of the functions so we can wrap the public versions and provide console friendly
-- __tostring methods.
local internalModuleFunctions = {}
for i,v in pairs(module) do internalModuleFunctions[i] = v end

-- Public interface ------------------------------------------------------

module.traits = _makeConstantsTable(module.traits)

module.names = function(...)
    return _arrayWrapper(internalModuleFunctions.names(...))
end

module.namesWithTraits = function(...)
    return _arrayWrapper(internalModuleFunctions.namesWithTraits(...))
end

module.info = function(...)
    return _tableWrapper(internalModuleFunctions.info(...))
end

-- Return Module Object --------------------------------------------------

return module
