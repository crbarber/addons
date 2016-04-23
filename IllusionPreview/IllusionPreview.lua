local illusions = { 		
	["173716"] = 5387, -- Agility
	["173717"] = 2675, -- Battlemaster
	["173718"] = 5391, -- Berserking
	["174979"] = 5392, -- Blood Draining
	["173720"] = 5393, -- Crusader
	["175076"] = 5398, -- Earthliving
	["173721"] = 4443, -- Elemental Force
	["173722"] = 3225, -- Executioner
	["173723"] = 803, -- Fiery Weapon
	["175072"] = 5400, -- Flametongue
	["175071"] = 5399, -- Frostbrand
	["173719"] = 5388, -- Greater Spellpower
	["173724"] = 5360, -- Hidden
	["175070"] = 4442, -- Jade Spirit
	["173725"] = 4099, -- Landslide
	["173726"] = 1898, -- Lifestealing
	["175085"] = 4066, -- Mending
	["173727"] = 2673, -- Mongoose
	["173728"] = 5364, -- Poisoned
	["173729"] = 4097, -- Power Torrent
	["175086"] = 4446, -- River's Song
	["175078"] = 5402, -- Rockbiter
	["173730"] = 2674, -- Spellsurge
	["173731"] = 5389, -- Striking
	["173732"] = 1899, -- Unholy
	["175074"] = 5401, -- Windfury
	["177355"] = -1, -- Remove Illusion
}

local f = CreateFrame("Frame") 

f:SetScript("OnEvent", function(self, event, addon) 

	if addon == "Blizzard_TradeSkillUI" then	
	
		for i=1, 8 do
			local button = _G["TradeSkillSkill"..i] 			
			
			button:HookScript("OnClick", function(self, button)						
				local spellID = strmatch(GetTradeSkillItemLink(self:GetID()), "^.-enchant:(%d+)")
				local enchantID = illusions[spellID]
				
				if IsControlKeyDown() and enchantID then		
								
					local slot = GetInventorySlotInfo(IsShiftKeyDown() and "SecondaryHandSlot" or "MainHandSlot") 
					local link = GetInventoryItemLink("player", slot)
					local before, currentID, after = strmatch(link, "^(.-Hitem:)[^:]+:([^:]+)(:.*)$") 
					local visibleID = select(6, GetTransmogrifySlotInfo(slot)) 
					
					if enchantID == -1 then -- Remove Illusion
						enchantID = currentID
					end 
					
					DressUpItemLink(before .. visibleID .. ":" .. enchantID .. after) 							
					
				end 
			end) 
		end 
		self:UnregisterEvent("ADDON_LOADED") 
	end 
end) 

f:RegisterEvent("ADDON_LOADED")		