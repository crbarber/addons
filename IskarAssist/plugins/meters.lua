

local RA = RaidAssist
local L = LibStub ("AceLocale-3.0"):GetLocale ("RaidAssistAddon")
local _
local default_priority = 0

local StopMeters = {version = "v0.1", pluginname = "Meters"}
StopMeters.IsDisabled = true


local default_config = {
	enabled = true,
	stop_recount = true,
	stop_skada = true,
	stop_details = true,
}

local icon_texcoord = {l=32/512, r=64/512, t=0, b=1}
local text_color_enabled = {r=1, g=1, b=1, a=1}
local text_color_disabled = {r=0.5, g=0.5, b=0.5, a=1}
local icon_texture = [[Interface\AddOns\IskarAssist\media\plugin_icons]]

local can_install = false

StopMeters.menu_text = function (plugin)
	if (StopMeters.db.enabled) then
		return icon_texture, icon_texcoord, "Stop Meters", text_color_enabled
	else
		return icon_texture, icon_texcoord, "Stop Meters", text_color_disabled
	end
end

StopMeters.menu_popup_show = function (plugin, ct_frame, param1, param2)
	RA:AnchorMyPopupFrame (StopMeters)
end

StopMeters.menu_popup_hide = function (plugin, ct_frame, param1, param2)
	StopMeters.popup_frame:Hide()
end

StopMeters.menu_on_click = function (plugin)
	--if (not StopMeters.options_built) then
	--	StopMeters.BuildOptions()
	--	StopMeters.options_built = true
	--end
	--StopMeters.main_frame:Show()
	
	RA.OpenMainOptions (StopMeters)
end

function StopMeters.PluginCommReceived (data)
	local _, prefix, player_name = unpack (data)
	local chr_name = Ambiguate (player_name, "none")
	if (UnitIsGroupLeader (chr_name)) then
		if (UnitIsInMyGuild (chr_name)) then
		
			--> Details! Damage Meter
			local Details = Details
			if (Details) then
				if (Details:IsInCombat() and Details:IsInEncounter()) then
					Details:CallWipe()
				end
			end
			
			--> Skada
			local Skada = Skada
			if (Skada) then
				if (Skada.current and not not Skada.current.stopped) then
					Skada:StopSegment()
				end
			end
			
			--> Recount
			
			
		end
	end
end

StopMeters.OnInstall = function (plugin)

	StopMeters.db.menu_priority = default_priority

	StopMeters:RegisterPluginComm ("SM", StopMeters.PluginCommReceived)
	StopMeters:RegisterEvent ("ENCOUNTER_START")
	StopMeters:RegisterEvent ("ENCOUNTER_STOP")
end



StopMeters.OnEnable = function (plugin)
	-- enabled from the options panel.
	
end

StopMeters.OnDisable = function (plugin)
	-- disabled from the options panel.
	
end

StopMeters.OnProfileChanged = function (plugin)
	if (plugin.db.enabled) then
		StopMeters.OnEnable (plugin)
	else
		StopMeters.OnDisable (plugin)
	end
	
	if (plugin.options_built) then
		--plugin.main_frame:RefreshOptions()
	end
end

function StopMeters:ENCOUNTER_START()
	StopMeters.in_encounter = true
end
function StopMeters:ENCOUNTER_STOP()
	StopMeters.in_encounter = false
end


function StopMeters.OnShowOnOptionsPanel()
	local OptionsPanel = StopMeters.OptionsPanel
	StopMeters.BuildOptions (OptionsPanel)
	
end
function StopMeters.BuildOptions (frame)

end

if (can_install) then
	local install_status = RA:InstallPlugin ("Stop Meters", "RAStopMeters", StopMeters, default_config)
end

SLASH_StopMeters1, SLASH_StopMeters2 = "/stop", "/stopmeters"
function SlashCmdList.StopMeters (msg, editbox)
	if (not IsInRaid (LE_PARTY_CATEGORY_HOME)) then
		return StopMeters:Msg ("You aren't in a raid group.")
	elseif (not UnitIsGroupLeader ("player")) then
		return StopMeters:Msg ("You aren't the group leader.")
	elseif (not StopMeters.in_encounter) then
		return StopMeters:Msg ("You aren't in a raid encounter.")
	end
	
	StopMeters:SendPluginCommMessage ("SM", "RAID-NOINSTANCE", _, _, StopMeters:GetPlayerNameWithRealm())
	StopMeters:Msg ("Meters has been stop.")
end
