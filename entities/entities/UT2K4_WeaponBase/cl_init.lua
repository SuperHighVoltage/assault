
include('shared.lua')

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()	

	self.Entity:SetCollisionBounds( Vector( -16, -16, 0 ), Vector( 16, 16, 40 ) )
	self.Entity:SetSolid( SOLID_NONE )
	
--the whole ClientsideModel part is broken on its own

//	if self:GetNWString("weaponModel") then
//		self.item_model = ClientsideModel(self:GetNWString("weaponModel"))
//	else
//		self.item_model = ClientsideModel(self:GetPickupModel())
//	end
//	self.item_model:SetPos(Vector( 0, 0, 32 )+self.Entity:GetPos())
//	self.item_model:DrawShadow( false )
	
end
local vAngle = Vector( 0, 0, 1 )
local UpAngle = Angle( 0, 0, 0 )

function ENT:Think()
local Weapon = self:GetEnt()
	if IsValid(Weapon) and Weapon.Owner == NULL then
		local phys = Weapon:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:EnableMotion( false )		
		end
		local UpAngle = Angle( 0, 0, 0 )
		UpAngle:RotateAroundAxis(vAngle:Angle():Forward(), RealTime()*120)
		Weapon:SetAngles(UpAngle)
	end
end

/*---------------------------------------------------------
   Name: DrawPre
---------------------------------------------------------*/
local Laser = Material( "sprites/Gridplate" )
function ENT:Draw()
	self.Entity:DrawModel()
	
//	local vAngle = Vector( 0, 0, 1 )
 //   local UpAngle = Angle( 0, 0, 0 )
//    UpAngle:RotateAroundAxis(vAngle:Angle():Forward(), RealTime()*120)
//	self.item_model:SetAngles(UpAngle)
	
//	if ( self:GetActiveTime() > CurTime() ) then
//		self.item_model:SetColor(Color(255, 255, 255, 0))
//	else
//		self.item_model:SetColor(Color(255, 255, 255, 255))
//	end
		
--[[	//uncomment to draw the Collision Bounds
	pos = self.Entity:GetPos()
	render.SetMaterial( Laser )
local Min,Max = self.Entity:GetCollisionBounds()
local a, b, c = Min.x, Min.y, Min.z		//Min
local d, e, f = Max.x, Max.y, Max.z		//Max
	render.DrawQuad(pos+Vector( a, b, c ), pos+Vector( a, b, f ), pos+Vector( d, b, f ), pos+Vector( d, b, c ))		//Front
	render.DrawQuad(pos+Vector( a, e, c ), pos+Vector( a, e, f ), pos+Vector( a, b, f ), pos+Vector( a, b, c ))		//Left
	render.DrawQuad(pos+Vector( a, b, f ), pos+Vector( a, e, f ), pos+Vector( d, e, f ), pos+Vector( d, b, f ))		//Top
	render.DrawQuad(pos+Vector( d, b, c ), pos+Vector( d, b, f ), pos+Vector( d, e, f ), pos+Vector( d, e, c ))		//Right
	render.DrawQuad(pos+Vector( d, e, c ), pos+Vector( d, b, c ), pos+Vector( a, b, c ), pos+Vector( a, e, c ))		//Bottom
	render.DrawQuad(pos+Vector( d, e, c ), pos+Vector( d, e, f ), pos+Vector( a, e, f ), pos+Vector( a, e, c ))		//Back
--]]--	
end
