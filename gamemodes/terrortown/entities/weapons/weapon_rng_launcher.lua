AddCSLuaFile()

SWEP.HoldType			= "rpg"

if CLIENT then
   SWEP.PrintName = "RNG Launcher"

   SWEP.Slot = 6
   SWEP.Icon = "vgui/ttt/lykrast/icon_hp_glauncher"
   SWEP.EquipMenuData = {
      type="Weapon",
      desc="Launches random grenades.\n\nRight click to dump the entire clip"
   };
end


SWEP.Base				= "weapon_tttbase"
SWEP.Spawnable = true

SWEP.Kind = WEAPON_EQUIP1

SWEP.Primary.Ammo = "Grenade"
SWEP.Primary.Damage = 45
SWEP.Primary.Delay = 0.2
SWEP.Primary.ClipSize = 6
SWEP.Primary.ClipMax = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Automatic = true

SWEP.AutoSpawnable      = false
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = true

SWEP.detonate_timer = 1

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 70
SWEP.ViewModel           = "models/weapons/c_rpg.mdl"
SWEP.WorldModel          = "models/weapons/w_rocket_launcher.mdl"
SWEP.Primary.Sound			= "weapons/mortar/mortar_fire1.wav"
SWEP.Primary.Recoil			= 7

SWEP.IronSightsPos = Vector(2.631, -0.03, 2.354)
SWEP.IronSightsAng = Vector(1.432, 2.44, 0)

function SWEP:WasBought(buyer)
   buyer:GiveAmmo( 6, "Grenade", true )
end

function SWEP:PrimaryAttack(worldsnd)

   self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

   if not self:CanPrimaryAttack() then return end

   self:SendWeaponAnim(self.PrimaryAnim)

   self.Owner:MuzzleFlash()
   self.Owner:SetAnimation( PLAYER_ATTACK1 )

   if not worldsnd then
      self:EmitSound( self.Primary.Sound, self.Primary.SoundLevel )
   elseif SERVER then
      sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
   end

   self:LaunchGrenade()

   self:TakePrimaryAmmo( 1 )

   local owner = self.Owner
   if not IsValid(owner) or owner:IsNPC() or (not owner.ViewPunch) then return end

   owner:ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0 ) )
end

function SWEP:LaunchGrenade()
   if SERVER then
      local ply = self.Owner
      if not IsValid(ply) then return end

      local ang = ply:EyeAngles()

      -- don't even know what this bit is for, but SDK has it
      -- probably to make it throw upward a bit
      if ang.p < 90 then
         ang.p = -10 + ang.p * ((90 + 10) / 90)
      else
         ang.p = 360 - ang.p
         ang.p = -10 + ang.p * -((90 + 10) / 90)
      end

      local vel = math.min(800, (90 - ang.p) * 6)

      local vfw = ang:Forward()
      local vrt = ang:Right()
      --      local vup = ang:Up()

      local src = ply:GetPos() + (ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset())
      src = src + (vfw * 8) + (vrt * 10)

      local thr = vfw * vel + ply:GetVelocity()

      self:CreateGrenade(src, Angle(math.random(0,100),math.random(0,100),math.random(0,100)), thr, Vector(600, math.random(-1200, 1200), 0), ply)
   end
end

function SWEP:CreateGrenade(src, ang, vel, angimp, ply)
   local gren_string = grenade_list[math.random(1, #grenade_list)]
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

function SWEP:SetupDataTables()
   self:DTVar("Bool", 0, "reloading")

   return self.BaseClass.SetupDataTables(self)
end

function SWEP:SecondaryAttack()
   while self:Clip1() > 0 do
      self:SendWeaponAnim(self.PrimaryAnim)

      self.Owner:MuzzleFlash()
      self.Owner:SetAnimation( PLAYER_ATTACK1 )
      self:EmitSound( self.Primary.Sound, self.Primary.SoundLevel )

      self:LaunchGrenade()

      self:TakePrimaryAmmo( 1 )
   end
end