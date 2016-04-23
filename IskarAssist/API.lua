

local RA = RaidAssist

--[=[
	RA:GetPopupAttachAnchors()
	get the anchors for the 'menu_popup_show' function. making your popup frame attach on the menu.
	the 'menu_popup_show' return on its seconds parameter the menu frame.
	use: ANCHOR1, <menu_frame>, ANCHOR2, X, Y
--]=]
function RA:GetPopupAttachAnchors()
	local anchor_side = RA.db.profile.addon.anchor_side
	local anchor1, anchor2, x, y
	
	if (anchor_side == "left") then
		anchor1, anchor2, x, y = "left", "right", 4, 0
	elseif (anchor_side == "right") then
		anchor1, anchor2, x, y = "right", "left", -4, 0
	elseif (anchor_side == "top") then
		anchor1, anchor2, x, y = "topleft", "topright", 4, 0
	elseif (anchor_side == "bottom") then
		anchor1, anchor2, x, y = "bottomleft", "right", 4, 0
	end
	
	return anchor1, anchor2, x, y
end

--[=[
	RA:AnchorMyPopupFrame (plugin)
--]=]
function RA:AnchorMyPopupFrame (plugin)
	assert (type (plugin) == "table" and plugin.popup_frame, "AnchorMyPopupFrame expects a plugin object on parameter 1.")
	local ct_frame = GameCooltipFrame1
	local anchor1, anchor2, x, y = RA:GetPopupAttachAnchors()
	plugin.popup_frame:SetPoint (anchor1, ct_frame, anchor2, x, y)
	plugin.popup_frame:Show()
end

--[=[
	RA:InstallPlugin (name, frame_name, plugin_object, default_config)
	name: string, name of the plugin.
	frame_name: string, name for the plugin frames.
	plugin_object: table, with all the plugin functions.
	default_config: table, with key and values to store on db.
--]=]
function RA:InstallPlugin (name, frame_name, plugin_object, default_config)
	assert (type (name) == "string", "InstallPlugin expects a string on parameter 1.")
	assert (type (frame_name) == "string", "InstallPlugin expects a string on parameter 2.")
	assert (not RA.plugins [name], "Plugin name " ..name.." already in use.")
	assert (type (plugin_object) == "table", "InstallPlugin expects a table on parameter 3.")
	
	if (not RA.db) then
		RA.schedule_install [#RA.schedule_install+1] = {name, frame_name, plugin_object, default_config}
		return "scheduled"
	end
	
	RA.plugins [name] = plugin_object
	plugin_object.db_default = default_config or {}
	setmetatable (plugin_object, RA)

	RA:LoadPluginDB (name, true)

	if (plugin_object.db.menu_priority == nil) then
		plugin_object.db.menu_priority = 1
	end
	
	plugin_object.popup_frame = RA:CreatePopUpFrame (plugin_object, frame_name .. "PopupFrame")
	plugin_object.main_frame = RA:CreatePluginFrame (plugin_object, frame_name .. "MainFrame", name)

	if (plugin_object.OnInstall) then
		local err = geterrorhandler()
		xpcall (plugin_object.OnInstall, err, plugin_object)
	end
	
	return "successful"
end

--[=[
	RA:EnablePlugin (name)
	Turn on a plugin and calls OnEnable member if exists.
--]=]
function RA:EnablePlugin (name)
	assert (type (name) == "string", "DisablePlugin expects a string on parameter 1.")
	local plugin = RA.plugins [name]
	if (plugin) then
		plugin.db.enabled = true
		if (plugin.OnEnable) then
			pcall (plugin.OnEnable, plugin)
		end
	end
end

--[=[
	RA:DisablePlugin (name)
	Turn off a plugin and calls OnDisable member if exists.
--]=]
function RA:DisablePlugin (name)
	assert (type (name) == "string", "DisablePlugin expects a string on parameter 1.")
	local plugin = RA.plugins [name]
	if (plugin) then
		plugin.db.enabled = false
		if (plugin.OnDisable) then
			pcall (plugin.OnDisable, plugin)
		end
	end
end

--[=[
	RA:GetPluginList()
	return the plugin list.
--]=]
function RA:GetPluginList()
	return RA.plugins
end

--[=[
	RA:RegisterPluginComm (prefix, func)
	prefix (string) combination of two-four letters for identify the function which will receive the data.
	func (function) a function to be called when receive data with the prefix.
--]=]
function RA:RegisterPluginComm (prefix, func)
	assert (type (prefix) == "string", "RegisterPluginComm expects a string on parameter 1.")
	assert (type (func) == "function", "RegisterPluginComm expects a function on parameter 2.")
	RA.comm [prefix] = func
end

--[=[
	RA:UnregisterPluginComm (prefix)
	prefix (string) a previous registered prefix.
--]=]
function RA:UnregisterPluginComm (prefix, func)
	assert (type (prefix) == "string", "RegisterPluginComm expects a string on parameter 1.")
	RA.comm [prefix] = nil
end

--[=[
	RA:SendPluginCommMessage (prefix, channel, ...)
	
	Is a customized function to use when sending comm messages.
	SendCommMessage / CommReceived / RegisterComm can all be used directly from the plugin.
	
	prefix (string) receiving func identification.
	channel (string) which channel the comm is sent.
	callback (function) called after the message as fully sent.
	callback_param (any value), param to be added within callback.
	... all parameter to be send within the comm.
--]=]

function RA:SendPluginCommWhisperMessage (prefix, target, callback, callback_param, ...)
	RA:SendCommMessage (RA.comm_prefix, RA:Serialize (prefix, self.version or "", ...), "WHISPER", target, nil, callback, callback_param)
end

function RA:SendPluginCommMessage (prefix, channel, callback, callback_param, ...)
	assert (type (prefix) == "string", "SendPluginCommMessage expects a string on parameter 1.")
	if (callback) then
		assert (type (callback) == "function", "SendPluginCommMessage expects a function as callback (optional).")
	end
	if (channel == "RAID-NOINSTANCE") then
		if (IsInRaid (LE_PARTY_CATEGORY_HOME)) then
			RA:SendCommMessage (RA.comm_prefix, RA:Serialize (prefix, self.version or "", ...), "RAID", nil, nil, callback, callback_param)
		end
	elseif (channel == "RAID") then
		if (IsInRaid (LE_PARTY_CATEGORY_INSTANCE)) then
			RA:SendCommMessage (RA.comm_prefix, RA:Serialize (prefix, self.version or "", ...), "INSTANCE_CHAT", nil, nil, callback, callback_param)
		else
			RA:SendCommMessage (RA.comm_prefix, RA:Serialize (prefix, self.version or "", ...), "RAID", nil, nil, callback, callback_param)
		end
	elseif (channel == "PARTY-NOINSTANCE") then
		if (IsInGroup (LE_PARTY_CATEGORY_HOME)) then
			RA:SendCommMessage (RA.comm_prefix, RA:Serialize (prefix, self.version or "", ...), "PARTY", nil, nil, callback, callback_param)
		end
	elseif (channel == "PARTY") then
		if (IsInGroup (LE_PARTY_CATEGORY_INSTANCE)) then
			RA:SendCommMessage (RA.comm_prefix, RA:Serialize (prefix, self.version or "", ...), "INSTANCE_CHAT", nil, nil, callback, callback_param)
		else
			RA:SendCommMessage (RA.comm_prefix, RA:Serialize (prefix, self.version or "", ...), "PARTY", nil, nil, callback, callback_param)
		end
	else
		RA:SendCommMessage (RA.comm_prefix, RA:Serialize (prefix, self.version or "", ...), channel, nil, nil, callback, callback_param)
	end
end

--[=[
	RA:IsAddOnInstalled (addon_name)
	return if the user has a addon installed and if is enabled or not.
	addon_name (string) name of an addon.
--]=]
function RA:IsAddOnInstalled (addon_name)
	assert (type (addon_name) == "string", "IsAddOnInstalled expects a string on parameter 1.")
	local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo (addon_name)
	
	-- need to check ingame what the values is returning.
	print (name, loadable, reason)
end

--[=[
	RA:RegisterForCLEUEvent (event, func)
	register a sub event of combat log and calls a function when this event happens.
	event (string) name of the CLEU token, e.g. SPELL_DAMAGE, SPELL_INTERRUPT.
	func (function) it's called when the event is triggered.
--]=]
function RA:RegisterForCLEUEvent (event, func)
	RA.CLEU_read_events [event] = true
	if (not RA.CLEU_registered_events [event]) then
		RA.CLEU_registered_events [event] = {}
	end
	tinsert (RA.CLEU_registered_events [event], func)
end

--[=[
	RA:UnregisterForCLEUEvent (event, func)
	unregister a previous registered event of combat log.
	event (string) the event previous registered.
	func (function) the function previous registered.
--]=]
function RA:UnregisterForCLEUEvent (event, func)
	if (RA.CLEU_registered_events [event]) then
		for index, f in ipairs (RA.CLEU_registered_events [event]) do 
			if (f == func) then
				tremove (RA.CLEU_registered_events [event], index)
				break
			end
		end
		if (#RA.CLEU_registered_events [event] < 1) then
			RA.CLEU_read_events [event] = nil
		end
	end
end

--[=[
	RA:GetRepairStatus()
	return the durability amount from the player's equipment.
--]=]
function RA:GetRepairStatus()
	local percent, items = 0, 0
	for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local durability, maxdurability = GetInventoryItemDurability (i)
		if (durability and maxdurability) then
			local p = durability / maxdurability * 100
			percent = percent + p
			items = items + 1
		end
	end

	if (items == 0) then
		return 100
	end

	return percent / items
end

--[=[
	RA:GetSloppyEquipment()
	return two tables containing the slot id of items without enchats and gems.
--]=]
local can_enchant_slot = {
	[INVSLOT_NECK] = true,
	[INVSLOT_FINGER1] = true,
	[INVSLOT_FINGER2] = true,
	[INVSLOT_BACK] = true,
	[INVSLOT_MAINHAND] = true,
}
local stats_table = {}
function RA:GetSloppyEquipment()

	local no_enchant = {}
	local no_gem = {}

	for equip_id = 1, 17 do
		if (equip_id ~= 4) then --shirt slot
			local item = GetInventoryItemLink ("player", equip_id)
			if (item) then
				local _, _, enchant, gemID1, gemID2, gemID3, gemID4 = strsplit (":", item)
				
				if (can_enchant_slot [equip_id] and enchant == "0") then
					no_enchant [#no_enchant+1] = equip_id
				end
				
				stats_table.EMPTY_SOCKET_PRISMATIC = nil
				GetItemStats (item, stats_table)
				
				--all sockets on WoD are prismatic, we are save to make this
				if (stats_table.EMPTY_SOCKET_PRISMATIC) then
					--in WoD, no item has more than 1 slot
					if (gemID1 == "0") then
						no_gem [#no_gem+1] = equip_id
					end
				end
			end
		end
	end

	return no_enchant, no_gem
end

--[=[
	RA:GetTalents()
	return a table where the first index is the specialization ID and the other 7 indexes are the IDs for the chosen talents.
--]=]
function RA:GetTalents()
	local spec_slot = GetActiveSpecGroup()
	if (spec_slot) then
		local talent_info = {}
		local id, name, description, icon, background, role = GetSpecializationInfo (spec_slot)
		talent_info [#talent_info+1] = id
		
		for i = 1, 7 do
			for o = 1, 3 do
				local talentID, name, texture, selected, available = GetTalentInfo (i, o, spec_slot)
				if (selected) then
					talent_info [#talent_info+1] = talentID
					break
				end
			end
		end
		
		return talent_info
	end
	return {}
end

--[=[
	RA:GetGuildRanks (for_dropdown)
	return a table with ranks for the player guild or a formated table for use on dropdowns.
--]=]
function RA:GetGuildRanks (for_dropdown)
	if (for_dropdown) then
		local t = {}
		for i = 1, GuildControlGetNumRanks() do 
			tinsert (t, {value = i, label = GuildControlGetRankName (i), onclick = empty_func})
		end
		return t
	else
		local t = {}
		for i = 1, GuildControlGetNumRanks() do 
			t [i] = GuildControlGetRankName (i)
		end
		return t
	end
end

--[=[
	RA:IsInQueue()
	return is the player is in queue for bg, arena, dungeon, rf, premade.
--]=]
function RA:IsInQueue()
	for LFG_CATEGORY = 1, 5 do 
		if (GetLFGMode (LFG_CATEGORY)) then
			return true
		end
	end
end

--[=[
	Friendship functions:
	RA:IsBnetFriend (character_name): return if the character is your bnet friend.
	RA:IsFriend (character_name): return if the character is in your friend list.
	RA:IsGuildFriend (character_name): return if the character is in the same guild as the player.
--]=]

function RA:IsBnetFriend (who)
	who = RA:RemoveRealName (who)
	local bnet_friends_amt = BNGetNumFriends()
	for i = 1, bnet_friends_amt do 
		local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isRIDFriend, broadcastTime, canSoR = BNGetFriendInfo (i)
		if (isOnline and client == BNET_CLIENT_WOW and who == toonName) then
			return true
		end
	end
end

function RA:IsFriend (who)
	local friends_amt = GetNumFriends()
	for i = 1, friends_amt do
		local toonName = GetFriendInfo (i)
		if (who == toonName) then
			return true
		end
	end
end

function RA:IsGuildFriend (who)
	if (IsInGuild()) then
		local is_showing_all = GetGuildRosterShowOffline()
		for i = 1, select (is_showing_all and 1 or 2, GetNumGuildMembers()) do
			local name = GetGuildRosterInfo (i)
			if (RA:RemoveRealName (name) == who) then
				return true
			end
		end
	end
end

--[=[
	RA:RegisterForEnterRaidGroup (func)
	RA:RegisterForLeaveRaidGroup (func)
	Calls 'func' when the player enters or left a raid group.
	
	RA:UnregisterForEnterRaidGroup (func)
	RA:UnregisterForLeaveRaidGroup (func)
	Remove a previous regitered function.
--]=]

function RA:RegisterForEnterRaidGroup (func)
	tinsert (RA.player_enter_raid, func)
end

function RA:RegisterForLeaveRaidGroup (func)
	tinsert (RA.player_leave_raid, func)
end

function RA:RegisterForEnterPartyGroup (func)
	tinsert (RA.player_enter_party, func)
end

function RA:RegisterForLeavePartyGroup (func)
	tinsert (RA.player_leave_party, func)
end

function RA:UnregisterForEnterRaidGroup (func)
	for i = #RA.player_enter_raid, 1, -1 do
		if (RA.player_enter_raid [i] == func) then
			tremove (RA.player_enter_raid, i)
		end
	end
end

function RA:UnregisterForLeavePartyGroup (func)
	for i = #RA.player_leave_party, 1, -1 do
		if (RA.player_leave_party [i] == func) then
			tremove (RA.player_leave_party, i)
		end
	end
end

function RA:UnregisterForEnterPartyGroup (func)
	for i = #RA.player_enter_party, 1, -1 do
		if (RA.player_enter_party [i] == func) then
			tremove (RA.player_enter_party, i)
		end
	end
end

function RA:UnregisterForLeaveRaidGroup (func)
	for i = #RA.player_leave_raid, 1, -1 do
		if (RA.player_leave_raid [i] == func) then
			tremove (RA.player_leave_raid, i)
		end
	end
end

--[=[
	GetPlayerWithRealmName()
	return the player name with its realm name.
--]=]

function RA:GetPlayerNameWithRealm()
	return UnitName ("player") .. "-" .. GetRealmName()
end

--[=[
	GetEncounterName (encounter_id)
	return the encounter name from a encounter id.
--]=]
function RA:GetEncounterName (encounterid)
	for _, instance_id in ipairs (RA.LootList.InstanceIds) do
		EJ_SelectInstance (instance_id)
		local name, description, encounterID, rootSectionID, link = EJ_GetEncounterInfo (encounterid)
		if (name) then
			return name
		end
	end
	return ""
end

--[=[
	GetCurrentRaidEncounterList()
	return a table with encounter names from the current raid.
--]=]

local raid_list = {
	[1448] = {669, {1778, 1785, 1787, 1798, 1786, 1783, 1788, 1794, 1777, 1800, 1784, 1795, 1799}}, --mapid / EJ_id / encounter ids (hellfire citadel)
}
local empty_table = {}
function RA:GetCurrentRaidEncounterList (mapid)
	local zoneName, zoneType, _, _, _, _, _, zoneMapID = GetInstanceInfo()
	if (mapid) then
		zoneMapID = mapid
	end
	local EJ_id, true_encounter_ids = unpack (raid_list [zoneMapID] or empty_table)
	if (EJ_id) then
		EJ_SelectInstance (EJ_id)
		local bosses = {}
		for i = 1, 99 do
			local boss_name = EJ_GetEncounterInfoByIndex (i, EJ_id)
			if (boss_name) then
				tinsert (bosses, {boss_name, true_encounter_ids [i]})
			else
				break
			end
		end
		return bosses
	else
		return {}
	end
end

--[=[
	UnitHasAssist (unit)
	return is a unit has assist on the raid
--]=]
function RA:UnitHasAssist (unit)
	return IsInRaid() and (UnitIsGroupAssistant (unit) or UnitIsGroupLeader (unit))
end

--[=[
	UnitIsRaidLeader (unit)
	return is a unit is the leader of the raid
--]=]
function RA:UnitIsRaidLeader (unit)
	if (type (unit) == "string") then
		return UnitIsGroupLeader (unit) or UnitIsGroupLeader (unit:gsub ("%-.*", ""))
	end
end

--[=[
	GetRaidLeader()
	return the raid leader name and raidunitid
--]=]
function RA:GetRaidLeader()
	if (IsInRaid()) then
		for i = 1, GetNumGroupMembers() do
			local name, rank = GetRaidRosterInfo (i)
			if (rank == 2) then
				return name, "raid" .. i
			end
		end
	end
	return false
end

--[=[
	PercentColor()
	return green <-> red color based on the value passed
--]=]
function RA:PercentColor (value, inverted)
	local r, g
	if (value < 50) then
		r = 255
	else
		r = floor ( 255 - (value * 2 - 100) * 255 / 100)
	end
	
	if (value > 50) then
		g = 255
	else
		g = floor ( (value * 2) * 255 / 100)
	end
	
	if (inverted) then
		return g/255, r/255, 0
	else
		return r/255, g/255, 0
	end
end
--[=[
	Hex()
	return a hex string for the number passed
--]=]
function RA:Hex (num)
	local hexstr = '0123456789abcdef'
	local s = ''
	while num > 0 do
		local mod = math.fmod (num, 16)
		s = string.sub (hexstr, mod+1, mod+1) .. s
		num = math.floor (num / 16)
	end
	if s == '' then s = '00' end
	if (string.len (s) == 1) then
		s = "0"..s
	end
	return s
end

--[=[
	GetBossSpellList (encounterid)
	return a table with spells id.
--]=]

local boss_spells = {
	--"Hellfire Assault"
	[1426] = {181155, 180417, 181968, 186737, 188884, 185806, 185021, 180945,185156,187655,187638,184065,186883,180080,190728,184243,190748,190739,181120,184394,184370},
	--"Iron Reaver"
	[1425] = {182094,181999,185282,179889,182328,179896,182668,182066,182055},
	--"Kormrok"
	[1392] = {181299,181293,181292,181306,181307,181300,181305,181297,180244,181356},
	--"Hellfire High Council"
	[1432] = {184449,184476,184657,184675,41062,183701,184358,184357,184355,183885,183480},
	--"Kilrogg Deadeye"
	[1396] = {180033,180127,183917,180243,182153,180163,180570,182428,184551,180224,180372,180199,180389},
	--"Gorefiend"
	[1372] = {187815,185190,182557,185982,181282,180148,180093,182049,182170,181085,181973},
	--"Shadow-Lord Iskar"
	[1433] = {181824,181827,181832,181753,179219,179218,26662,181873,181912,181956,182178,185345},
	--"Socrethar the Eternal"
	[1427] = {183329,183331,190776,188666,184124,184053,180418,183023,181288,182051,188693,180221,180008,182392,184239,182769},
	--"Fel Lord Zakuun"
	[1391] = {179582,179709,179583,189009,179406,181515,179668,179681,184096,184690},
	--"Xhul'horac"
	[1447] = {189779,189775,186333,186407,186292,186271,188939,186783,186546,186532,186453,186490},
	--"Tyrant Velhari"
	[1394] = {181718,179991,179986,180608,180300,180526,180260,180600,180533,180004,180040,181227,187213},
	--"Mannoroth"
	[1395] = {181841,182088,183377,185831,181557,181948,183376,185830,181597,182006,181793,182077,181192,181193,181134,181099,181126,181275},
	--"Mannoroth"
	[1438] = {183254,190506,185590,190686,189897,190313,190394,188514,183598,190821,184931,183817,183828,184265,186562,183864,187053,190018,190397,190398,191068,186662}
}
function RA:GetBossSpellList (ej_id)
	return boss_spells [ej_id]
end

--[=[
	GetBossIds (any id)
	return the encounter id from the journal and for the combatlog
--]=]
local encounter_journal = {
	1426,1425,1392,1432,1396,1372,1433,1427,1391,1447,1394,1395,1438,
	[1426] = 1778,
	[1425] = 1785,
	[1392] = 1787,
	[1432] = 1798,
	[1396] = 1786,
	[1372] = 1783,
	[1433] = 1788,
	[1427] = 1794,
	[1391] = 1777,
	[1447] = 1800,
	[1394] = 1784,
	[1395] = 1795,
	[1438] = 1799,
}

local combat_log_ids = {
	1778, 1785, 1787, 1798, 1786, 1783, 1788, 1794, 1777, 1800, 1784, 1795, 1799,
	[1778] = 1426, --"Hellfire Assault"
	[1785] = 1425, --"Iron Reaver"
	[1787] = 1392, --"Kormrok"
	[1798] = 1432, --"Hellfire High Council"
	[1786] = 1396, --"Kilrogg Deadeye"
	[1783] = 1372, --"Gorefiend"
	[1788] = 1433, --"Shadow-Lord Iskar"
	[1794] = 1427, --"Socrethar the Eternal"
	[1777] = 1391, --"Fel Lord Zakuun"
	[1800] = 1447, --"Xhul'horac"
	[1784] = 1394, --"Tyrant Velhari"
	[1795] = 1395, --"Mannoroth"
	[1799] = 1438, c
}

function RA:GetBossIds (bossid)
	local ejid = encounter_journal [bossid] or bossid
	local combatlog = combat_log_ids [bossid] or bossid
	return ejid, combatlog
end