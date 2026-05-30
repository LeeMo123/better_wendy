local upvaluehelper= require("hooks/upvaluehelper")

local function OnDugUp(inst, tool, worker)
    SpawnPrefab("attune_out_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())

    inst:RemoveComponent("gravediggable")

    inst.AnimState:PlayAnimation("grave" .. inst.random_stone_choice .. "_slide")

    local animlength = inst.AnimState:GetCurrentAnimationLength()

    inst.persists = false


    inst:DoTaskInTime(animlength, function()
        local stone_index = tostring(inst.random_stone_choice)

        -- 掉落花瓣
        print(inst.components.upgradeable:GetStage())
        if inst.components.upgradeable ~= nil and (inst.components.upgradeable:GetStage() > 1) then
            inst.components.lootdropper:SpawnLootPrefab("petals")
            if math.random() <= 0.3 then
                inst.components.lootdropper:SpawnLootPrefab("petals")
            end
        end

        -- 掉落墓碑
        local skin_build = inst:GetSkinBuild()
        if skin_build then
            skin_build = skin_build:gsub("dug_", "")
        end

        local gravestone = inst.components.lootdropper:SpawnLootPrefab("dug_gravestone", nil, skin_build, inst.skin_id) -- , nil, skin_build, inst.skin_id)
        gravestone.random_stone_choice = stone_index
        gravestone.AnimState:PlayAnimation("dug_grave" .. stone_index)
        
        if not inst:GetSkinBuild() then
            gravestone.components.inventoryitem:ChangeImageName("dug_gravestone" ..(stone_index == "1" and "" or inst.random_stone_choice))
        else
            gravestone.components.inventoryitem:ChangeImageName("dug_" ..skin_build)
        end
        
        inst:Remove()
    end)

    -- 注释掉这个 不然会打印一堆 错误
    -- if inst.mound ~= nil then
    --     ErodeAway(inst.mound, animlength)
    -- end

    return true
end

-- Upgrade (decorate)
local FLOWER_TAG = {"flower"}
local FLOWER_SPAWN_RADIUS = 1.5
local function try_evil_flower(inst)
    if TheWorld.state.iswinter then return end

    local ix, iy, iz = inst.Transform:GetWorldPosition()
    if TheSim:CountEntities(ix, iy, iz, 2 * FLOWER_SPAWN_RADIUS, FLOWER_TAG) < TUNING.WENDYSKILL_GRAVESTONE_EVILFLOWERCOUNT then
        local random_angle = PI2 * math.random()
        ix = ix + (FLOWER_SPAWN_RADIUS * math.cos(random_angle))
        iz = iz - (FLOWER_SPAWN_RADIUS * math.sin(random_angle))

        -- local evil_flower = SpawnPrefab("flower_evil")
        -- evil_flower.Transform:SetPosition(ix, iy, iz)
        local spawn_flower = math.random() > 0.5 and SpawnPrefab("flower_evil") or SpawnPrefab("flower")
        spawn_flower.Transform:SetPosition(ix, iy, iz)
        SpawnPrefab("attune_out_fx").Transform:SetPosition(ix, iy, iz)
    end
end

local function initiate_flower_state(inst)
    inst.AnimState:Show("flower")

    -- We call this when loading, and our onload happens after the timer component,
    -- so we might have loaded a more correct one. It knows how to handle constructor-started
    -- timers, but not onload-started ones, sadly.
    -- if not inst.components.timer:TimerExists("petal_decay") then
    --     -- Currently just matching the perish rate of petals.
    --     inst.components.timer:StartTimer("petal_decay", TUNING.PERISH_FAST)
    -- end
    if not inst.components.timer:TimerExists("try_evil_flower") then
        inst.components.timer:StartTimer(
            "try_evil_flower",  (TUNING.WENDYSKILL_GRAVESTONE_DECORATETIME / TUNING.WENDYSKILL_GRAVESTONE_EVILFLOWERCOUNT) * (1 + 0.5 * math.random())
        )
    end

    TheWorld.components.decoratedgrave_ghostmanager:RegisterDecoratedGrave(inst)
end

AddPrefabPostInit("gravestone", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    -- 迁坟
    inst.components.gravediggable.ondug = OnDugUp

    -- 掉落物
    inst:AddComponent("lootdropper")

    -- 随机生成恶魔花或者普通花瓣
    local timerdone = upvaluehelper.GetEventHandle(inst, "timerdone", "prefabs/gravestone")
    if timerdone then
        local oldtry_evil_flower = upvaluehelper.Get(timerdone, "try_evil_flower", "prefabs/gravestone")
        if oldtry_evil_flower then
            upvaluehelper.Set(timerdone, "try_evil_flower", try_evil_flower)
        end
    end
    
    --  保存  
    local OldOnSave = inst.OnSave
    inst.OnSave = function(inst, data)
        OldOnSave(inst, data)
        data.deploy = inst.deploy
    end

    local oldinitiate_flower_state = upvaluehelper.Get(inst.OnLoad, "initiate_flower_state", "prefabs/gravestone")
    if oldinitiate_flower_state then
        upvaluehelper.Set(inst.OnLoad, "initiate_flower_state", initiate_flower_state)
    end

    local OldOnLoad = inst.OnLoad
    inst.OnLoad = function(inst, data, newents)
        if data then
            if inst.mound and data.mounddata then
                if data.deploy then
                    inst.deploy = data.deploy
                    inst.mound:Remove()
                else
                    if newents and data.mounddata.id then
                        newents[data.mounddata.id] = {entity=inst.mound, data=data.mounddata}
                    end
                    inst.mound:SetPersistData(data.mounddata.data, newents)
                end
            end
    
            if data.stone_index then
                if not inst:GetSkinBuild() then
                    inst.AnimState:PlayAnimation("grave"..data.stone_index)
                end
                inst.random_stone_choice = tostring(data.stone_index)
            end
    
            if data.setepitaph then
                --this handles custom epitaphs set in the tile editor
                inst.components.inspectable:SetDescription("'"..data.setepitaph.."'")
                inst.setepitaph = data.setepitaph
            elseif data.epitaph_index then
                inst._epitaph_index = data.epitaph_index
                inst.components.inspectable:SetDescription(STRINGS.EPITAPHS[inst._epitaph_index])
            end
    
            if inst.components.upgradeable.stage > 1 then
                initiate_flower_state(inst)
            end
        end
    end
end)

AddPrefabPostInit("dug_gravestone", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    -- 放置
    local oldondeploy = inst.components.deployable.ondeploy
    inst.components.deployable.ondeploy = function(inst, pt, deployer)
        local skin_build = inst:GetSkinBuild()
        if skin_build then
            skin_build:gsub("dug_", "")
        end
    
        local gravestone = SpawnPrefab("gravestone", skin_build, inst.skin_id)
        gravestone.Transform:SetPosition(pt:Get())
    
        gravestone.random_stone_choice = tostring(inst.random_stone_choice)
        gravestone.AnimState:PlayAnimation("grave"..gravestone.random_stone_choice.."_place")
        gravestone.AnimState:PushAnimation("grave"..gravestone.random_stone_choice)
    
        if deployer.SoundEmitter then
            deployer.SoundEmitter:PlaySound("meta5/wendy/place_gravestone")
        end
    
        if inst._epitaph then
            local epitaph_type = type(inst._epitaph)
            if epitaph_type == "number" then
                gravestone._epitaph_index = inst._epitaph
                gravestone.components.inspectable:SetDescription(STRINGS.EPITAPHS[inst._epitaph])
            elseif epitaph_type == "string" then
                gravestone.setepitaph = inst._epitaph
                gravestone.components.inspectable:SetDescription("'"..inst._epitaph.."'")
            end
        end
    
        local mound = gravestone.mound
        if mound ~= nil then
            mound:Remove()
        end

        gravestone.deploy = true

        inst:Remove()
    end

end)