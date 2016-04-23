local OmniBar = LibStub("AceAddon-3.0"):GetAddon("OmniBar")
local L = LibStub("AceLocale-3.0"):GetLocale("OmniBar")

local spells = {}

local tooltip = CreateFrame("GameTooltip", "OmniBarTooltip", UIParent, "GameTooltipTemplate")
local function GetSpellTooltipText(spellID)
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetSpellByID(spellID)
	local lines = tooltip:NumLines()
	if lines < 1 then return end
	local line = _G["OmniBarTooltipTextLeft"..lines]:GetText()
	if not line then return end
	tooltip:Hide()
	return line
end

local function IsSpellEnabled(info)
	local key = info[2]
	return OmniBar_IsSpellEnabled(_G[key], OmniBar.options.args.bars.args[key].args.spells.args[info[4]].args[info[5]].arg)
end


function OmniBar:ToggleLock(button)
	self.db.profile.bars[button.arg].locked = not self.db.profile.bars[button.arg].locked
	OmniBar_Position(_G[button.arg])
	self.options.args.bars.args[button.arg].args.lock.name = self.db.profile.bars[button.arg].locked and L["Unlock"] or L["Lock"]
end

function OmniBar:AddBarToOptions(key, refresh)
	self.options.args.bars.args[key] = {
		name = self.db.profile.bars[key].name,
		type = "group",
		order = self.index + 1,
		childGroups = "tab",
		get = function(info)
			local option = info[#info]
			return self.db.profile.bars[key][option]
		end,
		set = function(info, state)
			local option = info[#info]
			self.db.profile.bars[key][option] = state
			self:Refresh()
		end,
		args = {
			settings = {
				name = L["Settings"],
				type = "group",
				order = 10,
				args = {
					name = {
						name = L["Name"],
						desc = L["Set the name of the bar"],
						type = "input",
						width = "double",
						set = function(info, state)
							local option = info[#info]
							self.db.profile.bars[key][option] = state
							self.options.args.bars.args[key].name = state
							local f = _G[key.."AnchorText"]
							f:SetText(state)
							local width = f:GetWidth() + 28
							_G[key.."Anchor"]:SetSize(width, 30)
							self:Refresh()
						end,
						order = 1,
					},
					lb1 = {
						name = "",
						type = "description",
						order = 2,
					},
					center = {
						name = L["Center Lock"],
						desc = L["Keep the bar centered horizontally"],
						width = "normal",
						type = "toggle",
						order = 3,
					},
					showUnused = {
						name = L["Show Unused Icons"],
						desc = L["Icons will always remain visible"],
						width = "normal",
						type = "toggle",
						order = 4,
						set = function(info, state)
							local option = info[#info]
							self.db.profile.bars[key][option] = state
							self:Refresh(true)
						end,
					},
					adaptive = {
						name = L["As Enemies Appear"],
						desc = L["Only show unused icons for arena opponents or enemies you target while in combat"],
						disabled = function()
							return not self.db.profile.bars[key].showUnused
						end,
						width = "normal",
						type = "toggle",
						order = 5,
						set = function(info, state)
							local option = info[#info]
							self.db.profile.bars[key][option] = state
							self:Refresh(true)
						end,
					},
					growUpward = {
						name = L["Grow Rows Upward"],
						desc = L["Toggle the grow direction of the icons"],
						width = "normal",
						type = "toggle",
						order = 6,
					},
					cooldownCount = {
						name = L["Countdown Count"],
						desc = L["Allow Blizzard and other addons to display countdown text on the icons"],
						width = "normal",
						type = "toggle",
						set = function(info, state)
							local option = info[#info]
							self.db.profile.bars[key][option] = state
							self:Refresh(true)
						end,
						order = 7,
					},
					border = {
						name = L["Show Border"],
						desc = L["Draw a border around the icons"],
						width = "normal",
						type = "toggle",
						order = 8,
					},
					highlightTarget = {
						name = L["Highlight Target"],
						desc = L["Draw a border around your target"],
						width = "normal",
						type = "toggle",
						order = 9,
					},
					highlightFocus = {
						name = L["Highlight Focus"],
						desc = L["Draw a border around your focus"],
						width = "normal",
						type = "toggle",
						order = 10,
					},
					names = {
						name = L["Show Names"],
						desc = L["Show the player name of the spell"],
						width = "normal",
						type = "toggle",
						order = 11,
					},
					multiple = {
						name = L["Track Multiple Players"],
						desc = L["If another player is detected using the same ability, a duplicate icon will be created and tracked separately"],
						width = "normal",
						type = "toggle",
						order = 16,
					},
					glow = {
						name = L["Glow Icons"],
						desc = L["Display a glow animation around an icon when it is activated"],
						width = "normal",
						type = "toggle",
						order = 17,
					},
					tooltips = {
						name = L["Show Tooltips"],
						desc = L["Show spell information when mousing over the icons (the bar must be unlocked)"],
						width = "normal",
						type = "toggle",
						order = 18,
					},
					lb2 = {
						name = "",
						type = "description",
						order = 19,
					},
					size = {
						name = L["Size"],
						desc = L["Set the size of the icons"],
						type = "range",
						min = 1,
						max = 100,
						step = 1,
						order = 100,
						width = "double",
					},
					sizeDesc = {
						name = L["Set the size of the icons"] .. "\n",
						type = "description",
						order = 101,
					},
					columns = {
						name = L["Columns"],
						desc = L["Set the maximum icons per row"],
						type = "range",
						min = 1,
						max = 100,
						step = 1,
						order = 102,
						width = "double",
					},
					columnsDesc = {
						name = L["Set the maximum icons per row"] .. "\n",
						type = "description",
						order = 103,
					},
					padding = {
						name = L["Padding"],
						desc = L["Set the space between icons"],
						type = "range",
						min = 1,
						max = 100,
						step = 1,
						order = 104,
						width = "double",
					},
					paddingDesc = {
						name = L["Set the space between icons"] .. "\n",
						type = "description",
						order = 105,
					},
					unusedAlpha = {
						name = L["Unused Icon Transparency"],
						desc = L["Set the transparency of unused icons"],
						isPercent = true,
						type = "range",
						min = 0,
						max = 1,
						step = 0.01,
						order = 106,
						width = "double",
					},
					unusedAlphaDesc = {
						name = L["Set the transparency of unused icons"] .. "\n",
						type = "description",
						order = 107,
					},
					swipeAlpha = {
						name = L["Swipe Transparency"],
						desc = L["Set the transparency of the swipe animation"],
						isPercent = true,
						type = "range",
						min = 0,
						max = 1,
						step = 0.01,
						order = 108,
						width = "double",
					},
					swipeAlphaDesc = {
						name = L["Set the transparency of the swipe animation"] .. "\n",
						type = "description",
						order = 109,
					},

				},
			},
			visibility = {
				name = L["Visibility"],
				type = "group",
				set = function(info, state)
					local option = info[#info]
					self.db.profile.bars[key][option] = state
					OmniBar_OnEvent(_G[key], "PLAYER_ENTERING_WORLD")
				end,
				order = 11,
				args = {
					arena = {
						name = L["Show in Arena"],
						desc = L["Show the icons in arena"],
						width = "double",
						type = "toggle",
						order = 11,
					},
					ratedBattleground = {
						name = L["Show in Rated Battlegrounds"],
						desc = L["Show the icons in rated battlegrounds"],
						width = "double",
						type = "toggle",
						order = 12,
					},
					battleground = {
						name = L["Show in Battlegrounds"],
						desc = L["Show the icons in battlegrounds"],
						width = "double",
						type = "toggle",
						order = 13,
					},
					ashran = {
						name = L["Show in Ashran"],
						desc = L["Show the icons in Ashran"],
						width = "double",
						type = "toggle",
						order = 14,
					},
					world = {
						name = L["Show in World"],
						desc = L["Show the icons in the world"],
						width = "double",
						type = "toggle",
						order = 15,
					},
				},
			},
			spells = {
				name = L["Spells"],
				type = "group",
				order = 12,
				arg = key,
				args = spells,
				set = function(info, state)
					local option = info[#info]
					self.db.profile.bars[key][option] = state
					self:Refresh(true)
				end,
			},
			lock = {
				type = "execute",
				name = self.db.profile.bars[key].locked and L["Unlock"] or L["Lock"],
				desc = L["Lock the bar to prevent dragging"],
				arg = key,
				func = "ToggleLock",
				handler = OmniBar,
				order = 1,
			},
			delete = {
				type = "execute",
				name = L["Delete"],
				desc = L["Delete the bar"],
				func = "Delete",
				handler = OmniBar,
				arg = key,
				order = 2,
			},
		},
	}
	if refresh then LibStub("AceConfigRegistry-3.0"):NotifyChange("OmniBar") end
end

function OmniBar:SetupOptions()

	for i = 1, MAX_CLASSES do
		
		spells[CLASS_SORT_ORDER[i]] = {
			name = LOCALIZED_CLASS_NAMES_MALE[CLASS_SORT_ORDER[i]],
			type = "group",
			args = {},
			icon = "Interface\\Icons\\ClassIcon_"..CLASS_SORT_ORDER[i],
		}

		for spellID, spell in pairs(self.cooldowns) do

			if spell.class and spell.class == CLASS_SORT_ORDER[i] then
				local text = GetSpellInfo(spellID) or ""
				if string.len(text) > 25 then
					text = string.sub(text, 0, 22) .. "..."
				end
				spells[CLASS_SORT_ORDER[i]].args["spell"..spellID] = {
					name = text,
					type = "toggle",
					get = IsSpellEnabled,
					width = "full",
					arg = spellID,
					desc = GetSpellTooltipText(spellID),
					name = function()
						return format("|T%s:20|t %s", GetSpellTexture(spellID), text)
					end,
				}

			end
			
		end
	end

	self.options = {
		name = "OmniBar",
		descStyle = "inline",
		type = "group",
		plugins = {
			profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) }
		},
		childGroups = "tab",
		args = {
			vers = {
				order = 1,
				type = "description",
				name = "|cffffd700"..L["Version"].."|r "..GetAddOnMetadata("OmniBar", "Version").."\n",
				cmdHidden = true
			},
			desc = {
				order = 2,
				type = "description",
				name = "|cffffd700 "..L["Author"].."|r Jordon\n",
				cmdHidden = true
			},
			test = {
				type = "execute",
				name = L["Test"],
				desc = L["Activate the icons for testing"],
				order = 3,
				func = "Test",
				handler = OmniBar,
			},

			bars = {
				name = L["Bars"],
				type = "group",
				order = 10,
				childGroups = "tab",
				args = {
					add = {
						type = "execute",
						name = L["Create Bar"],
						desc = L["Create a new bar"],
						order = 1,
						func = "Create",
						handler = OmniBar,
					},
				},
			},

		},
	}

	local LibDualSpec = LibStub('LibDualSpec-1.0')
	LibDualSpec:EnhanceDatabase(self.db, "OmniBarDB")
	LibDualSpec:EnhanceOptions(self.options.plugins.profiles.profiles, self.db)

	LibStub("AceConfig-3.0"):RegisterOptionsTable("OmniBar", self.options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("OmniBar", "OmniBar")
end
