
local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local default_priority = 0
local _ 

local default_config = {
	enabled = true,
	menu_priority = 1,
	pin_sets = {},
	maps = {},
}

local icon_texture = [[Interface\MINIMAP\TRACKING\Profession]]
local icon_texcoord = {l=0.078125, r=0.921875, t=0.078125, b=0.921875}
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}

local Boards = {version = "v0.1", pluginname = "Boards"}
Boards.IsDisabled = true

local can_install = false

Boards.menu_text = function (plugin)
	if (Boards.db.enabled) then
		return icon_texture, icon_texcoord, L["S_PLUGIN_BOARDS_NAME"], text_color_enabled
	else
		return icon_texture, icon_texcoord, L["S_PLUGIN_BOARDS_NAME"], text_color_disabled
	end
end

Boards.menu_popup_show = function (plugin, ct_frame, param1, param2)
	RA:AnchorMyPopupFrame (Boards)
end

Boards.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	Boards.popup_frame:Hide()
end

Boards.menu_on_click = function (plugin)
	--if (not Boards.mainpanel_built) then
	--	Boards.BuildMainPanel()
	--	Boards.mainpanel_built = true
	--end
	--Boards.main_frame:Show()
	
	RA.OpenMainOptions (Boards)
end

Boards.OnInstall = function (plugin)

	Boards.db.menu_priority = default_priority

	--C_Timer.After (1, function()Boards.BuildMainPanel(); Boards.main_frame:Show() end)
	
	
end


Boards.OnEnable = function (plugin)
	-- enabled from the options panel.
	Boards:RefreshResFrame()
end

Boards.OnDisable = function (plugin)
	-- disabled from the options panel.
	plugin.bres_frame:Hide()
end

Boards.OnProfileChanged = function (plugin)
	if (plugin.db.enabled) then
		Boards.OnEnable (plugin)
		Boards:RefreshResFrame()
	else
		Boards.OnDisable (plugin)
	end
end

-------------------------------------
-->API

function Boards:GetPinSetList()
	return Boards.db.pin_sets
end

function Boards:GetPinSet (id)
	return Boards.db.pin_sets [id]
end

local name_feedback_func = function (name)
	Boards.CreateNewPinSet (_, _, name)
end

function Boards.CreateNewPinSet (self, button, name)
	if (not name) then
		Boards:ShowTextPromptPanel ("Enter the name for the new Pin Set", name_feedback_func)
	else
		if (name ~= "") then
			local seed = math.random (10000000, 99999999)
			local newpinset = {
				pins = {},
				last_edit_date = time(),
				last_edit_by = UnitName ("player"),
				seed = seed,
				boss = Boards.boss_editing_id,
				name = name,
			}
			Boards.db.pin_sets [seed] = newpinset

			Boards.main_frame.dropdown_pinset:Refresh()
			Boards.main_frame.dropdown_pinset:Select (seed)
			
			Boards.SetCurrentEditingPinSet (seed)
		end
	end
end

function Boards:BuildBossList()
	local t = {}
	
	--> hellfire citadel
	EJ_SelectInstance (669)
	for i = 1, 13 do
		t [#t+1] = {label = EJ_GetEncounterInfoByIndex (i, 669), value = "669_" .. i, onclick = Boards.OnBossSelection}
	end
	
	return t
end

function Boards:GetBossName (boss_id)
	local instance_id, boss_index = boss_id:match ("(.-)_(.)")
	EJ_SelectInstance (tonumber (instance_id))
	return EJ_GetEncounterInfoByIndex (tonumber (boss_index), tonumber (instance_id))
end

function Boards.SetCurrentBoss (boss_id)
	Boards.boss_editing_id = boss_id
	
	Boards.main_frame.dropdown_pinset:Refresh()
	Boards.main_frame.dropdown_pinset:Select (false)
end

function Boards.SaveCurrentEditingPin()
	local PinSet = Boards:GetPinSet (Boards.Boards_editing_id)
	
	-- get pins showing in the window and save them
	
	PinSet.last_edit_by = UnitName ("player")
	PinSet.last_edit_date = time()
end

function Boards.DeleteCurrentPinSet()
	Boards.db.pin_sets [Boards.Boards_editing_id] = nil

	--> check if the pinset is enabled.
	Boards.CancelPinSetEditing()
	
end

function Boards.SetCurrentEditingPinSet (id)
	Boards.Boards_editing_id = id
	
	local main_frame = Boards.main_frame

	main_frame.button_create:Disable()
	main_frame.dropdown_pinset:Disable()
	main_frame.dropdown_boss:Disable()
	
	main_frame.button_erase:Enable()
	main_frame.button_cancel:Enable()
	main_frame.button_clear:Enable()
	main_frame.button_save:Enable()
	main_frame.button_save2:Enable()
	
	local PinSet = Boards:GetPinSet (id)
	
	-- load all pins and put in the main panel
	
end

function Boards.GetCurrentEditingPinSet()
	return Boards.Boards_editing_id
end

function Boards.CancelPinSetEditing()
	Boards.Boards_editing_id = nil
	
	local main_frame = Boards.main_frame
	
	main_frame.button_create:Enable()
	main_frame.dropdown_pinset:Enable()
	main_frame.dropdown_boss:Enable()
	
	main_frame.button_erase:Disable()
	main_frame.button_cancel:Disable()
	main_frame.button_clear:Disable()
	main_frame.button_save:Disable()
	main_frame.button_save2:Disable()
	
	Boards.main_frame.dropdown_pinset:Refresh()
	Boards.main_frame.dropdown_pinset:Select (false)
	
	-- clear the pin panel
end

function Boards.ClearAllPinsFromCurrentPinSet()
	local pinset = Boards.GetCurrentEditingPinSet()
	
	-- do the pin wipe
	
end

function Boards.SendCurrentEditingPin()
	--> send to others
end

function Boards.FillMap (map)
	local f = BoardsPreviewFrame
	for i = 1, 12 do
		f.Pieces [i]:SetTexture (map [i])
	end
end

local map = {
	"Interface\\WorldMap\\HellfireRaid\\HellfireRaid1", -- [1]
	"Interface\\WorldMap\\HellfireRaid\\HellfireRaid2", -- [2]
	"Interface\\WorldMap\\HellfireRaid\\HellfireRaid3", -- [3]
	"Interface\\WorldMap\\HellfireRaid\\HellfireRaid4", -- [4]
	"Interface\\WorldMap\\HellfireRaid\\HellfireRaid5", -- [5]
	"Interface\\WorldMap\\HellfireRaid\\HellfireRaid6", -- [6]
	"Interface\\WorldMap\\HellfireRaid\\HellfireRaid7", -- [7]
	"Interface\\WorldMap\\HellfireRaid\\HellfireRaid8", -- [8]
	"Interface\\WorldMap\\HellfireRaid\\HellfireRaid9", -- [9]
	"Interface\\WorldMap\\HellfireRaid\\HellfireRaid10", -- [10]
	"Interface\\WorldMap\\HellfireRaid\\HellfireRaid11", -- [11]
	"Interface\\WorldMap\\HellfireRaid\\HellfireRaid12", -- [12]
}

SLASH_BOARDS1 = "/b"
function SlashCmdList.BOARDS (msg, editbox)

	if (msg == "save") then
		
		local nname = function (name)
			Boards.db.maps [name] = {}
			local dumped = {}
			for i = 1, 12 do 
				Boards.db.maps [name][i] = _G ["WorldMapDetailTile" .. i]:GetTexture()
			end
			print ("SAVED:", name)
		end
		Boards:ShowTextPromptPanel ("Enter the name for save the map", nname)
		
	else
		local dumped = {}
		for i = 1, 12 do 
			dumped [i] = _G ["WorldMapDetailTile" .. i]:GetTexture()
		end
		Boards.FillMap (dumped)
	end
end

-------------------------------------
--> Main Panel

function Boards.BuildMainPanel()

	local main_frame = Boards.main_frame
	
	main_frame:SetSize (900, 600)
	
	--> dropdown for boss selection
	local label_boss = Boards:CreateLabel (main_frame, "Boss" .. ":", Boards:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	function Boards.OnBossSelection (self, fixed_value, selected_value)
		Boards.SetCurrentBoss (selected_value)
	end
	
	local boss_list = Boards:BuildBossList()
	local build_boss_list = function()
		return boss_list
	end
	local dropdown_boss = Boards:CreateDropDown (main_frame, build_boss_list, 1, 160, 20, "dropdown_boss", _, Boards:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	label_boss:SetPoint (10, -40)
	dropdown_boss:SetPoint ("topleft", label_boss, "bottomleft", 0, -5)
	
	
	--> dropdown for pinset selection
	local label_pinset = Boards:CreateLabel (main_frame, "Boards" .. ":", Boards:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	local on_Boards_selection = function (self, fixed_value, selected_value)
		Boards.SetCurrentEditingPinSet (selected_value)
	end
	local build_pinset_list = function()
		local t = {}
		for id, pinset_table in pairs (Boards:GetPinSetList()) do
			if (pinset_table.boss == Boards.boss_editing_id) then
				t [#t+1] = {label = pinset_table.name, value = id, onclick = on_Boards_selection, desc = pinset_table.text}
			end
		end
		return t
	end
	local dropdown_pinset = Boards:CreateDropDown (main_frame, build_pinset_list, 1, 160, 20, "dropdown_pinset", _, Boards:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
	label_pinset:SetPoint (10, -85)
	dropdown_pinset:SetPoint ("topleft", label_pinset, "bottomleft", 0, -5)

	--> map frame
	local f = CreateFrame ("frame", "BoardsPreviewFrame", main_frame)
	f:SetPoint ("topleft", dropdown_boss.widget, "topright", 10, 0)
	f:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
	f:SetBackdropColor (0, 0, 0, 0.8)
	f:SetBackdropBorderColor (0, 0, 0, 1)
	f:SetSize (700, 500)
	
	f.Pieces = {}
	
	local x, y = 0, 0
	local w, h = 4 + (f:GetWidth()/4), 25 + (f:GetHeight()/3)
	local counter = 1
	for o = 1, 3 do
		for i = 1, 4 do
			local t = f:CreateTexture (nil, "artwork")
			t:SetPoint ("topleft", f, x, y)
			t:SetSize (w, h)
			x = x + w
			f.Pieces [counter] = t
			counter = counter + 1
		end
		x, y = 0, y - h
	end
	
	--> toolbar buttons
	local buttons_y, buttons_width = -567, 70
	
	local create_button = Boards:CreateButton (main_frame, Boards.CreateNewPinSet, buttons_width, 20, "New", _, _, _, "button_create", _, _, Boards:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Boards:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	create_button:SetPoint ("topleft", main_frame, "topleft", 10 , buttons_y)
	
	--delete note "Erase"
	local erase_button =  Boards:CreateButton (main_frame, Boards.DeleteCurrentPinSet, buttons_width, 20, "Erase Note", _, _, _, "button_erase", _, _, Boards:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Boards:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	erase_button:SetPoint ("topleft", main_frame, "topleft", 90 , buttons_y)

	--clear "Clear"
	local clear_button =  Boards:CreateButton (main_frame, Boards.ClearAllPinsFromCurrentPinSet, buttons_width, 20, "Clear", _, _, _, "button_clear", _, _, Boards:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Boards:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	clear_button:SetPoint ("topleft", main_frame, "topleft", 310 , buttons_y)
	
	--save "Save"
	local save_button =  Boards:CreateButton (main_frame, Boards.SaveCurrentEditingPin, buttons_width, 20, "Save", _, _, _, "button_save", _, _, Boards:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Boards:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	save_button:SetPoint ("topleft", main_frame, "topleft", 390, buttons_y)
	
	local save_changes_and_send = function()
		Boards.SaveCurrentEditingPin()
		Boards.SendCurrentEditingPin()
	end
	
	local save_changes_and_close = function()
		Boards.SaveCurrentEditingPin()
		Boards.CancelPinSetEditing()
	end
	
	--save and send "Save and Send"
	local save2_button =  Boards:CreateButton (main_frame, save_changes_and_send, buttons_width, 20, "Send", _, _, _, "button_save2", _, _, Boards:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Boards:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	save2_button:SetPoint ("topleft", main_frame, "topleft", 470 , buttons_y)
	--cancel edition "Cancel"
	local cancel_button =  Boards:CreateButton (main_frame, save_changes_and_close, buttons_width, 20, "Done", _, _, _, "button_cancel", _, _, Boards:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"), Boards:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
	cancel_button:SetPoint ("topleft", main_frame, "topleft", 550 , buttons_y)	
	
	main_frame.button_erase:Disable()
	main_frame.button_cancel:Disable()
	main_frame.button_clear:Disable()
	main_frame.button_save:Disable()
	main_frame.button_save2:Disable()
	
	dropdown_boss:Refresh()
	dropdown_boss:Select (1, true)
	Boards.boss_editing_id = dropdown_boss.value
	dropdown_pinset:Refresh()
	dropdown_pinset:Select (false)
	
	Boards.mainpanel_built = true

	
	Boards.FillMap (map)
end

if (can_install) then
	local install_status = RA:InstallPlugin (L["S_PLUGIN_BOARDS_NAME"], "RABoards", Boards, default_config)
end
