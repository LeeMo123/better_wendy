modimport("scripts/postinit/widgets/healthbadge")           -- 多药剂显示等相关1
modimport("scripts/postinit/widgets/statusdisplays")        -- 多药剂显示等相关2
local upvaluehelper = require("hooks/upvaluehelper")        -- 监听函数修改

-- 获取玩家穿戴装备的护甲值
local function get_armor(wendy)
    local absorb_percent = 0
    local abigail = wendy.components.ghostlybond.ghost
    for k, v in pairs(wendy.components.inventory.equipslots) do
        if v.components.armor ~= nil then
            absorb_percent = absorb_percent + math.min(v.components.armor.absorb_percent, 0.3)
        end
    end
    
    abigail.components.health:SetAbsorptionAmount(math.min(absorb_percent, 0.6))
end

-- 退出恶魔花形态
local function deactivate_evil(inst, abigail)
    if not inst.state_evil then
        return
    end
    
    abigail.components.health:SetAbsorptionAmount(0)
    inst:RemoveEventCallback("equip", get_armor)
    inst:RemoveEventCallback("unequip", get_armor)
    inst.state_evil = false
end

-- 设置最大生命
local function SetMaxHealth(inst)
    local health = inst.components.health
    if health then
        if health:IsDead() then
            health.maxhealth = inst.base_max_health + inst.bonus_max_health
        else
            local health_percent = health:GetPercent()
            health:SetMaxHealth(inst.base_max_health + inst.bonus_max_health)
            health:SetPercent(health_percent, true)
        end

        if inst._playerlink ~= nil and inst._playerlink.components.pethealthbar ~= nil then
            inst._playerlink.components.pethealthbar:SetMaxHealth(health.maxhealth)
        end
    end
end

-- 额外生命值跟随等级变化
local function UpdateBonusHealth(inst, level)
	local health = level == 4 and TUNING.WENDY_BONUS_HEALTH.LEVEL4
        or level == 3 and TUNING.WENDY_BONUS_HEALTH.LEVEL3
        or level == 2 and TUNING.WENDY_BONUS_HEALTH.LEVEL2
        or level == 1 and TUNING.WENDY_BONUS_HEALTH.LEVEL1

    inst.bonus_max_health = health
    
    SetMaxHealth(inst)
end

local function update_bonus_health(inst, data)
    local abigail = inst.components.ghostlybond.ghost
    UpdateBonusHealth(abigail, data.level)
end

-- 退出月树花形态
local function deactivate_blossom(inst, abigail)
    if not inst.state_blossom then
        return
    end
    
    -- abigail -- 恢复最大生命值
    inst:RemoveEventCallback("ghostlybond_level_change", update_bonus_health)
    abigail.bonus_max_health = 0
    SetMaxHealth(abigail)

    inst.state_blossom = false
end

-- 退出普通形态
local function deactivate_normal(inst, abigail)
    if not inst.state_normal then
        return
    end
    
    -- abigail -- 恢复最大生命值
    abigail.components.health:StartRegen(1, 1)
    inst.state_normal = false
end

-- 恶魔花形态
local function evil_state(inst, abigail)
    -- print("Wendy: EVIL")
    inst.state_evil = true
    
    -- 获取护甲
    get_armor(inst) 
    inst:ListenForEvent("equip", get_armor)
    inst:ListenForEvent("unequip", get_armor)

    deactivate_blossom(inst, abigail)
    deactivate_normal(inst, abigail)
end

-- 月树花形态
local function blossom_state(inst, abigail)
    -- print("Wendy: BLOSSOM")
    inst.state_blossom = true

    -- abigail  -- 设置最大生命
    UpdateBonusHealth(abigail, inst.components.ghostlybond.bondlevel)
    inst:ListenForEvent("ghostlybond_level_change", update_bonus_health)
    
    deactivate_evil(inst, abigail)
    deactivate_normal(inst, abigail)
end

-- 普通形态 
local function normal_state(inst, abigail)
    -- print("Wendy: NORMAL")
    inst.state_normal = true
    abigail.components.health:StartRegen(5, 1)

    deactivate_blossom(inst, abigail)
    deactivate_evil(inst, abigail)
end

-- 获取各色花瓣的数量
local function get_petal_count(sisturn_state)
    local petals_evil, moon_tree_blossom, petals = 0,0,0
    if type(sisturn_state) == "table" then
        for _, petal in pairs(sisturn_state) do
            if petal == "petals_evil" then
                petals_evil = petals_evil + 1
            elseif petal == "moon_tree_blossom" then
                moon_tree_blossom = moon_tree_blossom + 1
            else
                petals = petals + 1
            end        
        end
    end

    -- print("Wendy: PETALS1: ", petals_evil, moon_tree_blossom, petals)
    return petals_evil, moon_tree_blossom, petals
end

-- 激活
-- print(Theplayer.components.ghostlybond.ghost)
local function activate(abigail, sisturn_state) 
    local petals_evil, moon_tree_blossom, petals = get_petal_count(sisturn_state)

    print("Wendy: PETALS2: ", petals_evil, moon_tree_blossom, petals)
    -- 护甲加成
    abigail.components.health:SetAbsorptionAmount(petals_evil == 4 and 0.5 or petals_evil *0.1)

    -- 血量加成
    abigail.bonus_max_health = moon_tree_blossom == 4 and 700 or moon_tree_blossom*100
    abigail:SetMaxHealth()

    -- 回血速度加成
    abigail.components.health:StartRegen(1 + (petals == 4 and 5 or petals), 1)
end

-- 花形态改变
local function update_sisturn_state(inst, sisturn_state)
    if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
        local abigail = inst.components.ghostlybond.ghost

        inst.components.ghostlybond:SetBondTimeMultiplier("sisturn", TheWorld.components.sisturnregistry ~= nil and TheWorld.components.sisturnregistry:IsActive() and 
                    TUNING.ABIGAIL_BOND_LEVELUP_TIME_MULT or nil)
        
        local is_skilled = inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("wendy_sisturn_3") or nil

        if is_skilled ~= nil and sisturn_state ~= nil then
            abigail:AddChild(SpawnPrefab("abigail_rising_twinkles_fx"))           
        end

        activate(abigail, sisturn_state)
        inst.components.ghostlybond.ghost:updatehealingbuffs()
    end

end

-- 等级改变
local function OnBondLevelDirty(inst)
	if inst.HUD ~= nil then
		local bond_level = inst._bondlevel:value()
		for i = 0, 4 do
			if i ~= 1 then
				inst:SetClientSideInventoryImageOverrideFlag("bondlevel"..i, i == bond_level)
			end
		end
		if not inst:HasTag("playerghost") then
			if bond_level > 1 then
				if inst.HUD.wendyflowerover ~= nil then
					inst.HUD.wendyflowerover:Play( bond_level )
				end
			end
		end
    end
end


---------------------------------------------

local function SetSymbol(inst,symbol)
    if TheWorld.ismastersim and inst._buffsymbol2:value() ~= symbol then
        inst._buffsymbol2:set(symbol)
    end
end

local function OnHealthbarBuffSymbol2Dirty(inst)
    if ThePlayer ~= nil and  ThePlayer == inst then
        ThePlayer:PushEvent("clienthealthbuffdirty", inst._buffsymbol2:value())
    end
end

local function OnDebuffRemoved(inst, name, debuff)
   if name == "elixir_extra_buff" then
     inst._buffsymbol2:set(0)
   end
end

---------------------------------------------

AddPrefabPostInit("wendy", function(inst)
    -- 温蒂可以引用2种药剂
    inst._buffsymbol2 = net_hash(inst.GUID, "healthbarbuff._buffsymbol2", "healthbarbuffsymboldirty")
    inst._buffsymbol2:set(0)    
    inst:ListenForEvent("healthbarbuffsymboldirty", OnHealthbarBuffSymbol2Dirty)

    -- 阿比盖尔之花 4级阿比相关错误修复
    local playeractivated = upvaluehelper.GetEventHandle(inst, "playeractivated", "prefabs/wendy")
    local OldOnBondLevelDirty = nil
    if playeractivated ~= nil then
        OldOnBondLevelDirty = upvaluehelper.Get(playeractivated, "OnBondLevelDirty")
        if OldOnBondLevelDirty ~= nil then
            -- print("Wendy: Fix OnBondLevelDirty")
            upvaluehelper.Set(playeractivated, "OnBondLevelDirty", OnBondLevelDirty)
        end
    end

    if not TheWorld.ismastersim then
        return inst
    end
       
    -- 移除击杀小动物变成暗影形态监听
    local OnMurdered = upvaluehelper.GetEventHandle(inst, "murdered", "prefabs/wendy")
    if OnMurdered ~= nil then
        inst:RemoveEventCallback("murdered", OnMurdered)
    end

    -- 重写 onsisturnstatechanged 监听函数
    local Oldonsisturnstatechanged = upvaluehelper.GetEventHandle(inst, "onsisturnstatechanged",  "prefabs/wendy")
    if Oldonsisturnstatechanged ~= nil then
        inst:RemoveEventCallback("onsisturnstatechanged", Oldonsisturnstatechanged)		
    end
    -- 监听 状态改变
    inst:ListenForEvent("onsisturnstatechanged", function(world, data)
        update_sisturn_state(inst, data.sisturns_state)
    end, TheWorld)
    update_sisturn_state(inst, nil)  -- 初始化为nil

    -- 
    local Old_Onload = inst.OnLoad
    inst.OnLoad = function(inst, data)
        inst:DoTaskInTime(0, function()
            if TheWorld.components.sisturnregistry ~= nil then
                TheWorld.components.sisturnregistry:OnLoad()
            end
        end)

        if Old_Onload ~= nil then
            Old_Onload(inst, data)
        end
    end

    -- 温蒂可以饮用2种药剂    
    -- 重写 debuffable 回调以支持自定义图标
    if inst.components.debuffable then
        local old_ondebuffadded = inst.components.debuffable.ondebuffadded     
        inst.components.debuffable.ondebuffadded = function(inst, name, debuff)
            print("Wendy: debuffable.ondebuffadded: ", name)
            if name == "elixir_extra_buff" then
                SetSymbol(inst, debuff.prefab)
            end    
            old_ondebuffadded(inst, name, debuff)
        end

        local old_ondebuffremoved = inst.components.debuffable.ondebuffremoved
        inst.components.debuffable.ondebuffremoved = function(inst, name, debuff)
            if name == "elixir_extra_buff" then
                SetSymbol(inst, 0)
            end
            old_ondebuffremoved(inst)
        end
    end
end)