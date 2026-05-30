-- 重写一下上药组件
AddComponentPostInit("ghostlyelixir", function(self)
    function self:Apply(doer, target)
        if target:HasTag("elixir_drinker") then
            target = target.components.inventoryitem.owner
            if not target then
                return false
            end
        elseif target:HasTag("abigail_flower") then
            local wendy = target.components.inventoryitem.owner or doer
            target = wendy and wendy.components.ghostlybond and wendy.components.ghostlybond.ghost
            if not target then
                return false
            end
        elseif target:HasTag("player") or  target:HasTag("abigail") then            
        end
        target = target.components.ghostlyelixirable:GetApplyToTarget(doer, self.inst)
    
        if target ~= nil and self.doapplyelixerfn ~= nil then
            local success, reason = self.doapplyelixerfn(self.inst, doer, target)
            if success then
                if self.inst.components.stackable ~= nil then
                    self.inst.components.stackable:Get():Remove()
                else
                    self.inst:Remove()
                end
            end
            return success, reason
        end
        return false
    end
end)