-- Add project root to package path
local script_path = debug.getinfo(1).source:match("@?(.*/)") or "./"
package.path = script_path .. "?.lua;" .. script_path .. "lua/?.lua;" .. package.path

-- Clear cached llm_flow modules
for k in pairs(package.loaded) do
    if k:match("^llm_flow") then
        package.loaded[k] = nil
    end
end

-- Get module and function from args
local module_name = arg[1]
local func_name = arg[2]

if not module_name or not func_name then
    print("Usage: lua run.lua <module_name> <function_name>")
    os.exit(1)
end

-- Require module and call function
local ok, module = pcall(require, module_name)
if not ok then
    print("Error loading module:", module)
    os.exit(1)
end

local func = module[func_name]
if not func then
    print("Function " .. func_name .. " not found in module " .. module_name)
    os.exit(1)
end

-- Call function and pretty print result
local function pretty_print(value, indent)
    indent = indent or ""
    if type(value) == "table" then
        local result = "{\n"
        for k, v in pairs(value) do
            result = result .. indent .. "  " .. tostring(k) .. " = "
            result = result .. pretty_print(v, indent .. "  "):gsub("^%s*(.-)%s*$", "%1") .. ",\n"
        end
        return result .. indent .. "}"
    else
        return tostring(value)
    end
end

local ok, result = pcall(func)
if not ok then
    print("Error calling function:", result)
    os.exit(1)
end

print(pretty_print(result))
