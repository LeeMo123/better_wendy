-- 修改夜视buff生效的时机
AddPrefabPostInit("ghostvision_buff", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    
    local _onattachedfn = inst.components.debuff.onattachedfn
    inst.components.debuff.onattachedfn = function(inst, target)
        inst:DoTaskInTime(FRAMES*3, function()
            if not (target.components.inventory and target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) ~= nil and target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "ghostflowerhat") then
                target:RemoveDebuff("ghostvision_buff")
                return
            end
            _onattachedfn(inst, target)            
        end)
    end
end)