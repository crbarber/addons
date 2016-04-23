
local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local _ 
local default_priority = 1

--battle res default config
local default_config = {
	enabled = true,
	menu_priority = 1,
	saved_lists = {},
	latest_raid_map = 1448,
}

local icon_texture = [[Interface\PaperDollInfoFrame\UI-EquipmentManager-Toggle]]
local icon_texcoord = {l=0.078125, r=0.921875, t=0.078125, b=0.921875}
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}

local BisListRaid = {version = "v0.1", pluginname = "BisListRaid"}
BisListRaid.IsDisabled = true

local BisList = _G ["RaidAssistBisList"]

local can_install = false

BisListRaid.last_data_request = 0
BisListRaid.last_data_sent = 0

BisListRaid.menu_text = function (plugin)
	if (BisListRaid.db.enabled) then
		return icon_texture, icon_texcoord, "Loot (Raid List)", text_color_enabled
	else
		return icon_texture, icon_texcoord, "Loot (Raid List)", text_color_disabled
	end
end

BisListRaid.menu_popup_show = function (plugin, ct_frame, param1, param2)
	RA:AnchorMyPopupFrame (BisListRaid)
end

BisListRaid.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	BisListRaid.popup_frame:Hide()
end

BisListRaid.menu_on_click = function (plugin)
	--if (not BisListRaid.options_built) then
	--	BisListRaid.BuildOptions()
	--	BisListRaid.options_built = true
	--end
	--BisListRaid.main_frame:Show()
	
	RA.OpenMainOptions (BisListRaid)
end

BisListRaid.OnInstall = function (plugin)

	BisListRaid.db.menu_priority = default_priority

	BisListRaid:RegisterPluginComm ("BLR", BisListRaid.PluginCommReceived)
	BisListRaid:RegisterPluginComm ("BLC", BisListRaid.PluginCommReceived)

	BisListRaid:RegisterForEnterRaidGroup (BisListRaid.OnEnterRaidGroup)
	BisListRaid:RegisterForLeaveRaidGroup (BisListRaid.OnLeaveRaidGroup)
	
	--C_Timer.After (5, BisListRaid.menu_on_click)
	
	BisListRaid.main_frame:SetScript ("OnShow", function()
		BisListRaid.QueryData()
	end)
end

BisListRaid.OnEnable = function (plugin)
	-- enabled from the options panel.
	BisListRaid:RefreshResFrame()
end

BisListRaid.OnDisable = function (plugin)
	-- disabled from the options panel.

end

BisListRaid.OnProfileChanged = function (plugin)
	if (plugin.db.enabled) then
		BisListRaid.OnEnable (plugin)
		BisListRaid:RefreshResFrame()
	else
		BisListRaid.OnDisable (plugin)
	end
	
	if (plugin.options_built) then
		plugin.main_frame:RefreshOptions()
	end
end

function BisListRaid.QueryData()
	if (BisListRaid.last_data_request+30 > time() or not BisListRaid.in_group or not IsInRaid (LE_PARTY_CATEGORY_HOME) or not BisListRaid:UnitHasAssist ("player")) then
		return
	end
	BisListRaid:SendPluginCommMessage ("BLR", "RAID-NOINSTANCE", _, _, BisListRaid:GetPlayerNameWithRealm())
	BisListRaid.last_data_request = time()
end

function BisListRaid.SendMyBisList (player_name)
	if (player_name and not BisListRaid:UnitHasAssist (player_name)) then
		return
	end
	if (not IsInRaid (LE_PARTY_CATEGORY_HOME)) then
		return
	end
	
	if (BisListRaid.last_data_sent+30 > time()) then
		if (BisListRaid.sending_timer and not BisListRaid.sending_timer._cancelled) then
			BisListRaid.sending_timer:Cancel()
		end
		BisListRaid.sending_timer = C_Timer.NewTimer (BisListRaid.last_data_sent+30-time(), BisListRaid.SendMyBisList)
	end
	
	local bislist = BisList:GetCharacterItemList()
	local current_items = BisList:GetMyItems()
	
	local s = ""
	for index, item_id in ipairs (bislist) do
		s = s .. item_id .. ":" .. current_items [index] .. ","
	end
	
	BisListRaid:SendPluginCommMessage ("BLC", "RAID-NOINSTANCE", _, _, BisListRaid:GetPlayerNameWithRealm(), s)
	BisListRaid.last_data_sent = time()
end

function BisListRaid.StoreReceivedBisList (player_name, item_string)
	local guid = UnitGUID (player_name)
	if (guid) then
		BisListRaid.db.saved_lists [guid] = item_string
		if (BisListRaid.main_frame:IsShown()) then
			BisListRaid.main_frame:Refresh()
		end
	end
end

function BisListRaid.PluginCommReceived (data)

	if (true) then
		return
	end

	local _, prefix, player_name, item_string = unpack (data)
	if (prefix == "BLR") then
		BisListRaid.SendMyBisList (player_name)
	elseif (prefix == "BLC") then
		BisListRaid.StoreReceivedBisList (player_name, item_string)
	end
end

function BisListRaid.OnEnterRaidGroup()
	BisListRaid.QueryData()
end

function BisListRaid.OnLeaveRaidGroup()
	return
end

function BisListRaid.OnShowOnOptionsPanel()
	local OptionsPanel = BisListRaid.OptionsPanel
	BisListRaid.BuildOptions (OptionsPanel)
end

function BisListRaid.BuildOptions (frame)
	
	if (frame.FirstRun) then
		return
	end
	frame.FirstRun = true	
	
	--window object
	local main_frame = frame
	BisListRaid.main_frame = frame
	main_frame:SetSize (422, 385)

	function main_frame:Refresh()
		
		--refresh function
		
	end
	
	--select encounter dropdown
	local on_select_boss = function (_, _, encounter_id)
		main_frame:Refresh()
		
		
		
	end
	local dropdown_build_encounter_lsit = function()
		local isIn, type = IsInInstance()
		local mapid
		if (not isIn or type ~= "raid") then
			mapid = BisListRaid.db.latest_raid_map
		end
		local encounters = BisListRaid:GetCurrentRaidEncounterList (mapid)
		local t = {}
		for index, encounter in ipairs (encounters) do
			local bossname, encounterid = unpack (encounter)
			tinsert (t, {value = encounterid, label = bossname, onclick = on_select_boss})
		end
		
		return t
	end

	local label_boss = BisListRaid:CreateLabel (main_frame, "Boss" .. ": ", BisListRaid:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	local dropdown_boss = BisListRaid:CreateDropDown (main_frame, dropdown_build_encounter_lsit, 1, 160, 20, "dropdown_boss_list", _, BisListRaid:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	dropdown_boss:SetPoint ("left", label_boss, "right", 2, 0)
	label_boss:SetPoint (10, -40)
	
	local fill_panel = BisListRaid:CreateFillPanel (main_frame, {}, 412, 320, false, false, true, {rowheight = 16}, "fill_panel", "BisListRaidFillPanel")
	fill_panel:SetPoint ("topleft", main_frame, "topleft", 5, -60)

end

if (can_install) then
	local install_status = RA:InstallPlugin ("BisListRaid", "RABisListRaid", BisListRaid, default_config)
end
