---
--提供一组常用函数
--@module LuaFunctions
--@author myc

---检查并尝试转换为数值，如果无法转换则返回 0
--@string value 要检查的值
--@param base 进制，默认为十进制
--@return number
function checknumber(value, base)
    return tonumber(value, base) or 0
end


---检查并尝试转换为数值，如果无法转换则返回 0
--@string value 要检查的值
--@return integer
function checkint(value)
    return math.round(checknumber(value))
end

--[[--
检查并尝试转换为布尔值，除了 nil 和 false，其他任何值都会返回 true
@string value 图片本地地址
@return boolean
]]
function checkbool(value)
    return (value ~= nil and value ~= false)
end


---检查值是否是一个表格，如果不是则返回一个空表格
--@string value 要检查的值
--@return table
function checktable(value)
    if type(value) ~= "table" then value = {} end
    return value
end


---如果表格中指定 key 的值为 nil，或者输入值不是表格，返回 false，否则返回 true
--@param hashtable 要检查的表格
--@param key 要检查的键名
--@return boolean
function isset(hashtable, key)
    local t = type(hashtable)
    return (t == "table" or t == "userdata") and hashtable[key] ~= nil
end

---深度克隆一个值
--@param object 要克隆的值
--@return copyObj
--@usage
-- --下面的代码，t2 是 t1 的引用，修改 t2 的属性时，t1 的内容也会发生变化
-- local t1 = {a = 1, b = 2}
-- local t2 = t1
-- t2.b = 3    -- t1 = {a = 1, b = 3} <-- t1.b 发生变化
-- clone() 返回 t1 的副本，修改 t2 不会影响 t1
-- local t1 = {a = 1, b = 2}
-- local t2 = clone(t1)
-- t2.b = 3    -- t1 = {a = 1, b = 2} <-- t1.b 不受影响
function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end