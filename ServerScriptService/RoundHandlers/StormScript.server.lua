-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local TweenService		= game:GetService("TweenService")
local Players			= game:GetService("Players")

-- constants

local STORM		= ReplicatedStorage.Storm
local REMOTES	= ReplicatedStorage.Remotes

local MAP_RADIUS	= 4700

-- variables

local finalPosition	= Vector3.new(math.random(-MAP_RADIUS * 0.4, MAP_RADIUS * 0.4), 0, math.random(-MAP_RADIUS * 0.4, MAP_RADIUS * 0.4))

-- functions

local function Lerp(a, b, d) return a + (b - a) * d end

local function MoveToTarget(t)
	local info		= TweenInfo.new(t, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tweenA	= TweenService:Create(STORM.Center, info, {Value = STORM.TargetCenter.Value})
	local tweenB	= TweenService:Create(STORM.Radius, info, {Value = STORM.TargetRadius.Value})
	
	tweenA:Play()
	tweenB:Play()
end

local function SetTarget(p, r)
	STORM.TargetCenter.Value	= p
	STORM.TargetRadius.Value	= r
end
	
local function Timer(t)
	for i = t, 0, -1 do
		STORM.Timer.Value	= i
		wait(1)
	end
end

local function GetRandomPosition(newRadius)
	local center	= STORM.Center.Value
	local maxDist	= STORM.Radius.Value - newRadius
	
	local offset	= finalPosition - center
	local direction	= Vector3.new()
	if offset.Magnitude > 1 then
		direction	= offset.Unit
	end
	local distance	= offset.Magnitude
	
	return center + direction * math.min(distance, maxDist)
end

local function RunSequence()
	REMOTES.RoundInfo:FireAllClients("Message", "Storm is forming in 1 minute")
	SetTarget(Vector3.new(), MAP_RADIUS)
	MoveToTarget(60)
	Timer(60)
	
	REMOTES.RoundInfo:FireAllClients("Message", "Storm is shrinking in 1 minute")
	SetTarget(GetRandomPosition(MAP_RADIUS * 0.8), MAP_RADIUS * 0.8)
	Timer(60)
	REMOTES.RoundInfo:FireAllClients("Message", "Storm is closing in")
	MoveToTarget(60)
	Timer(60)
	
	REMOTES.RoundInfo:FireAllClients("Message", "Storm is shrinking in 1 minute")
	SetTarget(GetRandomPosition(MAP_RADIUS * 0.6), MAP_RADIUS * 0.6)
	Timer(60)
	REMOTES.RoundInfo:FireAllClients("Message", "Storm is closing in")
	MoveToTarget(60)
	Timer(60)
	
	REMOTES.RoundInfo:FireAllClients("Message", "Storm is shrinking in 1 minute")
	SetTarget(GetRandomPosition(MAP_RADIUS * 0.35), MAP_RADIUS * 0.35)
	Timer(60)
	REMOTES.RoundInfo:FireAllClients("Message", "Storm is closing in")
	MoveToTarget(60)
	Timer(60)
	
	REMOTES.RoundInfo:FireAllClients("Message", "Storm is shrinking in 1 minute")
	SetTarget(GetRandomPosition(MAP_RADIUS * 0.1), MAP_RADIUS * 0.1)
	Timer(60)
	REMOTES.RoundInfo:FireAllClients("Message", "Storm is closing in")
	MoveToTarget(60)
	Timer(60)
	
	REMOTES.RoundInfo:FireAllClients("Message", "Storm is collapsing in 30 seconds")
	SetTarget(GetRandomPosition(0), 0)
	Timer(30)
	REMOTES.RoundInfo:FireAllClients("Message", "Storm is collapsing")
	MoveToTarget(30)
	Timer(30)
end

-- initiate

STORM.Radius.Value			= 100000
STORM.TargetRadius.Value	= 100000

STORM.Center.Value			= Vector3.new()
STORM.TargetCenter.Value	= Vector3.new()

-- events

script.RunSequence.Event:connect(RunSequence)

-- loop

while true do
	wait(1)
	
	local center	= Vector3.new(STORM.Center.Value.X, 0, STORM.Center.Value.Z)
	local alpha		= math.clamp(STORM.Radius.Value / 2000 + 0.1, 0, 1)
	local damage	= Lerp(10, 2, alpha)
	
	for _, player in pairs(Players:GetPlayers()) do
		local character	= player.Character
		if character then
			local humanoid	= character:FindFirstChildOfClass("Humanoid")
			
			if humanoid and humanoid.Health > 0 then
				local rootPart	= character:FindFirstChild("HumanoidRootPart")
				
				if rootPart then
					local distance	= (center - Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)).Magnitude
					
					if distance > STORM.Radius.Value then
						if humanoid:FindFirstChild("KillTag") then
							humanoid.KillTag:Destroy()
						end
						humanoid:TakeDamage(damage)
					end
				end
			end
		end
	end
end