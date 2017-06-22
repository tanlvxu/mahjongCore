---LogicTemplate
--@Logic LogicTemplate
--@author %s
--@Date: %s

local LogicBase = import(".LogicBase")
local CancelLogic = class("LogicTemplate",LogicBase)

function LogicTemplate:ctor(tableDB)
	self.debug_name = "LogicTemplate"
end

function LogicTemplate:active(opData)
	self:Log("LogicTemplate:active")
end

return LogicTemplate

