local SourceModifierList = require("util/sourcemodifierlist")

-- 扩展组件
AddComponentPostInit("damagetyperesist", function(self, inst)
    self.targets = {}

    -- 添加一个目标对源的抗性
    function self:AddTargetResist(target_entity, src, pct, key)
        local modifiers = self.targets[target_entity]
        if modifiers == nil then
            modifiers = SourceModifierList(self.inst)
            self.targets[target_entity] = modifiers
        end
        modifiers:SetModifier(src, pct, key)
    end

    -- 移除一个目标对源的抗性
    function self:RemoveTargetResist(target_entity, src, key)
        local modifiers = self.targets[target_entity]
        if modifiers ~= nil then
            modifiers:RemoveModifier(src, key)
            if modifiers:IsEmpty() then
                self.targets[target_entity] = nil
            end
        end
    end

    -- 获取对源的抗性
    function self:GetResist(attacker, weapon)
        local tag_mult, target_mult = 1, 1
        if attacker ~= nil and attacker:IsValid() then
            if next(self.tags) ~= nil then
                for k, v in pairs(self.tags) do
                    if attacker:HasTag(k) or (weapon ~= nil and weapon:HasTag(k)) then
                        tag_mult = tag_mult * v:Get()
                    end
                end
            end

            -- 直接检测是否是目标实体  武器存在且是目标实体
            if next(self.targets) ~= nil then
                if self.targets[attacker] then
                    target_mult = target_mult * self.targets[attacker]:Get()
                end
            end
        end
        return math.min(tag_mult, target_mult)
    end
end)
