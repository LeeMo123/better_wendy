local AllRecipes = GLOBAL.AllRecipes

-- 获取所有药剂
TUNING.GHOSTLYELIXIRS = {}
for i, recipe in pairs(AllRecipes) do
    if string.find(recipe.name, "ghostlyelixir_") then
        table.insert(TUNING.GHOSTLYELIXIRS, recipe.name)
    end
end

local toy_types =
{
    "lost_toy_1",
    "lost_toy_2",
    "lost_toy_7",
    "lost_toy_10",
    "lost_toy_11",
    "lost_toy_14",
    "lost_toy_18",
    "lost_toy_19",
    "lost_toy_42",
    "lost_toy_43",
}

-- 链接到玩家
local function unlink_from_player(inst)
    if inst._playerlink ~= nil then
        if inst._playerlink.components.leader ~= nil then
            inst._playerlink.components.leader:RemoveFollower(inst)
        end
        inst._playerlink:RemoveEventCallback("onremove", unlink_from_player, inst)
        inst._playerlink:RemoveEventCallback("onremove", inst._on_leader_removed)

        inst:RemoveEventCallback("death", inst._on_leader_death, inst._playerlink)

        inst._playerlink.questghost = nil
        inst._playerlink = nil
    end
end

-- 检查任务是否完成
local function check_for_quest_finished(inst)
    -- The toys array was initialized (i.e. a quest was started),
    -- but all of the actual targets have been removed from the list.
    -- So, our quest is over.
    if not inst._toys or next(inst._toys) ~= nil then
        return false
    end

    if inst._hotcold_task ~= nil then
        inst._hotcold_task:Cancel()
        inst._hotcold_task = nil
    end

    if inst._hotcold_fx ~= nil then
        inst._hotcold_fx:Remove()
    end

    unlink_from_player(inst)

    inst.sg:GoToState((inst._cancelled and "quest_abandoned") or "quest_finished")

    return true
end

-- 丢失的玩具
local function on_begin_quest(inst, doer)
    if doer.questghost ~= nil and doer.questghost ~= inst then
        return false, "ONEGHOST"
    end

    -- Spawn toys if we didn't have any already.
    if not inst._toys then
        inst._toys = {}

        local ghost_position = inst:GetPosition()

        -- We can kind of just recycle this for both the offset test and the spawn tests.
        local initial_angle = math.random() * TWOPI

        local spawn_distance = (doer.isplayer and doer.components.skilltreeupdater:IsActivated("wendy_smallghost_1") and
                                   TUNING.GHOST_HUNT.TOY_DIST.WENDY_UPGRADE_BASE) or TUNING.GHOST_HUNT.TOY_DIST.BASE
        local toy_center_offset = FindWalkableOffset(ghost_position, initial_angle, spawn_distance, nil, false)
        if toy_center_offset then
            ghost_position = ghost_position + toy_center_offset
        end

        inst._toy_center_position = ghost_position

        local toy_count = GetRandomMinMax(TUNING.GHOST_HUNT.TOY_COUNT.MIN, TUNING.GHOST_HUNT.TOY_COUNT.MAX)
        if doer.isplayer and doer.components.skilltreeupdater:IsActivated("wendy_smallghost_2") then
            toy_count = toy_count + TUNING.GHOST_HUNT.TOY_COUNT.WENDYSKILL_ADDITION
        end

        local angle_increment = TWOPI / toy_count

        -- Do a shuffle instead of random selection so that we don't get duplicates.
        local chosen_toys = shuffleArray(toy_types)

        local function on_toy_removed(t)
            if inst._toys then
                inst._toys[t] = nil
            end
            check_for_quest_finished(inst)
        end

        for i = 1, toy_count do
            local toy = SpawnPrefab(chosen_toys[i])
            if doer.components.skilltreeupdater:IsActivated("wendy_smallghost_1") then
                toy.AnimState:SetMultColour(1, 1, 1, 1)                
            end

            local toyangle = initial_angle + (i - 1) * angle_increment

            local offset = FindWalkableOffset(ghost_position, toyangle, GetRandomWithVariance(
                TUNING.GHOST_HUNT.TOY_DIST.RADIUS, TUNING.GHOST_HUNT.TOY_DIST.VARIANCE), nil, false)
            if offset then
                toy.Transform:SetPosition((ghost_position + offset):Get())
            else
                toy.Transform:SetPosition(ghost_position:Get())
            end

            inst._toys[toy] = true

            inst:ListenForEvent("onremove", on_toy_removed, toy)
        end
    end

    if doer.components.talker then
        doer.components.talker:Say(GetString(doer, "ANNOUNCE_GHOST_QUEST"))
    end

    local MIN_FX_SIZE, MAX_FX_SIZE = 0.20, 0.90
    local MAX_HUNT_HOT_DSQ = TUNING.GHOST_HUNT.MINIMUM_HINT_DIST * TUNING.GHOST_HUNT.MINIMUM_HINT_DIST

    inst:LinkToPlayer(doer)
    inst._hotcold_task = inst:DoPeriodicTask(0.25, function (inst)
        if inst._toys ~= nil and next(inst._toys) ~= nil then
            if inst._hotcold_fx == nil then
                inst._hotcold_fx = SpawnPrefab("hotcold_fx")
                inst._hotcold_fx.entity:SetParent(inst.entity)
                inst._hotcold_fx.entity:AddFollower():FollowSymbol(inst.GUID, "smallghost_hair", 0, 0.2, 0)
            end

            local distance_test_inst = inst.components.follower:GetLeader() or inst
            local dtx, dty, dtz = distance_test_inst.Transform:GetWorldPosition()

            local closest_toy_dsq = MAX_HUNT_HOT_DSQ + 1
            for toy in pairs(inst._toys) do
                closest_toy_dsq = math.min(closest_toy_dsq, toy:GetDistanceSqToPoint(dtx, dty, dtz))
            end

            local percent = (closest_toy_dsq >= MAX_HUNT_HOT_DSQ and 0)
                or math.clamp(1 - math.sqrt(closest_toy_dsq / MAX_HUNT_HOT_DSQ), MIN_FX_SIZE, MAX_FX_SIZE)

            inst._hotcold_fx.AnimState:SetScale(percent, percent)
        end
    end)

    inst.sg:GoToState("quest_begin")

    return true
end

AddPrefabPostInit("smallghost", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    -- 生成药剂
    local function spawn_ghostlyelixir(ix, iy, iz)
        local ghostlyelixir = SpawnPrefab(TUNING.GHOSTLYELIXIRS[math.random(#TUNING.GHOSTLYELIXIRS)])
        ghostlyelixir.Transform:SetPosition(ix, iy, iz)
        ghostlyelixir:Hide()
        ghostlyelixir.components.inventoryitem.canbepickedup = false

        inst:DoTaskInTime(3, function (inst)
            SpawnPrefab("attune_in_fx").Transform:SetPosition(ix, iy, iz)
            ghostlyelixir:Show()
            ghostlyelixir.components.inventoryitem.canbepickedup = true
        end)
    end

    -- 玩具拾取
    local _PickupToy = inst.PickupToy
    inst.PickupToy = function(inst, toy)
        _PickupToy(inst, toy)

        -- local tx, ty, tz = toy.Transform:GetWorldPosition() -- Get toy's position
        local ix, iy, iz = inst.Transform:GetWorldPosition()-- Get ghost's position

        local leader = inst.components.follower:GetLeader()       
        local skillactivated = leader ~= nil and leader.components.skilltreeupdater and (
            leader.components.skilltreeupdater:IsActivated("wendy_smallghost_3") and 0.60 or
            leader.components.skilltreeupdater:IsActivated("wendy_smallghost_2") and 0.35) or 0
        

        -- 概率生成药剂
        if not next(inst._toys) and math.random() < skillactivated then
            spawn_ghostlyelixir(ix, iy, iz)
        end
    end

    -- 帮助小惊吓任务 调整
    inst.components.questowner:SetOnBeginQuest(on_begin_quest)
end)