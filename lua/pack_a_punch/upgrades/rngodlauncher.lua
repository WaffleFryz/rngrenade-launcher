local UPGRADE = {}
UPGRADE.id = "weapon_ttt_rngodlauncher"
UPGRADE.class = "weapon_ttt_rnglauncher"
UPGRADE.name = "RNGod Launcher"
UPGRADE.desc = "Shoots better grenades"

function UPGRADE:Apply(SWEP)
    if SERVER and IsValid(SWEP:GetOwner()) then
        SWEP:GetOwner():GiveAmmo(6, "Grenade", true)
    end

    function SWEP:CreateGrenade(src, ang, vel, angimp, ply)
        local gren_string = pap_grenade_list[math.random(1, #pap_grenade_list)]
        local gren = ents.Create(gren_string)
        if not IsValid(gren) then return end
    
        gren:SetPos(src)
        gren:SetAngles(ang)
    
        --   gren:SetVelocity(vel)
        gren:SetOwner(ply)
        local isGrenade = scripted_ents.IsBasedOn(gren_string, "ttt_basegrenade_proj")
        if isGrenade then
        gren:SetThrower(ply)
        end
    
        gren:SetGravity(0.4)
        gren:SetFriction(0.2)
        gren:SetElasticity(0.45)
    
        gren:Spawn()
    
        gren:PhysWake()
    
        local phys = gren:GetPhysicsObject()
        if IsValid(phys) then
        phys:SetVelocity(vel)
        phys:AddAngleVelocity(angimp)
        end
    
        if isGrenade then
        -- This has to happen AFTER Spawn() calls gren's Initialize()
        gren:SetDetonateExact(CurTime() + self.detonate_timer)
        end
    
        return gren
    end
end

TTTPAP:Register(UPGRADE)