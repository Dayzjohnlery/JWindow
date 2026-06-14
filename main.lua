local Library = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("JWindowGui")
if oldGui then
	oldGui:Destroy()
end

-- Shared ScreenGui container for all windows created by this script
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JWindowGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create Window Function
function Library:CreateWindow(config)
	local windowName = config.Name or "Window"
	local windowWidth = config.Width or 250
	local headerHeight = 35
	local padding = 15
	
	-- Main Window Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainWindow_" .. windowName
	mainFrame.Size = UDim2.new(0, windowWidth, 0, headerHeight + padding)
	mainFrame.Position = UDim2.new(0.5, -windowWidth/2, 0.5, -50)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	mainFrame.BackgroundTransparency = 0.3 -- Transparent background
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = screenGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = mainFrame

	-- Header Bar (For Dragging)
	local headerBar = Instance.new("Frame")
	headerBar.Name = "Header"
	headerBar.Size = UDim2.new(1, 0, 0, headerHeight)
	headerBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	headerBar.BackgroundTransparency = 0.3
	headerBar.BorderSizePixel = 0
	headerBar.Parent = mainFrame

	local headerTitle = Instance.new("TextLabel")
	headerTitle.Name = "Title"
	headerTitle.Size = UDim2.new(1, -50, 1, 0)
	headerTitle.Position = UDim2.new(0, 15, 0, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = windowName
	headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	headerTitle.Font = Enum.Font.GothamBold
	headerTitle.TextSize = 14
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Parent = headerBar

	-- Collapse Button
	local collapseBtn = Instance.new("TextButton")
	collapseBtn.Name = "CollapseButton"
	collapseBtn.Size = UDim2.new(0, 35, 1, 0)
	collapseBtn.Position = UDim2.new(1, -35, 0, 0)
	collapseBtn.BackgroundTransparency = 1
	collapseBtn.Text = "-"
	collapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	collapseBtn.Font = Enum.Font.GothamBold
	collapseBtn.TextSize = 18
	collapseBtn.Parent = headerBar

	-- Content Frame Container
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, -30, 0, 0)
	contentContainer.Position = UDim2.new(0, 15, 0, headerHeight + 10)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = contentContainer

	-- Dynamic Height Handler 
	local isCollapsed = false
	local expandedSize = mainFrame.Size
	local collapsedSize = UDim2.new(0, windowWidth, 0, headerHeight)
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	-- Automatically scales the window length when text is added or changed
	local function updateWindowHeight()
		local contentHeight = listLayout.AbsoluteContentSize.Y
		expandedSize = UDim2.new(0, windowWidth, 0, headerHeight + contentHeight + (padding * 2))
		
		if not isCollapsed then
			TweenService:Create(mainFrame, TweenInfo.new(0.15), {Size = expandedSize}):Play()
		end
	end

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateWindowHeight)

	-- Collapse Click Action
	collapseBtn.MouseButton1Click:Connect(function()
		isCollapsed = not isCollapsed
		collapseBtn.Text = isCollapsed and "+" or "-"
		
		local targetSize = isCollapsed and collapsedSize or expandedSize
		TweenService:Create(mainFrame, tweenInfo, {Size = targetSize}):Play()
	end)

	-- Dragging Logic (PC & Mobile)
	local dragging, dragInput, dragStart, startPos
	headerBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	headerBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	-- Window Functions Object
	local WindowInstance = {}
	local elements = {}

	-- Add Text Label Function
	function WindowInstance:AddLabel(id, initialText, textColor)
		local textLine = Instance.new("TextLabel")
		textLine.Name = id
		-- Width fills window minus padding, Height automatically adjusts to text lengths/wrapping
		textLine.Size = UDim2.new(1, 0, 0, 0)
		textLine.AutomaticSize = Enum.AutomaticSize.Y
		textLine.BackgroundTransparency = 1
		textLine.Text = initialText

		textLine.TextColor3 = textColor or Color3.fromRGB(220, 220, 220)
		
		textLine.Font = Enum.Font.GothamMedium
		textLine.TextSize = 18
		textLine.TextXAlignment = Enum.TextXAlignment.Left
		textLine.TextWrapped = true -- Text wraps seamlessly inside your custom width
		textLine.Parent = contentContainer

		elements[id] = textLine
		return textLine
	end

	-- Update Text Label Function (with optional color update)
	function WindowInstance:UpdateLabel(id, newText, textColor)
		if elements[id] then
			if newText then
				elements[id].Text = newText
			end
			if textColor then
				elements[id].TextColor3 = textColor
			end
		else
			warn("Label with ID '" .. tostring(id) .. "' does not exist in this window.")
		end
	end

	-- Destroy Window Function
	function WindowInstance:Destroy()
		if mainFrame then
			mainFrame:Destroy()
			elements = nil -- Clear element references from memory
		end
	end

	return WindowInstance
end

return Library
