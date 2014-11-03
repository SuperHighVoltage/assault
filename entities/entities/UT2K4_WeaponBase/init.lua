
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()
	if self.modelname then
		self:SetModel( self.modelname )
	else
		self:SetModel( "models/HighVoltage/UT2K4/PickUps/weapon_base.mdl" )
	end

//	self:SetNWInt("weapon", math.random(0,2))	//if no weapon is selected pick one at randomz
	
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	self:DrawShadow( false )
	
	-- Note that we need a physics object to make it call triggers
//	self:SetCollisionBounds( Vector( -16, -16, 0 ), Vector( 16, 16, 40 ) )
//	self:PhysicsInitBox( Vector( -16, -16, 0 ), Vector( 16, 16, 40 ) )
	
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:EnableCollisions( false )		
	end
	
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )
//	self:SetTrigger( true )
//	self:SetNotSolid( true )
	
//key value crap	
//	if self.angle then
//		self:SetAngles(self.angle)
//	end
	self.Delay = self.Delay or 30
	self.effect_col = self.effect_col or Color(255,170,0)
//effect	
--[[	local f = function()
		local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		util.Effect( "ut2k4_weaponspawn", effectdata )
	end
	timer.Simple( 4, f )--]]--	
	self.EffectSpawned = false
	self:SpawnWeapon()
end

function ENT:SpawnWeapon()
	local Weapons = {	"ut2k4_lightning_gun", 
						"ut2k4_rocket_launcher", 
						"ut2k4_flak_cannon", 
						"ut2k4_assault_rifle", 
						"ut2k4_bio_rifle", 
						"ut2k4_mine_layer", 
						"ut2k4_minigun", 
						"ut2k4_shock_rifle", 
						"ut2k4_classic_sniper", 
						"ut2k4_grenade_launcher", 
						"weapon_crossbow", 
						"weapon_slam", 
						"weapon_shotgun",
						"weapon_pistol" }	
//	self.weapClass = table.Random(Weapons)
	self.Weapon = ents.Create(self.weapClass)
	self.Weapon:SetPos(Vector( 0, 0, 32 )+self:GetPos())
	self.Weapon:SetAngles(Angle(0,0,0))
	self.Weapon:Spawn()
	self.Weapon.FromWeaponBase = true
	self.Weapon:SetCustomCollisionCheck( true )
	self.Weapon:SetCollisionGroup( COLLISION_GROUP_NONE )
	self.RespawnTime = nil
	local phys = self.Weapon:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:EnableMotion( false )		
	end
	self:SetEnt(self.Weapon)
	local col = self.effect_col
	local effectdata = EffectData()
	effectdata:SetOrigin( self:GetPos()+Vector( 0, 0, 32 ))
	effectdata:SetStart(Vector(col.r,col.g,col.b))
	util.Effect( "ut2k4_itemrespawn", effectdata )
	//self:FireOutput("ItemSpawned")	//will eventually trigger map outputs
	self:TriggerOutput("OnItemSpawned", self)
end

local vAngle = Vector( 0, 0, 1 )
function ENT:Think()
	if !self.EffectSpawned and CurTime() > 4 then
		local col = self.effect_col
		local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetStart(Vector(col.r,col.g,col.b))
		util.Effect( "ut2k4_weaponspawn", effectdata )
		self.EffectSpawned = true
	end
	if !self.RespawnTime then
		//self:FireOutput("OnPickUp")	//will eventually trigger map outputs
		//MsgN("RespawnTime is nil "..CurTime())
	end
	
	if !IsValid(self.Weapon) or !IsEntity(self.Weapon) then
		if !self.RespawnTime then
			self.RespawnTime = CurTime()+self.Delay
			self:TriggerOutput("OnPickUp", self)
		elseif self.RespawnTime and self.RespawnTime < CurTime() then		//If the weapon doesn't exist
			self:SpawnWeapon()
		end
	elseif IsValid(self.Weapon) and IsEntity(self.Weapon) and self.Weapon.Owner != NULL then
		if !self.RespawnTime then
			self.RespawnTime = CurTime()+self.Delay
			self:TriggerOutput("OnPickUp", self)
		elseif self.RespawnTime and self.RespawnTime < CurTime() then		//If the weapon doesn't exist
			self:SpawnWeapon()
		end
	elseif IsValid(self.Weapon) and self.Weapon.Owner == NULL then
		local phys = self.Weapon:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:EnableMotion( false )		
		end
		local UpAngle = Angle( 0, 0, 0 )
		UpAngle:RotateAroundAxis(vAngle:Angle():Forward(), RealTime()*120)
		self.Weapon:SetAngles(UpAngle)
	else
		MsgN("[UT2K4_WeaponBase: Weapon isn't valid? (".. tostring(IsValid(self.Weapon)) ..")] This shouldn't be here, contact HighVoltage so he can fix it")
	end

end

function ENT:KeyValue( key, value )
//MsgN(tostring(self).." Key: "..key..", Value: "..value)
	if ( string.Left( key, 2 ) == "On" ) then
		self:StoreOutput( key, value )
	end

if ( key == "angles" ) then
		local Sep = string.Explode(" ", value)
		local ang = (Angle(Sep[1], Sep[2], Sep[3]))
		self.angle = ang
	end	
	
	if ( key == "weapon_class" ) then
		self.weapClass = value
	end
	
	if ( key == "effect_col" ) then
//		print("effect_col: ".. value)
		local Sep = string.Explode(" ", value)
//		PrintTable(Sep)
		local col = (Color(Sep[1], Sep[2], Sep[3]))
//		print("col: "..tostring(col))
		self.effect_col = col
	end
	
	if ( key == "model" ) then
		self.modelname = value
	end
	
	if ( key == "spawn_delay" ) then
		self.Delay = value
	end
end

function ENT:AcceptInput( inputName, activator, called, data )
	if ( inputName == "ForceSpawn" ) then
		if !IsValid(self.Weapon) or !IsEntity(self.Weapon) then
			self:SpawnWeapon()
		elseif IsValid(self.Weapon) and IsEntity(self.Weapon) and self.Weapon.Owner != NULL then
			self:SpawnWeapon()
		elseif IsValid(self.Weapon) and self.Weapon.Owner == NULL then
			MsgN("Can't spawn weapon when one already exists")
		else
			MsgN("Why am I being called?")
		end
	end	
	if ( inputName == "ChangeDelay" ) then
		self.RespawnTime = self.RespawnTime-self.Delay	//undo the delay time
		self.Delay = data								//set the new delay
		self.RespawnTime = CurTime()+self.Delay			//apply the new delay
	end	
end
					
function ENT:SpawnFunction( ply, tr )
	local Weapons = {	"ut2k4_lightning_gun", 
						"ut2k4_rocket_launcher", 
						"ut2k4_flak_cannon", 
						"ut2k4_assault_rifle", 
						"ut2k4_bio_rifle", 
						"ut2k4_mine_layer", 
						"ut2k4_minigun", 
						"ut2k4_shock_rifle", 
						"ut2k4_classic_sniper", 
						"ut2k4_grenade_launcher", 
						"weapon_crossbow", 
						"weapon_slam", 
						"weapon_shotgun",
						"weapon_pistol" }
	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 40
//	local SpawnPos = tr.HitPos.z + 10
	local ent = ents.Create( "ut2k4_weaponbase" )
	ent:SetPos( SpawnPos )
	ent.weapClass = table.Random(Weapons)
	ent:Spawn()
	ent:Activate()
	
	return ent
	
end

function ENT:OnRemove()
	if IsValid(self.Weapon) and self.Weapon.Owner == NULL then
		self.Weapon:Remove()
	end
end

hook.Add("PlayerCanPickupWeapon", "DontPickupWeaponsYouAlreadyHaveFromWeaponBases", function( ply, wep )
//	if (wep.FromWeaponBase and ply:HasWeapon(wep:GetClass())) then
//		return false
//	end
//	return true
	return !(wep.FromWeaponBase and ply:HasWeapon(wep:GetClass()))
end)

--[[

hook.Add("EntityTakeDamage", "DamageEffect", function( ent, dmginfo )
	local effectType = nil
	if dmginfo:IsDamageType(DMG_SHOCK) then
		effectType = DMG_SHOCK
	elseif dmginfo:IsDamageType(DMG_PLASMA) then
		effectType = DMG_PLASMA
	elseif dmginfo:IsDamageType(DMG_ENERGYBEAM) then
		effectType = DMG_ENERGYBEAM
	elseif dmginfo:IsDamageType(DMG_BULLET) then
		effectType = DMG_BULLET
	elseif dmginfo:IsDamageType(DMG_BUCKSHOT) then
		effectType = DMG_BUCKSHOT
	elseif dmginfo:IsDamageType(DMG_BLAST) then
		effectType = DMG_BLAST
	elseif dmginfo:IsDamageType(DMG_RADIATION) then
		effectType = DMG_RADIATION
	end
	if effectType then
		local fx = EffectData()
		fx:SetEntity(ent)
		fx:SetDamageType(effectType)
		fx:SetMagnitude(1)
		util.Effect("ut2k4_overlay", fx, true) 
	end
end)
--]]
