
AddClassPostConstruct("widgets/statusdisplays", function(self)
    -- 阿比盖尔多药剂
    function self:RefreshPetHealth()
        local pethealthbar = self.owner.components.pethealthbar
        self.pethealthbadge:SetValues(pethealthbar:GetSymbol(), pethealthbar:GetSymbol1(), pethealthbar:GetSymbol2(),pethealthbar:GetSymbol3(), pethealthbar:GetPercent(), pethealthbar:GetOverTime(), pethealthbar:GetMaxHealth(), pethealthbar:GetPulse(), pethealthbar:GetMaxBonus(), pethealthbar:GetPercentBonus())
        pethealthbar:ResetPulse()
    end

    -- 玩家的多药剂药剂        
    function self:RefreshHealthBuff2()   
        -- print("RefreshHealthBuff called! Symbol:", self.owner._buffsymbol2:value())
        self.heart:UpdateBuff2(self.owner._buffsymbol2:value())
    end    
    -- 如果需要监听第二个网络变量的变化
    if self.owner and self.owner._buffsymbol2 then
        self.inst:ListenForEvent("healthbarbuffsymboldirty", function()
            self:RefreshHealthBuff2()
        end, self.owner)
    end
end)