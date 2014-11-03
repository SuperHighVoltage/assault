ENT.Type = "anim"
 
function ENT:SetupDataTables()
 
        self:InstallDataTable();
        self:NetworkVar( "Entity", 1, "Ent" );
end
 
hook.Add("ShouldCollide", "DontCollideWithWeaponsYouAlreadyHaveFromWeaponBases", function( ent1, ent2 )
 
        if not IsValid(ent1) or not IsValid(ent2) then return true end
 
        if ent1:IsWeapon() and ent2:IsPlayer() then
                if ent1.FromWeaponBase and ent2:HasWeapon(ent1:GetClass()) then
                        return false
                end
        end
        if ent2:IsWeapon() and ent1:IsPlayer() then
                if ent2.FromWeaponBase and ent1:HasWeapon(ent1:GetClass()) then
                        return false
                end
        end
        return true
end)