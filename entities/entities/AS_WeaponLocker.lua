
AddCSLuaFile()
DEFINE_BASECLASS( "base_anim" )

if SERVER then util.AddNetworkString("LockerPickupEvent") end

ENT.PrintName		= "Weapon Locker"
ENT.Author			= "HighVoltage + Zak"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category		= "UT2K4"

ENT.Spawnable		= true
ENT.AdminOnly		= false
ENT.Editable		= true
 
ENT.models = {}
ENT.models.top = {Model = "models/props_junk/sawblade001a.mdl", Pos = Vector(0,0,45), Ang = Angle(0,0,0)}
ENT.models.mid = {Model = "models/props_c17/canister01a.mdl", Pos = Vector(0,0,30), Ang = Angle(0,0,0)}
ENT.models.bot = {Model = "models/props_vehicles/carparts_wheel01a.mdl", Pos = Vector(0,0,5), Ang = Angle(0,0,90)}

--Use this model if a weapon model entry doesn't exist
ENT.defaultWeaponModel 		= 	{ Model = "models/weapons/w_pistol.mdl" }

--Info about hl2 weapons, [optional] can include metadata about how to position the weapon
ENT.weaponInfos = {
	["weapon_357"]			= 	{ Model = "models/weapons/w_357.mdl",				PrimaryAmmoType = "357",		PrimaryAmmoAmount = 6 },
	["weapon_ar2"]			= 	{ Model = "models/weapons/w_irifle.mdl",			PrimaryAmmoType = "AR2",		PrimaryAmmoAmount = 30 },
	["weapon_crossbow"]		= 	{ Model = "models/weapons/w_crossbow.mdl",			PrimaryAmmoType = "XBowBolt",	PrimaryAmmoAmount = 6 },
	["weapon_crowbar"]		= 	{ Model = "models/weapons/w_crowbar.mdl",			PrimaryAmmoType = nil,			PrimaryAmmoAmount = 0 },
	["weapon_frag"]			= 	{ Model = "models/weapons/w_grenade.mdl",			PrimaryAmmoType = "Grenade",	PrimaryAmmoAmount = 3 },
	["weapon_pistol"]		= 	{ Model = "models/weapons/w_pistol.mdl",			PrimaryAmmoType = "Pistol",		PrimaryAmmoAmount = 25 },
	["weapon_rpg"]			= 	{ Model = "models/weapons/w_rocket_launcher.mdl",	PrimaryAmmoType = "RPG_Round",	PrimaryAmmoAmount = 3 },
	["weapon_slam"]			= 	{ Model = "models/weapons/w_slam.mdl",				PrimaryAmmoType = "slam",		PrimaryAmmoAmount = 4 },
	["weapon_shotgun"]		= 	{ Model = "models/weapons/w_shotgun.mdl",			PrimaryAmmoType = "Buckshot",	PrimaryAmmoAmount = 6 },
	["weapon_smg1"]			= 	{ Model = "models/weapons/w_smg1.mdl",				PrimaryAmmoType = "SMG1",		PrimaryAmmoAmount = 30 },
	["weapon_stunstick"]	=	{ Model = "models/weapons/w_stunbaton.mdl",			PrimaryAmmoType = nil,			PrimaryAmmoAmount = 0, },
}

function ENT:MakeDecoProp( modelEntry )

	local prop = ents.Create( "prop_physics" )
	prop:SetModel( modelEntry.Model )
	prop:SetPos( self:LocalToWorld( modelEntry.Pos ) )
	prop:SetAngles( self:LocalToWorldAngles( modelEntry.Ang ) )
	prop:SetParent( self )
	prop:Spawn()
	prop:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )

	modelEntry.Entity = prop

end

function ENT:InitDecorations()

	--Create decoration props
	for k,v in pairs(self.models) do self:MakeDecoProp( v ) end

end

function ENT:SetupDataTables()

	self:NetworkVar( "Bool",	0, "Enabled" )
	self:NetworkVar( "String",	0, "WeaponString" )
	self:NetworkVar( "Float",	0, "LastPickup" )

	self:SetEnabled( true )
	self:SetLastPickup( 0 )

end

function ENT:Initialize()

	self:SetModel( "models/props_c17/oildrum001.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

	if SERVER then
		self:SetTrigger( true )
	end
	
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	if self:HasSpawnFlags(1) then
		self:SetMoveType( MOVETYPE_NONE )
	end	

	if SERVER then self:InitDecorations() end
	if self.kv_weapons then self:SetWeapons(self.kv_weapons) end

end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 10
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 0
	SpawnAng.y = SpawnAng.y + 180
	
	--local weps = {"ut2k4_lightning_gun", "ut2k4_shock_rifle", "ut2k4_bio_rifle", "ut2k4_minigun", "ut2k4_flak_cannon", "ut2k4_rocket_launcher", "ut2k4_assault_rifle", "ut2k4_grenade_launcher", "ut2k4_mine_layer", "ut2k4_classic_sniper"}
	local weps = {"weapon_357", "weapon_ar2", "weapon_crossbow", "weapon_crowbar", "weapon_frag", "weapon_pistol", "weapon_rpg", "weapon_slam", "weapon_shotgun", "weapon_smg1"}

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
	ent:Spawn()
	ent:Activate()

	ent:SetWeapons( weps )
	
	return ent
end

function ENT:SetWeapons(weps)

	self:SetWeaponString( table.concat( weps, "," ) )

end

function ENT:GetWeaponInfo(class)

	local info = self.weaponInfos[class]

	if not info then
		local swep = weapons.Get(class)
		if swep then

			if swep.WeaponInfo then

				info = swep.WeaponInfo

			elseif swep.WorldModel then

				info = {
					Model = Model( swep.WorldModel ), 
					PrimaryAmmoType = swep.Primary.Ammo, 
					PrimaryAmmoAmount = swep.Primary.DefaultAmmoAmmount
				}

			end

		end
	end

	if not info then

		print("Weapon info not found for class: '" .. class .. "'' using default.")
		info = self.defaultWeaponModel

	end

	info.LocalPos = info.LocalPos or Vector(0,0,0)
	info.LocalAng = info.LocalAng or Angle(0,0,0)

	return info
end


function ENT:HideWeapons( hide )

	if SERVER or not self.weapon_props then return end

	for _,prop in pairs(self.weapon_props) do

		prop:SetRenderMode( hide and RENDERMODE_TRANSADD or RENDERMODE_NORMAL )
		prop:SetColor( Color(255,255,255,0) )

	end

end

function ENT:GetWeaponList()

	local weapon_string = self:GetWeaponString()
	local weapon_list = string.Explode( ",", weapon_string )

	return weapon_list

end

function ENT:SpawnWeapons()

	if SERVER then return end

	self:CleanupWeapons()

	local weapon_list = self:GetWeaponList()
	local num_weapons = #weapon_list
	local ang = 360/num_weapons
	local startvec = Vector(-10,10,35)

	self.weapon_props = {}

	for i=1, num_weapons do

		local weapon_class = weapon_list[i]
		local weapon_info = self:GetWeaponInfo( weapon_class )
		local weapon_model = weapon_info.Model
		local weapon_prop = ClientsideModel( Model(weapon_model), RENDERGROUP_OPAQUE )

		startvec:Rotate( Angle( 0,ang,0 ) )

		weapon_prop:SetPos( self:LocalToWorld( startvec ) + weapon_info.LocalPos )
		weapon_prop:SetAngles( self:LocalToWorldAngles( Angle(-90,ang * i,0) ) + weapon_info.LocalAng )
		weapon_prop:SetParent( self )

		table.insert( self.weapon_props, weapon_prop )

	end

end

function ENT:CleanupWeapons()

	if SERVER or not self.weapon_props then return end

	for k,v in pairs( self.weapon_props ) do
		v:Remove()
	end

	self.weapon_props = {}

end

function ENT:SendLockerPickupEvent( pl )
	-- send to all matching lockers?
	net.Start("LockerPickupEvent")
	net.WriteEntity( self )
	net.WriteFloat( self:GetSpawnDelay() )
	net.Send( pl )

end

function ENT:PlayerCanPickup( pl )

	if not pl:IsValid() or not pl:IsPlayer() then return false end
	self.PlayerPickups = self.PlayerPickups or {}
	self.PlayerPickups[pl] = self.PlayerPickups[pl] or 0

	if CurTime() - self.PlayerPickups[pl] < self:GetSpawnDelay() then
		return false
	end

	self.PlayerPickups[pl] = CurTime()

	return true

end

function ENT:DoPickup( pl )

	self:SetLastPickup( CurTime() )

	for _, weapon in pairs( self:GetWeaponList() ) do
		if pl:HasWeapon(weapon) then

			local info = self:GetWeaponInfo(weapon)
			if info and info.PrimaryAmmoType then
				pl:GiveAmmo( info.PrimaryAmmoAmount or 1, info.PrimaryAmmoType )
			end

		else
			pl:Give(weapon)
		end		
	end

	self:EmitSound( "assault/weaponlockerpickup.wav" )
	self:TriggerOutput("OnPickup", self)
	self:SendLockerPickupEvent( pl )

end

function ENT:StartTouch( entity )
	
	if CLIENT or not self:GetEnabled() then return end

	if self:PlayerCanPickup( entity ) then

		self:DoPickup( entity )

	end

end

function ENT:GetSpawnDelay()

	if self.spawn_delay then self.spawn_delay = tonumber(self.spawn_delay) end

	return self.spawn_delay or 5

end

function ENT:KeyValue( key, value )

	if string.Left( key, 2 ) == "On" then self:StoreOutput( key, value ) end
	if string.Left( key, 6 ) == "Weapon" and value != "" then

		self.kv_weapons = self.kv_weapons or {}
		table.insert(self.kv_weapons, value)

	end
	if key == "enabled" then self:SetEnabled(value) end	
	if key == "spawn_delay" then self.spawn_delay = tonumber(value) end
	if key == "angles" then

		local Sep = string.Explode(" ", value)
		local ang = Angle(Sep[1], Sep[2], Sep[3])
		self.angle = ang

	end

end

function ENT:AcceptInput( inputName, activator, called, data )

	if ( inputName == "TurnOn" ) then self:SetEnabled( true ) end
	if ( inputName == "TurnOff" ) then self:SetEnabled( false ) end

end

function ENT:GetBeaconColor()

	self.RespawnTime = self.RespawnTime or 0

	if !self:GetEnabled() then
		return Color(255,0,0)
	elseif self.RespawnTime > CurTime() then
		return Color(0,100,255)
	else
		return Color(50,255,80)
	end

end

ENT.SpriteMat = Material("effects/blueflare1.vmt")

function ENT:Draw()

	render.SetMaterial( self.SpriteMat )
	render.DrawSprite( 
		self:GetPos() + self:GetUp() * 60, 
		64 + math.sin(CurTime() * 4) * 5, 
		64 + math.sin(CurTime() * 4) * 5, 
		self:GetBeaconColor() 
	)

end

function ENT:Think()

	if CLIENT then
	
		local cl_weapons = self:GetWeaponString()
		if cl_weapons ~= self.RealWeaponList then
			self.RealWeaponList = cl_weapons
			self:SpawnWeapons()
		end

	end

end

function ENT:OnRespawn()

	self:HideWeapons(false)

end

function ENT:OnLocalPickup( spawnDelay )

	self.RespawnTime = CurTime() + spawnDelay

	self:HideWeapons(true)

	timer.Simple( spawnDelay, function() 

		if IsValid(self) then self:OnRespawn() end

	end )

end

function ENT:OnRemove()

	self:CleanupWeapons()

end

--NETWORKING STUFF

if CLIENT then

	net.Receive( "LockerPickupEvent", function(len)

		local locker = net.ReadEntity()
		local spawnDelay = net.ReadFloat()

		if IsValid(locker) then
			locker:OnLocalPickup( spawnDelay )
		end

	end )

end