
-- serverside extensions to player table

local plymeta = FindMetaTable( "Player" )
if not plymeta then Error("FAILED TO FIND PLAYER TABLE") return end


function plymeta:ReadyToSpawn()
   -- do not spawn players who have no team or are spectators
   if self:Team() == TEAM_UNASSIGNED or self:Team() == TEAM_SPECTATOR then return false end

   return true
end

function plymeta:IsAttacking(ignoreRound)
	
	if GetRoundState() == ROUND_WAIT and self:Team() != TEAM_SPECTATOR then return true end	-- While waiting for more players all waiting players can complete objectives as watermelons
	if (GetRoundState() == ROUND_STARTING or GetRoundState() == ROUND_WAIT) and !ignoreRound then return false end
	if GetAttackingTeam() == self:Team() then return true end
	
	return false
end

function plymeta:IsDefending()
	return !self:IsAttacking()
end