-- 月晷
AddPrefabPostInit("moondial", function(inst)
    inst:AddTag("moondial")
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    -- 移除月亮变异的功能
    if inst.components.ghostgestalter ~= nil then
        inst:RemoveComponent("ghostgestalter")
    end
end)