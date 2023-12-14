
local Name, AddOn = ...;
local Title = select(2, GetAddOnInfo(Name));
local Version = GetAddOnMetadata(Name, "Version");
local addon, ns = ...
ns.Options = {};
AddOn.Options = ns.Options;

local function SyncOptions(new, old, merge)
    if old == nil then
        return new;
    end
    if type(old) ~= "table" then
        return old;
    end
    if type(new) ~= "table" then
        new = {};
    end

    for i, j in pairs(old) do
        local val = rawget(new, i);
        if merge or val == nil then
            rawset(new, i, SyncOptions(val, j, merge));
        end
    end
    return new;
end

local Defaults = {
    include_dungeons_outside_of_level_range = false,
    show_time_stamp_on_messages = false,
    display_channel_on_all_messages = false,
    hide_XP_runs = false,
    hide_cleave_and_AOE_runs = false,
    keep_looking_while_in_full_group = false,
    DEBUG_MODE = false,
    display_channel_if_from_other_addon_user = true,
    include_LFG_messages_in_addition_to_LFM = false,
    lock_window=false
};

ChatFilterAddon_Options = SyncOptions(ns.Options, Defaults);

local Changes = SyncOptions({}, ns.Options);
local Panel = CreateFrame("Frame");
Panel.name = Title;

do
    local title = Panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    title:SetPoint("TOPLEFT", 12, -12);
    title:SetText(Title);

    local ver = Panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    ver:SetPoint("TOPLEFT", title, "TOPRIGHT", 4, 0);
    ver:SetTextColor(0.5, 0.5, 0.5);
    ver:SetText("v" .. Version);
end

Panel:RegisterEvent("ADDON_LOADED");
Panel:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and (...) == Name then
        ChatFilterAddon_Options = SyncOptions(ns.Options, ChatFilterAddon_Options, true);
        SyncOptions(Changes, ns.Options, true);
        serverTag = GetNormalizedRealmName();
        if serverTag == nil then
            serverTag = "Gandling"
        end
        self:UnregisterEvent(event);
    end
end);

local Buttons = {};
local function BuildButton(tbl, var, txt, x, y)
    local btn = CreateFrame("CheckButton", nil, Panel, "UICheckButtonTemplate");
    btn:SetPoint("TOPLEFT", x, y);
    local tempVar = var:gsub("%_", " ")
    btn:SetScript("OnClick", function(self)
        self.Table[self.Var] = self:GetChecked();
    end);
    btn.Text:SetText(txt or tempVar:gsub("^(.)", string.upper));
    btn.Table = tbl;
    btn.Var = var;
    btn.Refresh = function(self)
        self:SetChecked(self:IsEnabled() and self.Table[self.Var]);
    end;

    Buttons[#Buttons + 1] = btn;
    return btn;
end

do
    local list = {};
    for i, j in pairs(Defaults) do
        list[#list + 1] = i;
    end
    table.sort(list);
    for i, j in ipairs(list) do
        BuildButton(Changes, j, nil, 16, -i * 24 - 24);
    end
end

Panel.okay = function()
    SyncOptions(ns.Options, Changes, true);
    AddOn.RecompileLinks();
end
Panel.cancel = function()
    SyncOptions(Changes, ns.Options, true);
end
Panel.default = function()
    SyncOptions(ns.Options, Defaults, true);
    SyncOptions(Changes, Defaults, true);
end
Panel.refresh = function()
    for i, j in ipairs(Buttons) do
        j:Refresh();
    end
end

InterfaceOptions_AddCategory(Panel);

SLASH_ChatFilterAddon1 = "/lfm";
function SlashCmdList.ChatFilterAddon(msg)
    InterfaceOptionsFrame_OpenToCategory(Panel);
    InterfaceOptionsFrame_OpenToCategory(Panel);
end

return Options