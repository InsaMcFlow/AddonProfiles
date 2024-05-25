local ADDON_NAME, _ = ...;

local strlower = _G.strlower;
local strsplit = strsplit;
local strjoin = strjoin;

local UnitName = UnitName;
local GetNumAddOns = GetNumAddOns;
local GetAddOnInfo = GetAddOnInfo;
local GetAddOnEnableState = GetAddOnEnableState;
local EnableAddOn = EnableAddOn;
local DisableAddOn = DisableAddOn;

--##############################################################################

local profiles;
local events = {};
local eventFrame = CreateFrame('frame');

function events.ADDON_LOADED (addonName)
  if (addonName ~= ADDON_NAME) then return end

  if (type(_G.AddonProfiles_Saved) == 'table') then
    profiles = _G.AddonProfiles_Saved;
  else
    profiles = {};
  end

  events.ADDON_LOADED = nil;
  eventFrame:UnregisterEvent('ADDON_LOADED');
end

function events.PLAYER_LOGOUT ()
  if (profiles == nil) then return end

  _G.AddonProfiles_Saved = profiles;
end

for event in pairs(events) do
  eventFrame:RegisterEvent(event);
end

eventFrame:SetScript('OnEvent', function (self, event, ...)
  events[event](...);
end);

--##############################################################################

local slashCommands = {};

local function executeSlashCommand (command, ...)
  if (not slashCommands[command]) then
    return print(ADDON_NAME .. ': unknown command "' .. command .. '"');
  end

  -- All slash commands use profile names so passing "default" as the profile
  -- name if none was passed prevents code duplication.
  if (... == nil) then
    slashCommands[command]('default');
  else
    slashCommands[command](...);
  end
end

local function slashHandler (input)
  if (input == nil or input == '') then
    return executeSlashCommand('default');
  end

  executeSlashCommand (strsplit(' ', input));
end

_G['SLASH_' .. ADDON_NAME .. '1'] = '/' .. ADDON_NAME;
_G['SLASH_' .. ADDON_NAME .. '2'] = '/ap';
_G.SlashCmdList[ADDON_NAME] = slashHandler;

--##############################################################################

local function getPlayerName ()
  return UnitName('player');
end

local function getAddonEnabledInfo ()
  local playerName = getPlayerName();
  local info = {};

  for x = 1, GetNumAddOns(), 1 do
    info[GetAddOnInfo(x)] = (GetAddOnEnableState(playerName, x) == 2);
  end

  return info;
end

function slashCommands.save (profileName)
  profiles[profileName] = getAddonEnabledInfo();
  print('saved addon profile:', profileName);
end

local function getAddonProfile (profileName)
  local profile = profiles[profileName];

  if (profile == nil) then
    print('addon profile not found:', profileName);
  end

  return profile;
end

local function restoreProfile (profile, characterOrAll)
  for x = 1, GetNumAddOns(), 1 do
    local addonName = GetAddOnInfo(x);

    if (profile[addonName] == true) then
      EnableAddOn(addonName, characterOrAll);
    else
      DisableAddOn(addonName, characterOrAll);
    end
  end
end

local function mergeProfile (profile, characterOrAll)
  for x = 1, GetNumAddOns(), 1 do
    local addonName = GetAddOnInfo(x);

    if (profile[addonName] == true) then
      EnableAddOn(addonName, characterOrAll);
    end
  end
end

local function removeProfile (profile, characterOrAll)
  for x = 1, GetNumAddOns(), 1 do
    local addonName = GetAddOnInfo(x);
    if (profile[addonName] == true and addonName ~= ADDON_NAME) then
      DisableAddOn(addonName, characterOrAll);
    end
  end
end
--[[ This has to return either a character name or nil, as it will be passed
     directly to EnableAddOn ]]
local function parseAllCharactersFlag (allCharacters)
  if (allCharacters == nil) then
    return getPlayerName();
  end

  allCharacters = allCharacters:lower();

  if (allCharacters == 'all' or allCharacters == 'true') then
    return nil;
  end

  return getPlayerName();
end

function slashCommands.load (profileName, allCharacters)
  local profile = getAddonProfile(profileName);

  if (profile ~= nil) then
    restoreProfile(profile, parseAllCharactersFlag(allCharacters));
    print('restored saved addon profile:', profileName);
  end
end

function slashCommands.delete (...)
  local profileName = strjoin(' ', ...);

  if (getAddonProfile(profileName) ~= nil) then
    profiles[profileName] = nil;
    print('deleted profile:', profileName);
  end
end

function slashCommands.default ()
  print('available commands:')
  print('save|load|delete <profileName> [all]')
  print('add <profileName> [all]: enable all addons from profileName')
  print('remove <profileName> [all]: disable all addons from profileName')
  if (next(profiles) == nil) then
    return print('no addon profiles saved');
  end

  print('available addon profiles:');
  for profileName in pairs(profiles) do
    print(profileName);
  end
end

function slashCommands.add (profileName, allCharacters)
  local profile = getAddonProfile(profileName);
  if (profile ~= nil) then
    mergeProfile(profile, parseAllCharactersFlag(allCharacters))
    print('merging addons from profile:', profileName)
  end
end 

function slashCommands.remove (profileName, allCharacters)
  local profile = getAddonProfile(profileName);
  if (profile ~= nil) then
    removeProfile(profile, parseAllCharactersFlag(allCharacters))
    print('disabling addons from profile:', profileName)
  end
end 