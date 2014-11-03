AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "player_ext.lua" )
AddCSLuaFile( "player.lua" )
AddCSLuaFile( "objectives.lua" )

include( "shared.lua" )
include( "player_ext.lua" )
include( "player.lua" )
include( "objectives.lua" )
include( "vehicles.lua" )

//CreateConVar("as_round_time", "10", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED)
CreateConVar("as_round_time_override", "10", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED)
CreateConVar("as_wait_time", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED)
CreateConVar("as_required_players", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED)

DEFINE_BASECLASS( "gamemode_base" )

function GM:Initialize()
	MsgN("Initialize gamemode")
	SetGlobalFloat("as_round_time", GetConVar("as_round_time_override"):GetInt())
	SetAttackingTeam( TEAM_RED )
	StartRound(ROUND_WAIT)
end 

function StartRound(state)
	SetGlobalInt("as_round_state", state)
	local endtime = -1
	if state == ROUND_WAIT then
		endtime = CurTime() + GetConVar("as_wait_time"):GetInt() --* 60
		PrintMessage( HUD_PRINTTALK, "Waiting to start round for "..(GetConVar("as_wait_time"):GetInt() * 60).." seconds." )
		MsgN( "Waiting to start round for "..(GetConVar("as_wait_time"):GetInt() * 60).." seconds." )
		//chat.AddText( Color( 100, 100, 255 ), "Waiting to start round for ", Color( 255, 100, 100 ), GetConVar("as_wait_time"):GetInt() * 60, Color( 100, 100, 255 ), " seconds." )
	elseif state == ROUND_STARTING then
		-- start round count down
		endtime = CurTime() + 10
		PrintMessage( HUD_PRINTTALK, "Round starting in 5 seconds." )
		MsgN( "Round starting in 10 seconds." )
		//chat.AddText( Color( 100, 100, 255 ), "Round starting in 5 seconds." )
	elseif state == ROUND_ACTIVE then
		-- round length should be the time it took to do the last round or the default time
		endtime = CurTime() + GetGlobalFloat("as_last_round_time", GetGlobalFloat("as_round_time",10) * 60)
		BeginRound()
		PrintMessage( HUD_PRINTTALK, team.GetName( GetAttackingTeam() ).." is now attacking." )
		MsgN( team.GetName( GetAttackingTeam() ).." is now attacking." )
		//chat.AddText( team.GetColor( GetAttackingTeam() ), team.GetName( GetAttackingTeam() ), Color( 100, 100, 255 ), " is now attacking." )
	end
	SetGlobalFloat("as_round_end", endtime)
	StartRoundChecks()
end 

local function RoundCheck()
	if GetRoundState() == ROUND_WAIT then
	
		if CheckWaitingPlayers() >= GetConVar("as_required_players"):GetInt() then
			//StartRound(ROUND_STARTING)
		end
		if CurTime() > GetGlobalFloat("as_round_end", 0) then
			SetGlobalFloat("as_round_end", CurTime() + GetConVar("as_wait_time"):GetInt() * 60)
			StartRound(ROUND_STARTING)
		end
		
	elseif GetRoundState() == ROUND_STARTING then
	
		if CurTime() > GetGlobalFloat("as_round_end", 0) then
			StartRound(ROUND_ACTIVE)
		end
		
	elseif GetRoundState() == ROUND_ACTIVE then
	
		if CurTime() > GetGlobalFloat("as_round_end", 0) then
			-- end round
			hook.Call("CompleteRound", GAMEMODE, COMPLETE_TIME)
		else
			-- check for objectives being complete?
		end
		
	end
end

function StartRoundChecks()
   if not timer.Start("RoundChecker") then
      //timer.Create("RoundChecker", 1, 0, RoundCheck)
   end
end

-- Called when the actual round starts
-- Spawn players and ready objectives
function BeginRound()
	MsgN("Beginning round")
	
	if GetGlobalFloat("as_number_of_rounds", 0 ) != 0 then
		SwitchAttackingTeam()
	end
	
//	AS.ResetObjectives()	-- Just incase we didn't do this before
	game.CleanUpMap()
	AS.InitObjectives()
	SpawnReadyPlayers()
	
	local ent = ents.FindByClass( "as_global" )
	for k,v in pairs( ent ) do
		v:TriggerOutput("OnRoundStart", ent)
	end
end
	
function GM:CompleteRound(condition,ply)	-- condition is how the round ended and player is the player that completed the last objective

	if condition == COMPLETE_TIME then
		EveryoneSpectateEntity(AS.GetCurObjectives(true)[1])
	else
		
	end
	
	local ent = ents.FindByClass( "as_global" )
	for k,v in pairs( ent ) do
		v:TriggerOutput("OnRoundComplete", ply)
	end
	
	MsgN("Completed round")
	local time = CurTime() - (GetGlobalFloat("as_round_end", 0) - GetGlobalFloat("as_last_round_time", GetGlobalFloat("as_round_time",10) * 60) )
	MsgN("Round was completed in "..time.." seconds")
	MsgN("Or "..string.FormattedTime( math.max(0, time), "%02i:%02i") )
	
	SetGlobalFloat("as_number_of_rounds", GetGlobalFloat("as_number_of_rounds", 0) + 1)
	SetGlobalFloat("as_last_round_time", time )
	
//	AS.ResetObjectives()
	StartRound(ROUND_STARTING)
end






local function RoundThink()
	if GetRoundState() == ROUND_WAIT then
	
		if CheckWaitingPlayers() >= GetConVar("as_required_players"):GetInt() then
			//StartRound(ROUND_STARTING)
		end
		if CurTime() > GetGlobalFloat("as_round_end", 0) then
		
			SetGlobalFloat("as_round_end", CurTime() + GetConVar("as_wait_time"):GetInt() * 60)
			StartRound(ROUND_STARTING)
			
		end
		
	elseif GetRoundState() == ROUND_STARTING then
	
		if CurTime() > GetGlobalFloat("as_round_end", 0) then
		
			StartRound(ROUND_ACTIVE)
			
		end
		
	elseif GetRoundState() == ROUND_ACTIVE then
	
		if CurTime() > GetGlobalFloat("as_round_end", 0) then
		
			hook.Call("CompleteRound", GAMEMODE, COMPLETE_TIME)
			
		end
		
	end
end
hook.Add( "Think", "AS_RoundThink", RoundThink )




--[[
local GamemodeList = engine.GetGamemodes()
local MapPatterns = {}

for k, gm in pairs( GamemodeList ) do
	local Name			= gm.name or "sandbox"
	local Maps			= string.Split( gm.maps, "|" )

	if ( Maps && gm.maps != "" ) then
		for k, pattern in pairs( Maps ) do
			MapPatterns[ pattern ] = Name
		end
	end
end

function ChangeMap(map)
	local Gamemode = "sandbox"
	local name = string.gsub( map, ".bsp", "" )
	local lowername = string.lower( map )

	for pattern, Game in pairs( MapPatterns ) do
		if ( ( string.StartWith( pattern, "^" ) || string.EndsWith( pattern, "_" ) || string.EndsWith( pattern, "-" ) ) && string.find( lowername, pattern ) ) then
			Gamemode = Game
		end
	end
	RunConsoleCommand( "gamemode", Gamemode ); 
	RunConsoleCommand( "changelevel", map) 
end--]]