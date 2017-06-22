---
--提供一组常用函数，以及对 Lua 标准库的扩展
--@module LuaFunctions
--@author myc

--[[--
载入一个模块

@usage
import() 与 require() 功能相同，但具有一定程度的自动化特性。
假设我们有如下的目录结构：
app/
app/classes/
app/classes/MyClass.lua
app/classes/MyClassBase.lua
app/classes/data/Data1.lua
app/classes/data/Data2.lua
MyClass 中需要载入 MyClassBase 和 MyClassData。如果用 require()，MyClass 内的代码如下:
local MyClassBase = require("app.classes.MyClassBase")
local MyClass = class("MyClass", MyClassBase)

local Data1 = require("app.classes.data.Data1")
local Data2 = require("app.classes.data.Data2")

--假如我们将 MyClass 及其相关文件换一个目录存放，那么就必须修改 MyClass 中的 require() 命令，否则将找不到模块文件。
--而使用 import()，我们只需要如下写：

local MyClassBase = import(".MyClassBase")
local MyClass = class("MyClass", MyClassBase)

local Data1 = import(".data.Data1")
local Data2 = import(".data.Data2")


当在模块名前面有一个"." 时，import() 会从当前模块所在目录中查找其他模块。因此 MyClass 及其相关文件不管存放到什么目录里，我们都不再需要修改 MyClass 中的 import() 命令。这在开发一些重复使用的功能组件时，会非常方便。

我们可以在模块名前添加多个"." ，这样 import() 会从更上层的目录开始查找模块。


不过 import() 只有在模块级别调用（也就是没有将 import() 写在任何函数中）时，才能够自动得到当前模块名。如果需要在函数中调用 import()，那么就需要指定当前模块名：

MyClass.lua

这里的 ...     是隐藏参数，包含了当前模块的名字，所以最好将这行代码写在模块的第一行

local CURRENT_MODULE_NAME = ...
local function testLoad()
    local MyClassBase = import(".MyClassBase", CURRENT_MODULE_NAME)
end

@param moduleName 要载入的模块的名字
@param currentModuleNameParts 当前模块名
@return module

]]
function import(moduleName, currentModuleName)
    local currentModuleNameParts
    local moduleFullName = moduleName
    local offset = 1

    while true do
        -- print("moduleName " .. moduleName);
        if string.byte(moduleName, offset) ~= 46 then -- .
            moduleFullName = string.sub(moduleName, offset)
            -- print("moduleFullName1 " .. moduleFullName);
            if currentModuleNameParts and #currentModuleNameParts > 0 then
                moduleFullName = table.concat(currentModuleNameParts, ".") .. "." .. moduleFullName
            end
            break
        end
        offset = offset + 1

        if not currentModuleNameParts then
            if not currentModuleName then
                local n,v = debug.getlocal(3, 1)
                currentModuleName = v
                -- print("moduleFullName2 ",currentModuleName);
            end
            if currentModuleName and type(currentModuleName) == "string" then
                ---如果以/引用 则转换成.
                if string.find(currentModuleName, "/%.", 1) then
                    currentModuleNameParts = string.split(currentModuleName, "%.")    
                else
                    currentModuleName = string.gsub(currentModuleName, "/", "%.")
                    currentModuleNameParts = string.split(currentModuleName, "%.")
                end
            end


        end
        if currentModuleNameParts then
            table.remove(currentModuleNameParts, #currentModuleNameParts)
        end
        
    end
    local m = require(moduleFullName);
    if m and type(m) == "table" then
        -- m.moduleFullName_ = moduleFullName
    end
    return m
end

function g_reload(moduleName)
    if moduleName then
        package.loaded[moduleName] = nil
        return require(moduleName)
    end
end



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

---检查并尝试转换为布尔值，除了 nil 和 false，其他任何值都会返回 true
--@string value 要检查的值
--@return boolean
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


--[[--
将 Lua 对象及其方法包装为一个匿名函数

@usage
~~~ lua

local MyScene = class()

function MyScene:ctor()
    self.frameTimeCount = 0
    -- 注册回调函数
    self:setCallBack(self,self.onEnterFrame)
end

--注册回调函数
function MyScene:setCallBack(obj, method)
    self.callBackObj = obj;
    self.callBackMethod = method;
end

--执行回调函数
function MyScene:doCallBack()
    self.callBackMethod(self.callBackObj);
end

~~~

上述代码执行时没有问题，但是却持有了回调函数的对象（obj）
此时开发者可以访问改对象，并且如果当前类(MyScene) 如果释放不干净
则导致obj也被引用这 释放不掉(lua 强引用)

~~~ lua handler

local MyScene = class()

function MyScene:ctor()
    self.frameTimeCount = 0
    -- 注册回调函数
    self:setCallBack(handler(self,self.onEnterFrame))
end

--注册回调函数
function MyScene:setCallBack(omethod)
    self.callBackMethod = method;
end

--执行回调函数
function MyScene:doCallBack()
    self.callBackMethod();
end

~~~

使用 handler() 的好处是回调的类不需要持有回调函数的类，可以减少引用。

@param obj Lua 对象
@param method 对象方法

@return function
]]
function handler(obj, method)
    return function(...)
        if method and obj then
           return method(obj, ...)
        end    
    end
end

---根据系统时间初始化随机数种子，让后续的 math.random() 返回更随机的值
function math.newrandomseed()
    math.randomseed(os.clock()*10000 + os.time())
    math.random()
    math.random()
    math.random()
    math.random()
end


---
---对数值进行四舍五入，如果不是数值则返回 0
-- @param value 输入值
-- @return number
function math.round(value)
    value = checknumber(value)
    return math.floor(value + 0.5)
end

---
-- 角度转弧度
-- @param angle 角度值
-- @return number 弧度值
function math.angle2radian(angle)
    return angle*math.pi/180
end

---
-- 弧度转角度
-- @param angle 弧度
-- @return number 角度
function math.radian2angle(radian)
    return radian/math.pi*180
end



--[[--
计算表格包含的字段数量



Lua table 的 "#" 操作只对依次排序的数值下标数组有效，table.nums() 则计算 table 中所有不为 nil 的值的个数。

@param t 要计算的表格
@return integer
]]
function table.nums(t)
    local temp = checktable(t)
    local count = 0
    for k, v in pairs(temp) do
        count = count + 1
    end
    return count
end


--[[--
将来源表格中所有键及其值复制到目标表格对象中，如果存在同名键，则覆盖其值

@usage
local dest = {a = 1, b = 2}
local src  = {c = 3, d = 4}
table.merge(dest, src)
-- dest = {a = 1, b = 2, c = 3, d = 4}

@param dest 目标表格
@param src  来源表格
]]
function table.merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

--[[--
合并两个表格的内容

@usage
local src1 = {a = 1, b = 2}
local src2  = {c = 3, d = 4}
local temp = table.merge(src1, src2)
-- src1 = {a = 1, b = 2}
-- temp = {a = 1, b = 2, c = 3, d = 4}

@param src1 来源表格1
@param src2 来源表格2
]]
function table.merge2(src1, src2)
    local tb ={}
    for k, v in pairs(src1) do
        table.insert(tb,v);
    end
    for k, v in pairs(src2) do
        table.insert(tb,v);
    end
    return tb;
end


--[[--
同步数据,把tab2 的数据同步到 tab1（不是合并）

@usage
local tab1 = {c = 1, b = 2,g=9}
local tab2  = {c = 3, d = 4}
table.sync(tab1, tab2)
-- tab1  = {c = 3, b = 2,g=9}
-- tab2  = {c = 3, d = 4}
@param tab1 来源表格1
@param tab2 来源表格2
]]
function table.sync(tab1, tab2)
    for k, v in pairs(tab2) do
        if tab1[k] ~= nil then
           tab1[k] = v;
        end
    end
end

--[[--
从表格中查找指定值，返回其 key，如果没找到返回 nil

@usage
local hashtable = {name = "dualface", comp = "chukong"}
print(table.keyof(hashtable, "chukong")) -- 输出 comp

@param table hashtable 表格
@param mixed value 要查找的值
@return string 该值对应的 key

]]
function table.keyof(hashtable, value)
    for k, v in pairs(hashtable) do
        if v == value then return k end
    end
    return nil
end

--[[--
从表格中查找指定值，返回其索引，如果没找到返回 false
@function [parent=#table] indexof
@param table array 表格
@param mixed value 要查找的值
@param integer begin 起始索引值
@return integer#integer 

从表格中查找指定值，返回其索引，如果没找到返回 false

]]

function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then return i end
    end
    return false
end

--[[--
从表格中删除指定值，返回删除的值的个数

@param table array 表格
@param mixed value 要删除的值
@param [boolean removeall] 是否删除所有相同的值

@usage 
local array = {"a", "b", "c", "c"}
print(table.removebyvalue(array, "c", true)) -- 输出 2

@return integer
]]
function table.removeByValue(array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table.remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end

-- object.lua
-- Author: Vicent Gong
-- Date: 2012-09-30
-- Last modification : 2013-5-29
-- Description: Provide object mechanism for lua
--[[--
@usage
import() 与 require() 功能相同，但具有一定程度的自动化特性。
假设我们有如下的目录结构：
app/
app/classes/
app/classes/MyClass.lua
app/classes/MyClassBase.lua
app/classes/data/Data1.lua
app/classes/data/Data2.lua
MyClass 中需要载入 MyClassBase 和 MyClassData。如果用 require()，MyClass 内的代码如下:
local MyClassBase = require("app.classes.MyClassBase")
local MyClass = class("MyClass", MyClassBase)

local Data1 = require("app.classes.data.Data1")
local Data2 = require("app.classes.data.Data2")

--假如我们将 MyClass 及其相关文件换一个目录存放，那么就必须修改 MyClass 中的 require() 命令，否则将找不到模块文件。
--而使用 import()，我们只需要如下写：

local MyClassBase = import(".MyClassBase")
local MyClass = class("MyClass", MyClassBase)

local Data1 = import(".data.Data1")
local Data2 = import(".data.Data2")


当在模块名前面有一个"." 时，import() 会从当前模块所在目录中查找其他模块。因此 MyClass 及其相关文件不管存放到什么目录里，我们都不再需要修改 MyClass 中的 import() 命令。这在开发一些重复使用的功能组件时，会非常方便。

我们可以在模块名前添加多个"." ，这样 import() 会从更上层的目录开始查找模块。


不过 import() 只有在模块级别调用（也就是没有将 import() 写在任何函数中）时，才能够自动得到当前模块名。如果需要在函数中调用 import()，那么就需要指定当前模块名：

MyClass.lua

这里的 ...     是隐藏参数，包含了当前模块的名字，所以最好将这行代码写在模块的第一行

local CURRENT_MODULE_NAME = ...
local function testLoad()
    local MyClassBase = import(".MyClassBase", CURRENT_MODULE_NAME)
end

@param moduleName 要载入的模块的名字
@param currentModuleNameParts 当前模块名
@return module

]]
-- function import(moduleName, currentModuleName)
--     local currentModuleNameParts
--     local moduleFullName = moduleName
--     local offset = 1

--     while true do
--         if string.byte(moduleName, offset) ~= 46 then -- .
--             moduleFullName = string.sub(moduleName, offset)
--             -- print("moduleFullName1 " .. moduleFullName);
--             if currentModuleNameParts and #currentModuleNameParts > 0 then
--                 moduleFullName = table.concat(currentModuleNameParts, ".") .. "." .. moduleFullName
--             end
--             break
--         end
--         offset = offset + 1

--         if not currentModuleNameParts then
--             if not currentModuleName then
--                 local n,v = debug.getlocal(3, 1)
--                 currentModuleName = v
--                 -- print("moduleFullName2 " .. currentModuleName);
--             end

--             currentModuleNameParts = string.split(currentModuleName, ".")
--             -- dump(currentModuleNameParts)
--         end
--         table.remove(currentModuleNameParts, #currentModuleNameParts)
--     end
--     -- print("moduleFullName " .. moduleFullName);
--     return require(moduleFullName)
-- end

--通过判断类型
--返回值顺序 table, boolean, string
--总的有如下N种情况
--1) super, autoConstructSuper, name
--1) super, name, autoConstructSuper
--2) name, super, autoConstructSuper
--3) name, autoConstructSuper,super
local function changeParamsName( p1, p2, p3 )
    if type(p1) == "table" then
        if type(p2) == "boolean" then
            return p1,p2,p3;
        end
        if type(p2) == "string" then
            return p1,p3,p2
        end
    end

    if type(p1) == "string" then
        if type(p2) == "table" then
            return p2,p3,p1
        end

        if type(p2) == "boolean" then
            return p3,p2,p1
        end
    end
end


-- Note for the object model here:
--      1.The feature like C++ static members is not support so perfect.
--      What that means is that if u need something like c++ static members,
--      U can access it as a rvalue like C++, but if u need access it
--      as a lvalue u must use [class.member] to access,but not [object.member].
--      2.The function delete cannot release the object, because the gc is based on 
--      reference count in lua.If u want to relase all the object memory, u have to 
--      set the obj to nil to enable lua gc to recover the memory after calling delete.


---------------------Global functon class ---------------------------------------------------
--Parameters:   super               -- The super class
--              autoConstructSuper   -- If it is true, it will call super ctor automatic,when 
--                                      new a class obj. Vice versa.
--Return    :   return an new class type
--Note      :   This function make single inheritance possible.
---------------------------------------------------------------------------------------------
function class(super, autoConstructSuper,name)
    super, autoConstructSuper, name = changeParamsName(super, autoConstructSuper, name)
    local classType = {};
    classType.autoConstructSuper = autoConstructSuper or (autoConstructSuper == nil);
    
    if super then
        classType.super = super;
        local mt = getmetatable(super);
        setmetatable(classType, { __index = super; __newindex = mt and mt.__newindex;});

    else
        classType.setDelegate = function(self,delegate)
            self.m_delegate = delegate;
        end
    end

    if name then
        classType.className__ = name;
    end

    return classType;
end

---------------------Global functon super ----------------------------------------------
--Parameters:   obj         -- The current class which not contruct completely.
--              ...         -- The super class ctor params.
--Return    :   return an class obj.
--Note      :   This function should be called when newClass = class(super,false).
-----------------------------------------------------------------------------------------
function super(obj, ...)
    do 
        local create;
        create =
            function(c, ...)
                if c.super and c.autoConstructSuper then
                    create(c.super, ...);
                end
                if rawget(c,"ctor") then
                    obj.currentSuper = c.super;
                    c.ctor(obj, ...);
                end
            end

        create(obj.currentSuper, ...);
    end
end

---------------------Global functon new -------------------------------------------------
--Parameters:   classType -- Table(As Class in C++)
--              ...        -- All other parameters requisted in constructor
--Return    :   return an object
--Note      :   This function is defined to simulate C++ new function.
--              First it called the constructor of base class then to be derived class's.
-----------------------------------------------------------------------------------------
function new(classType, ...)
    local obj = {};
    local mt = getmetatable(classType);
    setmetatable(obj, { __index = classType; __newindex = mt and mt.__newindex;});
    do
        local create;
        create =
            function(c, ...)
                if c.super and c.autoConstructSuper then
                    create(c.super, ...);
                end
                if rawget(c,"ctor") then
                    obj.currentSuper = c.super;
                    c.ctor(obj, ...);
                end
            end

        create(classType, ...);
    end
    obj.currentSuper = nil;
    return obj;
end

---------------------Global functon delete ----------------------------------------------
--Parameters:   obj -- the object to be deleted
--Return    :   no return
--Note      :   This function is defined to simulate C++ delete function.
--              First it called the destructor of derived class then to be base class's.
-----------------------------------------------------------------------------------------
function delete(obj)
    do
        local destory =
            function(c)
                while c do
                    if rawget(c,"dtor") then
                        c.dtor(obj);
                    end
              
                    c = getmetatable(c);
                    c = c and c.__index;                   
                end
            end
        destory(obj);
    end
end

---------------------Global functon delete ----------------------------------------------
--Parameters:   class       -- The class type to add property
--              varName     -- The class member name to be get or set
--              propName    -- The name to be added after get or set to organize a function name.
--              createGetter-- if need getter, true,otherwise false.
--              createSetter-- if need setter, true,otherwise false.
--Return    :   no return
--Note      :   This function is going to add get[PropName] / set[PropName] to [class].
-----------------------------------------------------------------------------------------
function property(class, varName, propName, createGetter, createSetter)
    createGetter = createGetter or (createGetter == nil);
    createSetter = createSetter or (createSetter == nil);
    
    if createGetter then
        class[string.format("get%s",propName)] = function(self)
            return self[varName];
        end
    end
    
    if createSetter then
        class[string.format("set%s",propName)] = function(self,var)
            self[varName] = var;
        end
    end
end

---------------------Global functon delete ----------------------------------------------
--Parameters:   obj         -- A class object
--              classType   -- A class
--Return    :   return true, if the obj is a object of the classType or a object of the 
--              classType's derive class. otherwise ,return false;
-----------------------------------------------------------------------------------------
function typeof(obj, classType)
    if type(obj) ~= type(table) or type(classType) ~= type(table) then
        return type(obj) == type(classType);
    end
    
    while obj do
        if obj == classType then
            return true;
        end
        obj = getmetatable(obj) and getmetatable(obj).__index;
    end
    return false;
end

---------------------Global functon delete ----------------------------------------------
--Parameters:   obj         -- A class object
--Return    :   return the object's type class.
-----------------------------------------------------------------------------------------
function decltype(obj)
    if type(obj) ~= type(table) or obj.autoConstructSuper == nil then
        --error("Not a class obj");
        return nil;
    end
    
    if rawget(obj,"autoConstructSuper") ~= nil then
        --error("It is a class but not a class obj");
        return nil;
    end
        
    local class = getmetatable(obj) and getmetatable(obj).__index;
    if not class then
        --error("No class reference");
        return nil;
    end
    
    return class;
end