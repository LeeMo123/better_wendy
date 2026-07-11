-- 由于修改了骨灰盒里月树花可以使得阿比盖尔回san
-- 温蒂又面以鬼魂的san光环影响
-- 只能出此下策了
AddPrefabPostInitAny(function(inst)
    if inst:HasTag("ghost") then
        if inst.prefab ~= "abigail" then
            inst:AddTag("ghost_wendy")
        end
    end
end)