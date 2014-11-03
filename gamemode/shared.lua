
include( "player_class/player_assault.lua" )


DEFINE_BASECLASS( "gamemode_base" )



GM.Name = "Assault"
GM.Author = "HighVoltage"
GM.Email = "N/A"
GM.Website = "N/A"

GM.TeamBased 	= true

ROUND_WAIT		= 0		-- Waiting for more players
ROUND_STARTING	= 1		-- Time between rounds
ROUND_ACTIVE	= 2		-- Gameplay

COMPLETE_TIME	= 1		-- Game over after running out of time
COMPLETE_OBJECTIVE = 2	-- After completeing all the objectives

OBJECTIVE_HOLD = 0
OBJECTIVE_TOUCH = 1
OBJECTIVE_DESTROY = 2
OBJECTIVE_VEHICLE = 3

ATTACKINGTEAM	= TEAM_RED	-- Red team attacks first 

RebelModels = {}
for i = 7, 12 do
	table.insert( RebelModels, "female"..(i<10 and "0"..i or i ) )
end
for i = 10, 18 do
	table.insert( RebelModels, "male"..(i<10 and "0"..i or i ) )
end
CitizenModels = {}
for i = 1, 6 do
	table.insert( CitizenModels, "female"..(i<10 and "0"..i or i ) )
end
for i = 1, 9 do
	table.insert( CitizenModels, "male"..(i<10 and "0"..i or i ) )
end
CombineModels = { "combine", "combineprison", "combineelite", "police", "policefem" }
ZombieModels = { "zombie", "zombiefast", "zombine" }
CorpseModels = { "charple", "corpse", "skeleton" }
TerroristModels = { "css_arctic", "css_guerilla", "css_leet", "css_phoenix" }
CounterTerroristModels = { "css_gasmask", "css_riot", "css_swat", "css_urban" }
HostageModels = { "hostage01", "hostage02", "hostage03", "hostage04" }
ResistanceModels = { "alyx", "barney", "eli", "kleiner", "monk", "mossman", "odessa", "magnusson" }
AmericanModels = { "dod_american" }
GermanModels = { "dod_german" }

PlayerModels = {
					[0] = RebelModels,
					[1] = CitizenModels,
					[2] = ResistanceModels,
					[3] = CombineModels,
					[4] = TerroristModels,
					[5] = CounterTerroristModels,
					[6] = HostageModels,
					[7] = ZombieModels,
					[8] = CorpseModels,
					[9] = AmericanModels,
					[10] = GermanModels
				}
PlayerLoadouts = {
					[1] = { wep = { "weapon_pistol" }, ammo = {["Pistol"] = 50}},
					[2] = { wep = { "weapon_pistol", "weapon_crowbar"}, ammo = {["Pistol"] = 50}},
					[3] = { wep = { "weapon_pistol", "weapon_smg1"}, ammo = {["Pistol"] = 50, ["SMG1"] = 90}},
					[4] = { wep = { "weapon_pistol", "weapon_smg1", "weapon_physcannon"}, ammo = {["Pistol"] = 50, ["SMG1"] = 90}},
					[5] = { wep = { "weapon_pistol", "weapon_stunstick"}, ammo = {["Pistol"] = 50}},
					[6] = { wep = { "weapon_pistol", "weapon_ar2"}, ammo = {["Pistol"] = 50, ["AR2"] = 60, ["AR2AltFire"] = 1}},
					[7] = { wep = { "weapon_fists"}},	--weapon_zombie
					[8] = { wep = { "weapon_crowbar"}},
					[9] = { wep = { "weapon_stunstick"}}
				}	

--[[---------------------------------------------------------
   Name: gamemode:CreateTeams()
   Desc: Note - HAS to be shared.
-----------------------------------------------------------]]
function GM:CreateTeams()

	TEAM_RED = 1
	team.SetUp( TEAM_RED, "Red Team", Color( 200, 0, 0 ) )
//	team.SetSpawnPoint( TEAM_RED, "ai_hint" ) -- <-- This would be info_terrorist or some entity that is in your map
	
	TEAM_BLUE = 2
	team.SetUp( TEAM_BLUE, "Blue Team", Color( 42, 62, 200 ) )
//	team.SetSpawnPoint( TEAM_BLUE, "sky_camera" ) -- <-- This would be info_terrorist or some entity that is in your map
	
	team.SetSpawnPoint( TEAM_SPECTATOR, "worldspawn" ) 

end

function GetAttackingTeam()
	return GetGlobalFloat("as_attacking_team", TEAM_RED )
end

function GetDefendingTeam()
	if GetGlobalFloat("as_attacking_team", TEAM_RED ) == TEAM_RED then
		return TEAM_BLUE
	else
		return TEAM_RED
	end
end

function SetAttackingTeam( Team )
	SetGlobalFloat("as_attacking_team", Team)
end

function SwitchAttackingTeam()
	SetAttackingTeam( GetAttackingTeam() == TEAM_RED and TEAM_BLUE or TEAM_RED )
end

function GetRoundState()
	return GetGlobalInt("as_round_state", ROUND_WAIT)
end

local function EnableNoclip( ply )
	return game.SinglePlayer()//ply:IsAdmin()
end
hook.Add( "PlayerNoClip", "EnableNoclip", EnableNoclip )

local function EnableFlashlight( ply )
	return true//ply:IsAdmin()
end
hook.Add( "PlayerSwitchFlashlight", "EnableFlashlight", EnableFlashlight )


--[[
local function ConfigureMapSettings() 
	local global = ents.FindByClass( "as_global" )[1]
	if !global return end
end
hook.Add( "InitPostEntity", "AS_Configure_Settings", ConfigureMapSettings )
--]]