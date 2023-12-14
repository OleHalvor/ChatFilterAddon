print("ChatFilterAddon By Tryllemann Loaded")

local messageList = {"melding -2", "melding -1", "melding 0", "melding 1", "melding 2", "melding 3"}
local messageListSize = 0 -- this is calculated, size is defined by array above
for _ in pairs(messageList) do messageListSize = messageListSize + 1 end
local lastMessageListUpdateTime = time()
local messageListClearInterval = 60
local serverTag = ""
local versionNumber = "0.9.3"
local hasWarnedAboutFullGroup = false

local function pushToMessageList (message)
    local tableLengthInt = 0
    for _ in pairs(messageList) do tableLengthInt = tableLengthInt + 1 end
    if (tableLengthInt >= messageListSize) then
        for i=1, (tableLengthInt-1) do
            messageList[i] = messageList[i+1]
        end
    end
    messageList[tableLengthInt] = message
    return messageList
end

local function printMessageList()
    local tableLengthInt = 0
    for _ in pairs(messageList) do tableLengthInt = tableLengthInt + 1 end
    print('printing message list: ')
    for i = 1, tableLengthInt do
        print('message '..i..': '..messageList[i])
    end
end


local Name,AddOn=...;
local Title=select(2,GetAddOnInfo(Name));
local Version=GetAddOnMetadata(Name,"Version");
local Options={};
AddOn.Options=Options;
local addon_users = {}

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


local disabledDungeons = {
    "The Scarlet Monastery: Library",
    "The Scarlet Monastery: Cathedral",
    "The Scarlet Monastery: Armory",
    "The Scarlet Monastery: Graveyard"
}
disabledDungeons = {}

local Defaults={
    --include_dungeons_outside_of_level_range=true,
    include_dungeons_outside_of_level_range=false,
    show_time_stamp_on_messages=false,
    display_channel_on_all_messages=false,
    hide_XP_runs=false,
    hide_cleave_and_AOE_runs=false,
    keep_looking_while_in_full_group=false,
    DEBUG_MODE=false,
    display_channel_if_from_other_addon_user=true,
    include_LFG_messages_in_addition_to_LFM=false
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
        serverTag=GetNormalizedRealmName();
        if serverTag==nil then
            serverTag = "Gandling"
        end
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
        local tempVar = var:gsub("%_"," ")
        btn:SetScript("OnClick",OnClick);
        btn.Text:SetText(txt or tempVar:gsub("^(.)",string.upper));
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

local successFullReg = C_ChatInfo.RegisterAddonMessagePrefix("LFMCF")
local successFullRegVersion = C_ChatInfo.RegisterAddonMessagePrefix("LFMCFV")

-- /run C_ChatInfo.SendAddonMessage("prefix", "LFM DM","WHISPER","Dudetwo");
-- /script C_ChatInfo.SendAddonMessage("prefix", "LFM DM","WHISPER","Dudetwo-Gandling");
-- /script SendChatMessage("melding" ,"WHISPER" ,"COMMON" ,"Dudetwo-Gandling");
-- /script SendAddonMessage("LFMCF", "LFM DM", "WHISPER", "Dudetwo-Gandling");


SLASH_ChatFilterAddon1 = "/lfm";
function SlashCmdList.ChatFilterAddon(msg)
    InterfaceOptionsFrame_OpenToCategory(Panel);
    InterfaceOptionsFrame_OpenToCategory(Panel);
end


local function getQuestsInLog()
    quests = {}
    for i=1, GetNumQuestLogEntries() do
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(i)
        if (not level==0) then
            quests[i] = GetQuestLogTitle(i);
        end
    end
    return quests
end

local function isQuestFromLogInText(text)
    quests = getQuestsInLog();
    for _, quest in pairs(quests) do
        if (string.find(text:lower(),quest:lower() )) then
            return true
        end
    end
    return false
end

local function containsText(message,text)
    if (string.find(message:lower(),text:lower() )) then
        return true
    end
    return false
end

local function containsTextFromArray(message,array)
    for _, var in pairs(array) do
        if (containsText(message,var)) then
            return true
        end
    end
    return false
end

print(getQuestsInLog())

local function getLFMAddonChannelIndex()
    -- this doesn't work, right?
    numberOfChannels = C_ChatInfo.GetNumActiveChannels()
    lfmAddonChannelIndex = 0
    for i = 1, numberOfChannels do
        if (GetChannelDisplayInfo(i) == "lfm-addon-channel" ) then
            lfmAddonChannelIndex = i
        end
    end
    if (lfmAddonChannelIndex==0) then
        JoinTemporaryChannel("lfm-addon-channel", "", ChatFrame1:GetID(), 0);
        RemoveChatWindowChannel(1,"lfm-addon-channel")
    end
    return lfmAddonChannelIndex
end

local function spamAllHiddenChannels(networkMessage)
    JoinChannelByName("LfmAddonChannel", "", ChatFrame1:GetID(), 0);
    RemoveChatWindowChannel(ChatFrame1:GetID(),"LfmAddonChannel")

    for i = 1, GetNumDisplayChannels() do
        id, name = GetChannelName(i);
        if(name=="LfmAddonChannel") then
            C_ChatInfo.SendAddonMessage("LFMCFV",versionNumber,"CHANNEL",i)
            C_ChatInfo.SendAddonMessage("LFMCF", networkMessage,"CHANNEL",i)
        end
    end
    --success = C_ChatInfo.SendAddonMessage("LFMCF", networkMessage,"GUILD")
    --success = C_ChatInfo.SendAddonMessage("LFMCFV", versionNumber,"GUILD")
end

local function mysplit (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

local function hasXPRunTags(message)
    xpTags = {
        "xp",
        "exp"
    }
    if (containsTextFromArray(message,xpTags)) then
        return true
    end
    return false
end

local function hasCleaveTags(message)
    cleaveTags = {
        "cleave",
        "spellcleave",
        "aoe"
    }
    if (containsTextFromArray(message,cleaveTags)) then
        return true
    end
    return false
end


local hasWarnedAboutChatName = false
local DungeonList = {}
local Dungeons = {}
local lastMessage = ""
local Frame = CreateFrame("frame")
Frame:RegisterEvent("CHAT_MSG_CHANNEL")
Frame:RegisterEvent("CHAT_MSG_ADDON")
Frame:SetScript("OnEvent", function(_, event, ...)
    if (event == "CHAT_MSG_CHANNEL") then
        local message, player, _, _, _, _, _, _, channelName = ...
        local lfmSend = ParseMessageCFA(player, message, channelName,"false")
        if(lfmSend == false and Options.DEBUG_MODE) then
            printMessageToNotLfmWindow(message)
        end
    end

    if (event == "CHAT_MSG_ADDON") then
        local prefix, message, type, sender, _, _, _, _, _ = ...
        if (prefix=="LFMCF") then
            if ( not (UnitName("player")==sender or UnitName("player")..'-'..serverTag==sender) ) then
                words = mysplit(message,";")
                if (Options.DEBUG_MODE==true) then
                    channelPlusNetworkSender=words[3].." - "..words[2]
                else
                    channelPlusNetworkSender=words[3]
                end

                if (tablelength(words) >= 4) then
                    ParseMessageCFA(words[1], words[4], channelPlusNetworkSender,"true")
                else
                    print('received message from other client which did not parse: '..message)
                end
            end
        end
        if (prefix=="LFMCFV" and Options.DEBUG_MODE) then
            if(addon_users[sender] ~= sender) then
                printMessageToLfmWindow('|cFF00FF00'..sender..' is using addon version: '..message..'|r')
                addon_users[sender] = sender
            else
                addon_users[sender] = sender
            end

            --printMessageToLfmWindow('|cFF00FF00'..sender..' is using addon version: '..message..'|r')


        end
    end
end)

local function GetPlayerLevel(sender)
    local _, _, _, _, level = GetPlayerInfoByGUID(sender)
    return level or 0
end


local hasSentVersionNumber = false

function printMessageToLfmWindow(output)
    local lfgOutputFound = false
    for i = 1, NUM_CHAT_WINDOWS do
        if (GetChatWindowInfo(i)=="p" or GetChatWindowInfo(i)=="P") then --if (GetChatWindowInfo(i)=="lfm" or GetChatWindowInfo(i)=="LFM") then
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
            if (i==8) then
                ChatFrame8:AddMessage(output)
            end
            if (i==9) then
                ChatFrame9:AddMessage(output)
            end
        end
    end
    if (not lfgOutputFound and not hasWarnedAboutChatName) then
        print('Did not find any chat windows named "LFM", please create one')
        hasWarnedAboutChatName = true
    end
end

function printMessageToNotLfmWindow(output)
    local lfgOutputFound = false
    for i = 1, NUM_CHAT_WINDOWS do
        if (GetChatWindowInfo(i)=="notlfm" or GetChatWindowInfo(i)=="NOTLFM") then
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
            if (i==8) then
                ChatFrame8:AddMessage(output)
            end
            if (i==9) then
                ChatFrame9:AddMessage(output)
            end
        end
    end
    if (not lfgOutputFound and not hasWarnedAboutChatName) then
        print('Did not find any chat windows named "NOTLFM", please create one')
        hasWarnedAboutChatName = true
    end
end

local function isInDungeon()
    -- loop over dungeons, if current zone is a dungeon, return dungeon. else return false
    return
end

local waitTable = {};
local waitFrame = nil;

function LFMCF__wait(delay, func, ...)
if(type(delay)~="number" or type(func)~="function") then
return false;
end
if(waitFrame == nil) then
waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
waitFrame:SetScript("onUpdate",function (self,elapse)
local count = #waitTable;
local i = 1;
while(i<=count) do
local waitRecord = tremove(waitTable,i);
local d = tremove(waitRecord,1);
local f = tremove(waitRecord,1);
local p = tremove(waitRecord,1);
if(d>elapse) then
tinsert(waitTable,i,{d-elapse,f,p});
i = i + 1;
else
count = count - 1;
f(unpack(p));
end
end
end);
end
tinsert(waitTable,{delay,func,{...}});
    return true;
end

local function removeBlizzIcons(text)
    local textWithoutIcons = text
    icons = {
        "{Skull}",
        "{Cross}",
        "{Square}",
        "{Moon}",
        "{Triangle}",
        "{Diamond}",
        "{Circle}",
        "{Star}"
        }
    for _, var in pairs(icons) do
        if (containsText(text,var)) then
            textWithoutIcons = textWithoutIcons:gsub(("%"..var)," ")
        end
    end
    for _, var in pairs(icons) do
        if (containsText(text,var:upper())) then
            textWithoutIcons = textWithoutIcons:gsub(("%"..var:upper())," ")
        end
    end
    for _, var in pairs(icons) do
        if (containsText(text,var:lower())) then
            textWithoutIcons = textWithoutIcons:gsub(("%"..var:lower())," ")
        end
    end
    if (text ~= textWithoutIcons and Options.DEBUG_MODE) then
        printMessageToLfmWindow("Fjernet blizz ikon! før var det: "..text)
    end
    return textWithoutIcons
end

local srep = string.rep
local function rpadLFM (s, l, c)
    local res = s .. srep(c or ' ', l - #s)
    return res, res ~= s
end

function ParseMessageCFA(sender, chatMessage, channel,network)

    if (lastMessageListUpdateTime + messageListClearInterval < time()) then
        for i = 1, messageListSize do
            messageList[i] = i
        end
        lastMessageListUpdateTime = time()
    end

    local messageListActualSize = 0
    for _ in pairs(messageList) do messageListActualSize = messageListActualSize + 1 end
    for i = 0, messageListActualSize do
        if (messageList[i] == chatMessage) then
            return nil
        end
    end

	local lowerMessage = chatMessage:lower()
	if (HasLFMTagCFA(lowerMessage) or (Options.include_LFG_messages_in_addition_to_LFM or (GetNumGroupMembers()>1 and GetNumGroupMembers()<5) and HasLFGTagCFA(lowerMessage))) then
        if(Options.hide_XP_runs == true) then
            if (hasXPRunTags(lowerMessage)) then
                if(Options.DEBUG_MODE) then
                    print('DEBUG: not showing message because it has XP run tags '..chatMessage)
                end
                return false
            end
        end
        if (Options.hide_cleave_and_AOE_runs == true) then
            if (hasCleaveTags(lowerMessage)) then
                if(Options.DEBUG_MODE) then
                    print('DEBUG: not showing message because it has Cleave run tags '..chatMessage)
                end
                return false
            end
        end

        if (network == "false") then --send message to other clients
            words = {}
            for word in chatMessage:gmatch("%w+") do
                table.insert(words, word)
            end
            networkMessage=sender..";"..UnitName("player")..";"..channel..";"..chatMessage
            success = C_ChatInfo.SendAddonMessage("LFMCF", networkMessage)
            --success = C_ChatInfo.SendAddonMessage("LFMCF", networkMessage,"GUILD")
            spamAllHiddenChannels(networkMessage)
        end

        if ((not Options.keep_looking_while_in_full_group) and (GetNumGroupMembers() == 5)) then
            if (not hasWarnedAboutFullGroup) then
                printMessageToLfmWindow("You're inn a full group. LFM will be disabled")
                printMessageToLfmWindow("If you still wish to look for LFM request this can be toggled in the settings")
                printMessageToLfmWindow("Good luck and have fun in the dungeon :)")
            end
            hasWarnedAboutFullGroup = true
            return false
        end

        local dungeonInMessage = HasDungeonAbbreviationCFA(lowerMessage)
        if ( dungeonInMessage ~= false or (isQuestFromLogInText(lowerMessage))) then
            hasWarnedAboutFullGroup = false
            pushToMessageList(chatMessage)
            local link = "|cffffc0c0|Hplayer:"..sender.."|h["..sender.."]|h|r:";
            local j,k = string.find(lowerMessage,dungeonInMessage:lower())
            local newMessage = string.sub(chatMessage,0,(j-1)).."|cffffc0FF"..string.sub(chatMessage,j,k):upper().."|r"..string.sub(chatMessage,k+1,chatMessage:len())
            --local output = "|cffffc0FF["..dungeonInMessage:upper().."]"
            local output = ""
            if (Options.show_time_stamp_on_messages) then
                local hours,minutes = GetGameTime();
                output = (output.."["..hours..":"..minutes.."] ")
            end
            output = output..link.." "..newMessage
            if (Options.display_channel_on_all_messages or (Options.display_channel_if_from_other_addon_user and network=="true") ) then
                output = output.." ["..channel.."]";
            end
            printMessageToLfmWindow(removeBlizzIcons(output))
            return true
        end
        return false
	end
    return false
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
        "last spot",
        "looking for more"
    }
    for _, tag in pairs(lfmTags) do
        if (string.find(text:lower(), tag)) then
            return true
        end
    end
    return false
end

function HasLFGTagCFA(text)
    if (string.find(text, "lfg")) then
        return true
    end
    return false
end

function ArrayContainsValueCFA(array, val)
    for index, value in ipairs(array) do
        if value == val then
            return true
        end
        if value:gsub('[%p%c%s]', '') == val then
            return true
        end
    end
    return false
end

function HasDungeonAbbreviationCFA(chatMessage)
    local lowerChatMessage = chatMessage:lower()
    local level = UnitLevel("player")
    if (not Options.include_dungeons_outside_of_level_range) then
        for key, dungeon in pairs(GetDungeonsByLevelCFA(level)) do
            if (containsTextFromArray(Dungeons[key].Name,disabledDungeons)) then
                return false
            end
            for _, abbreviation in pairs(dungeon.Abbreviations) do
                words = {}
                for word in lowerChatMessage:gmatch("%w+") do table.insert(words, word) end
                if (ArrayContainsValueCFA(words, abbreviation:lower())) then
                    return abbreviation
                end
            end
        end
    else
        for key, dungeon in pairs(Dungeons) do
            for _, abbreviation in pairs(dungeon.Abbreviations) do
                words = {}
                for word in lowerChatMessage:gmatch("%w+") do table.insert(words, word) end
                if (ArrayContainsValueCFA(words, abbreviation:lower())) then
                    return abbreviation
                end
            end
        end
    end
    return false
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
        if (dungeon.MinLevel <= level and dungeon.MaxLevel >= level) then
            dungeonsForLevel[dungeon.Name] = dungeon
        end
    end
    return dungeonsForLevel
end


-- Dungeon defining stole shamelessly from ClassicLFG addon
DefineDungeonCFA("Ragefire Chasm", 5, 13, 18, "Orgrimmar", "rfc", {"rfc", "ragefire"})
DefineDungeonCFA("Wailing Caverns", 5, 17, 24, "Barrens", "wc", {"wc","wailing"})
DefineDungeonCFA("The Deadmines", 5, 17, 24, "Westfall", "vc", {"vc", "deadmines"})
DefineDungeonCFA("Shadowfang Keep", 5, 21, 30, "Silverpine Forest", "sfk", {"sfk", "shadowfang"})
DefineDungeonCFA("Blackfathom Deeps", 5, 22, 32, "Ashenvale", "bfd", {"bfd","blackfathom"})
DefineDungeonCFA("The Stockades", 5, 22, 30, "Stormwind", "stockades", {"stockades", "stocks","stockade"})
DefineDungeonCFA("Gnomeregan", 5, 28, 38, "Dun Morogh", "gnomergan", {"gnomeregan", "gnomer","gnome"})
DefineDungeonCFA("Razorfen Kraul", 5, 25, 39, "Barrens", "rfk", {"rfk", "kraul"})
DefineDungeonCFA("The Scarlet Monastery: Graveyard", 5, 28, 44, "Tirisfal Glades", "sm graveyard", {"grave","graveyard","sm","scarlet"})
DefineDungeonCFA("The Scarlet Monastery: Library", 5, 30, 44, "Tirisfal Glades", "sm library", {"lib","library","sm","scarlet"})
DefineDungeonCFA("The Scarlet Monastery: Armory", 5, 32, 44, "Tirisfal Glades", "sm armory", {"arms","arm","sm","scarlet"})
DefineDungeonCFA("The Scarlet Monastery: Cathedral", 5, 34, 44, "Tirisfal Glades", "sm cathedral", {"cath","cathedral","scarlet","sm"})
DefineDungeonCFA("Razorfen Downs", 5, 36, 46, "Barrens", "rfd", {"rfd","razorfen","downs"})
DefineDungeonCFA("Uldaman", 5, 41, 52, "Badlands", "ulda", {"ulda","uldaman"})
DefineDungeonCFA("Zul'Farak", 5, 42, 54, "Tanaris", "zf", {"zf","zul","farak","farrak"})
DefineDungeonCFA("Maraudon", 5, 44, 54, "Desolace", "maraudon", {"maraudon", "mara"})
DefineDungeonCFA("Temple of Atal'Hakkar", 5, 47, 60, "Swamp of Sorrows", "st", {"st", "toa", "atal", "sunken"})
DefineDungeonCFA("Blackrock Depths", 5, 49, 60, "Blackrock Mountain", "brd", {"blackrock", "depths","brd","moira","lava","arena", "anger","golem","jailbreak","jailbreack","angerforge"})
DefineDungeonCFA("Lower Blackrock Spire", 10, 55, 60, "Blackrock Mountain", "lbrs", {"lbrs","lower blackrock spire"})
DefineDungeonCFA("Upper Blackrock Spire", 10, 55, 60, "Blackrock Mountain", "ubrs", {"ubrs","upper blackrock spire","rend"})
-- ToDo: Need to add all the Dungeon parts once they are released on Classic Realms
DefineDungeonCFA("Dire Maul", 5, 56, 60, "Feralas", "Dire", {"dire","dm","tribute","maul","diremaul","dme","dmn","dmw"})
--
DefineDungeonCFA("Stratholme", 5, 56, 60, "Eastern Plaguelands", "strat", {"strat","stratholme","start"," living"," ud ","undead","Startholme"})
DefineDungeonCFA("Scholomance", 5, 56, 60, "Eastern Plaguelands", "scholo", {"scholo","scholomance"})
DefineDungeonCFA("Molten Core", 40, 60, 60, "Blackrock Depths", "mc", {"mc","molten"})
DefineDungeonCFA("Onyxia's Lair", 40, 60, 60, "Dustwallow Marsh", "ony", {"ony", "onyxia","onyxia's"})

print("Possible dungeons for your level: ")
for key, dungeon in pairs(GetDungeonsByLevelCFA(UnitLevel("player"))) do
    print(key)
end



