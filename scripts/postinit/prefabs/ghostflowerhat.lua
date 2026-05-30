-- 幽魂花冠
local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, "swap_hat", inst.GUID, "hat_ghostflower")
    else
        owner.AnimState:OverrideSymbol("swap_hat", "hat_ghostflower", "swap_hat")
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StartConsuming()
    end

    if inst.skin_equip_sound and owner.SoundEmitter then
        owner.SoundEmitter:PlaySound(inst.skin_equip_sound)
    end
    
    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    owner.AnimState:Show("HEAD")
    owner.AnimState:Hide("HEAD_HAT")
    owner.AnimState:Hide("HEAD_HAT_NOHELM")
    owner.AnimState:Hide("HEAD_HAT_HELM")

    owner:AddTag("ghost_ally")
    inst:AddTag("elixir_drinker")
end

local function onunequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    owner.AnimState:ClearOverrideSymbol("headbase_hat") --it might have been overriden by _onequip
    if owner.components.skinner ~= nil then
        owner.components.skinner.base_change_cb = owner.old_base_change_cb
    end

    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end

    owner:RemoveTag("ghost_ally")
    inst:RemoveTag("elixir_drinker")
end


AddPrefabPostInit("ghostflowerhat", function(inst)
    inst:RemoveTag("show_spoilage")

    if not TheWorld.ismastersim then
        return inst
    end
    
    -- 移除腐烂组件
    if inst.components.perishable ~= nil then
        inst:RemoveComponent("perishable")
    end

    -- 移除充能组件
    if inst.components.rechargeable ~= nil then
        inst:RemoveComponent("rechargeable")
    end

    -- 添加耐久度组件
    if inst.components.fueled == nil then
        inst:AddComponent("fueled")
    end
    inst.components.fueled:InitializeFuelLevel(TUNING.TOPHAT_PERISHTIME)
    inst.components.fueled:SetDepletedFn(inst.Remove)


    -- 脱帽子移除buff 戴上帽子上buff
    --[[
    if inst.components.equippable ~= nil then
        -- 卸下装备
        local old_onunequipfn = inst.components.equippable.onunequipfn
        inst.components.equippable.onunequipfn = function(inst, owner)            
            inst.buff_name = owner:GetDebuff("elixir_buff") and owner:GetDebuff("elixir_buff").prefab or nil  -- buff            
            inst.buff_time = inst.buff_name and math.floor(owner:GetDebuff("elixir_buff").components.timer:GetTimeLeft("decay")) or 0-- buff剩余时间
            inst.uneq_time = GetTime()
            ---------------------------------------------------

            old_onunequipfn(inst, owner)
        end

        -- 带上装备
        local old_onequipfn = inst.components.equippable.onequipfn
        inst.components.equippable.onequipfn = function(inst, owner)
            old_onequipfn(inst, owner)
            ---------------------------------------------------
            local buff_left_time = inst.uneq_time and math.floor(inst.buff_time - (GetTime() - inst.uneq_time)) or 0
            if inst.buff_name ~= nil and buff_left_time > 0 then
                print("Equip SetTimeLeft", buff_left_time)

                owner:AddDebuff("elixir_buff", inst.buff_name)
                local buff = owner:GetDebuff("elixir_buff")

                if buff ~= nil then
                    buff.components.timer:SetTimeLeft("decay", buff_left_time)
                    
                    -- 初始化数据
                    inst.buff_name = nil
                    inst.buff_time = 0
                    inst.uneq_time = 0

                    return buff
                end
            end
            
        end
    end

    local _OnSave = inst.OnSave
    inst.OnSave = function(inst, data)
        data.buff_time = inst.buff_time or 0
        data.buff_name = inst.buff_name or nil

        if _OnSave ~= nil then
            _OnSave(inst, data)
        end
    end

    local _OnLoad = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if data ~= nil then
            inst.buff_name = data.buff_name
            inst.buff_time = data.buff_time
        end
        
        if _OnLoad ~= nil then
            _OnLoad(inst, data)
        end
    end
    ]]

    if inst.components.equippable ~= nil then
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
    end
end)