local upvaluehelper = require("hooks/upvaluehelper")

-- 扩展组件
AddComponentPostInit("sisturnregistry", function(self, inst)
    self.all_sisturns = {}              -- 存储所有注册的sisturn
    self.sisturns_state = nil           -- 当前sisturn的状态
    local _is_active = false            -- 当前是否处于活动状态

    local function InitSisturnState()
        print("sisturns: update state")
        -- 重置状态（查找前设为无效）
        self.sisturns_state = nil
        _is_active = false

        -- 当前sisturn无效
        -- 则查找其他有效的sisturn
        for _, v in pairs(self.all_sisturns) do
            if v ~= nil then
                self.sisturns_state = v
                _is_active = true
                break  -- 找到第一个有效值即退出
            end
        end
        
        TheWorld:PushEvent("onsisturnstatechanged", { sisturns_state = self.sisturns_state }) -- Wendy will be listening for this event
    end

    -- 移除原事件
    local OnUpdateSisturnState = upvaluehelper.GetEventHandle(inst, "ms_updatesisturnstate", "components/sisturnregistry")
    inst:RemoveEventCallback("ms_updatesisturnstate", OnUpdateSisturnState)

    -- 
    local function UpdateSisturnState(inst)
        local old_sisturns_state = self.sisturns_state

        -- 重置状态（查找前设为无效）
        self.sisturns_state = nil
        _is_active = false
        
        if self.all_sisturns[inst] ~= nil then
            -- 当前sisturn有效
            self.sisturns_state = self.all_sisturns[inst]
            _is_active = true
        else
            -- 当前sisturn无效
            -- 则查找其他有效的sisturn
            for _, v in pairs(self.all_sisturns) do
                if v ~= nil then
                    self.sisturns_state = v
                    _is_active = true
                    break  -- 找到第一个有效值即退出
                end
            end
        end
        
        -- print("sisturns: state:", self.sisturns_state)
        -- 当状态改变时退出事件
        if old_sisturns_state ~= self.sisturns_state then
            _is_active = true
            TheWorld:PushEvent("onsisturnstatechanged", { sisturns_state = self.sisturns_state }) -- Wendy will be listening for this event
        end
    end

    -- 获取所有
    local function getpetals(inst)
        local petals = {}
        for _, v in pairs(inst.components.container.slots) do
            if v ~= nil then
                table.insert(petals, v.prefab)
            end
        end
        return petals
    end

    -- all_sisturns状态获取和更新
    local function OnUpdateSisturnState(world, data)
        self.all_sisturns[data.inst] = data.is_active and getpetals(data.inst) or nil

        UpdateSisturnState(data.inst)
    end

    inst:ListenForEvent("ms_updatesisturnstate", OnUpdateSisturnState)

    -- 从缓存中移除
    local function OnRemoveSisturn(sisturn)
        if self.all_sisturns[sisturn] ~= nil then
            self.all_sisturns[sisturn] = nil
            inst:RemoveEventCallback("onremove", OnRemoveSisturn, sisturn)
            inst:RemoveEventCallback("onburnt", OnRemoveSisturn, sisturn)
        end
    
        UpdateSisturnState(sisturn)
    end

    -- 添加到缓存
    function self:Register(sisturn)
        if sisturn ~= nil and self.all_sisturns[sisturn] ~= nil then
            return
        end
    
        self.all_sisturns[sisturn] = nil
    
        inst:ListenForEvent("onremove", OnRemoveSisturn, sisturn)
        inst:ListenForEvent("onburnt", OnRemoveSisturn, sisturn)
    end

    function self:IsActive()
        return _is_active
    end

    -- 世界组件不会自动调用 OnLoad
    -- 需要手动调用
    function self:OnLoad(data)
        print("sisturnregister: onload")
        InitSisturnState()
    end
end)