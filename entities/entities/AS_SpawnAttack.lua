AddCSLuaFile()
ENT.Base = "base_point"
ENT.Type = "point"

function ENT:Initialize()
//	self.Defalut = self:HasSpawnFlags(1)
	self.Enabled = self:HasSpawnFlags(1)
	
end

function ENT:Think()
	if SERVER then
		debugoverlay.Text( self:GetPos(), tostring(self.Enabled), 1 )
	end
	//print("self.Enabled",self.Enabled)
	self:NextThink( CurTime() + 1 )
end

function ENT:Enable()
	self.Enabled = true
	debugoverlay.Text( self:GetPos()+Vector(0,0,20), "Input: Enabled "..CurTime(), 100 )
end

function ENT:Disable()
	self.Enabled = false
	debugoverlay.Text( self:GetPos()+Vector(0,0,10), "Input: Disabled "..CurTime(), 100 )
end
--[[
function ENT:KeyValue( key, value )
	if ( string.Left( key, 2 ) == "On" ) then
		self:StoreOutput( key, value )
	end
end
--]]
function ENT:AcceptInput( inputName, activator, called, data )
	if ( inputName == "Enable" ) then
		self:Enable()
	end	
	if ( inputName == "Disable" ) then
		self:Disable()
	end	
end

function ENT:UpdateTransmitState()

	--
	-- The default behaviour for point entities is to not be networked.
	-- If you're deriving an entity and want it to appear clientside, override this
	-- TRANSMIT_ALWAYS = always send, TRANSMIT_PVS = send if in PVS
	--
	return TRANSMIT_ALWAYS

end