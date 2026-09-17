local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

local Onyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/iamdookie1/Ui2/main/Ui.lua?v=" .. tostring(tick())
))()

Onyx:SetConfigScope("universe")

local FIXED_DT  = 1 / 120
local MAX_STEPS = 6

local cfg = {
    frontEnabled    = true,
    frontSize       = 100,
    frontProjection = 100,
    frontHeight     = 10,
    frontSep        = 50,
    frontWeight     = 48,
    frontReactivity = 58,
    frontCollide    = false,
    frontAutoColor  = true,
    frontColor      = Color3.fromRGB(255, 200, 183),
    nippleColor     = Color3.fromRGB(210, 120, 108),
    nippleDetail    = "Both",
    nippleSize      = 100,

    rearEnabled     = true,
    rearSize        = 100,
    rearProjection  = 100,
    rearHeight      = -8,
    rearSep         = 38,
    rearWeight      = 62,
    rearReactivity  = 65,
    rearCollide     = false,
    rearAutoColor   = true,
    rearColor       = Color3.fromRGB(250, 190, 173),

    physicsEnabled  = true,
    removeClothing  = true,
    animReaction    = true,
    limbCollision   = true,
    matchMaterial   = true,
    normalMapId     = "",
    roughnessMapId  = "",
}

local function getSkinColor(char)
    local head = char:FindFirstChild("Head")
    if head then return head.Color end
    return Color3.fromRGB(220, 180, 150)
end

local function getSkinMaterial(char)
    local ref = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
    if ref and ref:IsA("BasePart") then
        return ref.Material, ref.Reflectance
    end
    return Enum.Material.SmoothPlastic, 0
end

local function makeFrontProf()
    local w, r = cfg.frontWeight, cfg.frontReactivity
    local m = r / 100
    local base = math.max(5, 30 - w * 0.25)
    return {
        kVert        = base,
        kLat         = base * 1.15,
        kIn          = base * 2.60,
        kOut         = base * 0.80,
        hardness     = 3.2,
        damping      = math.max(1.5, 8 - w * 0.065),
        gravSag      = w * 0.0022,
        velLag       = 0.006 + m * 0.026,
        accelKick    = m * 0.0035,
        spinLag      = 0.30 + m * 0.70,
        centrifugal  = 0.008 + m * 0.020,
        tiltComp     = 0.40 + m * 0.90,
        breathe      = 0.003 + m * 0.004,
        walkOsc      = r * 0.00018,
        stepKick     = r * 0.009,
        landKick     = r * 0.019,
        jumpKick     = r * 0.013,
        animKick     = r * 0.006,
        rotStiffness = 17,
        rotDamping   = 4.0,
        rotAccelMult = 0.0025 + m * 0.0065,
        maxOffset    = 0.32,
        maxRot       = 0.13,
        sideCouple   = 0.55,
        chainCouple  = 2.40,
        lagBlend     = 0.42,
        lagTilt      = 1.35,
    }
end

local function makeRearProf()
    local w, r = cfg.rearWeight, cfg.rearReactivity
    local m = r / 100
    local base = math.max(3, 20 - w * 0.17)
    return {
        kVert        = base,
        kLat         = base * 1.10,
        kIn          = base * 2.40,
        kOut         = base * 0.85,
        hardness     = 2.8,
        damping      = math.max(1.2, 7 - w * 0.058),
        gravSag      = w * 0.0025,
        velLag       = 0.010 + m * 0.034,
        accelKick    = m * 0.006,
        spinLag      = 0.50 + m * 1.00,
        centrifugal  = 0.012 + m * 0.028,
        tiltComp     = 0,
        breathe      = 0.002 + m * 0.003,
        walkOsc      = r * 0.00022,
        stepKick     = r * 0.013,
        landKick     = r * 0.021,
        jumpKick     = r * 0.015,
        animKick     = r * 0.008,
        rotStiffness = 11,
        rotDamping   = 3.2,
        rotAccelMult = 0.003 + m * 0.010,
        maxOffset    = 0.44,
        maxRot       = 0.17,
        sideCouple   = 0.70,
        chainCouple  = 2.10,
        lagBlend     = 0.38,
        lagTilt      = 1.15,
    }
end

local function clearClothing(char)
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("Clothing") or v:IsA("Accessory")
                or v:IsA("ShirtGraphic") or v:IsA("BodyColors") then
            pcall(function() v:Destroy() end)
        end
    end
end

local PAD_NAMES = {
    FrontLeftPad = true, FrontRightPad = true,
    RearLeftPad = true, RearRightPad = true,
}

local function isOurPart(p)
    local n = p.Name
    if PAD_NAMES[n] then return true end
    return n:find("_Nipple$") ~= nil or n:find("_Areola$") ~= nil
end

local function destroyPads(char)
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") and isOurPart(p) then
            pcall(function() p:Destroy() end)
        end
    end
end

local function applySurface(part)
    if cfg.normalMapId == "" and cfg.roughnessMapId == "" then return end
    pcall(function()
        local sa = Instance.new("SurfaceAppearance")
        if cfg.normalMapId ~= "" then sa.NormalMap = cfg.normalMapId end
        if cfg.roughnessMapId ~= "" then sa.RoughnessMap = cfg.roughnessMapId end
        sa.Parent = part
    end)
end

local function makePart(name, size, color, trans, char, mat, refl)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = mat or Enum.Material.SmoothPlastic
    p.Reflectance = refl or 0
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Massless = true
    p.Anchored = false
    p.CastShadow = true
    p.Transparency = trans
    p.Parent = char
    return p
end

local function sphereMesh(part, scale, offset)
    local m = Instance.new("SpecialMesh")
    m.MeshType = Enum.MeshType.Sphere
    m.Scale = scale
    m.Offset = offset or Vector3.zero
    m.Parent = part
    return m
end

local function weldTo(parent, child, cf)
    local w = Instance.new("Weld")
    w.Part0 = parent
    w.Part1 = child
    w.C0 = cf
    w.Parent = child
    return w
end

local function addNipple(padPart, char, tipZ, nipCol, sizePct, showNip, showArea, mat)
    local sf = sizePct / 100
    if showArea then
        local areola = makePart(padPart.Name .. "_Areola",
            Vector3.new(0.36 * sf, 0.36 * sf, 0.06 * sf), nipCol, 0.06, char, mat, 0)
        sphereMesh(areola, Vector3.new(1.10, 1.10, 0.28))
        weldTo(padPart, areola, CFrame.new(0, -0.08, tipZ + 0.05))
    end
    if showNip then
        local nip = makePart(padPart.Name .. "_Nipple",
            Vector3.new(0.11 * sf, 0.11 * sf, 0.10 * sf), nipCol, 0, char, mat, 0)
        sphereMesh(nip, Vector3.new(0.80, 0.80, 1.70))
        weldTo(padPart, nip, CFrame.new(0, -0.08, tipZ - 0.035))
    end
end

local function softCollide(a, b, minDist, strength)
    local pa, pb = a.weld.Part1, b.weld.Part1
    if not (pa and pa.Parent and pb and pb.Parent) then return end
    local sep = pb.Position - pa.Position
    local dist = sep.Magnitude
    if dist > 0 and dist < minDist then
        local push = sep.Unit * (minDist - dist) * strength
        a.upper.vel -= push
        b.upper.vel += push
    end
end

local activePads, activeChar, renderConn = nil, nil, nil
local charConns = {}
local lastChestCF = nil
local accumulator = 0

local function disconnectAll()
    if renderConn then renderConn:Disconnect() ; renderConn = nil end
    for _, c in pairs(charConns) do
        pcall(function() c:Disconnect() end)
    end
    charConns = {}
end

local function applyProf(d, p, softenFactor)
    for k, v in pairs(p) do d.prof[k] = v end
    d.lowerProf = {}
    for k, v in pairs(p) do d.lowerProf[k] = v end
    d.lowerProf.kVert   = p.kVert * softenFactor
    d.lowerProf.kLat    = p.kLat * softenFactor
    d.lowerProf.kOut    = p.kOut * softenFactor
    d.lowerProf.damping = p.damping * 0.88
end

local function updateFrontProfs()
    if not activePads then return end
    local p = makeFrontProf()
    for _, d in pairs(activePads) do
        if d.isFront then applyProf(d, p, 0.62) end
    end
end

local function updateRearProfs()
    if not activePads then return end
    local p = makeRearProf()
    for _, d in pairs(activePads) do
        if not d.isFront then applyProf(d, p, 0.58) end
    end
end

local function resetPadPositions()
    if not activePads then return end
    for _, d in pairs(activePads) do
        d.upper.vel = Vector3.zero ; d.upper.pos = Vector3.zero
        d.lower.vel = Vector3.zero ; d.lower.pos = Vector3.zero
        d.rotVel = Vector3.zero ; d.rot = Vector3.zero
        if d.weld and d.weld.Parent then d.weld.C0 = d.base end
    end
end

local function updatePadColors(char)
    if not char then return end
    local skinColor = getSkinColor(char)
    local frontCol = cfg.frontAutoColor and skinColor or cfg.frontColor
    local rearCol  = cfg.rearAutoColor and skinColor or cfg.rearColor
    local nipCol   = cfg.frontAutoColor and skinColor or cfg.nippleColor

    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            local n = p.Name
            if n:find("^Front") then
                if n:find("_Nipple$") or n:find("_Areola$") then
                    p.Color = nipCol
                else
                    p.Color = frontCol
                end
            elseif n:find("^Rear") then
                p.Color = rearCol
            end
        end
    end
end

local function stepMass(mass, pr, d, sdt, ctx, isLower)
    local target = Vector3.new(
        -ctx.localVel.X * pr.velLag,
        0,
        -ctx.localVel.Z * pr.velLag * 0.55
    ) + ctx.localDown * pr.gravSag * (isLower and 1.25 or 1.0)

    if d.isFront and pr.tiltComp > 0 then
        target = target + Vector3.new(0, 0, -ctx.tiltFwd * pr.tiltComp * 0.12)
    end

    local ph = d.phase + (isLower and 0.22 or 0)
    if ctx.hSpd > 0.5 then
        mass.vel = mass.vel + Vector3.new(0,
            math.sin(ctx.t * ctx.hSpd * 1.05 + ph) * pr.walkOsc * math.min(ctx.hSpd / 8, 1), 0)
    else
        mass.vel = mass.vel + Vector3.new(0, math.sin(ctx.t * 0.85 + ph) * pr.breathe, 0)
    end

    if ctx.isStep then mass.vel = mass.vel + Vector3.new(0, pr.stepKick, 0) end

    mass.vel = mass.vel + Vector3.new(
        -ctx.localAccel.X * pr.accelKick,
        -ctx.localAccel.Y * pr.accelKick * 0.45,
        -ctx.localAccel.Z * pr.accelKick * 0.35
    ) * sdt

    mass.vel = mass.vel + Vector3.new(-ctx.turnRate * pr.spinLag, 0, 0) * sdt
    mass.vel = mass.vel + ctx.localCentri * pr.centrifugal * sdt

    if cfg.animReaction and ctx.animMag > 0.08 then
        local ai = math.min(ctx.animMag, 0.5) * pr.animKick
        mass.vel = mass.vel + Vector3.new(0, ai * 0.7, ai * 0.35)
    end

    local disp = mass.pos - target
    local r = mass.pos.Magnitude / pr.maxOffset
    local hard = 1 + pr.hardness * (r * r * r * r)

    local zK = (disp.Z * d.inwardSign > 0) and pr.kIn or pr.kOut
    local force = Vector3.new(
        -disp.X * pr.kLat * hard,
        -disp.Y * pr.kVert * hard,
        -disp.Z * zK * hard
    )

    mass.vel = mass.vel + (force - mass.vel * pr.damping) * sdt
end

local function stepPad(d, sdt, ctx)
    local pu, pl = d.prof, d.lowerProf

    stepMass(d.upper, pu, d, sdt, ctx, false)
    stepMass(d.lower, pl, d, sdt, ctx, true)

    d.lower.vel = d.lower.vel + (d.upper.pos - d.lower.pos) * pu.chainCouple * sdt
    d.upper.vel = d.upper.vel + (d.lower.pos - d.upper.pos) * pu.chainCouple * 0.35 * sdt

    d.upper.pos = d.upper.pos + d.upper.vel * sdt
    d.lower.pos = d.lower.pos + d.lower.vel * sdt

    local mu = d.upper.pos.Magnitude
    if mu > pu.maxOffset then
        d.upper.pos = d.upper.pos * (pu.maxOffset / mu)
        d.upper.vel = d.upper.vel * 0.55
    end
    local ml = d.lower.pos.Magnitude
    if ml > pl.maxOffset then
        d.lower.pos = d.lower.pos * (pl.maxOffset / ml)
        d.lower.vel = d.lower.vel * 0.55
    end

    local rTgt  = Vector3.new(-ctx.localAccel.Z * pu.rotAccelMult, 0, ctx.localAccel.X * pu.rotAccelMult * d.side)
    local rDisp = d.rot - rTgt
    d.rotVel = d.rotVel + (-rDisp * pu.rotStiffness - d.rotVel * pu.rotDamping) * sdt
    d.rot    = d.rot + d.rotVel * sdt
    local rMag = d.rot.Magnitude
    if rMag > pu.maxRot then d.rot = d.rot * (pu.maxRot / rMag) end
end

local function setupCharacter(char)
    disconnectAll()
    destroyPads(char)
    activePads = nil
    lastChestCF = nil
    accumulator = 0

    local rootPart = char:WaitForChild("HumanoidRootPart")
    local humanoid = char:WaitForChild("Humanoid")
    local upper    = char:FindFirstChild("UpperTorso")
    local lowerT   = char:FindFirstChild("LowerTorso")
    local torso    = char:FindFirstChild("Torso")
    local isR6     = (upper == nil) and (torso ~= nil)

    local chest    = upper or torso
    local rearBone = lowerT or torso
    if not chest then return end

    if cfg.removeClothing then clearClothing(char) end

    local skinMat, skinRefl = Enum.Material.SmoothPlastic, 0
    if cfg.matchMaterial then skinMat, skinRefl = getSkinMaterial(char) end

    local torsoSize  = chest.Size
    local widthScale = math.clamp(torsoSize.X / 2, 0.75, 1.6)
    local depthScale = math.clamp(torsoSize.Z / 1, 0.75, 1.6)

    local pads = {}
    local V0 = Vector3.zero
    local frontL, frontR, rearL, rearR

    local skinColor = getSkinColor(char)
    local frontCol  = cfg.frontAutoColor and skinColor or cfg.frontColor
    local rearCol   = cfg.rearAutoColor and skinColor or cfg.rearColor
    local nipCol    = cfg.frontAutoColor and skinColor or cfg.nippleColor

    local function newMass() return { pos = V0, vel = V0 } end

    if cfg.frontEnabled then
        local s   = (cfg.frontSize / 100) * widthScale
        local zSc = 1.38 * (cfg.frontProjection / 100) * depthScale
        local sz  = Vector3.new(1.12 * s, 0.98 * s, 0.70 * s)
        local msc = Vector3.new(1.26, 1.04, zSc)
        local halfD = (sz.Z / 2) * zSc
        local fzOff = -math.max(0, halfD - 0.45)
        local tipZ  = math.clamp(fzOff - halfD + 0.025, -3.5, -0.12)

        local x = cfg.frontSep * 0.01
        local y = cfg.frontHeight * 0.01

        local flPart = makePart("FrontLeftPad", sz, frontCol, 0.02, char, skinMat, skinRefl)
        sphereMesh(flPart, msc, Vector3.new(0, -0.10, fzOff))
        local flW = weldTo(chest, flPart,
            CFrame.new(-x, y, -0.61 * depthScale)
            * CFrame.Angles(math.rad(-13), math.rad(15), math.rad(-9)))
        applySurface(flPart)

        local frPart = makePart("FrontRightPad", sz, frontCol, 0.02, char, skinMat, skinRefl)
        sphereMesh(frPart, msc, Vector3.new(0, -0.10, fzOff))
        local frW = weldTo(chest, frPart,
            CFrame.new(x, y, -0.61 * depthScale)
            * CFrame.Angles(math.rad(-13), math.rad(-15), math.rad(9)))
        applySurface(frPart)

        local showNip  = cfg.nippleDetail == "Nipple" or cfg.nippleDetail == "Both"
        local showArea = cfg.nippleDetail == "Areola" or cfg.nippleDetail == "Both"
        if showNip or showArea then
            addNipple(flPart, char, tipZ, nipCol, cfg.nippleSize, showNip, showArea, skinMat)
            addNipple(frPart, char, tipZ, nipCol, cfg.nippleSize, showNip, showArea, skinMat)
        end

        local d1 = { weld = flW, base = flW.C0, prof = {}, lowerProf = {}, side = -1, isFront = true,
                     phase = 0.28, inwardSign = 1, upper = newMass(), lower = newMass(),
                     rotVel = V0, rot = V0 }
        local d2 = { weld = frW, base = frW.C0, prof = {}, lowerProf = {}, side = 1, isFront = true,
                     phase = 0.0, inwardSign = 1, upper = newMass(), lower = newMass(),
                     rotVel = V0, rot = V0 }
        d1.sibling = d2 ; d2.sibling = d1
        table.insert(pads, d1) ; frontL = d1
        table.insert(pads, d2) ; frontR = d2
    end

    if cfg.rearEnabled then
        local s    = (cfg.rearSize / 100) * widthScale
        local rZSc = 1.14 * (cfg.rearProjection / 100) * depthScale
        local sz   = Vector3.new(1.34 * s, 1.26 * s, 1.08 * s)
        local msc  = Vector3.new(1.10, 1.22, rZSc)
        local halfD = (sz.Z / 2) * rZSc
        local rzOff = math.max(0, halfD - 0.55)

        local x  = cfg.rearSep * 0.01
        local y  = (isR6 and -0.80 or 0.0) + cfg.rearHeight * 0.01
        local rz = (isR6 and 0.56 or 0.52) * depthScale

        local rlPart = makePart("RearLeftPad", sz, rearCol, 0.02, char, skinMat, skinRefl)
        sphereMesh(rlPart, msc, Vector3.new(0, -0.07, rzOff))
        local rlW = weldTo(rearBone, rlPart,
            CFrame.new(-x, y, rz) * CFrame.Angles(math.rad(6), math.rad(5), math.rad(4)))
        applySurface(rlPart)

        local rrPart = makePart("RearRightPad", sz, rearCol, 0.02, char, skinMat, skinRefl)
        sphereMesh(rrPart, msc, Vector3.new(0, -0.07, rzOff))
        local rrW = weldTo(rearBone, rrPart,
            CFrame.new(x, y, rz) * CFrame.Angles(math.rad(6), math.rad(-5), math.rad(-4)))
        applySurface(rrPart)

        local d3 = { weld = rlW, base = rlW.C0, prof = {}, lowerProf = {}, side = -1, isFront = false,
                     phase = 0.18, inwardSign = -1, upper = newMass(), lower = newMass(),
                     rotVel = V0, rot = V0 }
        local d4 = { weld = rrW, base = rrW.C0, prof = {}, lowerProf = {}, side = 1, isFront = false,
                     phase = 0.0, inwardSign = -1, upper = newMass(), lower = newMass(),
                     rotVel = V0, rot = V0 }
        d3.sibling = d4 ; d4.sibling = d3
        table.insert(pads, d3) ; rearL = d3
        table.insert(pads, d4) ; rearR = d4
    end

    activePads = pads
    updateFrontProfs()
    updateRearProfs()
    lastChestCF = chest.CFrame

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { char }
    rayParams.IgnoreWater = true

    local limbNames = {
        "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm",
        "LeftUpperArm", "RightUpperArm", "Left Arm", "Right Arm",
    }
    local limbs = {}
    for _, ln in ipairs(limbNames) do
        local lp = char:FindFirstChild(ln)
        if lp and lp:IsA("BasePart") then table.insert(limbs, lp) end
    end

    table.insert(charConns, humanoid.StateChanged:Connect(function(old, new)
        if not cfg.physicsEnabled or not activePads then return end
        if new == Enum.HumanoidStateType.Jumping then
            for _, d in pairs(activePads) do
                local k = d.prof.jumpKick
                d.upper.vel = d.upper.vel + Vector3.new(0, -k, 0)
                d.lower.vel = d.lower.vel + Vector3.new(0, -k * 1.2, 0)
            end
        end
        local wasAir = old == Enum.HumanoidStateType.Freefall or old == Enum.HumanoidStateType.Jumping
        local isGnd  = new == Enum.HumanoidStateType.Running or new == Enum.HumanoidStateType.Landed
                    or new == Enum.HumanoidStateType.RunningNoPhysics
                    or new == Enum.HumanoidStateType.StrafingNoPhysics
        if wasAir and isGnd then
            for _, d in pairs(activePads) do
                local k = d.prof.landKick
                d.upper.vel = d.upper.vel + Vector3.new(0, k, 0)
                d.lower.vel = d.lower.vel + Vector3.new(0, k * 1.25, 0)
            end
        end
    end))

    table.insert(charConns, humanoid.Died:Connect(function()
        disconnectAll()
        activePads = nil
    end))

    table.insert(charConns, char.AncestryChanged:Connect(function(_, parent)
        if not parent then
            disconnectAll()
            activePads = nil
        end
    end))

    local lastVel     = V0
    local lastRootCF  = rootPart.CFrame
    local wasGrounded = true
    local stepCD      = 0

    renderConn = RunService.PreSimulation:Connect(function(dt)
        if not char or not char.Parent or not rootPart or not rootPart.Parent then return end
        if not chest or not chest.Parent then return end
        if not cfg.physicsEnabled or not activePads or #activePads == 0 then return end

        dt = math.min(dt, 0.1)

        local cv    = rootPart.AssemblyLinearVelocity
        local av    = rootPart.AssemblyAngularVelocity
        local accel = (cv - lastVel) / math.max(dt, 0.001)
        lastVel = cv

        local deltaCF  = lastRootCF:Inverse() * rootPart.CFrame
        local lv       = deltaCF.LookVector
        local turnRate = math.clamp(math.atan2(lv.X, -lv.Z) / math.max(dt, 0.001), -20, 20)
        lastRootCF = rootPart.CFrame

        local animMag = 0
        if cfg.animReaction and lastChestCF then
            local cd = lastChestCF:Inverse() * chest.CFrame
            local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cd:GetComponents()
            animMag = math.acos(math.clamp((r00 + r11 + r22 - 1) / 2, -1, 1))
        end
        lastChestCF = chest.CFrame

        stepCD = math.max(0, stepCD - dt)
        local hit = Workspace:Raycast(rootPart.Position, Vector3.new(0, -5, 0), rayParams)
        local grounded = hit ~= nil and hit.Distance < 3.6
        local isStep = false
        if grounded and not wasGrounded and stepCD == 0 then
            isStep = true
            stepCD = 0.16
        end
        wasGrounded = grounded

        if grounded and stepCD == 0 then
            local hs = Vector3.new(cv.X, 0, cv.Z).Magnitude
            if hs > 4 and math.abs(cv.Y) > 1.4 then
                isStep = true
                stepCD = 0.22
            end
        end

        local cf = chest.CFrame
        local worldDown = Vector3.new(0, -1, 0)
        if Workspace.Gravity < 0.01 then worldDown = Vector3.zero end

        local centriWorld = av:Cross(av:Cross(cf.Position - rootPart.Position))

        local ctx = {
            localVel    = cf:VectorToObjectSpace(cv),
            localAccel  = cf:VectorToObjectSpace(accel),
            localDown   = cf:VectorToObjectSpace(worldDown),
            localCentri = cf:VectorToObjectSpace(centriWorld),
            turnRate    = turnRate,
            animMag     = animMag,
            tiltFwd     = math.clamp((1 - cf.UpVector.Y) * 5, 0, 0.5),
            hSpd        = Vector3.new(cv.X, 0, cv.Z).Magnitude,
            isStep      = isStep,
            t           = tick(),
        }

        accumulator = accumulator + dt
        local steps = 0
        while accumulator >= FIXED_DT and steps < MAX_STEPS do
            for _, d in pairs(activePads) do
                stepPad(d, FIXED_DT, ctx)
            end

            for _, d in pairs(activePads) do
                if d.sibling then
                    d.upper.vel = d.upper.vel
                        + (d.sibling.upper.vel - d.upper.vel) * d.prof.sideCouple * FIXED_DT
                end
            end

            if cfg.frontCollide and frontL and frontR then
                softCollide(frontL, frontR, cfg.frontSep * 0.014, 7)
            end
            if cfg.rearCollide and rearL and rearR then
                softCollide(rearL, rearR, cfg.rearSep * 0.012, 9)
            end

            accumulator = accumulator - FIXED_DT
            steps = steps + 1
            ctx.isStep = false
        end
        if steps >= MAX_STEPS then accumulator = 0 end

        if cfg.limbCollision and #limbs > 0 then
            for _, d in pairs(activePads) do
                local part = d.weld.Part1
                if part and part.Parent then
                    local pp = part.Position
                    for _, lp in ipairs(limbs) do
                        local sep  = pp - lp.Position
                        local dist = sep.Magnitude
                        local rad  = (lp.Size.Magnitude * 0.30) + (part.Size.Magnitude * 0.26)
                        if dist > 0.001 and dist < rad then
                            local pushW = sep.Unit * (rad - dist) * 2.2
                            d.upper.vel = d.upper.vel + cf:VectorToObjectSpace(pushW)
                        end
                    end
                end
            end
        end

        if humanoid.Sit and rearL and rearR then
            rearL.upper.vel = rearL.upper.vel + Vector3.new(0, 0.06, 0)
            rearR.upper.vel = rearR.upper.vel + Vector3.new(0, 0.06, 0)
        end

        for _, d in pairs(activePads) do
            if d.weld and d.weld.Parent then
                local pr = d.prof
                local blended = d.upper.pos:Lerp(d.lower.pos, pr.lagBlend)
                local lagVec  = d.lower.pos - d.upper.pos

                local extraPitch = math.clamp(lagVec.Y * pr.lagTilt, -pr.maxRot, pr.maxRot)
                local extraRoll  = math.clamp(lagVec.X * pr.lagTilt * 0.8, -pr.maxRot, pr.maxRot)

                d.weld.C0 = d.base * CFrame.new(blended) * CFrame.Angles(
                    d.rot.X + extraPitch,
                    d.rot.Y,
                    d.rot.Z + extraRoll
                )
            end
        end
    end)
end

local rebuildTask = nil
local function scheduleRebuild()
    if rebuildTask then task.cancel(rebuildTask) end
    rebuildTask = task.delay(0.28, function()
        if activeChar and activeChar.Parent then setupCharacter(activeChar) end
    end)
end

local Window = Onyx:CreateWindow({
    Title = "Body Physics",
    SubTitle = "v6.1",
    Size = UDim2.fromOffset(560, 520),
    Position = UDim2.fromScale(0.5, 0.5),
    Keybind = Enum.KeyCode.RightShift,
    OnClose = "hide",
    UnibarIcon = true,
    MobileButton = "auto",
})

local ChestTab = Window:CreateTab({ Title = "Chest", Default = true })
local CS = ChestTab:CreateSection("Shape")
local CD = ChestTab:CreateSection("Detail")
local CP = ChestTab:CreateSection("Physics")

CS:Toggle({ Title = "Enabled", Default = cfg.frontEnabled,
    Callback = function(v) cfg.frontEnabled = v ; scheduleRebuild() end })
CS:Slider({ Title = "Size", Min = 50, Max = 200, Default = cfg.frontSize, Increment = 5, Suffix = "%",
    Callback = function(v) cfg.frontSize = v ; scheduleRebuild() end })
CS:Slider({ Title = "Projection", Min = 50, Max = 400, Default = cfg.frontProjection, Increment = 5, Suffix = "%",
    Callback = function(v) cfg.frontProjection = v ; scheduleRebuild() end })
CS:Slider({ Title = "Height", Min = -30, Max = 30, Default = cfg.frontHeight, Increment = 1,
    Callback = function(v) cfg.frontHeight = v ; scheduleRebuild() end })
CS:Slider({ Title = "Separation", Min = 30, Max = 70, Default = cfg.frontSep, Increment = 2,
    Callback = function(v) cfg.frontSep = v ; scheduleRebuild() end })
CS:Toggle({ Title = "Auto Color (skin)", Default = cfg.frontAutoColor,
    Callback = function(v) cfg.frontAutoColor = v ; updatePadColors(activeChar) end })
CS:Colorpicker({ Title = "Color", Default = cfg.frontColor,
    Callback = function(c) cfg.frontColor = c ; if not cfg.frontAutoColor then updatePadColors(activeChar) end end })

CD:Segmented({ Title = "Detail", Values = { "None", "Nipple", "Areola", "Both" }, Default = cfg.nippleDetail,
    Callback = function(v) cfg.nippleDetail = v ; scheduleRebuild() end })
CD:Slider({ Title = "Detail Size", Min = 50, Max = 150, Default = cfg.nippleSize, Increment = 5, Suffix = "%",
    Callback = function(v) cfg.nippleSize = v ; scheduleRebuild() end })

CP:Slider({ Title = "Weight", Min = 0, Max = 100, Default = cfg.frontWeight, Increment = 5,
    Callback = function(v) cfg.frontWeight = v ; updateFrontProfs() end })
CP:Slider({ Title = "Reactivity", Min = 0, Max = 100, Default = cfg.frontReactivity, Increment = 5,
    Callback = function(v) cfg.frontReactivity = v ; updateFrontProfs() end })
CP:Toggle({ Title = "Collide", Default = cfg.frontCollide,
    Callback = function(v) cfg.frontCollide = v end })

local RearTab = Window:CreateTab({ Title = "Rear" })
local RS = RearTab:CreateSection("Shape")
local RP = RearTab:CreateSection("Physics")

RS:Toggle({ Title = "Enabled", Default = cfg.rearEnabled,
    Callback = function(v) cfg.rearEnabled = v ; scheduleRebuild() end })
RS:Slider({ Title = "Size", Min = 50, Max = 200, Default = cfg.rearSize, Increment = 5, Suffix = "%",
    Callback = function(v) cfg.rearSize = v ; scheduleRebuild() end })
RS:Slider({ Title = "Projection", Min = 50, Max = 400, Default = cfg.rearProjection, Increment = 5, Suffix = "%",
    Callback = function(v) cfg.rearProjection = v ; scheduleRebuild() end })
RS:Slider({ Title = "Height", Min = -40, Max = 10, Default = cfg.rearHeight, Increment = 1,
    Callback = function(v) cfg.rearHeight = v ; scheduleRebuild() end })
RS:Slider({ Title = "Separation", Min = 25, Max = 55, Default = cfg.rearSep, Increment = 2,
    Callback = function(v) cfg.rearSep = v ; scheduleRebuild() end })
RS:Toggle({ Title = "Auto Color (skin)", Default = cfg.rearAutoColor,
    Callback = function(v) cfg.rearAutoColor = v ; updatePadColors(activeChar) end })
RS:Colorpicker({ Title = "Color", Default = cfg.rearColor,
    Callback = function(c) cfg.rearColor = c ; if not cfg.rearAutoColor then updatePadColors(activeChar) end end })

RP:Slider({ Title = "Weight", Min = 0, Max = 100, Default = cfg.rearWeight, Increment = 5,
    Callback = function(v) cfg.rearWeight = v ; updateRearProfs() end })
RP:Slider({ Title = "Reactivity", Min = 0, Max = 100, Default = cfg.rearReactivity, Increment = 5,
    Callback = function(v) cfg.rearReactivity = v ; updateRearProfs() end })
RP:Toggle({ Title = "Collide", Default = cfg.rearCollide,
    Callback = function(v) cfg.rearCollide = v end })

local GenTab = Window:CreateTab({ Title = "General" })
local GS = GenTab:CreateSection("Controls")
local GV = GenTab:CreateSection("Visual")

GS:Toggle({ Title = "Physics Active", Default = cfg.physicsEnabled,
    Callback = function(v)
        cfg.physicsEnabled = v
        if not v then resetPadPositions() end
    end })
GS:Toggle({ Title = "Remove Clothing", Default = cfg.removeClothing,
    Callback = function(v)
        cfg.removeClothing = v
        if v and activeChar then clearClothing(activeChar) end
    end })
GS:Toggle({ Title = "React to Animations", Default = cfg.animReaction,
    Callback = function(v) cfg.animReaction = v end })
GS:Toggle({ Title = "Limb Collision", Default = cfg.limbCollision,
    Callback = function(v) cfg.limbCollision = v end })

GV:Toggle({ Title = "Match Skin Material", Default = cfg.matchMaterial,
    Callback = function(v) cfg.matchMaterial = v ; scheduleRebuild() end })
GV:Input({ Title = "Normal Map ID", Default = cfg.normalMapId, Placeholder = "rbxassetid://...",
    Callback = function(v) cfg.normalMapId = v ; scheduleRebuild() end })
GV:Input({ Title = "Roughness Map ID", Default = cfg.roughnessMapId, Placeholder = "rbxassetid://...",
    Callback = function(v) cfg.roughnessMapId = v ; scheduleRebuild() end })

GS:Button({ Title = "Rebuild Now",
    Callback = function()
        if activeChar and activeChar.Parent then
            setupCharacter(activeChar)
            Onyx:Notify({ Title = "Done", Type = "success", Duration = 2 })
        end
    end })

activeChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
task.wait(0.8)
setupCharacter(activeChar)

localPlayer.CharacterAdded:Connect(function(newChar)
    disconnectAll()
    task.wait(0.8)
    activeChar = newChar
    setupCharacter(activeChar)
end)

localPlayer.CharacterRemoving:Connect(function()
    disconnectAll()
    activePads = nil
end)

Onyx:Notify({ Title = "Body Physics v6.1", Content = "RightShift for settings", Duration = 4 })
print("Body Physics v6.1 loaded")
