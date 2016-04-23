local MogIt_WowHead, MogIt_WowHead_Table  = ...;

local module = MogIt:GetModule("MogIt_WowHead") or MogIt:RegisterModule("MogIt_WowHead",{});

local LBI = LibStub("LibBabble-Inventory-3.0"):GetUnstrictLookupTable();

local data;

function MogIt_WowHead_Table.SetData(dataTable)
	data = dataTable;
end

local armorTypes = {
	[1] = "Cloth",
	[2] = "Leather",
	[3] = "Mail",
	[4] = "Plate",
};

local list = {};

local function DropdownTier2(self)
	module.active = self.value
	MogIt:SetModule(self.arg1, "WowHead Transmog Sets - "..LBI[armorTypes[self.value]]);
	CloseDropDownMenus();
end

function module.Dropdown(module, tier)
	local info;
	if tier == 1 then
		info = UIDropDownMenu_CreateInfo();
		info.text = "WowHead Transmog Sets";
		info.value = module;
		info.colorCode = "\124cFF00FF00";
		info.hasArrow = true;
		info.keepShownOnClick = true;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info, tier);

	elseif tier == 2 then
		for key, name in ipairs(armorTypes) do
			info = UIDropDownMenu_CreateInfo();
			info.text = LBI[name]
			info.value = key;

			info.notCheckable = true;
			info.func = DropdownTier2;
			info.arg1 = module;
			UIDropDownMenu_AddButton(info, tier);
		end
	end
end

function module.FrameUpdate(module, self, value)
	self.data.items = data[value]["items"];
	self.data.name  = data[value]["name"];
	MogIt.Set_FrameUpdate(self, self.data);
end

function module:OnEnter(frame, value)
	MogIt.ShowSetTooltip(frame, data[value]["items"], data[value]["name"])
end

function module.OnClick(module, self, btn, value)
	if btn == "RightButton" and IsShiftKeyDown() then
		StaticPopup_Show(
			"MOGIT_URL",
			"\124TInterface\\AddOns\\MogIt\\Images\\fav_wh:18:18\124t",
			"Wowhead",
			MogIt.L["http://www.wowhead.com/"].."transmog-set="..value
		);
	else
		MogIt.Set_OnClick(self, btn, self.data);
	end
end

function module.Unlist(module)
	wipe(list);
end

function module.BuildList(module)
	wipe(list);
	for k, set in pairs(data) do
		if set["type"] == module.active and MogIt:GetFilter("class").Filter(set["classes"]) then
			tinsert(list, set["id"]);
		end
	end
	return list;
end

module.filters = {
	"class"
};