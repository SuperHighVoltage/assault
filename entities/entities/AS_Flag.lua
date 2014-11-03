
AddCSLuaFile()

local BounceSound = Sound( "garrysmod/balloon_pop_cute.wav" )

DEFINE_BASECLASS( "base_anim" )

ENT.Editable			= false
ENT.Spawnable			= false
ENT.AdminOnly			= false
ENT.RenderGroup 		= RENDERGROUP_TRANSLUCENT


function ENT:SetupDataTables()

	self:NetworkVar( "Bool", 	0, "PickedUp" )
	self:NetworkVar( "Bool", 	1, "Missing" )
	self:NetworkVar( "Bool", 	2, "PhysicsCarry" )
	self:NetworkVar( "Entity", 	0, "Objective" )
	self:NetworkVar( "Entity", 	1, "Player" )
	self:NetworkVar( "Float",	0, "DroppedTime" )
	self:NetworkVar( "Float",	1, "ResetTime" )
	self:NetworkVar( "Float",	2, "PickUpRadius" )
	self:NetworkVar( "Vector",	0, "HomePos" )
	self:NetworkVar( "Vector",	1, "CompletePos" )
	
	self:SetResetTime(20)
	self:SetPhysicsCarry(false)
end

function ENT:Initialize()

	if ( SERVER ) then

		self:SetModel( "models/roller.mdl" )
		
		self:PhysicsInit(SOLID_VPHYSICS)
		
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableMotion(self:GetPhysicsCarry())
			if self:GetPhysicsCarry() then phys:Wake() end
		end

		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		self:SetTrigger(true)
		self:SetMissing(false)
		self:SetPickedUp(false)
		self:SetHomePos(self:GetPos())
		
		hook.Add( "AllowPlayerPickup", 		self, self.PlayerPickup )
		hook.Add( "GravGunPickupAllowed",	self, self.GravGunPickup )
		hook.Add( "GravGunPunt", 			self, self.GravGunPunt )
		hook.Add( "GravGunOnPickedUp", 		self, self.GravGunOnPickedUp )
		hook.Add( "GravGunOnDropped", 		self, self.GravGunOnDropped )
	end
	
end

function ENT:PlayerPickup(ply, ent)
	if ent != self then return true end
	MsgN("PlayerPickup "..CurTime())
	if !self:GetPhysicsCarry() then return false end
	self:PickUp(ply)
	return true
end

function ENT:GravGunPickup(ply, ent)
	if ent != self then return true end
	MsgN("GravGunPickup "..CurTime())
	if !self:GetPhysicsCarry() then return false end
	return true
end

function ENT:GravGunPunt(ply, ent)
	if ent != self then return true end
	MsgN("GravGunPunt "..CurTime())
	if !self:GetPhysicsCarry() then return false end
	self:Drop()
	return true
end

function ENT:GravGunOnPickedUp(ply, ent)
	if ent != self then return end
	MsgN("GravGunOnPickedUp "..CurTime())
	if !self:GetPhysicsCarry() then return end
	self:PickUp(ply)
end

function ENT:GravGunOnDropped(ply, ent)
	if ent != self then return end
	MsgN("GravGunOnDropped "..CurTime())
	if !self:GetPhysicsCarry() then return end
	self:Drop()
end

function ENT:OnTakeDamage( dmginfo )

	-- React physically when shot/getting blown
	self:TakePhysicsDamage( dmginfo )
	
end

function ENT:Think()
	if CLIENT then return end
	if !self:GetPickedUp() and self:GetMissing() then
		if (self:GetDroppedTime() + self:GetResetTime()) < CurTime() then
			self:Reset()
			return
		end
	end
	if (self:GetObjective():GetCompleted() or !self:GetObjective():GetEnabled()) and self:GetMissing() then
		self:Reset()
		return
	end
	
	if !self:GetPickedUp() and !self:GetObjective():GetCompleted() and self:GetObjective():GetEnabled() and !self:GetPhysicsCarry() then
		MsgN("Not picked up, searching for players")
		local ent = ents.FindInSphere( self:GetPos(), self:GetPickUpRadius() )
		for k,v in pairs( ent ) do		-- search for players
			if v:IsPlayer() and v:Alive() then
				MsgN("Found an alive player")
				if v:IsAttacking() then
					self:PickUp(v)
					MsgN("Player is attacking, picking up")
				else
					self:Reset(z)
				end
			end
		end
	end	
	
	if !self:GetPickedUp() then return end
	if !IsValid(self:GetPlayer()) or !self:GetPlayer():Alive() then
	//	print(self:GetPlayer())
	//	print(self:GetPlayer(),"!IsValid(self:GetPlayer())",!IsValid(self:GetPlayer()),"!self:GetPlayer():Alive()",!self:GetPlayer():Alive())
		self:Drop()
	end
end

function ENT:PickUp(ply)
	
	if self:GetPickedUp() or self:GetObjective():GetCompleted() or !self:GetObjective():GetEnabled() then return end
	MsgN("flag picked up")
	print("------",ply)
	self:SetMissing(true)
	self:SetPickedUp(true)
	self:SetPlayer(ply)
	MsgN("GetPhysicsCarry = "..tostring(self:GetPhysicsCarry()))
	if !self:GetPhysicsCarry() then
		self:SetPos(ply:GetPos()+Vector(0,0,100))
		self:SetParent(ply)
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableMotion(false)
		end
	else
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableMotion(true)
			phys:Wake()
		end
	end
end

function ENT:Drop()
	MsgN("flag dropped")
	self:SetPickedUp(false)
	self:SetDroppedTime(CurTime())
	self:SetParent(nil)
	if !self:GetPhysicsCarry() then self:SetPos(self:GetPlayer():GetPos()+Vector(0,0,100)) end
	self:SetPlayer(nil)
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(true)
		phys:Wake()
	end
end

function ENT:Completed()
	MsgN("flag at new home")
	self:SetMissing(false)
	self:SetPickedUp(false)
	self:SetParent(nil)
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(false)
	end
	self:SetPos(self:GetCompletePos())
	self:SetPlayer(nil)
end

function ENT:Reset()
	MsgN("flag reset")
	self:SetMissing(false)
	self:SetPickedUp(false)
	self:SetPlayer(nil)
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(false)
	end
	self:SetPos(self:GetHomePos())
end

function ENT:StartTouch(ent)
	if CLIENT then return end
	if !ent:IsPlayer() then return end
	if self:GetPhysicsCarry() then return end
	print(ent)
	if ent:IsAttacking() then
		print("---",ent)
		self:PickUp(ent)
	else
		self:Reset(ent)
	end
end


