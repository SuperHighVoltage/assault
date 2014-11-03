
ENT.Base = "base_brush"
ENT.Type = "brush"

--[[---------------------------------------------------------
   Name: Initialize
-----------------------------------------------------------]]
function ENT:Initialize()	
	self.players = {}
	self.enabled = true
	self:SetCustomCollisionCheck( true )
end

--[[---------------------------------------------------------
   Name: StartTouch
-----------------------------------------------------------]]
function ENT:StartTouch( ply )
	if !self.enabled then return end
	if !ply:IsPlayer() then return end
	if !ply:Alive() then return end
	-- self.team == 0 is attackers
	-- self.team == 1 is defenders
	if (self.team == 0 and ply:IsAttacking()) or (self.team == 1 and !ply:IsAttacking()) then
		self:TriggerOutput("OnStartTouch", self)
		if table.Count(self.players) == 0 then
			self:TriggerOutput("OnStartTouchAll", self)
		end
		table.insert(self.players,ply)
	end
end

--[[---------------------------------------------------------
   Name: EndTouch
-----------------------------------------------------------]]
function ENT:EndTouch( ply )
	if !self.enabled then return end
	if !ply:IsPlayer() then return end
	if !ply:Alive() then return end
	-- self.team == 0 is attackers
	-- self.team == 1 is defenders
	if (self.team == 0 and ply:IsAttacking()) or (self.team == 1 and !ply:IsAttacking()) then
		table.RemoveByValue(self.players,ply)
		self:TriggerOutput("OnEndTouch", self)
		if table.Count(self.players) == 0 then
			self:TriggerOutput("OnEndTouchAll", self)
		end
	end
end

--[[---------------------------------------------------------
   Name: Touch
-----------------------------------------------------------]]
function ENT:Touch( ply )
	-- print( "Touch"..ply )
end

--[[---------------------------------------------------------
   Name: PassesTriggerFilters
   Desc: Return true if this object should trigger us
-----------------------------------------------------------]]
function ENT:PassesTriggerFilters( ply )
	return true
end

--[[---------------------------------------------------------
   Name: KeyValue
   Desc: Called when a keyvalue is added to us
-----------------------------------------------------------]]
function ENT:KeyValue( key, value )
	if ( string.Left( key, 2 ) == "On" ) then
		self:StoreOutput( key, value )
	end
	if ( key == "team" ) then
		self.team = tonumber(value)
	end	
end

function ENT:AcceptInput( inputName, activator, called, data )
	if ( inputName == "Enable" ) then
		self.enabled = true
	end	
	if ( inputName == "Disable" ) then
		self.enabled = false
	end	
	if ( inputName == "TouchTest" ) then
		if table.Count(self.players) == 0 then
			self:TriggerOutput("OnNotTouching", self)
		else
			self:TriggerOutput("OnTouching", self)
		end
	end	
end

--[[---------------------------------------------------------
   Name: Think
   Desc: Entity's think function. 
-----------------------------------------------------------]]
function ENT:Think()
end

--[[---------------------------------------------------------
   Name: OnRemove
   Desc: Called just before entity is deleted
-----------------------------------------------------------]]
function ENT:OnRemove()
end
