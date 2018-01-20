local RaidSummonOptions_DefaultSettings = {
	whisper = true,
	zone    = true,
    shards  = true,
    debug   = false
}

local function RaidSummon_Initialize()
	if not RaidSummonOptions  then
		RaidSummonOptions = {}
	end
	for i in RaidSummonOptions_DefaultSettings do
		if (not RaidSummonOptions[i]) then
			RaidSummonOptions[i] = RaidSummonOptions_DefaultSettings[i]
		end
	end
end

function RaidSummon_EventFrame_OnLoad()
	DEFAULT_CHAT_FRAME:AddMessage(string.format("RaidSummon version %s by %s. Type /rs or /raidsummon to show.", GetAddOnMetadata("RaidSummon", "Version"), GetAddOnMetadata("RaidSummon", "Author")))
    this:RegisterEvent("VARIABLES_LOADED")
    this:RegisterEvent("CHAT_MSG_ADDON")
    this:RegisterEvent("CHAT_MSG_RAID")
	this:RegisterEvent("CHAT_MSG_RAID_LEADER")
    this:RegisterEvent("CHAT_MSG_SAY")
    this:RegisterEvent("CHAT_MSG_YELL")
    this:RegisterEvent("CHAT_MSG_WHISPER")
    -- Commands
	SlashCmdList["RAIDSUMMON"] = RaidSummon_SlashCommand
	SLASH_RAIDSUMMON1 = "/raidsummon"
	SLASH_RAIDSUMMON2 = "/rs"
	MSG_PREFIX_ADD		= "RSAdd"
	MSG_PREFIX_REMOVE	= "RSRemove"
	RaidSummonDB = {}
	-- Sync Summon Table between raiders ? (if in raid & raiders with unempty table)
	--localization
	RaidSummonLoc_Header = "RaidSummon"
end

function RaidSummon_EventFrame_OnEvent()
	if event == "VARIABLES_LOADED" then
		this:UnregisterEvent("VARIABLES_LOADED")
		RaidSummon_Initialize()
	elseif event == "CHAT_MSG_SAY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_WHISPER" then	
		-- if (string.find(arg1, "^123") and UnitClass("player")~=arg2) then
		if string.find(arg1, "^123") then
			-- DEFAULT_CHAT_FRAME:AddMessage("CHAT_MSG")
			SendAddonMessage(MSG_PREFIX_ADD, arg2, "RAID")
		elseif string.find(arg1, "^sum") then
			-- DEFAULT_CHAT_FRAME:AddMessage("CHAT_MSG")
			SendAddonMessage(MSG_PREFIX_ADD, arg2, "RAID")
		elseif string.find(arg1, "^summon") then
			-- DEFAULT_CHAT_FRAME:AddMessage("CHAT_MSG")
			SendAddonMessage(MSG_PREFIX_ADD, arg2, "RAID")
		end
	elseif event == "CHAT_MSG_ADDON" then
		if arg1 == MSG_PREFIX_ADD then
			-- DEFAULT_CHAT_FRAME:AddMessage("CHAT_MSG_ADDON - RSAdd : " .. arg2)
			if not RaidSummon_hasValue(RaidSummonDB, arg2) and UnitName("player")~=arg2 then
				table.insert(RaidSummonDB, arg2)
				RaidSummon_UpdateList()
			end
		elseif arg1 == MSG_PREFIX_REMOVE then
			if RaidSummon_hasValue(RaidSummonDB, arg2) then
				-- DEFAULT_CHAT_FRAME:AddMessage("CHAT_MSG_ADDON - RSRemove : " .. arg2)
				for i, v in ipairs (RaidSummonDB) do
					if v == arg2 then
						table.remove(RaidSummonDB, i)
						RaidSummon_UpdateList()
					end
				end
			end
		end
	end
end

function RaidSummon_hasValue (tab, val)
    for i, v in ipairs (tab) do
        if v == val then
            return true
        end
    end
    return false
end

--GUI
function RaidSummon_NameListButton_OnClick(button)
	local name = getglobal(this:GetName().."TextName"):GetText()
	local message, base_message, whisper_message, base_whisper_message, whisper_eviltwin_message, zone_message, subzone_message = ""
	local bag,slot,texture,count = FindItem("Soul Shard")
	local eviltwin_debuff = "Spell_Shadow_Charm"
	local has_eviltwin = false

	if button  == "LeftButton" and IsControlKeyDown() then
		RaidSummon_GetRaidMembers()
		if RaidSummon_UnitIDDB then
			for i, v in ipairs (RaidSummon_UnitIDDB) do
				if v.rName == name then
					UnitID = "raid"..v.rIndex
				end
			end
			if UnitID then
				TargetUnit(UnitID)
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cff9482c9RaidSummon|r : no raid found")
		end
	elseif button == "LeftButton" and not IsControlKeyDown() then
		RaidSummon_GetRaidMembers()
		if RaidSummon_UnitIDDB then
			for i, v in ipairs (RaidSummon_UnitIDDB) do
				if v.rName == name then
					UnitID = "raid"..v.rIndex
				end
			end
			if UnitID then
				playercombat = UnitAffectingCombat("player")
				targetcombat = UnitAffectingCombat(UnitID)
			
				if not playercombat and not targetcombat then
					base_message 			= "Summoning <" .. name .. ">"
					base_whisper_message    = "Summoning you"
					zone_message            = " @" .. GetZoneText()
					subzone_message         = " @" .. GetSubZoneText()
					shards_message          = " [" .. count .. " shards]"
					message                 = base_message
					whisper_message         = base_whisper_message

					-- Evil Twin check
					for i=1,16 do
						s=UnitDebuff("target", i)
						if(s) then
							if (strfind(strlower(s), strlower(eviltwin_debuff))) then
						        has_eviltwin = true
							end
						end
					end

					TargetUnit(UnitID)

					if (has_eviltwin) then
						whisper_eviltwin_message = "Can't summon you because of Evil Twin Debuff, you need either to die or to run by yourself"
						SendChatMessage(whisper_eviltwin_message, "WHISPER", nil, name)
						DEFAULT_CHAT_FRAME:AddMessage("|cff9482c9RaidSummon|r : <" .. name .. "> has |cffff0000Evil Twin|r !")
						for i, v in ipairs (RaidSummonDB) do
							if v == name then
								SendAddonMessage(MSG_PREFIX_REMOVE, name, "RAID")
								table.remove(RaidSummonDB, i)
							end
						end
					elseif (Check_TargetInRange()) then
						DEFAULT_CHAT_FRAME:AddMessage("|cff9482c9RaidSummon|r : <" .. name .. "> has been summoned already (|cffff0000in range|r)")
						-- Remove the already summoned target
						for i, v in ipairs (RaidSummonDB) do
							if v == name then
						    	SendAddonMessage(MSG_PREFIX_REMOVE, name, "RAID")
						    	table.remove(RaidSummonDB, i)
						    	RaidSummon_UpdateList()
						    end
						end
					else
						-- TODO: Detect if spell is aborted/cancelled : use SpellStopCasting if sit ("You must be standing to do that")
						CastSpellByName("Ritual of Summoning")

						-- Send Raid Message
						if RaidSummonOptions.zone then
							if GetSubZoneText() == "" then
						    	message         = message .. zone_message
						    	whisper_message = base_whisper_message .. zone_message
							else
						    	message         = message .. subzone_message
						    	whisper_message = whisper_message .. subzone_message
							end
						end
						if RaidSummonOptions.shards then
					    	message = message .. shards_message
						end
						SendChatMessage(message, "RAID")

						-- Send Whisper Message
						if RaidSummonOptions.whisper then
							SendChatMessage(whisper_message, "WHISPER", nil, name)
						end

						-- Remove the summoned target
						for i, v in ipairs (RaidSummonDB) do
							if v == name then
						    	SendAddonMessage(MSG_PREFIX_REMOVE, name, "RAID")
						    	table.remove(RaidSummonDB, i)
						    	RaidSummon_UpdateList()
						    end
						end
					end
				else
					DEFAULT_CHAT_FRAME:AddMessage("|cff9482c9RaidSummon|r : Player is in combat")
				end
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cff9482c9RaidSummon|r : <" .. tostring(name) .. "> not found in raid. UnitID: " .. tostring(UnitID))
				SendAddonMessage(MSG_PREFIX_REMOVE, name, "RAID")
				RaidSummon_UpdateList()
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cff9482c9RaidSummon|r : no raid found")
		end
	elseif button == "RightButton" then
		for i, v in ipairs (RaidSummonDB) do
			if v == name then
				SendAddonMessage(MSG_PREFIX_REMOVE, name, "RAID")
				table.remove(RaidSummonDB, i)
				RaidSummon_UpdateList()
			end
		end
	end
	RaidSummon_UpdateList()
end

function RaidSummon_UpdateList()
	RaidSummon_BrowseDB = {}
	--only Update and show if Player is Warlock
	 if (UnitClass("player") == "Warlock") then
		--get raid member data
		local raidnum = GetNumRaidMembers()
		if (raidnum > 0) then
			for raidmember = 1, raidnum do
				local rName, rRank, rSubgroup, rLevel, rClass = GetRaidRosterInfo(raidmember)
				--check raid data for RaidSummon data
				for i, v in ipairs (RaidSummonDB) do 
					--if player is found fill BrowseDB
					if v == rName then
						RaidSummon_BrowseDB[i] = {}
						RaidSummon_BrowseDB[i].rName = rName
						RaidSummon_BrowseDB[i].rClass = rClass
						RaidSummon_BrowseDB[i].rIndex = i
						if rClass == "Warlock" then
							RaidSummon_BrowseDB[i].rVIP = true
						else
							RaidSummon_BrowseDB[i].rVIP = false
						end
					end
				end
			end

			--sort warlocks first
			table.sort(RaidSummon_BrowseDB, function(a,b) return tostring(a.rVIP) > tostring(b.rVIP) end)
		end
		
		for i=1,10 do
			if RaidSummon_BrowseDB[i] then
				getglobal("RaidSummon_NameList"..i.."TextName"):SetText(RaidSummon_BrowseDB[i].rName)
				
				--set class color
				if RaidSummon_BrowseDB[i].rClass == "Druid" then
					local c = RaidSummon_GetClassColour("DRUID")
					getglobal("RaidSummon_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif RaidSummon_BrowseDB[i].rClass == "Hunter" then
					local c = RaidSummon_GetClassColour("HUNTER")
					getglobal("RaidSummon_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif RaidSummon_BrowseDB[i].rClass == "Mage" then
					local c = RaidSummon_GetClassColour("MAGE")
					getglobal("RaidSummon_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif RaidSummon_BrowseDB[i].rClass == "Paladin" then
					local c = RaidSummon_GetClassColour("PALADIN")
					getglobal("RaidSummon_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif RaidSummon_BrowseDB[i].rClass == "Priest" then
					local c = RaidSummon_GetClassColour("PRIEST")
					getglobal("RaidSummon_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif RaidSummon_BrowseDB[i].rClass == "Rogue" then
					local c = RaidSummon_GetClassColour("ROGUE")
					getglobal("RaidSummon_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif RaidSummon_BrowseDB[i].rClass == "Shaman" then
					local c = RaidSummon_GetClassColour("SHAMAN")
					getglobal("RaidSummon_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif RaidSummon_BrowseDB[i].rClass == "Warlock" then
					local c = RaidSummon_GetClassColour("WARLOCK")
					getglobal("RaidSummon_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif RaidSummon_BrowseDB[i].rClass == "Warrior" then
					local c = RaidSummon_GetClassColour("WARRIOR")
					getglobal("RaidSummon_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				end				
				
				getglobal("RaidSummon_NameList"..i):Show()
			else
				getglobal("RaidSummon_NameList"..i):Hide()
			end
		end
		
		if not RaidSummonDB[1] then
			if RaidSummon_RequestFrame:IsVisible() then
				RaidSummon_RequestFrame:Hide()
			end
		else
			ShowUIPanel(RaidSummon_RequestFrame, 1)
		end
	end	
end

--Slash Handler
function RaidSummon_SlashCommand(msg)
	if msg == "help" then
		DEFAULT_CHAT_FRAME:AddMessage("RaidSummon usage:")
		DEFAULT_CHAT_FRAME:AddMessage("/rs or /raidsummon { help | show | zone | whisper | shards | debug }")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9help|r: prints out this help")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9show|r: shows the current summon list")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9zone|r: toggles zoneinfo in /ra and /w")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9whisper|r: toggles the usage of /w")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9shards|r: toggles shards count when you announce a summon in /ra")
		DEFAULT_CHAT_FRAME:AddMessage("To drag the frame use left mouse button")
	elseif msg == "show" then
		for i, v in ipairs(RaidSummonDB) do
			DEFAULT_CHAT_FRAME:AddMessage(tostring(v))
		end
	elseif msg == "zone" then
		if RaidSummonOptions["zone"] == true then
			RaidSummonOptions["zone"] = false
			DEFAULT_CHAT_FRAME:AddMessage("RaidSummon - zoneinfo: |cffff0000disabled|r")
		elseif RaidSummonOptions["zone"] == false then
			RaidSummonOptions["zone"] = true
			DEFAULT_CHAT_FRAME:AddMessage("RaidSummon - zoneinfo: |cff00ff00enabled|r")
		end
	elseif msg == "whisper" then
		if RaidSummonOptions["whisper"] == true then
			RaidSummonOptions["whisper"] = false
			DEFAULT_CHAT_FRAME:AddMessage("RaidSummon - whisper: |cffff0000disabled|r")
		elseif RaidSummonOptions["whisper"] == false then
			RaidSummonOptions["whisper"] = true
			DEFAULT_CHAT_FRAME:AddMessage("RaidSummon - whisper: |cff00ff00enabled|r")
		end
	 elseif msg == "shards" then
		if RaidSummonOptions["shards"] == true then
	       RaidSummonOptions["shards"] = false
	       DEFAULT_CHAT_FRAME:AddMessage("RaidSummon - shards: |cffff0000disabled|r")
		elseif RaidSummonOptions["shards"] == false then
	       RaidSummonOptions["shards"] = true
	       DEFAULT_CHAT_FRAME:AddMessage("RaidSummon - shards: |cff00ff00enabled|r")
		end
		elseif msg == "debug" then
		if RaidSummonOptions["debug"] == true then
	       RaidSummonOptions["debug"] = false
	       DEFAULT_CHAT_FRAME:AddMessage("RaidSummon - debug: |cffff0000disabled|r")
		elseif RaidSummonOptions["debug"] == false then
	       RaidSummonOptions["debug"] = true
	       DEFAULT_CHAT_FRAME:AddMessage("RaidSummon - debug: |cff00ff00enabled|r")
		end
	else
		if RaidSummon_RequestFrame:IsVisible() then
			RaidSummon_RequestFrame:Hide()
		else
			RaidSummon_UpdateList()
			ShowUIPanel(RaidSummon_RequestFrame, 1)
		end
	end
end

--class color
function RaidSummon_GetClassColour(class)
	if (class) then
		local color = RAID_CLASS_COLORS[class]
		if (color) then
			return color
		end
	end
	return {r = 0.5, g = 0.5, b = 1}
end

--raid member
function RaidSummon_GetRaidMembers()
    local raidnum = GetNumRaidMembers()
    if (raidnum > 0) then
		RaidSummon_UnitIDDB = {}
		for i = 1, raidnum do
		    local rName, rRank, rSubgroup, rLevel, rClass = GetRaidRosterInfo(i)
			RaidSummon_UnitIDDB[i] = {}
			if (not rName) then 
			    rName = "unknown"..i
			end
			RaidSummon_UnitIDDB[i].rName    = rName
			RaidSummon_UnitIDDB[i].rClass   = rClass
			RaidSummon_UnitIDDB[i].rIndex   = i
	    end
	end
end

-- FindItem function from SuperMacro to get the total number of Soul Shards
function FindItem(item)
	if (not item) then return end
	item = string.lower(ItemLinkToName(item))
	local link
	for i = 1,23 do
       link = GetInventoryItemLink("player",i)
       if (link) then
           if (item == string.lower(ItemLinkToName(link))) then
                return i, nil, GetInventoryItemTexture('player', i), GetInventoryItemCount('player', i)
           end
       end
	end
	local count, bag, slot, texture
	local totalcount = 0
	for i = 0,NUM_BAG_FRAMES do
       for j = 1,MAX_CONTAINER_ITEMS do
           link = GetContainerItemLink(i,j)
           if (link) then
               if (item == string.lower(ItemLinkToName(link))) then
	               bag, slot = i, j
	               texture, count = GetContainerItemInfo(i,j)
	               totalcount = totalcount + count
               end
           end
       end
	end
	return bag, slot, texture, (totalcount - 1)
end

-- Checks if the target is in range (28 yards)
function Check_TargetInRange()
   if not (GetUnitName("target")==nil) then
       local t = UnitName("target")
       if (CheckInteractDistance("target", 4)) then
           return true
       else
           return false
       end
   end
end
