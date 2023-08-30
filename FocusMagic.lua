local PREFIX = "|cff33ff99"..(...).."|r:"
local LOCALE = GetLocale()
local CI = LibStub("LibClassicInspector")

local GetNumGroupMembers, GetRaidRosterInfo, IsInGroup, IsInRaid, SendChatMessage, SlashCmdList, UnitClass, UnitIsUnit, UnitName = GetNumGroupMembers, GetRaidRosterInfo, IsInGroup, IsInRaid, SendChatMessage, SlashCmdList, UnitClass, UnitIsUnit, UnitName
local print, tinsert, tremove, tsort = print, table.insert, table.remove, table.sort

local ASSUME_FOCUS_MAGIC_IF_WAITING_TO_INSPECT = true
local PREFER_SMALL_CIRCLES = true
local COLOR_HIGHLIGHT = "|cff1eff0c"

local group = {}


function group:Build()
  self.isInGroup = IsInGroup()
  self.isInRaid = IsInRaid()
  if self.isInGroup then
    self.size = GetNumGroupMembers()
  else
    self.size = 1
  end
  self.roster = {}
  for i = 1, self.size do
    self:AddRoster(i)
  end
end


function group:AddRoster(index)
  local unitId = "party"..index
  local party = 1
  if not self.isInGroup then
    unitId = "player"
  elseif self.isInRaid then
    unitId = "raid"..index
    party = select(3, GetRaidRosterInfo(index))
  end
  local data = {
    ["name"] = UnitName(unitId),
    ["party"] = party,
    ["isPlayer"] = UnitIsUnit(unitId, "player"),
    ["isMage"] = false,
    ["needToInspect"] = false,
    ["hasFocusMagic"] = false,
  }
  if select(2, UnitClass(unitId)) == "MAGE" then
    data.isMage = true
    local _, _, _, _, rank = CI:GetTalentInfo(unitId, 1, 29)
    if not rank then
      data.needToInspect = true
      data.hasFocusMagic = ASSUME_FOCUS_MAGIC_IF_WAITING_TO_INSPECT
    elseif rank == 1 then
      data.hasFocusMagic = true
    end
  end
  self.roster[index] = data
end


function group:GetMagesToInspect()
  local names = {}
  for i = 1, self.size do
    if self.roster[i].needToInspect then
      tinsert(names, self.roster[i].name)
    end
  end
  tsort(names)
  return names
end


function group:GetMagesWithFocusMagic()
  local names = {}
  for i = 1, self.size do
    if self.roster[i].hasFocusMagic then
      tinsert(names, self.roster[i].name)
    end
  end
  tsort(names)
  return names
end


function group:GetMagesWithoutFocusMagic()
  local names = {}
  for i = 1, self.size do
    if self.roster[i].isMage and not self.roster[i].hasFocusMagic then
      tinsert(names, self.roster[i].name)
    end
  end
  tsort(names)
  return names
end


function group:ShouldUsePartyChat()
  local parties = {}
  for i = 1, self.size do
    if self.roster[i].hasFocusMagic or self.roster[i].isPlayer then
      parties[self.roster[i].party] = true
    end
  end
  return #parties == 1
end


local function join(sep, list)
  if #list < 1 then
    return ""
  end
  local result = list[i]
  for i = 2, #list do
    result = result..sep..list[i]
  end
  return result
end


local function announceFocusMagicAssignments(shouldAnnounce, shouldForce)
  group:Build()
  local goodMages = group:GetMagesWithFocusMagic()
  if #goodMages < 2 then
    print(PREFIX.." There are fewer than 2 mages with focus magic.")
    return
  end
  if not shouldForce then
    local magesToInspect = group:GetMagesToInspect()
    if #magesToInspect > 0 then
      shouldAnnounce = false
      print(PREFIX.." Need to inspect "..join("/", magesToInspect).." to verify they spec into focus magic.")
      print("Type "..COLOR_HIGHLIGHT.."/fm force|r to assume yes and announce anyway.")
    end
  end

  --Generate assignment message, e.g.:
  --FM: Amage<=>Bmage
  --FM: Amage<=>Bmage (Xmage does not have FM)
  --FM alphabetically: Amage=>Bmage=>Cmage=>Amage
  --FM alphabetically: Amage<=>Bmage, Cmage<=>Dmage
  --FM alphabetically: Amage<=>Bmage, Cmage=>Dmage=>Emage=>Cmage
  --FM alphabetically: Amage<=>Bmage, Cmage<=>Dmage, Emage=>Fmage=>Gmage=>Emage (Xmage/Ymage do not have FM)
  local message = "FM"
  if #goodMages > 2 then
    message = message.." alphabetically"
  end
  while PREFER_SMALL_CIRCLES and #goodMages > 3 do
    message = message..", "..goodMages[1].."<=>"..goodMages[2]
    tremove(goodMages, 1)
    tremove(goodMages, 1)
  end
  if #goodMages < 3 then
    message = message..", "..goodMages[1].."<=>"..goodMages[2]
  else
    message = message..", "
    for i = 1, #goodMages do
      message = message..goodMages[i].."=>"
    end
    message = message..goodMages[1]
  end
  local badMages = group:GetMagesWithoutFocusMagic()
  if #badMages == 1 then
    message = message.." ("..badMages[1].." does not have FM)"
  elseif #badMages > 1 then
    message = message.." ("..join("/", badMages).." do not have FM)"
  end
  message = message:gsub(",", ":", 1)

  if shouldAnnounce then
    local channel = "RAID"
    if group:ShouldUsePartyChat() then
      channel = "PARTY"
    end
    SendChatMessage(message, channel)
  else
    print(message)
  end
end


local function printHelp()
  print(PREFIX.." Usage:")
  print(" "..COLOR_HIGHLIGHT.."/fm|r - announce focus magic assignments")
  print(" "..COLOR_HIGHLIGHT.."/fm force|r - same as above, but announce even if the addon hasn't verified that all mages spec into FM")
  print(" "..COLOR_HIGHLIGHT.."/fm quiet|r - generate focus assignments but don't announce them")
end


local function slashCommand(args)
  args = string.lower(args or "")
  if args == "" then
    announceFocusMagicAssignments(true, false)
  elseif args == "f" or args == "force" then
    announceFocusMagicAssignments(true, true)
  elseif args == "q" or args == "quiet" then
    announceFocusMagicAssignments(false, false)
  else
    printHelp()
  end
end


SLASH_FM1 = "/fm"
SlashCmdList["FM"] = slashCommand
