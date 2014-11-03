

/*---------------------------------------------------------
   Initializes the effect. The data is a table of data 
   which was passed from the server.
---------------------------------------------------------*/
function EFFECT:Init( data )
	
	// Keep the start and end pos - we're going to interpolate between them
	local Pos = data:GetOrigin()
	local col = data:GetStart() or Vector(255, 170, 0)

//	WorldSound( "weapons/slam/mine_mode.wav", Pos, 140 )
	sound.Play( "assault/item_respawn.wav", Pos, 75, 100, 1 )
	
	local emitter = ParticleEmitter( Pos )
	
		local particle = emitter:Add( "sprites/UT2K4/FlashFlare1", Pos )
		particle:SetDieTime( 0.75 )
		particle:SetStartAlpha( 250 )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( 0 )
		particle:SetEndSize( 50 )
		particle:SetRoll( math.Rand( 0, 360 ) )
		particle:SetRollDelta( math.Rand( -5.5, 5.5 ) )
		particle:SetColor(col.x, col.y, col.z)
		
		for i= 0, 32 do
			local newPos = Pos + (VectorRand()*30)
			local particle = emitter:Add( "sprites/UT2K4/FlashFlare1", newPos )
			particle:SetVelocity( (Pos-newPos) * math.Rand( 1, 5 ) )
			particle:SetDieTime( math.Rand( 0.5, 1 ) )
			particle:SetStartAlpha( 250 )
			particle:SetEndAlpha( 250 )
			particle:SetStartSize( 10 )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( 0, 360 ) )
			particle:SetRollDelta( math.Rand( -5.5, 5.5 ) )
			particle:SetColor(col.x, col.y, col.z)
			
--[[			local particle = emitter:Add( "sprites/UT2K4/FlashFlare1", Pos )
			particle:SetVelocity( (VectorRand()) * math.Rand( 50, 100 ) )
			particle:SetDieTime( math.Rand( 0.5, 1 ) )
			particle:SetStartAlpha( 250 )
			particle:SetEndAlpha( 250 )
			particle:SetStartSize( 10 )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( 0, 360 ) )
			particle:SetRollDelta( math.Rand( -5.5, 5.5 ) )
			particle:SetColor(255, 170, 0)--]]--
				
		end
				
	emitter:Finish()
	
end


/*---------------------------------------------------------
   THINK
   Returning false makes the entity die
---------------------------------------------------------*/
function EFFECT:Think( )
	return false
end


/*---------------------------------------------------------
   Draw the effect
---------------------------------------------------------*/
function EFFECT:Render()	
end



