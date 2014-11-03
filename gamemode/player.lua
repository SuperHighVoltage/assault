
--player_manager.AddValidHands( "police",		"models/weapons/c_arms_hev.mdl",		0,		"0000000" )
--player_manager.AddValidHands( "policefem",		"models/weapons/c_arms_hev.mdl",		0,		"0000000" )
player_manager.AddValidHands( "hostage01",		"models/weapons/c_arms_refugee.mdl",		1,		"0100000" )
player_manager.AddValidHands( "hostage02",		"models/weapons/c_arms_refugee.mdl",		0,		"0100000" )
player_manager.AddValidHands( "hostage03",		"models/weapons/c_arms_refugee.mdl",		1,		"0100000" )
player_manager.AddValidHands( "hostage04",		"models/weapons/c_arms_refugee.mdl",		0,		"0100000" )

function CheckWaitingPlayers()
	local numready = 0
	-- only count truly available players, ie. no forced specs
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and ply:ReadyToSpawn() then
			numready = numready + 1
		end
	end
	return numready
end 

function SpawnReadyPlayers()
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and ply:ReadyToSpawn() then
			ply:Spawn()
		end
	end
end 

function EveryoneSpectateEntity(ent)
	local fakeent = ents.Create( "prop_physics" )
	fakeent:SetModel( "models/hunter/misc/sphere025x025.mdl" )
	fakeent:SetPos( ent:GetPos() )
	fakeent:SetRenderMode(RENDERMODE_TRANSALPHA)
	fakeent:SetColor(Color( 0, 0, 0, 0 ))
	fakeent:Spawn()
	fakeent:GetPhysicsObject():EnableMotion(false)
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) then
			//ply:Spectate(OBS_MODE_CHASE)
			//ply:SpectateEntity(ent)
			ply:Spectate( OBS_MODE_CHASE )
			ply:SpectateEntity( fakeent )
			ply:StripWeapons()
		end
	end
end 

function TeleportPlayerToSpawnpoint(ply)
	local ent = GAMEMODE:PlayerSelectSpawn( ply )
	ply:SetPos(ent:GetPos())
end

function SendDefendersToNewSpawn()
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and ply:ReadyToSpawn() and ply:IsDefending() then
			TeleportPlayerToSpawnpoint(ply)
		end
	end
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerInitialSpawn( )
   Desc: Called just before the player's first spawn
-----------------------------------------------------------]]
function GM:PlayerInitialSpawn( pl )

	pl:SetTeam( TEAM_UNASSIGNED )
	
//	if ( GAMEMODE.TeamBased ) then
//		pl:ConCommand( "gm_showteam" )
//	end
	local t = team.BestAutoJoinTeam( )
	PrintMessage( HUD_PRINTTALK, pl:Name().." has joined "..team.GetName( t ) )
	MsgC( team.GetColor( t ), pl:Name().." has joined "..team.GetName( t ).."\n" )
	pl:SetTeam( t )

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnPreRound( )
   Desc: Player spawns as a spectator
-----------------------------------------------------------]]
function GM:PlayerSpawnPreRound( pl )

	pl:StripWeapons();
	
	
	if ( pl:Team() == TEAM_UNASSIGNED ) then
	
		pl:Spectate( OBS_MODE_FIXED )
		return
		
	end

	pl:Spectate( OBS_MODE_ROAMING )

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawn( )
   Desc: Called when a player spawns
-----------------------------------------------------------]]
function GM:PlayerSpawn( ply )
	ply:StripWeapons()
	--
	-- If the player doesn't have a team in a TeamBased game
	-- then spawn him as a spectator
	--
	if GetRoundState() == ROUND_WAIT or GetRoundState() == ROUND_STARTING then

		GAMEMODE:PlayerSpawnPreRound( ply )
		return
	
	end

	-- Stop observer mode
	ply:UnSpectate()
	
	-- Model
	local playermodel = table.Random( ply:Team() == GetAttackingTeam() and RebelModels or CombineModels  )	-- If attacking use rebel models else use combine
	if ply:Team() == GetAttackingTeam() then
		playermodel = table.Random( PlayerModels[GetGlobalFloat("as_attackermodels",1)] )	-- default 0
	else
		playermodel = table.Random( PlayerModels[GetGlobalFloat("as_defendermodels",3)] )	-- default 3
	end
	local modelname = player_manager.TranslatePlayerModel( playermodel )
	util.PrecacheModel( modelname )
	ply:SetModel( modelname )
	local col = team.GetColor(ply:Team())
	local veccol = Vector(col.r/255, col.g/255, col.b/255)
	ply:SetPlayerColor( veccol )
	ply:SetWeaponColor( veccol )
	
	-- Hands
	local oldhands = ply:GetHands()
	if ( IsValid( oldhands ) ) then oldhands:Remove() end

	local hands = ents.Create( "gmod_hands" )
	if ( IsValid( hands ) ) then
		ply:SetHands( hands )
		hands:SetOwner( ply )

		-- Which hands should we use?
		local info = player_manager.TranslatePlayerHands( playermodel )
	--	MsgN(playermodel)
	--	PrintTable(info)
		if ( info ) then
			hands:SetModel( info.model )
			hands:SetSkin( info.skin )
			hands:SetBodyGroups( info.body )
		end

		-- Attach them to the viewmodel
		local vm = ply:GetViewModel( 0 )
		hands:AttachToViewmodel( vm )

		vm:DeleteOnRemove( hands )
		ply:DeleteOnRemove( hands )

		hands:Spawn()
 	end
	
	-- Loadout
	ply:RemoveAllAmmo()
	--[[
	if ply:Team() == GetAttackingTeam() then
		ply:GiveAmmo( 100, "Pistol", true )
		ply:Give( "weapon_pistol" )
		ply:Give( "weapon_physcannon" )
	else
		ply:GiveAmmo( 50, "Pistol", true )
		//ply:GiveAmmo( 100,	"AR2", 	true )
		ply:Give( "weapon_pistol" )
		ply:Give( "weapon_ar2" )
	end--]]
	
	
	local loadout = {}
	if ply:Team() == GetAttackingTeam() then
		loadout = PlayerLoadouts[GetGlobalFloat("as_attackerloadout",7)]	-- default 0
	else
		loadout = PlayerLoadouts[GetGlobalFloat("as_defenderloadout",7)]	-- default 3
	end
	for _, wep in pairs( loadout.wep ) do
	--	MsgN("wep ".._.." "..wep)
		ply:Give( wep )
	end
	if loadout.ammo then
		for ammotype, count in pairs( loadout.ammo ) do
			--MsgN("ammo "..ammotype.." "..count)
			ply:GiveAmmo( count, ammotype, true )
		end
	end
//	ply:GiveAmmo( 100, "Pistol", true )
//	ply:GiveAmmo( 100, "Assault rounds", true )
//	ply:Give( "weapon_pistol" )
//	ply:Give( "ut2k4_assault_rifle" )
	ply:SwitchToDefaultWeapon()

	-- Call item loadout function
	hook.Call( "PlayerLoadout", GAMEMODE, ply )
	
	-- Set player model
	hook.Call( "PlayerSetModel", GAMEMODE, ply )
	
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSelectTeamSpawn( player )
   Desc: Find a spawn point entity for this player's team
-----------------------------------------------------------]]
function GM:PlayerSelectTeamSpawn( TeamID, ply )
	local str = "info_player_start"
	if GetAttackingTeam() == TeamID then
		str = "as_spawnattack"
	else
		str = "as_spawndefend"
	end
	local SpawnPoints = ents.FindByClass( str )
	
	local Count = table.Count( SpawnPoints )
	
	if ( Count == 0 ) then
		Msg("[PlayerSelectSpawn] Error! No assault spawn points!\n")
		return nil
	end

	local ChosenSpawnPoint = nil

	-- Try to work out the best, random spawnpoint
	for i=0, Count do
	
		ChosenSpawnPoint = table.Random( SpawnPoints )
		if ( ChosenSpawnPoint &&
			ChosenSpawnPoint:IsValid() &&
			ChosenSpawnPoint:IsInWorld() &&
			ChosenSpawnPoint.Enabled &&
			ChosenSpawnPoint != ply:GetVar( "LastSpawnpoint" ) &&
			ChosenSpawnPoint !=self.LastSpawnPoint ) then
			
			if ( hook.Call( "IsSpawnpointSuitable", GAMEMODE, ply, ChosenSpawnPoint, i == Count ) ) then
			
				self.LastSpawnPoint = ChosenSpawnPoint
				ply:SetVar( "LastSpawnpoint", ChosenSpawnPoint )

				return ChosenSpawnPoint
			
			end
			
		end
			
	end

	return ChosenSpawnPoint
	
	
end


--[[---------------------------------------------------------
   Name: gamemode:PlayerSelectSpawn( player )
   Desc: Find a spawn point entity for this player
-----------------------------------------------------------]]
function GM:IsSpawnpointSuitable( pl, spawnpointent, bMakeSuitable )

	local Pos = spawnpointent:GetPos()
	
	-- Note that we're searching the default hull size here for a player in the way of our spawning.
	-- This seems pretty rough, seeing as our player's hull could be different.. but it should do the job
	-- (HL2DM kills everything within a 128 unit radius)
	local Ents = ents.FindInBox( Pos + Vector( -16, -16, 0 ), Pos + Vector( 16, 16, 64 ) )
	
	if ( pl:Team() == TEAM_SPECTATOR ) then return true end
	
	local Blockers = 0
	
	for k, v in pairs( Ents ) do
		if ( IsValid( v ) && v:GetClass() == "player" && v:Alive() ) then
		
			Blockers = Blockers + 1
			
			if ( bMakeSuitable ) then
				v:Kill()
			end
			
		end
	end
	
	if ( bMakeSuitable ) then return true end
	if ( Blockers > 0 ) then return false end
	return true

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSelectSpawn( player )
   Desc: Find a spawn point entity for this player
-----------------------------------------------------------]]
function GM:PlayerSelectSpawn( pl )

	if ( GAMEMODE.TeamBased ) then
	
		local ent = GAMEMODE:PlayerSelectTeamSpawn( pl:Team(), pl )
		if ( IsValid(ent) ) then return ent end
	
	end

	-- Save information about all of the spawn points
	-- in a team based game you'd split up the spawns
	if ( !IsTableOfEntitiesValid( self.SpawnPoints ) ) then
	
		self.LastSpawnPoint = 0
		self.SpawnPoints = ents.FindByClass( "info_player_start" )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_deathmatch" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_combine" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_rebel" ) )
		
		-- CS Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_counterterrorist" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_terrorist" ) )
		
		-- DOD Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_axis" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_allies" ) )

		-- (Old) GMod Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "gmod_player_start" ) )
		
		-- TF Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_teamspawn" ) )
		
		-- INS Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "ins_spawnpoint" ) )  

		-- AOC Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "aoc_spawnpoint" ) )

		-- Dystopia Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "dys_spawn_point" ) )

		-- PVKII Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_pirate" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_viking" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_knight" ) )

		-- DIPRIP Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "diprip_start_team_blue" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "diprip_start_team_red" ) )
 
		-- OB Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_red" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_blue" ) )        
 
		-- SYN Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_coop" ) )
 
		-- ZPS Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_human" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_zombie" ) )      
 
		-- ZM Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_deathmatch" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_zombiemaster" ) )  		

	end
	
	local Count = table.Count( self.SpawnPoints )
	
	if ( Count == 0 ) then
		Msg("[PlayerSelectSpawn] Error! No spawn points!\n")
		return nil
	end
	
	-- If any of the spawnpoints have a MASTER flag then only use that one.
	-- This is needed for single player maps.
	for k, v in pairs( self.SpawnPoints ) do
		
		if ( v:HasSpawnFlags( 1 ) ) then
			return v
		end
		
	end
	
	local ChosenSpawnPoint = nil
	
	-- Try to work out the best, random spawnpoint
	for i=0, Count do
	
		ChosenSpawnPoint = table.Random( self.SpawnPoints )

		if ( ChosenSpawnPoint &&
			ChosenSpawnPoint:IsValid() &&
			ChosenSpawnPoint:IsInWorld() &&
			ChosenSpawnPoint != pl:GetVar( "LastSpawnpoint" ) &&
			ChosenSpawnPoint != self.LastSpawnPoint ) then
			
			if ( hook.Call( "IsSpawnpointSuitable", GAMEMODE, pl, ChosenSpawnPoint, i == Count ) ) then
			
				self.LastSpawnPoint = ChosenSpawnPoint
				pl:SetVar( "LastSpawnpoint", ChosenSpawnPoint )

				return ChosenSpawnPoint
			
			end
			
		end
			
	end

	return ChosenSpawnPoint
	
end