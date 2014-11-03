AddCSLuaFile()
ENT.Base = "base_point"
ENT.Type = "point"

function ENT:Initialize()
end

function ENT:Think()
end

function ENT:OnRemove()
end

function ENT:KeyValue( key, value )
	if ( string.Left( key, 2 ) == "On" ) then
		self:StoreOutput( key, value )
	end
	if ( key == "roundmin" ) then
		SetGlobalFloat("as_round_time", tonumber(value))
	end	
	if ( key == "attackermodels" ) then
		SetGlobalFloat("as_attackermodels", tonumber(value))
	end	
	if ( key == "defendermodels" ) then
		SetGlobalFloat("as_defendermodels", tonumber(value))
	end	
	if ( key == "attackerloadout" ) then
		SetGlobalFloat("as_attackerloadout", tonumber(value))
	end	
	if ( key == "defenderloadout" ) then
		SetGlobalFloat("as_defenderloadout", tonumber(value))
	end	
end

function ENT:AcceptInput( inputName, activator, called, data )
end

function ENT:UpdateTransmitState()

	--
	-- The default behaviour for point entities is to not be networked.
	-- If you're deriving an entity and want it to appear clientside, override this
	-- TRANSMIT_ALWAYS = always send, TRANSMIT_PVS = send if in PVS
	--
	return TRANSMIT_ALWAYS

end