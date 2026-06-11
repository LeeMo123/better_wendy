local GHOSTVISION_NIGHTVISION_COLOURCUBES =
{
    day = "images/colour_cubes/ghost_cc.tex",
    dusk = "images/colour_cubes/ghost_cc.tex",
    night = "images/colour_cubes/ghost_cc.tex",
    full_moon = "images/colour_cubes/ghost_cc.tex",
--}
  --  nightvision_fruit = true, -- NOTES(DiogoW): Here for convinience.
}

local function Appllynightvision(target)                
    local is_night = TheWorld.state.isnight
    local is_cave = TheWorld:HasTag("cave")
    if is_night or is_cave then
        target.components.playervision:PushForcedNightVision(target, 1, GHOSTVISION_NIGHTVISION_COLOURCUBES, true)
    else
        target.components.playervision:PopForcedNightVision(target)
    end
    
end

local function buff_OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0)

    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)

    if target.components.playervision ~= nil then
        inst._enabled:set(true)
        Appllynightvision(target)
        target:WatchWorldState("phase", Appllynightvision)
    end
end

local function buff_OnDetached(inst, target)
    if target ~= nil and target:IsValid() then
        if target.components.playervision ~= nil then            
            target.components.playervision:PopForcedNightVision(target)
            inst._enabled:set(false)

            target:StopWatchingWorldState("phase", Appllynightvision)
        end

        if target.components.sanity ~= nil then
            target.components.sanity.externalmodifiers:RemoveModifier(inst)
        end
    end

    -- NOTES(DiogoW): Delayed removal to let the client run the dirty event.
    inst:DoTaskInTime(10*FRAMES, inst.Remove)
end

AddPrefabPostInit("ghostvision_buff", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst.components.debuff:SetAttachedFn(buff_OnAttached)
    inst.components.debuff:SetDetachedFn(buff_OnDetached)
end)