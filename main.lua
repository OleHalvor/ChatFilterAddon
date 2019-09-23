print('ChatFilterAddon Loaded! - develop branch')


local Name,AddOn=...;
local Title=select(2,GetAddOnInfo(Name));
local Version=GetAddOnMetadata(Name,"Version");
local Options={};
AddOn.Options=Options;

local function SyncOptions(new,old,merge)
    --	This is practicly a table copy function to copy values from old to new
    --	new will always be the table modified and is the same table returned
    --	old shall always remain untouched
    --	merge controls if shared keys are overwritten

    --	Exception handling
    if old==nil then return new; end--		If old is missing, return new
    if type(old)~="table" then return old; end--	If old is non-table, return old
    if type(new)~="table" then new={}; end--	If new is non-table, overwrite; proceed with copying of old

    for i,j in pairs(old) do
        local val=rawget(new,i);
        if merge or val==nil then
            rawset(new,i,SyncOptions(val,j,merge));
        end
    end
    return new;
end

function try(f, catch_f)
    local status, exception = pcall(f)
    if not status then
        catch_f(exception)
    end
end


local Defaults={
    onlyShowRelevantDungeons=true,
    showTimeStamp=true,
    showChannelOrigin=false
};

ChatFilterAddon_Options=SyncOptions(Options,Defaults);

--------------------------
--[[	Options Panel	]]
--------------------------
local Changes=SyncOptions({},Options);
local Panel=CreateFrame("Frame");
Panel.name=Title;

do--	Title
    local txt;

    local title=Panel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");
    title:SetPoint("TOPLEFT",12,-12);
    title:SetText(Title);

    local ver=Panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");
    ver:SetPoint("TOPLEFT",title,"TOPRIGHT",4,0);
    ver:SetTextColor(0.5,0.5,0.5);
    ver:SetText("v"..Version);
end

Panel:RegisterEvent("ADDON_LOADED");
Panel:SetScript("OnEvent",function(self,event,...)
    if event=="ADDON_LOADED" and (...)==Name then
        ChatFilterAddon_Options=SyncOptions(Options,ChatFilterAddon_Options,true);
        SyncOptions(Changes,Options,true);
        self:UnregisterEvent(event);
    end
end);

----------------------------------
--[[	Options Controls	]]
----------------------------------
local Buttons={};
local BuildButton; do--	function BuildButton(tbl,var,txt,x,y)
    local function OnClick(self) self.Table[self.Var]=self:GetChecked(); end
    local function Refresh(self) self:SetChecked(self:IsEnabled() and self.Table[self.Var]); end
    function BuildButton(tbl,var,txt,x,y)
        local btn=CreateFrame("CheckButton",nil,Panel,"UICheckButtonTemplate");
        btn:SetPoint("TOPLEFT",x,y);
        btn.text:SetText(txt or var:gsub("^(.)",string.upper));
        btn:SetScript("OnClick",OnClick);

        btn.Table=tbl;
        btn.Var=var;
        btn.Refresh=Refresh;

        Buttons[#Buttons+1]=btn;
        return btn;
    end
end

do--	LinkButtons
    local list={};
    for i,j in pairs(Defaults) do list[#list+1]=i; end
    table.sort(list);
    for i,j in ipairs(list) do
        BuildButton(Changes,j,nil,16,-i*24-24);
    end



end

--------------------------
--[[	Panel Callbacks	]]
--------------------------
Panel.okay=function()
    SyncOptions(Options,Changes,true);
    AddOn.RecompileLinks();
end
Panel.cancel=function()
    SyncOptions(Changes,Options,true);
end
Panel.default=function()
    --	Note, the defaults table may have dirty values since it lends its subtables to the options var if needed
    SyncOptions(Options,Defaults,true);
    SyncOptions(Changes,Defaults,true);
end
Panel.refresh=function()
    for i,j in ipairs(Buttons) do j:Refresh(); end
end

----------------------------------
--[[	Panel Registration	]]
----------------------------------
InterfaceOptions_AddCategory(Panel);
-- a lot of this code is copied from classicLFG addon

local DungeonList = {}
local Dungeons = {}
local lastMessage = ""
local Frame = CreateFrame("frame")
Frame:RegisterEvent("CHAT_MSG_CHANNEL")
Frame:SetScript("OnEvent", function(_, event, ...)
        if (event == "CHAT_MSG_CHANNEL") then
            local message, player, _, _, _, _, _, _, channelName = ...
            ParseMessageCFA(player, message, channelName)
        end
end)

    function ParseMessageCFA(sender, chatMessage, channel)
	local lowerMessage = chatMessage:lower()
	if (HasLFMTagCFA(lowerMessage)) then
        if (HasDungeonAbbreviationCFA(lowerMessage)) then
            local link = "|cffffc0c0|Hplayer:"..sender.."|h["..sender.."]|h|r";
            local output = ""
            if (Options.showTimeStamp) then
                local hours,minutes = GetGameTime();
                output = (output.."["..hours..":"..minutes.."] ")
            end
            output = output..link..": "..chatMessage
            if (Options.showChannelOrigin) then
                output = output.." ["..channel.."]";
            end

            if (chatMessage == lastMessage) then
                return false
            end
            local lfgOutputFound = false
            for i = 1, NUM_CHAT_WINDOWS do
                if (GetChatWindowInfo(i)=="lfm" or GetChatWindowInfo(i)=="LFM") then
                    lfgOutputFound = true
                    -- don't know how to specify correct chat frame without hard coding. please don't judge me
                    if (i==1) then
                        ChatFrame1:AddMessage(output)
                    end
                    if (i==2) then
                        ChatFrame2:AddMessage(output)
                    end
                    if (i==3) then
                        ChatFrame3:AddMessage(output)
                    end
                    if (i==4) then
                        ChatFrame4:AddMessage(output)
                    end
                    if (i==5) then
                        ChatFrame5:AddMessage(output)
                    end
                    if (i==6) then
                        ChatFrame6:AddMessage(output)
                    end
                    if (i==7) then
                        ChatFrame7:AddMessage(output)
                     end
                end
            end
            if (not lfgOutputFound) then
                message('Did not find any chat windows named "LFM", please create one')
                hasWarnedAboutChatName = true
            end
            lastMessage = chatMessage
		end
	end
end

function HasLFMTagCFA(text)
    local lfmTags = {
        "lfm",
        "lf3m",
        "lf2m",
        "lf1m",
        "lf1",
        "lf2",
        "lf3",
        "lf ",
        "looking for more"
    }
    for _, tag in pairs(lfmTags) do
        if (string.find(text, tag)) then
            return true
        end
    end
    return false
end

function ArrayContainsValueCFA(array, val)
    for index, value in ipairs(array) do
        if value == val then
            return true
        end
    end
    return false
end

function HasDungeonAbbreviationCFA(chatMessage)
    local level = UnitLevel("player")
    if (Options.onlyShowRelevantDungeons) then
        for key, dungeon in pairs(GetDungeonsByLevelCFA(level)) do
            for _, abbreviation in pairs(dungeon.Abbreviations) do
                words = {}
                for word in chatMessage:gmatch("%w+") do table.insert(words, word) end
                if (ArrayContainsValueCFA(words, abbreviation)) then
                    return true
                end
            end
        end
    else
        for key, dungeon in pairs(Dungeons) do
            for _, abbreviation in pairs(dungeon.Abbreviations) do
                words = {}
                for word in chatMessage:gmatch("%w+") do table.insert(words, word) end
                if (ArrayContainsValueCFA(words, abbreviation)) then
                    return true
                end
            end
        end
    end
    return nil
end

function DefineDungeonCFA(name, size, minLevel, maxLevel, location, abbreviation, abbreviations)
    Dungeons[name] = {
        Name = name,
        MinLevel = minLevel,
        MaxLevel = maxLevel,
        Location = location,
        Faction = faction,
        Abbreviation = abbreviation,
        Abbreviations = abbreviations,
        Background = background,
        Size = size
    }
    DungeonList[name] = name
end

function GetDungeonsByLevelCFA(level)
    local dungeonsForLevel = {}
    for key in pairs(Dungeons) do
        local dungeon = Dungeons[key]
        if (Options[dungeon.abbreviation]==true) then
            print('matching '..dungeon.abbreviation..' because of options')
            dungeonsForLevel[dungeon.Name] = dungeon
        else
            if (dungeon.MinLevel <= level and dungeon.MaxLevel >= level) then
                dungeonsForLevel[dungeon.Name] = dungeon
            end
        end
    end
    return dungeonsForLevel
end

-- Dungeon defining stole shamelessly from ClassicLFG addon

DefineDungeonCFA("Ragefire Chasm", 5, 12, 21, "Orgrimmar", "rfc", {"rfc", "ragefire"})
DefineDungeonCFA("Wailing Caverns", 5, 15, 25, "Barrens", "wc", {"wc"})
DefineDungeonCFA("The Deadmines", 5, 16, 24, "Westfall", "vc", {"dm", "vc", "deadmines"})
DefineDungeonCFA("Shadowfang Keep", 5, 18, 27, "Silverpine Forest", "sfk", {"sfk", "shadowfang"})
DefineDungeonCFA("Blackfathom Deeps", 5, 22, 30, "Ashenvale", "bfd", {"bfd"})
DefineDungeonCFA("The Stockades", 5, 21, 30, "Stormwind", "stockades", {"stockades", "stocks","stockade"})
DefineDungeonCFA("Gnomeregan", 5, 27, 35, "Dun Morogh", "gnomergan", {"gnomeregan", "gnomer"})
DefineDungeonCFA("Razorfen Kraul", 5, 22, 32, "Barrens", "rfk", {"rfk", "kraul"})
DefineDungeonCFA("The Scarlet Monastery: Graveyard", 5, 28, 35, "Tirisfal Glades", "sm graveyard", {"sm gy","gy","grave","graveyard"})
DefineDungeonCFA("The Scarlet Monastery: Library", 5, 30, 39, "Tirisfal Glades", "sm library", {"sm", "lib","library"})
DefineDungeonCFA("The Scarlet Monastery: Armory", 5, 32, 42, "Tirisfal Glades", "sm armory", {"sm","arms","arm"})
DefineDungeonCFA("The Scarlet Monastery: Cathedral", 5, 34, 44, "Tirisfal Glades", "sm cathedral", {"sm","cath"})
DefineDungeonCFA("Razorfen Downs", 5, 33, 43, "Barrens", "rfd", {"rfd"})
DefineDungeonCFA("Uldaman", 5, 35, 45, "Badlands", "ulda", {"ulda","uldaman"})
DefineDungeonCFA("Zul'Farak", 5, 40, 50, "Tanaris", "zf", {"zf"})
DefineDungeonCFA("Maraudon", 5, 44, 54, "Desolace", "maraudon", {"maraudon", "mara"})
DefineDungeonCFA("Temple of Atal'Hakkar", 5, 47, 60, "Swamp of Sorrows", "st", {"st", "toa", "atal", "sunken temple"})
DefineDungeonCFA("Blackrock Depths", 5, 49, 60, "Blackrock Mountain", "brd", {"brd"})
DefineDungeonCFA("Lower Blackrock Spire", 10, 55, 60, "Blackrock Mountain", "lbrs", {"lbrs"})
DefineDungeonCFA("Upper Blackrock Spire", 10, 55, 60, "Blackrock Mountain", "ubrs", {"ubrs"})
-- ToDo: Need to add all the Dungeon parts once they are released on Classic Realms
--ClassicLFG:DefineDungeon("Dire Maul", 55, 60, "Feralas", {"dm:"})
--
DefineDungeonCFA("Stratholme", 5, 56, 60, "Eastern Plaguelands", "strat", {"strat"})
DefineDungeonCFA("Scholomance", 5, 56, 60, "Eastern Plaguelands", "scholo", {"scholo"})
DefineDungeonCFA("Molten Core", 40, 60, 60, "Blackrock Depths", "mc", {"mc"})
DefineDungeonCFA("Onyxia's Lair", 40, 60, 60, "Dustwallow Marsh", "ony", {"ony", "onyxia"})

print("Possible dungeons for your level: ")
for key, dungeon in pairs(GetDungeonsByLevelCFA(UnitLevel("player"))) do
    print(key)
end






