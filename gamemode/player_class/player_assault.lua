
AddCSLuaFile()
DEFINE_BASECLASS( "player_default" )

local PLAYER = {}


PLAYER.DuckSpeed			= 0.1		-- How fast to go from not ducking, to ducking
PLAYER.UnDuckSpeed			= 0.1		-- How fast to go from ducking, to not ducking

--
-- Creates a Taunt Camera
--
PLAYER.TauntCam = TauntCamera()

--
-- See gamemodes/base/player_class/player_default.lua for all overridable variables
--
PLAYER.WalkSpeed 			= 200
PLAYER.RunSpeed				= 400

--
-- Set up the network table accessors
--
function PLAYER:SetupDataTables()

	BaseClass.SetupDataTables( self )

end


function PLAYER:Loadout()

	self.Player:RemoveAllAmmo()
	
	self.Player:GiveAmmo( 100, "Pistol", true )
	self.Player:GiveAmmo( 100, "Assault rounds", true )
	
	self.Player:Give( "weapon_pistol" )
	self.Player:Give( "ut2k4_assault_rifle" )

	self.Player:SwitchToDefaultWeapon()

end

PLAYER.AttackerModels = {}
for i = 7, 12 do
	table.insert( PLAYER.AttackerModels, "female"..(i<10 and "0"..i or i ) )
end
for i = 10, 18 do
	table.insert( PLAYER.AttackerModels, "male"..i )
end
PLAYER.DefenderModels = { "combine", "combineprison", "combineelite", "police", "policefem" }

function PLAYER:SetModel()

	local playermodel = table.Random( PLAYER.AttackerModels )
	local modelname = player_manager.TranslatePlayerModel( playermodel )
	util.PrecacheModel( modelname )
	self.Player:SetModel( modelname )

end

--
-- Called when the player spawns
--
function PLAYER:Spawn()

	BaseClass.Spawn( self )

	self.Player:SetPlayerColor( Vector( 1,0,0 ) )

	self.Player:SetWeaponColor( Vector( 1,0,0 ) )

end

--
-- Return true to draw local (thirdperson) camera - false to prevent - nothing to use default behaviour
--
function PLAYER:ShouldDrawLocal() 

	if ( self.TauntCam:ShouldDrawLocalPlayer( self.Player, self.Player:IsPlayingTaunt() ) ) then return true end

end

--
-- Allow player class to create move
--
function PLAYER:CreateMove( cmd )

	if ( self.TauntCam:CreateMove( cmd, self.Player, self.Player:IsPlayingTaunt() ) ) then return true end

end

--
-- Allow changing the player's view
--
function PLAYER:CalcView( view )

	if ( self.TauntCam:CalcView( view, self.Player, self.Player:IsPlayingTaunt() ) ) then return true end

	-- Your stuff here

end

player_manager.RegisterClass( "player_assault", PLAYER, "player_default" )
