-- services

-- constants

local CHARACTER	= script.Parent
local HUMANOID	= CHARACTER.Humanoid

-- variables

local motors	= {
	Head		= {"Neck"};
	UpperTorso	= {"Waist"};
	RightUpperArm	= {"RightShoulder"};
	RightLowerArm	= {"RightElbow"};
	RightHand		= {"RightWrist"};
	LeftUpperArm	= {"LeftShoulder"};
	LeftLowerArm	= {"LeftElbow"};
	LeftHand		= {"LeftWrist"};
	RightUpperLeg	= {"RightHip"};
	RightLowerLeg	= {"RightKnee"};
	RightFoot		= {"RightAnkle"};
	LeftUpperLeg	= {"LeftHip"};
	LeftLowerLeg	= {"LeftKnee"};
	LeftFoot		= {"LeftAnkle"};
}

local sockets	= {}

-- functions

-- initiate

for part, joints in pairs(motors) do
	for _, m in pairs(joints) do
		local motor		= CHARACTER[part][m]
		
		local attachA	= Instance.new("Attachment")
			attachA.Name		= motor.Name .. "A"
			attachA.CFrame		= motor.C0
			attachA.Parent		= motor.Part0
			
		local attachB	= Instance.new("Attachment")
			attachB.Name		= motor.Name .. "B"
			attachB.CFrame		= motor.C1
			attachB.Parent		= motor.Part1
		
		local socket	= Instance.new("BallSocketConstraint")
			socket.Name			= motor.Name .. "Socket"
			socket.Attachment0	= attachA
			socket.Attachment1	= attachB
			socket.Enabled		= false
			socket.Parent		= motor.Part1
			
		sockets[motor]	= socket
	end
end

-- events

HUMANOID.Died:connect(function()
	for motor, socket in pairs(sockets) do
		socket.Enabled	= true
		motor.Part1		= nil
	end
end)