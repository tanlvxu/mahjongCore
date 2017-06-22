---
--序列化lua table
--@module luaUtil
--@author myc

local luaUtil = {};

local tostring = tostring
local type = type
local pairs = pairs
local ipairs = ipairs
local table_format = string.format
local string_len = string.len
local string_rep = string.rep


---数列化table 报错到文件
--@string t 表
--@string tabName 表名
--@retrurn tableStr
function luaUtil.serialize(t, tabName)
    local function dump(value, desciption, nesting)
    	local lookup = {}
    	local result = {}
    	if type(nesting) ~= "number" then nesting = 10 end

		local function _dump_value(v)
		    if type(v) == "string" then
		        v = "\"" .. v .. "\""
		    end
		    return tostring(v)
		end

		local function _dump_key(v)
		    if type(v) == "number" then
		        v = "[" .. v .. "]"
		    end
		    return v
		end

	    local function _dump(value, desciption, indent, nest, keylen)
	        desciption = desciption or "<var>"
	        local spc = ""
	        if type(keylen) == "number" then
	            spc = string_rep(" ", keylen - string_len(_dump_value(desciption)))
	        end

	        if type(value) ~= "table" then
	            result[#result +1 ] = table_format("%s%s%s = %s,", indent, _dump_key(desciption), spc, _dump_value(value))
	        elseif lookup[tostring(value)] then
	            result[#result +1 ] = table_format("%s%s%s = *REF*", indent, desciption, spc)
	        else
	            lookup[tostring(value)] = true
	            if nest > nesting then
	                result[#result +1 ] = table_format("%s%s = *MAX NESTING*", indent, desciption)
	            else
	            	result[#result +1 ] = table_format("%s%s = {", indent, _dump_key(desciption))
	                local indent2 = indent.."    "
	                local keys = {}
	                local keylen = 0
	                local values = {}
	                for k, v in pairs(value) do
	                    keys[#keys + 1] = k
	                    local vk = _dump_value(k)
	                    local vkl = string_len(vk)
	                    if vkl > keylen then keylen = vkl end
	                    values[k] = v
	                end
	                table.sort(keys, function(a, b)
	                    if type(a) == "number" and type(b) == "number" then
	                        return a < b
	                    else
	                        return tostring(a) < tostring(b)
	                    end
	                end)
	                for i, k in ipairs(keys) do
	                    _dump(values[k], k, indent2, nest + 1, keylen)
	                end
	                result[#result +1] = table_format("%s},", indent)
	            end
	        end
	    end

    	_dump(value, desciption, "", 1)
    	result[1] 		= "{";
    	result[#result] = "}";

    	local ret = ""
	    for i, line in ipairs(result) do
	        ret = ret .. line .. "\n";
	    end
	    return ret;
	end

	tabName = tabName or "ret"
    local str = "do local " .. tabName .. " =\n"..dump(t) .. string.format("\nreturn %s end",tabName);
    local path = sys_get_string("storage_tmp") .. "../scripts/"  .. tabName .. ".lua"
    luaUtil.writefile(str,path)
  
    return str;
end


function luaUtil.writefile(str, file)
    os.remove(file);
    local file=io.open(file,"ab");
    file:write(str);
    file:close();
end


function luaUtil.dumpToFile(tabName,t)
	return luaUtil.serialize(t,tabName)
end

dumpToFile = luaUtil.dumpToFile

return luaUtil;