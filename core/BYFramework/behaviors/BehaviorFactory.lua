
local behaviorsClass = {
    RobotBehavior             = import(".RobotBehavior"),
}

local BehaviorFactory = {}


function BehaviorFactory.createBehavior(behaviorName)
    local classObj = behaviorsClass[behaviorName]
    assert(classObj ~= nil, string.format("BehaviorFactory.createBehavior() - Invalid behavior name \"%s\"", tostring(behaviorName)))
    return new(classObj)
end


function BehaviorFactory.combineBehaviorsClass(newBehaviorsClass)
    for k, v in pairs(newBehaviorsClass) do
        assert(behaviorsClass[k] == nil, string.format("BehaviorFactory.combineBehaviorsClass() - Exists behavior name \"%s\"", tostring(behaviorName)))
        behaviorsClass[k] = v        
    end
end


function BehaviorFactory.removeBehaviorsClass(removeBehaviorsClass)
    for k, v in pairs(removeBehaviorsClass) do
        behaviorsClass[k] = nil;      
    end
end

return BehaviorFactory