local flowers = {"petals", "moon_tree_blossom", "petals_evil"}

-- 三朵花  -- 存储一下腐烂时的掉落物  
for _, flower in pairs(flowers) do
    AddPrefabPostInit(flower, function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        -- 初始化参数
        inst._ghostflower = false

        local OldOnSave = inst.OnSave
        inst.OnSave = function(inst, data)
            data._ghostflower = inst._ghostflower or nil
            if OldOnSave then
                OldOnSave(inst, data)
            end
        end

        local OldOnload = inst.OnLoad
        inst.OnLoad = function(inst, data)
            if data ~= nil then
                inst._ghostflower = data._ghostflower or nil
                if inst._ghostflower then
                    inst.components.perishable.onperishreplacement = "ghostflower"
                end
            end

            if OldOnload then
                OldOnload(inst, data)
            end
        end
    end)    
end