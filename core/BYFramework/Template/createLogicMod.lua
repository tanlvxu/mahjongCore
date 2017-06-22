require("IOEx")
---Logic名称
local LogicName = "TemplateTestLogic";
---游戏根目录
local gameServer = "../../../../../";
---具体游戏目录
local game = gameServer .. "bin/"
---逻辑目录
local logicDir = game .. "game/"
---如果创建失败 ，请先创建父目录，暂时不支持递归创建
print(logicDir)

io.mkdir(logicDir)

local function getAuthor()
	local t = io.popen("echo %username%")
	local a = t:read("*all");
	a = string.sub(a,1,-2);
	local authorMap = {
		["HymanLiu"] = "刘虎"
	};
	if not authorMap[tostring(a)] then
		error("请添加中文名配置");
	end
	return authorMap[tostring(a)];
end

local tab = os.date("*t",os.time());
local time = string.format("%s-%s-%s",tab.year,tab.month,tab.day);

local Author = getAuthor ();

if io.exists("LogicTemplate.lua") then

	local content = io.readfile("LogicTemplate.lua");
	content = string.gsub(content, "LogicTemplate", LogicName);
	content = string.format(content,Author,time);
	io.writefile(logicDir .. LogicName ..".lua",content);
	print("path : " .. logicDir .. LogicName ..".lua");
end
