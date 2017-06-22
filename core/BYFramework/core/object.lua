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
function import(moduleName, currentModuleName)
    local currentModuleNameParts
    local moduleFullName = moduleName
    local offset = 1

    while true do
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
                -- print("moduleFullName2 " .. currentModuleName);
            end

            currentModuleNameParts = string.split(currentModuleName, ".")
            -- dump(currentModuleNameParts)
        end
        table.remove(currentModuleNameParts, #currentModuleNameParts)
    end
    -- print("moduleFullName " .. moduleFullName);
    return require(moduleFullName)
end

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
--		1.The feature like C++ static members is not support so perfect.
--		What that means is that if u need something like c++ static members,
--		U can access it as a rvalue like C++, but if u need access it
--		as a lvalue u must use [class.member] to access,but not [object.member].
--		2.The function delete cannot release the object, because the gc is based on 
--		reference count in lua.If u want to relase all the object memory, u have to 
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
--Parameters: 	classType -- Table(As Class in C++)
-- 				...		   -- All other parameters requisted in constructor
--Return 	:   return an object
--Note		:	This function is defined to simulate C++ new function.
--				First it called the constructor of base class then to be derived class's.
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
--Parameters: 	obj -- the object to be deleted
--Return 	:   no return
--Note		:	This function is defined to simulate C++ delete function.
--				First it called the destructor of derived class then to be base class's.
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