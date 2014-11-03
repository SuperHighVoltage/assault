
AddCSLuaFile()
DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "JumpPad"
ENT.Author			= "HighVoltage"
ENT.Contact			= ""
ENT.Purpose			= "To help you get to that spot you can't reach"
ENT.Instructions	= "Where ever you spawn the jumppad will be the destionation you will be launched to. Right click on the entity in the contex menu to edit its properties"
ENT.Category		= "UT2K4"

ENT.Spawnable			= true
ENT.AdminOnly			= false
ENT.Editable			= true
 
function ENT:Initialize()
	if ( CLIENT ) then return end
	
	self:SetModel( self:GetWorldModel() )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetUseType( ONOFF_USE )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )
	self:SetTrigger( true )
	
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	if !self:CreatedByMap() then
		self:SetTargetPos(self:GetPos())
	end
	if self:HasSpawnFlags(1) then
		self:SetMoveType( MOVETYPE_NONE )
	end
	self:SetEnabled( !self:HasSpawnFlags(2) )
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 10
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 0
	SpawnAng.y = SpawnAng.y + 180
	
	local ent = ents.Create( ClassName )
		ent:SetPos( SpawnPos )
		ent:SetAngles( SpawnAng )
	ent:Spawn()
	ent:Activate()
	
	return ent
	
end

function ENT:SetupDataTables()
	self:NetworkVar( "Float",	0, "HeightAdd", 	{ KeyName = "z_modifier", 	Edit = { type = "Float", min = 0.01, max = 4, order = 1 } }  );
	self:NetworkVar( "Vector",	0, "EffectColor", 	{ KeyName = "effect_col", 	Edit = { type = "VectorColor", 	order = 2 } }  );
	self:NetworkVar( "Bool",	0, "Enabled", 		{ KeyName = "enabled", 		Edit = { type = "Boolean", 		order = 3 } }  );
	self:NetworkVar( "String",	0, "WorldModel", 	{ KeyName = "model"}  );--, 		Edit = { type = "Generic", 		order = 4 } }  );
	self:NetworkVar( "Entity",	0, "TargetEnt", 	{ KeyName = "targetent"}  );--, 	Edit = { type = "Generic", 		order = 5 } }  );
	self:NetworkVar( "String",	1, "TargetName", 	{ KeyName = "target_name", 	Edit = { type = "Generic", 		order = 6 } }  );
	self:NetworkVar( "Vector",	1, "TargetPos", 	{ KeyName = "targetpos", 	Edit = { type = "VectorPos", 	order = 7 } }  );
	
	self:NetworkVar( "String",	2, "TargetType"  );
//	if ( SERVER ) then

		-- call this function when something changes these variables
//		self:NetworkVarNotify( "HeightAdd",		self.OnVariableChanged );
//		self:NetworkVarNotify( "EffectColor",	self.OnVariableChanged );
//		self:NetworkVarNotify( "Enabled",		self.OnVariableChanged );
		self:NetworkVarNotify( "WorldModel",	self.OnModelChanged );
		self:NetworkVarNotify( "TargetEnt",		self.OnTargetChanged );
		self:NetworkVarNotify( "TargetName",	self.OnTargetChanged );
		self:NetworkVarNotify( "TargetPos",		self.OnTargetChanged );

		-- defaults
		self:SetHeightAdd( 1 )
		self:SetEffectColor( Vector(255, 170, 0)/255 )
		self:SetEnabled( true )
		self:SetWorldModel("models/HighVoltage/UT2K4/PickUps/Jump_pad.mdl")
		//self:SetTargetPos(self:GetPos())
//	end
end

function ENT:OnModelChanged(var,old,new)
	if SERVER then
		self:SetModel( self:GetWorldModel() )
		self:PhysicsInit( SOLID_VPHYSICS )
	end
end
function ENT:OnTargetChanged(var,old,new)
//	MsgN('NetworkVar "'..var..'" has been changed to "'..tostring(new)..'" from "'..tostring(old)..'"' )
	self:SetTargetType(type(new))
end

function ENT:Think()
	if ( CLIENT ) then return end
	self.LastEffect = self.LastEffect or 0
	if CurTime() > self.LastEffect then
		self.LastEffect = CurTime() + 0.1
		if !self:GetEnabled() then return end		// Don't do anything if turned off
		local targetpos = self:GetPos()//Vector(0,0,0)
		if self:GetTargetType() == "string" and ents.FindByName(self:GetTargetName())[1] and ents.FindByName(self:GetTargetName())[1]:IsValid() then
			targetpos = ents.FindByName(self:GetTargetName())[1]:GetPos()
		elseif self:GetTargetType() == "Entity" and IsEntity(self:GetTargetEnt()) then
			targetpos = self:GetTargetEnt():GetPos()
		elseif self:GetTargetType() == "Vector" then
			targetpos = self:GetTargetPos()
		else
			//ErrorNoHalt('Your trying to set a "'..self:GetTargetType()..'" as the target, instead of a vector, valid entity, or entity name.\n')
		end
		
		local col = self:GetEffectColor()*255
		debugoverlay.Cross( targetpos, 4, 0.22, Color(col.r,col.g,col.b), true )
		local ang = self:getvel(targetpos, self:GetPos(), self:GetHeightAdd()):Angle()
		local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetStart( col )
		effectdata:SetAngles( ang )
		util.Effect( "ut2k4_jumppadfx2", effectdata )
	end
end
--[[
function ENT:OnTakeDamage(dmginfo)
	self.health = self.health or 50
	self.health = self.health - dmginfo:GetDamage()
	if self.health < 25 and self.health > 0 then
		self:SetEffectColor( self:GetEffectColor()/2 )
	elseif self.health <= 0 then
		self:Remove()
	end
end]]--

//Below function credited to CmdrMatthew
local g = -600 --gravity
function ENT:getvel(pos, pos2, time)	
    local diff = pos - pos2 --subtract the vectors
     
    local velx = diff.x/time -- x velocity
    local vely = diff.y/time -- y velocity
 
    local velz = (diff.z - 0.5*(-GetConVarNumber( "sv_gravity"))*(time^2))/time --  x = x0 + vt + 0.5at^2 conversion
     
    return Vector(velx, vely, velz)
end
/*---------------------------------------------------------
   Name: Touch
---------------------------------------------------------*/
function ENT:StartTouch( entity )
	
	if !self:GetEnabled() then return end		// Don't do anything if turned off
	
	if ( entity:IsValid() ) then//and entity:IsPlayer() ) then

		local targetpos = Vector(0,0,0)
		if self:GetTargetType() == "string" and ents.FindByName(self:GetTargetName())[1]:IsValid() then
			targetpos = ents.FindByName(self:GetTargetName())[1]:GetPos()
		elseif self:GetTargetType() == "Entity" and IsEntity(self:GetTargetEnt()) then
			targetpos = self:GetTargetEnt():GetPos()
		elseif self:GetTargetType() == "Vector" then
			targetpos = self:GetTargetPos()
		else
			ErrorNoHalt('Your trying to set a "'..self:GetTargetType()..'" as the target, instead of a vector, valid entity, or entity name.\n')
		end
		
		local entphys = entity:GetPhysicsObject();
		if !entity:IsPlayer() and !entity:IsNPC() and entphys:IsValid() then
			entphys:SetVelocity(self:getvel(targetpos, entity:GetPos(), self:GetHeightAdd()))
		else
			if entity:IsPlayer() and self:HasSpawnFlags(4) then
				entity:Fire("ignorefalldamage","",0)
			end
			entity:SetLocalVelocity(self:getvel(targetpos, entity:GetPos(), self:GetHeightAdd()))
//			entity:SetLocalVelocity(self:getvel(self.target:GetPos(), entity:GetPos(), self.HightAdd))
		end
		self:EmitSound( "assault/Jump_pad_launch.wav" )
		self:TriggerOutput("OnLaunch", self)
	end
end

function ENT:KeyValue( key, value )
//	print(bit.band(31,1),bit.band(31,2),bit.band(31,4),bit.band(31,8),bit.band(31,16))
	if ( string.Left( key, 2 ) == "On" ) then
		self:StoreOutput( key, value )
	end
	if ( key == "angles" ) then
		local Sep = string.Explode(" ", value)
		local ang = (Angle(Sep[1], Sep[2], Sep[3]))
		self.angle = ang
	end	
	if ( key == "target" ) then
		self:SetTargetName(value)	-- Support for any map using the old way
	end	
	if ( key == "z_modifier" ) then	-- NetworkVar keyvalues now working?
		self:SetHeightAdd(value)	
	end	
	if ( key == "effect_col" ) then
		local Sep = string.Explode(" ", value)
		local Col = (Vector(Sep[1], Sep[2], Sep[3]))
		self:SetEffectColor(Col)
	end	
	if ( key == "enabled" ) then
		self:SetEnabled(value)
	end	
	if ( key == "model" ) then
		self:SetWorldModel(value)	
	end	
	if ( key == "target_name" ) then
		self:SetTargetName(value)	
	end	
//	if ( key == "spawnflags" ) then
//		if value == "1" then
//			self.Frozen = true
//		end
//	end	
end

function ENT:AcceptInput( inputName, activator, called, data )

	if ( inputName == "ChangeTarget" ) then
		self:SetTargetName(data)
	end	
	if ( inputName == "ChangeZMod" ) then
		self:SetHeightAdd(tonumber(data))
	end	
	if ( inputName == "TurnOn" ) then
		self:SetEnabled( true )
	end	
	if ( inputName == "TurnOff" ) then
		self:SetEnabled( false )
	end	
end

if SERVER then return end
if true then return end
local Laser = Material( "sprites/Gridplate" )
function ENT:Draw()
	self.Entity:DrawModel()
	if self:GetTargetType() == "Vector" then
	local pos = self:GetTargetPos()
	render.SetMaterial( Laser )
	render.DrawQuad( pos + Vector( 16, -16, 0 ), pos + Vector( 16, 16, 0 ), pos + Vector( -16, 16, 0 ), pos + Vector( -16, -16, 0 ))	
	
	end
--[[	//uncomment to draw the Collision Bounds
	pos = self.Entity:GetPos()
	render.SetMaterial( Laser )
local Min,Max = self.Entity:GetCollisionBounds()
local a, b, c = Min.x, Min.y, Min.z		//Min
local d, e, f = Max.x, Max.y, Max.z		//Max
	render.DrawQuad(self:LocalToWorld(Vector( a, b, c )), self:LocalToWorld(Vector( a, b, f )), self:LocalToWorld(Vector( d, b, f )), self:LocalToWorld(Vector( d, b, c )))		//Front
	render.DrawQuad(self:LocalToWorld(Vector( a, e, c )), self:LocalToWorld(Vector( a, e, f )), self:LocalToWorld(Vector( a, b, f )), self:LocalToWorld(Vector( a, b, c )))		//Left
	render.DrawQuad(self:LocalToWorld(Vector( a, b, f )), self:LocalToWorld(Vector( a, e, f )), self:LocalToWorld(Vector( d, e, f )), self:LocalToWorld(Vector( d, b, f )))		//Top
	render.DrawQuad(self:LocalToWorld(Vector( d, b, c )), self:LocalToWorld(Vector( d, b, f )), self:LocalToWorld(Vector( d, e, f )), self:LocalToWorld(Vector( d, e, c )))		//Right
	render.DrawQuad(self:LocalToWorld(Vector( d, e, c )), self:LocalToWorld(Vector( d, b, c )), self:LocalToWorld(Vector( a, b, c )), self:LocalToWorld(Vector( a, e, c )))		//Bottom
	render.DrawQuad(self:LocalToWorld(Vector( d, e, c )), self:LocalToWorld(Vector( d, e, f )), self:LocalToWorld(Vector( a, e, f )), self:LocalToWorld(Vector( a, e, c )))		//Back
--]]--	
end
