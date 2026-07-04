local function OnSymbolDirty(inst)
    inst:PushEvent("clientpethealthsymboldirty", {
        symbol = inst.components.pethealthbar:GetSymbol()
    })
end
local function OnSymbolDirty1(inst)
    inst:PushEvent("clientpethealthsymboldirty", {
        symbol1 = inst.components.pethealthbar:GetSymbol1()
    })
end
local function OnSymbolDirty3(inst)
    inst:PushEvent("clientpethealthsymboldirty", {
        symbol3 = inst.components.pethealthbar:GetSymbol3()
    })
end
AddComponentPostInit("pethealthbar", function(self, inst)
    self._symbol1 = net_hash(inst.GUID, "pethealthbar._symbol1", "pethealthsymbol1dirty")
    self._symbol3 = net_hash(inst.GUID, "pethealthbar._symbol3", "pethealthsymbol3dirty")

    if not self.ismastersim then
        inst:ListenForEvent("pethealthsymbol1dirty", OnSymbolDirty1)
        inst:ListenForEvent("pethealthsymbol3dirty", OnSymbolDirty3)
    end

    -- function self:GetSymbol()
    --     return self._symbol:value()
    -- end

    function self:GetSymbol1()
        return self._symbol1:value()
    end

    function self:GetSymbol3()
        return self._symbol3:value()
    end

    -- Server only

    -- function self:SetSymbol(symbol)
    --     if self.ismastersim and self._symbol:value() ~= symbol then
    --         if self.freshsymbol ~= nil then
    --             self.freshsymbol:Cancel()
    --             self.freshsymbol = nil
    --         end

    --         if symbol ~= 0 and self.inst.components.ghostlybond.ghost:GetDebuff("elixir_extra_buff") ~= nil and self:GetSymbol1() == 0 then
    --             self:SetSymbol1(self:GetSymbol())
    --         end
            
    --         self.inst.freshsymbol = self.inst:DoTaskInTime(4.5, function()
    --             if symbol == 0 and self:GetSymbol1() ~= 0 then
    --                 local _symbol = self:GetSymbol1()
    --                 self:SetSymbol1(0)
    --                 self:SetSymbol(_symbol)
    --             end
    --         end)
    --         self._symbol:set(symbol)
    --         OnSymbolDirty(self.inst)
    --     end
    -- end

    function self:SetSymbol1(symbol)
        if self.ismastersim and self._symbol1:value() ~= symbol then
            self._symbol1:set(symbol)
            OnSymbolDirty1(self.inst)
        end
    end

    function self:SetSymbol3(symbol)
        if self.ismastersim and self._symbol3:value() ~= symbol then
            self._symbol3:set(symbol)
            OnSymbolDirty3(self.inst)
        end
    end
end)
