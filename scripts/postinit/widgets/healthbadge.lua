local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local WagBossUtil = require("prefabs/wagboss_util")


AddClassPostConstruct("widgets/healthbadge", function(self, owner, colour, iconbuild, bonuscolor)
	self.inst:DoTaskInTime(0.1,function()
		self.underNumber:MoveToFront()
	end)

    self.bufficon2 = self.underNumber:AddChild(UIAnim())
    self.bufficon2:GetAnimState():SetBank("status_abigail")
    self.bufficon2:GetAnimState():SetBuild("status_abigail")
    self.bufficon2:GetAnimState():PlayAnimation("buff_none")
    self.bufficon2:GetAnimState():AnimateWhilePaused(false)
    self.bufficon2:SetClickable(false)
    self.bufficon2:SetScale(1,1,1)
    self.buffsymbol2 = 0

    function self:ShowBuff(symbol)
        if symbol == 0 then
            if self.buffsymbol ~= 0 then
                self.bufficon:GetAnimState():PlayAnimation("buff_deactivate")
                self.bufficon:GetAnimState():PushAnimation("buff_none", false)
            end
        elseif symbol ~= self.buffsymbol then
            self.bufficon:GetAnimState():OverrideSymbol("buff_icon", self.OVERRIDE_SYMBOL_BUILD[symbol] or self.default_symbol_build, symbol)
    
            self.bufficon:GetAnimState():PlayAnimation("buff_activate")
            self.bufficon:GetAnimState():PushAnimation("buff_idle", false)
        end
    
        self.buffsymbol = symbol
    end
    
    function self:UpdateBuff(symbol)
        self:ShowBuff(symbol)
    end
    
    function self:ShowBuff2(symbol)
        if symbol == 0 then
            if self.buffsymbol2 ~= 0 then
                self.bufficon2:GetAnimState():PlayAnimation("buff_deactivate")
                self.bufficon2:GetAnimState():PushAnimation("buff_none", false)
            end
        elseif symbol ~= self.buffsymbol2 then
            self.bufficon2:GetAnimState():OverrideSymbol("buff_icon", self.OVERRIDE_SYMBOL_BUILD[symbol] or self.default_symbol_build, symbol)
    
            self.bufficon2:GetAnimState():PlayAnimation("buff_activate")
            self.bufficon2:GetAnimState():PushAnimation("buff_idle", false)
        end
    
        self.buffsymbol2 = symbol
    end
    
    function self:UpdateBuff2(symbol)
        self:ShowBuff2(symbol)
    end    
end)