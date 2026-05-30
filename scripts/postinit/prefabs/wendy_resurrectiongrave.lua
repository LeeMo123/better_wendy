-- 温蒂的复活祭坛也可以生成小惊吓
-- Ghosts on a quest (following someone) shouldn't block other ghost spawns!
local CANTHAVE_GHOST_TAGS = {"questing"}
local MUSTHAVE_GHOST_TAGS = {"ghostkid"}
local function on_day_change(inst)
    -- 固定一下生成的概率为0.05吧
    if (not inst.ghost or not inst.ghost:IsValid()) and math.random() < TUNING.GHOST_GRAVESTONE_CHANCE then
        local gx, gy, gz = inst.Transform:GetWorldPosition()
        local nearby_ghosts = TheSim:FindEntities(gx, gy, gz, TUNING.UNIQUE_SMALLGHOST_DISTANCE, MUSTHAVE_GHOST_TAGS,
            CANTHAVE_GHOST_TAGS)
        if #nearby_ghosts == 0 then
            inst.ghost = SpawnPrefab("smallghost")
            inst.ghost.Transform:SetPosition(gx + 0.3, gy, gz + 0.3)
            inst.ghost:LinkToHome(inst)
        end
    end
end

AddPrefabPostInit("wendy_resurrectiongrave", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    --
    inst:WatchWorldState("cycles", on_day_change)
end)
