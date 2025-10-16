-- SawMillHub.lua (LocalScript)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SawMillHub = {}
SawMillHub.__index = SawMillHub

-- ======== FUNÇÕES AUXILIARES ========

local function create(class, props)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			pcall(function() inst[k] = v end)
		end
	end
	return inst
end

local function safePropertyExists(obj, propName)
	local ok, _ = pcall(function() local _ = obj[propName] end)
	return ok
end

local function tween(obj, time, props, style, direction)
	style = style or Enum.EasingStyle.Quad
	direction = direction or Enum.EasingDirection.Out
	local ok, t = pcall(function()
		return TweenService:Create(obj, TweenInfo.new(time, style, direction), props)
	end)
	if ok and t then t:Play() end
end

-- ======== DRAG & RESIZE ========

local function enableDragging(topBar, mainFrame, dragSpeed)
	if not topBar or not mainFrame then return end

	local resizeHandle = create("Frame", {
		Parent = mainFrame,
		Size = UDim2.new(0, 16, 0, 16),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -3, 1, -3),
		BackgroundColor3 = Color3.fromRGB(80, 80, 80),
		BackgroundTransparency = 0.4,
		Name = "ResizeHandle",
		ZIndex = 20
	})
	create("UICorner", { Parent = resizeHandle, CornerRadius = UDim.new(0, 4) })
	create("UIStroke", { Parent = resizeHandle, Color = Color3.fromRGB(130, 130, 130), Thickness = 1.2 })

	local resizing = false
	local startSize, startInputPos

	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			startSize = mainFrame.Size
			startInputPos = input.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then resizing = false end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startInputPos
			local maxW = workspace.CurrentCamera.ViewportSize.X - 50
			local maxH = workspace.CurrentCamera.ViewportSize.Y - 50
			local newWidth = math.max(math.min(startSize.X.Offset + delta.X, maxW), 300)
			local newHeight = math.max(math.min(startSize.Y.Offset + delta.Y, maxH), 200)
			mainFrame.Size = UDim2.new(startSize.X.Scale, newWidth, startSize.Y.Scale, newHeight)
		end
	end)

	resizeHandle.MouseEnter:Connect(function()
		TweenService:Create(resizeHandle, TweenInfo.new(0.15), {
			BackgroundTransparency = 0.2,
			BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		}):Play()
	end)

	resizeHandle.MouseLeave:Connect(function()
		if not resizing then
			TweenService:Create(resizeHandle, TweenInfo.new(0.15), {
				BackgroundTransparency = 0.4,
				BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			}):Play()
		end
	end)

	local dragging = false
	local dragStart, startPos
	local speed = dragSpeed == "Slow" and 0.2 or 1

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			if speed < 1 then
				tween(mainFrame, speed, { Position = newPos })
			else
				mainFrame.Position = newPos
			end
		end
	end)
end

-- ======== FECHAR HUB ========

function SawMillHub:Close()
	if not self.Gui or not self.Main or self._IsClosing then return end
	self._IsClosing = true
	pcall(function() self.OnClose:Fire() end)

	tween(self.Main, 0.28, {
		Size = UDim2.new(
			self.Main.Size.X.Scale, math.max(2, math.floor(self.Main.Size.X.Offset * 0.9)),
			self.Main.Size.Y.Scale, math.max(2, math.floor(self.Main.Size.Y.Offset * 0.9))
		),
		BackgroundTransparency = 1
	})

	for _, child in ipairs(self.Main:GetDescendants()) do
		if child:IsA("GuiObject") then
			local props = {}
			if safePropertyExists(child, "BackgroundTransparency") then props.BackgroundTransparency = 1 end
			if (child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox")) and safePropertyExists(child, "TextTransparency") then
				props.TextTransparency = 1
			end
			if (child:IsA("ImageLabel") or child:IsA("ImageButton")) and safePropertyExists(child, "ImageTransparency") then
				props.ImageTransparency = 1
			end
			if child:IsA("UIStroke") and safePropertyExists(child, "Transparency") then
				props.Transparency = 1
			end
			if next(props) then tween(child, 0.22, props) end
		end
	end

	task.delay(0.34, function()
		if self.Gui and self.Gui.Parent then pcall(function() self.Gui:Destroy() end) end
		self._IsClosing = false
	end)
end

-- ======== MINIMIZAR / RESTAURAR ========

function SawMillHub:ToggleMinimize()
	if not self.Main then return end

	local main = self.Main
	local btn = self.MinimizeButton
	local mainSize = self._OriginalSize or UDim2.new(0, 450, 0, 300)

	if self._Minimized then
		tween(main, 0.35, { Size = mainSize }, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
		if btn then
			btn.Text = "–"
			btn.BackgroundColor3 = Color3.fromRGB(255, 190, 60)
		end
		self._Minimized = false
	else
		if not self._OriginalSize then self._OriginalSize = main.Size end
		local newSize = UDim2.new(self._OriginalSize.X.Scale, self._OriginalSize.X.Offset, 0, 42)
		tween(main, 0.35, { Size = newSize }, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
		if btn then
			btn.Text = "+"
			btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		end
		self._Minimized = true
	end
end

-- ======== CONSTRUTOR COMPLETO ========

function SawMillHub.new(title, dragSpeed)
	dragSpeed = dragSpeed or "Default"
	local self = setmetatable({}, SawMillHub)

	self.OnClose = Instance.new("BindableEvent")
	self.Gui = create("ScreenGui", { Name = "SawMillHub", ResetOnSpawn = false, Parent = PlayerGui })
	create("ObjectValue", { Parent = self.Gui, Name = "SawMillHubObject", Value = self, Archivable = false })

	local mainSize = UDim2.new(0, 450, 0, 300)
	local mainPos = UDim2.new(0.5, -mainSize.X.Offset / 2, 0.5, -mainSize.Y.Offset / 2)
	self.Main = create("Frame", {
		Parent = self.Gui,
		Size = UDim2.new(0, 0, 0, 0),
		Position = mainPos,
		BackgroundColor3 = Color3.fromRGB(28, 28, 28),
		ClipsDescendants = true,
		Name = "Main"
	})
	create("UICorner", { Parent = self.Main, CornerRadius = UDim.new(0, 12) })
	local mainStroke = create("UIStroke", { Parent = self.Main, Color = Color3.fromRGB(90, 90, 90), Thickness = 1.6 })

	self._OriginalSize = mainSize
	self._Minimized = false

	local topBar = create("Frame", {
		Parent = self.Main,
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		Name = "TopBar"
	})
	create("UICorner", { Parent = topBar, CornerRadius = UDim.new(0, 12) })

	local titleLabel = create("TextLabel", {
		Parent = topBar,
		Text = title or "SawMillHub",
		Size = UDim2.new(1, -110, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		TextColor3 = Color3.fromRGB(245, 245, 245),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		Name = "TitleLabel"
	})

	self.Sidebar = create("Frame", {
		Parent = self.Main,
		Size = UDim2.new(0, 140, 1, -42),
		Position = UDim2.new(0, 0, 0, 42),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		Name = "Sidebar"
	})
	create("UICorner", { Parent = self.Sidebar, CornerRadius = UDim.new(0, 8) })

	self.TabHolder = create("Frame", {
		Parent = self.Main,
		Size = UDim2.new(1, -140, 1, -42),
		Position = UDim2.new(0, 140, 0, 42),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		Name = "TabHolder"
	})
	create("UICorner", { Parent = self.TabHolder, CornerRadius = UDim.new(0, 8) })

	self.Tabs, self.Keybinds, self.Notifs = {}, {}, {}
	self.MaxNotifs = 5

	local function animateButton(btn, baseColor, hoverColor)
		btn.MouseEnter:Connect(function()
			tween(btn, 0.15, { BackgroundColor3 = hoverColor, Size = UDim2.new(0, 36, 0, 36) })
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, 0.15, { BackgroundColor3 = baseColor, Size = UDim2.new(0, 32, 0, 32) })
		end)
		btn.MouseButton1Down:Connect(function()
			tween(btn, 0.1, { Size = UDim2.new(0, 28, 0, 28) })
		end)
		btn.MouseButton1Up:Connect(function()
			tween(btn, 0.1, { Size = UDim2.new(0, 32, 0, 32) })
		end)
	end

	-- MINIMIZE BUTTON
	local minimizeButton = create("TextButton", {
		Parent = topBar,
		Text = "–",
		Size = UDim2.new(0, 32, 0, 32),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -44, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 190, 60),
		TextColor3 = Color3.fromRGB(10, 10, 10),
		Font = Enum.Font.GothamBold,
		TextSize = 24,
		AutoButtonColor = false,
		Name = "MinimizeButton"
	})
	create("UICorner", { Parent = minimizeButton, CornerRadius = UDim.new(0, 8) })
	minimizeButton.MouseButton1Click:Connect(function()
		self:ToggleMinimize()
	end)
	animateButton(minimizeButton, Color3.fromRGB(255, 190, 60), Color3.fromRGB(255, 220, 80))
	self.MinimizeButton = minimizeButton

	-- CLOSE BUTTON
	local closeButton = create("TextButton", {
		Parent = topBar,
		Text = "X",
		Size = UDim2.new(0, 32, 0, 32),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(235, 75, 75),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		AutoButtonColor = false,
		Name = "CloseButton"
	})
	create("UICorner", { Parent = closeButton, CornerRadius = UDim.new(0, 8) })
	closeButton.MouseButton1Click:Connect(function() self:Close() end)
	animateButton(closeButton, Color3.fromRGB(235, 75, 75), Color3.fromRGB(255, 95, 95))

	-- RESET BUTTON
	local resetButton = create("TextButton", {
		Parent = topBar,
		Size = UDim2.new(0, 32, 0, 32),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -82, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(90, 170, 255),
		Text = "R",
		TextColor3 = Color3.fromRGB(10, 10, 10),
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		AutoButtonColor = false,
		Name = "ResetButton"
	})
	create("UICorner", { Parent = resetButton, CornerRadius = UDim.new(0, 8) })
	resetButton.MouseButton1Click:Connect(function()
		local pulseSize = UDim2.new(mainSize.X.Scale, mainSize.X.Offset * 1.15, mainSize.Y.Scale, mainSize.Y.Offset * 1.15)
		tween(self.Main, 0.25, { Size = pulseSize }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(0.25, function()
			tween(self.Main, 0.25, { Size = mainSize }, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
		end)
		self._OriginalSize = mainSize
	end)
	animateButton(resetButton, Color3.fromRGB(90, 170, 255), Color3.fromRGB(120, 200, 255))

	-- ENABLE DRAGGING
	enableDragging(topBar, self.Main, dragSpeed)

	-- RAINBOW BORDER
	local hue = 0
	RunService.RenderStepped:Connect(function(dt)
		hue = (hue + dt * 0.08) % 1
		if mainStroke then mainStroke.Color = Color3.fromHSV(hue, 0.9, 1) end
		if titleLabel then titleLabel.TextColor3 = Color3.fromHSV(hue, 1, 1) end
	end)

	-- ANIMAÇÃO DE ABERTURA
	tween(self.Main, 0.4, { Size = mainSize }, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)

	return self
end

--// 🌈 SawMillHub:CreateTab - Cria uma aba estilosa com animações e efeitos visuais
function SawMillHub:CreateTab(tabName, icon)
	-- Área de scroll lateral (criada apenas uma vez)
	if not self.TabScroll then
		local scroll = create("ScrollingFrame", {
			Parent = self.Sidebar,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y
		})

		create("UIListLayout", {
			Parent = scroll,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center
		})

		create("UIPadding", {
			Parent = scroll,
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8)
		})

		self.TabScroll = scroll
	end

	local tabWidth, tabHeight = 150, 40

	-- Botão da aba
	local btn = create("TextButton", {
		Parent = self.TabScroll,
		Text = (icon and icon .. " " or "") .. tabName,
		Size = UDim2.new(0, tabWidth, 0, tabHeight),
		BackgroundColor3 = Color3.fromRGB(55, 55, 55),
		TextColor3 = Color3.fromRGB(220, 220, 220),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AutoButtonColor = false
	})
	create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 10) })
	create("UIStroke", { Parent = btn, Color = Color3.fromRGB(90, 90, 90), Thickness = 1, Transparency = 0.5 })

	-- Indicador lateral colorido
	local indicator = create("Frame", {
		Parent = btn,
		Size = UDim2.new(0, 4, 0.8, 0),
		Position = UDim2.new(0, 0, 0.1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		Visible = false,
		ZIndex = 5
	})
	create("UICorner", { Parent = indicator, CornerRadius = UDim.new(0, 2) })

	-- Container da aba
	local cont = create("ScrollingFrame", {
		Parent = self.TabHolder,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y
	})
	create("UIListLayout", { Parent = cont, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
	create("UIPadding", {
		Parent = cont,
		PaddingTop = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8)
	})

	local tab = {
		Name = tabName,
		Button = btn,
		Container = cont,
		Indicator = indicator
	}
	self.Tabs[tabName] = tab

	-- 🌈 Animação suave de arco-íris no indicador ativo
	local hue = 0
	RunService.RenderStepped:Connect(function(dt)
		hue = (hue + dt * 0.1) % 1
		if indicator.Visible then
			indicator.BackgroundColor3 = Color3.fromHSV(hue, 0.9, 1)
		end
	end)

	-- 🎨 Funções de animação
	local function hoverAnim(button, hover)
		local target = hover and Color3.fromRGB(75, 75, 75) or Color3.fromRGB(55, 55, 55)
		tween(button, 0.15, { BackgroundColor3 = target })
	end

	local function clickAnim(button)
		tween(button, 0.08, { Size = UDim2.new(0, tabWidth, 0, tabHeight - 4) })
		task.delay(0.08, function()
			tween(button, 0.1, { Size = UDim2.new(0, tabWidth, 0, tabHeight) })
		end)
	end

	local function glowText(button, active)
		local target = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
		tween(button, 0.25, { TextColor3 = target })
	end

	local function pulseIndicator(frame)
		task.spawn(function()
			while frame.Visible do
				tween(frame, 0.4, { Size = UDim2.new(0, 4, 0.85, 0) })
				task.wait(0.4)
				tween(frame, 0.4, { Size = UDim2.new(0, 4, 0.8, 0) })
				task.wait(0.4)
			end
		end)
	end

	local function spawnParticles(button)
		local p = create("Frame", {
			Parent = button,
			Size = UDim2.new(0, 4, 0, 4),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(math.random(), 0, math.random(), 0),
			ZIndex = 10,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.5
		})
		create("UICorner", { Parent = p, CornerRadius = UDim.new(0, 2) })
		tween(p, 0.6, {
			Position = UDim2.new(math.random(), 0, math.random(), 0),
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 0, 0, 0)
		})
		task.delay(0.6, function()
			pcall(function() p:Destroy() end)
		end)
	end

	-- 🖱️ Eventos de interação
	btn.MouseEnter:Connect(function()
		if self.CurrentTab ~= tab then hoverAnim(btn, true) end
	end)

	btn.MouseLeave:Connect(function()
		if self.CurrentTab ~= tab then hoverAnim(btn, false) end
	end)

	btn.MouseButton1Click:Connect(function()
		clickAnim(btn)
		spawnParticles(btn)

		-- Oculta as outras abas
		for _, t in pairs(self.Tabs) do
			t.Container.Visible = false
			t.Indicator.Visible = false
			hoverAnim(t.Button, false)
			glowText(t.Button, false)
		end

		-- Exibe a aba clicada
		cont.Visible = true
		indicator.Visible = true
		glowText(btn, true)
		hoverAnim(btn, true)
		pulseIndicator(indicator)

		self.CurrentTab = tab
	end)

	-- 🟢 Define a primeira aba como ativa
	if not self.CurrentTab then
		cont.Visible = true
		indicator.Visible = true
		glowText(btn, true)
		pulseIndicator(indicator)
		self.CurrentTab = tab
		btn.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
	end

	self:UpdateScrolling(tab)
	return tab
end

-- ======== UPDATE SCROLLING ========
function SawMillHub:UpdateScrolling(tab)
	if type(tab) == "string" then tab = self.Tabs[tab] end
	if not tab or not tab.Container then return end

	local container = tab.Container
	if not container:IsA("ScrollingFrame") then return end

	local layout = container:FindFirstChildOfClass("UIListLayout")
	local padding = container:FindFirstChildOfClass("UIPadding")

	local topPad = (padding and (padding.PaddingTop.Offset or 0)) or 0
	local bottomPad = (padding and (padding.PaddingBottom.Offset or 0)) or 0

	local function applyCanvas(y)
		container.CanvasSize = UDim2.new(0, 0, 0, math.max(0, math.floor(y + 0.5)))
	end

	local function update()
		if layout then
			local contentSize = layout.AbsoluteContentSize.Y
			local total = contentSize + topPad + bottomPad + 8
			applyCanvas(total)
		else
			local total = topPad + bottomPad + 8
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("GuiObject") and child.Visible then
					total = total + (child.AbsoluteSize.Y > 0 and child.AbsoluteSize.Y or (child.Size.Y.Offset or 0))
				end
			end
			applyCanvas(total)
		end
	end

	update()
	if layout and not layout:GetAttribute("ScrollLinked") then
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
		layout:SetAttribute("ScrollLinked", true)
	end
end

function SawMillHub:CreateSlider(tab, text, min, max, increment, default, callback)
	if not self.Tabs[tab] then return end
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local Debris = game:GetService("Debris")

	min, max = tonumber(min) or 0, tonumber(max) or 100
	increment = tonumber(increment) or 1
	default = math.clamp(default or min, min, max)
	local currentValue = default
	local dragging, draggingInput, lastUpdate = false, nil, 0
	local throttle = 1/120

	local function roundIncrement(v)
		if increment>0 then return math.clamp(math.floor((v+increment/2)/increment)*increment, min, max) else return math.clamp(v, min, max) end
	end

	-- FRAME
	local frame = create("Frame",{Parent=self.Tabs[tab].Container,Size=UDim2.new(1,-10,0,60),BackgroundColor3=Color3.fromRGB(18,18,28)})
	create("UICorner",{Parent=frame,CornerRadius=UDim.new(0,12)})
	create("UIStroke",{Parent=frame,Color=Color3.fromRGB(40,40,60),Transparency=0.5,Thickness=1})

	-- LABEL
	local lbl = create("TextLabel",{Parent=frame,Text=string.format("%s: %d",text,default),Position=UDim2.new(0,14,0,6),Size=UDim2.new(1,-100,0,20),BackgroundTransparency=1,TextColor3=Color3.fromRGB(180,120,255),Font=Enum.Font.GothamSemibold,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left})

	-- INPUT BOX
	local inputBox = create("TextBox",{Parent=frame,Size=UDim2.new(0,52,0,26),AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8,0,6),Text=tostring(default),BackgroundColor3=Color3.fromRGB(28,28,40),TextColor3=Color3.fromRGB(180,120,255),Font=Enum.Font.GothamBold,TextSize=14,ClearTextOnFocus=false})
	create("UICorner",{Parent=inputBox,CornerRadius=UDim.new(0,7)})
	create("UIStroke",{Parent=inputBox,Color=Color3.fromRGB(120,80,255),Transparency=0.5,Thickness=1})

	-- BAR
	local bar = create("Frame",{Parent=frame,Position=UDim2.new(0,14,0,36),Size=UDim2.new(1,-28,0,10),BackgroundColor3=Color3.fromRGB(25,25,35)})
	create("UICorner",{Parent=bar,CornerRadius=UDim.new(0,5)})
	local track = create("Frame",{Parent=bar,Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(20,20,30),ZIndex=1})
	create("UICorner",{Parent=track,CornerRadius=UDim.new(0,5)})

	local hitbox = create("TextButton",{Parent=bar,Size=UDim2.new(1,20,2,0),Position=UDim2.new(0,-10,0,-5),BackgroundTransparency=1,AutoButtonColor=false,Text=""})
	hitbox.ZIndex = 6

	-- FILL
	local fill = create("Frame",{Parent=bar,Size=UDim2.new((default-min)/(max-min),0,1,0),BackgroundColor3=Color3.fromRGB(120,80,255),ZIndex=3})
	create("UICorner",{Parent=fill,CornerRadius=UDim.new(0,5)})
	local fillGrad = create("UIGradient",{Parent=fill,Color=ColorSequence.new{
		ColorSequenceKeypoint.new(0,Color3.fromRGB(120,80,255)),
		ColorSequenceKeypoint.new(0.5,Color3.fromRGB(60,60,180)),
		ColorSequenceKeypoint.new(1,Color3.fromRGB(40,40,120))
	},Rotation=0})

	-- THUMB
	local thumb = create("Frame",{Parent=bar,Size=UDim2.new(0,20,0,20),Position=UDim2.new(fill.Size.X.Scale,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.fromRGB(200,150,255),ZIndex=7})
	create("UICorner",{Parent=thumb,CornerRadius=UDim.new(1,0)})
	create("UIStroke",{Parent=thumb,Color=Color3.fromRGB(150,100,255),Transparency=0.3,Thickness=1})
	local thumbGlow = create("ImageLabel",{Parent=thumb,Size=UDim2.new(3,0,3,0),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),Image="rbxassetid://5028857084",BackgroundTransparency=1,ImageTransparency=0.7,ImageColor3=Color3.fromRGB(180,120,255),ZIndex=1})

	-- TOOLTIP
	local tooltip = create("TextLabel",{Parent=frame,Size=UDim2.new(0,64,0,28),BackgroundColor3=Color3.fromRGB(18,18,28),BackgroundTransparency=0.85,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(fill.Size.X.Scale,0,0,14),Text=tostring(default),TextColor3=Color3.fromRGB(200,150,255),Font=Enum.Font.GothamBold,TextSize=13,ZIndex=10,Visible=false})
	create("UICorner",{Parent=tooltip,CornerRadius=UDim.new(0,8)})

	-- PARTICLES & PULSE
	local function spawnParticle(pct)
		local p = create("Frame",{Parent=bar,Size=UDim2.new(0,6,0,6),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(pct,0,0.5,0),BackgroundColor3=Color3.fromRGB(200,150,255),BackgroundTransparency=0.1,ZIndex=8})
		create("UICorner",{Parent=p,CornerRadius=UDim.new(1,0)})
		TweenService:Create(p,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1}):Play()
		task.delay(0.4,function() p:Destroy() end)
	end
	local function pulse(positionUDim)
		local p = create("ImageLabel",{Parent=bar,Image="rbxassetid://5028857084",Size=UDim2.new(0,0,0,0),AnchorPoint=Vector2.new(0.5,0.5),Position=positionUDim,ImageColor3=fill.BackgroundColor3,BackgroundTransparency=1,ImageTransparency=0.35,ZIndex=5})
		TweenService:Create(p,TweenInfo.new(0.44,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Size=UDim2.new(0,60,0,60),ImageTransparency=1}):Play()
		task.delay(0.44,function() p:Destroy() end)
	end

	-- UPDATE
	local function _update(val,instant,fromUser)
		val = roundIncrement(val)
		if val==currentValue and not instant then return end
		currentValue=val
		local pct = (max~=min) and (val-min)/(max-min) or 0
		TweenService:Create(fill,TweenInfo.new((instant and 0 or 0.22),Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(pct,0,1,0)}):Play()
		TweenService:Create(thumb,TweenInfo.new((instant and 0 or 0.22),Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(pct,0,0.5,0)}):Play()
		lbl.Text=string.format("%s: %d",text,val)
		inputBox.Text=tostring(val)
		tooltip.Position=UDim2.new(pct,0,0,14)
		tooltip.Text=tostring(val)
		spawnParticle(pct)
		pulse(UDim2.new(pct,0,0.5,0))
		if callback then task.spawn(callback,val) end
	end

	-- EVENTS
	inputBox.FocusLost:Connect(function()
		local n = tonumber(inputBox.Text)
		if n then _update(n,true,true) else inputBox.Text=tostring(currentValue) end
	end)
	local function positionToValue(x)
		local left, width = bar.AbsolutePosition.X, bar.AbsoluteSize.X
		return math.clamp((x-left)/math.max(1,width),0,1)*(max-min)+min
	end

	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true
			draggingInput=input
			tooltip.Visible=true
			TweenService:Create(tooltip,TweenInfo.new(0.16,Enum.EasingStyle.Quad),{BackgroundTransparency=0.85,TextTransparency=0}):Play()
			local pos=input.Position or UserInputService:GetMouseLocation()
			_update(positionToValue(pos.X),false,true)
			thumb.Size=UDim2.new(0,22,0,22)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input~=draggingInput then
			if not (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then return end
		end
		if tick()-lastUpdate<throttle then return end
		lastUpdate=tick()
		local pos=input.Position or UserInputService:GetMouseLocation()
		local newVal=positionToValue(pos.X)
		_update(newVal,false,true)
		tooltip.Text=tostring(roundIncrement(newVal))
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input==draggingInput or (dragging and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch)) then
			dragging=false
			draggingInput=nil
			local pct=(max~=min) and (currentValue-min)/(max-min) or 0
			pulse(UDim2.new(pct,0,0.5,0))
			TweenService:Create(tooltip,TweenInfo.new(0.18,Enum.EasingStyle.Quad),{BackgroundTransparency=0.85,TextTransparency=0.9}):Play()
			task.delay(0.2,function() tooltip.Visible=false end)
			thumb.Size=UDim2.new(0,20,0,20)
		end
	end)

	thumb.MouseEnter:Connect(function()
		TweenService:Create(thumb,TweenInfo.new(0.16,Enum.EasingStyle.Quad),{Size=UDim2.new(0,22,0,22)}):Play()
	end)
	thumb.MouseLeave:Connect(function()
		if not dragging then
			TweenService:Create(thumb,TweenInfo.new(0.16,Enum.EasingStyle.Quad),{Size=UDim2.new(0,20,0,20)}):Play()
		end
	end)

	RunService.Heartbeat:Connect(function()
		local hue = 0.75 + 0.12*math.sin(tick()*2)
		local neon = Color3.fromHSV(hue,1,1)
		fill.BackgroundColor3 = neon
		lbl.TextColor3 = neon
		thumbGlow.ImageColor3 = neon
	end)

	_update(default,true,false)
	self:UpdateScrolling(tab)

	return {Set=function(_,newValue) _update(newValue,true,false) end}
end

function SawMillHub:CreateLabel(tab, text)
	if not self.Tabs[tab] then return end

	local TweenService = game:GetService("TweenService")

	-- Frame principal
	local frame = create("Frame", {
		Parent = self.Tabs[tab].Container,
		Size = UDim2.new(1, -10, 0, 50),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		ClipsDescendants = true,
		ZIndex = 1
	})
	create("UICorner", {Parent = frame, CornerRadius = UDim.new(0, 14)})

	-- Sombra sutil
	local shadow = create("Frame", {
		Parent = frame,
		Size = UDim2.new(1, 0, 1, 6),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.85,
		ZIndex = 0
	})
	create("UICorner", {Parent = shadow, CornerRadius = UDim.new(0, 14)})

	-- Stroke elegante (rainbow suave)
	local stroke = create("UIStroke", {
		Parent = frame,
		Color = Color3.fromRGB(80, 80, 80),
		Thickness = 1,
		Transparency = 0.5
	})

	-- Texto
	local lbl = create("TextLabel", {
		Parent = frame,
		Text = tostring(text or "Label"),
		Size = UDim2.new(1, -20, 1, -10),
		Position = UDim2.new(0, 10, 0, 5),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(240, 240, 240),
		Font = Enum.Font.Gotham,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true
	})

	-- ===== Rainbow animado suave =====
	local hue = 0
	local running = true
	spawn(function()
		while running do
			hue = (hue + 0.005) % 1
			local rainbowColor = Color3.fromHSV(hue, 0.6, 1)
			if frame then
				frame.BackgroundColor3 = Color3.fromHSV(hue, 0.1, 0.15)
				stroke.Color = rainbowColor
				shadow.BackgroundColor3 = rainbowColor:lerp(Color3.fromRGB(0,0,0), 0.8)
			end
			task.wait(0.03)
		end
	end)

	-- Hover e clique animado
	frame.MouseEnter:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, frame.Position.Y.Scale, frame.Position.Y.Offset - 2)
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.2}):Play()
	end)
	frame.MouseLeave:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, frame.Position.Y.Scale, frame.Position.Y.Offset + 2)
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
	end)
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = frame.Position + UDim2.new(0,0,0,2)
			}):Play()
		end
	end)
	frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = frame.Position - UDim2.new(0,0,0,2)
			}):Play()
		end
	end)

	self:UpdateScrolling(tab)

	return {
		Frame = frame,
		Label = lbl,
		SetText = function(_, newText)
			lbl.Text = tostring(newText)
		end,
		Destroy = function()
			running = false
			frame:Destroy()
		end
	}
end

-----------------------------------------------------
-- Botão Profissional Moderno com Rainbow
-----------------------------------------------------
function SawMillHub:CreateButton(tab, text, callback)
	if not self.Tabs[tab] then return end

	local initialText = tostring(text or "")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")

	-- Botão principal
	local btn = create("TextButton", {
		Parent = self.Tabs[tab].Container,
		Text = initialText,
		Size = UDim2.new(1, -10, 0, 40),
		BackgroundColor3 = Color3.fromRGB(28, 28, 38),
		TextColor3 = Color3.fromRGB(235, 235, 235),
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		AutoButtonColor = false,
		ClipsDescendants = true
	})
	create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 10)})

	-- Stroke animado
	local stroke = create("UIStroke", {
		Parent = btn,
		Color = Color3.fromRGB(70, 70, 100),
		Thickness = 2,
		Transparency = 0.4
	})

	-- Glow interno
	local glow = create("Frame", {
		Parent = btn,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 0
	})
	create("UICorner", {Parent = glow, CornerRadius = UDim.new(0, 10)})

	-- Hover Effect + Neon Pulse
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(28, 28, 38)
		}):Play()
	end)

	-- Click Feedback
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(20, 20, 28),
			TextColor3 = Color3.fromRGB(200, 200, 255)
		}):Play()
	end)

	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(45, 45, 60),
			TextColor3 = Color3.fromRGB(235, 235, 255)
		}):Play()
	end)

	-- Execução do callback
	btn.MouseButton1Click:Connect(function()
		if callback then pcall(callback) end
	end)

	-- RAINBOW STROKE + Glow Neon Pulsante
	local hue = 0
	RunService.RenderStepped:Connect(function(dt)
		hue = (hue + dt * 0.4) % 1
		local neonColor = Color3.fromHSV(hue, 0.9, 1)
		stroke.Color = neonColor
		glow.BackgroundColor3 = neonColor
		glow.BackgroundTransparency = 0.7 + 0.3 * math.sin(tick()*3)
	end)

	-- Pequeno pulse de texto
	RunService.RenderStepped:Connect(function(dt)
		btn.TextColor3 = btn.TextColor3:lerp(Color3.fromRGB(180, 120, 255), 0.05)
	end)

	self:UpdateScrolling(tab)

	return {
		Button = btn,
		Set = function(_, newText)
			btn.Text = tostring(newText)
		end
	}
end

function SawMillHub:CreateToggle(tab, text, default, callback)
	if not self.Tabs[tab] then return end
	local container = self.Tabs[tab].Container

	-- Cores neon
	local NEON_ON = Color3.fromRGB(0, 255, 120)
	local NEON_OFF_BG = Color3.fromRGB(30, 30, 30)
	local NEON_OFF_GLOW = Color3.fromRGB(255, 50, 50)
	local TEXT_COLOR_OFF = Color3.fromRGB(180, 180, 180)

	local currentState = default == true
	local ON_POS = UDim2.new(1, -25, 0.5, -12)
	local OFF_POS = UDim2.new(0, 1, 0.5, -12)

	-- Container do toggle
	local toggle = Instance.new("Frame")
	toggle.Parent = container
	toggle.Size = UDim2.new(1, -10, 0, 44)
	toggle.BackgroundTransparency = 1

	-- Label com fundo animado
	local label = Instance.new("TextLabel")
	label.Parent = toggle
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 0.85
	label.BackgroundColor3 = Color3.fromRGB(20,20,20)
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextColor3 = currentState and NEON_ON or TEXT_COLOR_OFF
	label.TextXAlignment = Enum.TextXAlignment.Left
	local labelCorner = Instance.new("UICorner", label)
	labelCorner.CornerRadius = UDim.new(0.25,0)

	-- Gradiente animado no label
	local labelGradient = Instance.new("UIGradient", label)
	labelGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 120, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 200))
	}
	labelGradient.Rotation = 0
	task.spawn(function()
		while label.Parent do
			labelGradient.Rotation = (labelGradient.Rotation + 1.5) % 360
			task.wait(0.016)
		end
	end)

	-- Switch principal
	local switch = Instance.new("Frame")
	switch.Parent = toggle
	switch.AnchorPoint = Vector2.new(1, 0.5)
	switch.Position = UDim2.new(1, -10, 0.5, 0)
	switch.Size = UDim2.new(0, 55, 0, 26)
	switch.BackgroundColor3 = currentState and NEON_ON or NEON_OFF_BG
	switch.BorderSizePixel = 0
	local switchCorner = Instance.new("UICorner", switch)
	switchCorner.CornerRadius = UDim.new(1, 0)

	-- Glow pulsante contínuo
	local glow = Instance.new("UIStroke")
	glow.Parent = switch
	glow.Color = currentState and NEON_ON or NEON_OFF_GLOW
	glow.Transparency = 0.3
	glow.Thickness = 3
	task.spawn(function()
		local direction = 1
		while glow.Parent do
			glow.Transparency = glow.Transparency + 0.01 * direction
			if glow.Transparency >= 0.6 then direction = -1
			elseif glow.Transparency <= 0.2 then direction = 1 end
			task.wait(0.016)
		end
	end)

	-- Handle
	local handle = Instance.new("Frame")
	handle.Parent = switch
	handle.Size = UDim2.new(0, 24, 0, 24)
	handle.Position = currentState and ON_POS or OFF_POS
	handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	handle.BorderSizePixel = 0
	local handleCorner = Instance.new("UICorner", handle)
	handleCorner.CornerRadius = UDim.new(1, 0)

	-- Gradiente animado no handle
	local gradient = Instance.new("UIGradient", handle)
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200,200,255))
	})
	gradient.Rotation = 30
	task.spawn(function()
		while handle.Parent do
			gradient.Rotation = (gradient.Rotation + 2) % 360
			task.wait(0.016)
		end
	end)

	-- Partículas flutuantes contínuas
	task.spawn(function()
		while switch.Parent do
			local part = Instance.new("Frame")
			part.Size = UDim2.new(0,4,0,4)
			part.Position = UDim2.new(math.random(),0,math.random(),0)
			part.AnchorPoint = Vector2.new(0.5,0.5)
			part.BackgroundColor3 = currentState and NEON_ON or NEON_OFF_GLOW
			part.BorderSizePixel = 0
			part.ZIndex = 2
			part.Parent = switch
			Debris:AddItem(part,0.7)
			TweenService:Create(part, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(math.random(),0,math.random(),0),
				Size = UDim2.new(0,2,0,2),
				BackgroundTransparency = 1
			}):Play()
			task.wait(0.1)
		end
	end)

	-- Pulso expandido
	local function createPulse(color)
		local pulse = Instance.new("Frame")
		pulse.Parent = switch
		pulse.AnchorPoint = Vector2.new(0.5, 0.5)
		pulse.Position = UDim2.new(0.5, 0, 0.5, 0)
		pulse.Size = UDim2.new(0.9, 0, 0.9, 0)
		pulse.BackgroundColor3 = color
		pulse.BackgroundTransparency = 0.7
		pulse.BorderSizePixel = 0
		pulse.ZIndex = -1
		local pulseCorner = Instance.new("UICorner", pulse)
		pulseCorner.CornerRadius = UDim.new(1, 0)
		TweenService:Create(pulse, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(2.5, 0, 2.5, 0),
			BackgroundTransparency = 1
		}):Play()
		Debris:AddItem(pulse, 0.6)
	end

	-- Atualiza estado com animações
	local function updateToggle(state)
		currentState = state
		local colorBG = state and NEON_ON or NEON_OFF_BG
		local colorGlow = state and NEON_ON or NEON_OFF_GLOW
		local colorText = state and NEON_ON or TEXT_COLOR_OFF

		TweenService:Create(switch, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = colorBG}):Play()
		TweenService:Create(glow, TweenInfo.new(0.35), {Color = colorGlow}):Play()
		TweenService:Create(label, TweenInfo.new(0.35), {TextColor3 = colorText}):Play()
		TweenService:Create(handle, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = state and ON_POS or OFF_POS}):Play()

		createPulse(colorGlow)

		-- Bounce elegante do handle
		TweenService:Create(handle, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0,30,0,30)}):Play()
		task.delay(0.2,function()
			TweenService:Create(handle, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0,24,0,24)}):Play()
		end)

		if callback then
			task.spawn(callback, currentState)
		end
	end

	local function onToggle()
		updateToggle(not currentState)
	end

	switch.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			onToggle()
		end
	end)

	-- Hover suave com brilho extra
	switch.MouseEnter:Connect(function()
		TweenService:Create(switch, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.05}):Play()
	end)
	switch.MouseLeave:Connect(function()
		TweenService:Create(switch, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
	end)

	self:UpdateScrolling(tab)

	local toggleObject = {}
	function toggleObject:Set(state) updateToggle(state) end
	toggleObject.Frame = toggle
	toggleObject.Switch = switch

	return toggleObject
end

-- DROPDOWN FUNCIONAL E ANIMADO
-- =====================================

function SawMillHub:CreateDropdown(tab, text, options, callback)
	if not self.Tabs[tab] then return end
	options = options or {}
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")

	local darkBackground = Color3.fromRGB(18, 18, 28)
	local optionBackground = Color3.fromRGB(28, 28, 40)
	local optionHover = Color3.fromRGB(50, 40, 80)
	local highlightStart = Color3.fromRGB(180, 120, 255)
	local highlightEnd = Color3.fromRGB(80, 120, 255)

	local selectedValue = nil
	local optionMap = {}
	local dropdown = {}

	-- CONTAINER PRINCIPAL
	local frame = Instance.new("Frame")
	frame.Parent = self.Tabs[tab].Container
	frame.Size = UDim2.new(1, -10, 0, 50)
	frame.BackgroundColor3 = darkBackground
	frame.ClipsDescendants = true
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
	local frameStroke = Instance.new("UIStroke", frame)
	frameStroke.Color = Color3.fromRGB(60, 60, 80)
	frameStroke.Thickness = 1
	frameStroke.Transparency = 0.5

	-- BOTÃO PRINCIPAL
	local btn = Instance.new("TextButton")
	btn.Parent = frame
	btn.Text = ""
	btn.Size = UDim2.new(1, 0, 0, 50)
	btn.BackgroundTransparency = 1
	btn.AutoButtonColor = false

	local btnLabel = Instance.new("TextLabel")
	btnLabel.Parent = btn
	btnLabel.Text = text .. ": (Selecione)"
	btnLabel.Size = UDim2.new(1, -60, 1, 0)
	btnLabel.Position = UDim2.new(0, 14, 0, 0)
	btnLabel.BackgroundTransparency = 1
	btnLabel.TextColor3 = highlightStart
	btnLabel.Font = Enum.Font.GothamBold
	btnLabel.TextSize = 15
	btnLabel.TextXAlignment = Enum.TextXAlignment.Left

	local arrow = Instance.new("TextLabel")
	arrow.Parent = btn
	arrow.Text = "▼"
	arrow.Size = UDim2.new(0, 28, 0, 28)
	arrow.AnchorPoint = Vector2.new(1, 0.5)
	arrow.Position = UDim2.new(1, -12, 0.5, 0)
	arrow.BackgroundTransparency = 1
	arrow.TextColor3 = highlightStart
	arrow.Font = Enum.Font.GothamBlack
	arrow.TextSize = 22
	arrow.ZIndex = 2

	-- LISTA DE OPÇÕES
	local list = Instance.new("ScrollingFrame")
	list.Parent = frame
	list.Size = UDim2.new(1, 0, 0, 0)
	list.Position = UDim2.new(0, 0, 0, 50)
	list.BackgroundColor3 = optionBackground
	list.Visible = false
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Instance.new("UICorner", list).CornerRadius = UDim.new(0, 10)
	local listStroke = Instance.new("UIStroke", list)
	listStroke.Color = highlightStart
	listStroke.Thickness = 1
	listStroke.Transparency = 0.7

	local layout = Instance.new("UIListLayout", list)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	local padding = Instance.new("UIPadding", list)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 5)
	padding.PaddingRight = UDim.new(0, 5)

	local open = false
	local selectedCheck = nil

	-- AJUSTE DE TAMANHO
	local function updateDropdownSize(animated)
		local totalHeight = layout.AbsoluteContentSize.Y + 8
		list.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
		local goalY = open and (50 + math.min(totalHeight, 180)) or 50
		if animated then
			TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, -10, 0, goalY)
			}):Play()
		else
			frame.Size = UDim2.new(1, -10, 0, goalY)
		end
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		updateDropdownSize(false)
	end)

	-- TOGGLE ABRIR/FECHAR
	local function toggleDropdown()
		open = not open
		list.Visible = true
		TweenService:Create(arrow, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Rotation = open and 180 or 0}):Play()
		local targetSize = open and UDim2.new(1, 0, 0, 180) or UDim2.new(1, 0, 0, 0)
		TweenService:Create(list, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = targetSize}):Play()
		task.defer(function() updateDropdownSize(true) end)
		if not open then
			task.delay(0.3, function()
				if not open then list.Visible = false end
			end)
		end
	end
	btn.MouseButton1Click:Connect(toggleDropdown)

	-- SELECIONAR OPÇÃO
	local function selectOption(opt)
		if selectedCheck then selectedCheck.Visible = false end
		local item = optionMap[opt]
		if not item then return end
		item.Check.Visible = true
		selectedCheck = item.Check
		selectedValue = opt
		btnLabel.Text = text .. ": " .. opt
		if callback then pcall(callback, opt) end
	end

	-- CRIAR OPÇÃO
	local function createOption(opt)
		if optionMap[opt] then return end
		local optBtn = Instance.new("TextButton")
		optBtn.Parent = list
		optBtn.Text = ""
		optBtn.Size = UDim2.new(1, -10, 0, 34)
		optBtn.BackgroundColor3 = optionBackground
		optBtn.AutoButtonColor = false
		Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 8)

		local lbl = Instance.new("TextLabel")
		lbl.Parent = optBtn
		lbl.Text = opt
		lbl.Size = UDim2.new(1, -50, 1, 0)
		lbl.Position = UDim2.new(0, 12, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 15
		lbl.TextXAlignment = Enum.TextXAlignment.Left

		local check = Instance.new("TextLabel")
		check.Parent = optBtn
		check.Text = "✓"
		check.Size = UDim2.new(0, 24, 0, 24)
		check.AnchorPoint = Vector2.new(1, 0.5)
		check.Position = UDim2.new(1, -12, 0.5, 0)
		check.BackgroundTransparency = 1
		check.TextColor3 = highlightStart
		check.Font = Enum.Font.GothamBlack
		check.TextSize = 22
		check.Visible = false

		optionMap[opt] = { Button = optBtn, Check = check, Label = lbl }

		-- HOVER & CLICK ANIMADO
		optBtn.MouseEnter:Connect(function()
			TweenService:Create(optBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { BackgroundColor3 = optionHover }):Play()
		end)
		optBtn.MouseLeave:Connect(function()
			TweenService:Create(optBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { BackgroundColor3 = optionBackground }):Play()
		end)
		optBtn.MouseButton1Click:Connect(function()
			selectOption(opt)
			toggleDropdown()
		end)
	end

	-- FUNÇÃO :SET
	function dropdown:Set(newOptions)
		for _, opt in pairs(optionMap) do
			if opt.Button then opt.Button:Destroy() end
		end
		optionMap = {}
		for _, opt in ipairs(newOptions or {}) do
			createOption(opt)
		end
		selectedValue = nil
		btnLabel.Text = text .. ": (Selecione)"
		updateDropdownSize(true)
	end

	-- INICIALIZAÇÃO
	dropdown.Frame = frame
	dropdown:Set(options)

	-- ANIMAÇÃO PREMIUM: neon pulse + gradiente colorido
	RunService.Heartbeat:Connect(function()
		local pulse = 0.5 + 0.5 * math.sin(tick()*2)
		local hue = 0.75 + 0.12*math.sin(tick())
		local neon = Color3.fromHSV(hue, 1, 1)
		btnLabel.TextColor3 = neon:Lerp(highlightEnd, pulse)
		arrow.TextColor3 = neon:Lerp(highlightEnd, pulse)
		for _, v in pairs(optionMap) do
			if v.Check.Visible then
				v.Check.TextColor3 = neon:Lerp(highlightEnd, pulse)
			end
		end
	end)

	self:UpdateScrolling(tab)
	return dropdown
end

function SawMillHub:CreateInput(tab, text, placeholder, callback)
	if not self.Tabs[tab] then return end

	-- Container principal
	local frame = create("Frame", {
		Parent = self.Tabs[tab].Container,
		Size = UDim2.new(1, -10, 0, 55),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		ClipsDescendants = true
	})
	create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 12) })
	local stroke = create("UIStroke", {
		Parent = frame,
		Color = Color3.fromRGB(70, 70, 70),
		Thickness = 1,
		Transparency = 0.4
	})

	-- Vidro / overlay
	local glass = create("Frame", {
		Parent = frame,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BackgroundTransparency = 0.3,
		ZIndex = 1
	})
	create("UICorner", { Parent = glass, CornerRadius = UDim.new(0, 12) })
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
	})
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0.7)
	})
	gradient.Parent = glass

	-- Label acima do TextBox
	local label = create("TextLabel", {
		Parent = frame,
		Text = text or "Input",
		Size = UDim2.new(1, -12, 0, 18),
		Position = UDim2.new(0, 8, 0, 6),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(180, 180, 180),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2
	})

	-- Caixa de texto
	local box = create("TextBox", {
		Parent = frame,
		Text = "",
		Size = UDim2.new(1, -16, 0, 22),
		Position = UDim2.new(0, 8, 0, 28),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(235, 235, 235),
		Font = Enum.Font.Gotham,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 2
	})

	-- Placeholder
	local placeholderLbl = create("TextLabel", {
		Parent = box,
		Text = placeholder or "Digite aqui...",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 2, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(120, 120, 120),
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3
	})

	-- Atualizar placeholder
	local function updatePlaceholder()
		if box.Text == "" and not box:IsFocused() then
			TweenService:Create(placeholderLbl, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
		else
			TweenService:Create(placeholderLbl, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
		end
	end
	updatePlaceholder()

	-- Foco animação
	local function focusAnim(focused)
		if focused then
			TweenService:Create(stroke, TweenInfo.new(0.25), {
				Color = Color3.fromRGB(0, 255, 180),
				Thickness = 2,
				Transparency = 0
			}):Play()
			TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
				BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			}):Play()
		else
			TweenService:Create(stroke, TweenInfo.new(0.25), {
				Color = Color3.fromRGB(70, 70, 70),
				Thickness = 1,
				Transparency = 0.4
			}):Play()
			TweenService:Create(frame, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
		end
		updatePlaceholder()
	end

	box.Focused:Connect(function() focusAnim(true) end)
	box.FocusLost:Connect(function(enter)
		focusAnim(false)
		if enter and callback then
			pcall(callback, box.Text)
			TweenService:Create(frame, TweenInfo.new(0.15), {Size = UDim2.new(1, -10, 0, 57)}):Play()
			task.delay(0.15, function()
				TweenService:Create(frame, TweenInfo.new(0.15), {Size = UDim2.new(1, -10, 0, 55)}):Play()
			end)
		end
	end)

	box:GetPropertyChangedSignal("Text"):Connect(updatePlaceholder)

	-- ======================================
	-- Rainbow Animation (Label, Placeholder e Texto)
	-- ======================================
	local hue = 0
	RunService.Heartbeat:Connect(function(dt)
		hue = (hue + dt * 0.5) % 1
		local rainbow = Color3.fromHSV(hue, 1, 1)
		label.TextColor3 = rainbow
		placeholderLbl.TextColor3 = rainbow
		box.TextColor3 = rainbow
	end)

	self:UpdateScrolling(tab)

	return {
		Box = box,
		Set = function(_, newText, newPlaceholder)
			if newText ~= nil then
				box.Text = tostring(newText)
			end
			if newPlaceholder ~= nil then
				placeholderLbl.Text = tostring(newPlaceholder)
			end
			updatePlaceholder()
		end
	}
end

function SawMillHub:CreateKeybind(tab, text, defaultKey, callback)
	if not self.Tabs[tab] then return end
	local container = self.Tabs[tab].Container

	local selectedKey = defaultKey or Enum.KeyCode.F
	local listening = false
	local connections = {}

	-- 🧱 Container principal
	local frame = Instance.new("Frame")
	frame.Parent = container
	frame.Size = UDim2.new(1, -10, 0, 44)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	frame.BorderSizePixel = 0
	frame.Name = "Keybind"
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	-- 🌟 Sombra e glow
	local shadow = Instance.new("ImageLabel")
	shadow.Parent = frame
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
	shadow.Size = UDim2.new(1, 8, 1, 8)
	shadow.Image = "rbxassetid://5028857084"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.75
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(24, 24, 276, 276)
	shadow.ZIndex = 0

	local glow = Instance.new("Frame")
	glow.Parent = frame
	glow.Size = UDim2.new(1,0,1,0)
	glow.Position = UDim2.new(0,0,0,0)
	glow.BackgroundColor3 = Color3.fromRGB(255,0,0)
	glow.BackgroundTransparency = 0.85
	Instance.new("UICorner", glow).CornerRadius = UDim.new(0,8)
	local glowStroke = Instance.new("UIStroke", glow)
	glowStroke.Color = Color3.fromRGB(255,0,0)
	glowStroke.Thickness = 1
	glowStroke.Transparency = 0.5

	-- 🏷️ Título
	local label = Instance.new("TextLabel")
	label.Parent = frame
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = tostring(text or "Keybind")
	label.TextColor3 = Color3.fromRGB(235, 235, 235)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextXAlignment = Enum.TextXAlignment.Left

	-- ⌨️ Botão da tecla
	local keyButton = Instance.new("TextButton")
	keyButton.Parent = frame
	keyButton.Size = UDim2.new(0, 110, 0, 28)
	keyButton.AnchorPoint = Vector2.new(1, 0.5)
	keyButton.Position = UDim2.new(1, -10, 0.5, 0)
	keyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	keyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyButton.Text = selectedKey.Name
	keyButton.Font = Enum.Font.Gotham
	keyButton.TextSize = 14
	keyButton.AutoButtonColor = false
	Instance.new("UICorner", keyButton).CornerRadius = UDim.new(0, 6)

	-- Stroke rainbow sutil
	local stroke = Instance.new("UIStroke", keyButton)
	stroke.Color = Color3.fromRGB(90, 90, 90)
	stroke.Thickness = 1
	stroke.Transparency = 0.25

	-- ===== Rainbow animado para fundo, stroke e glow =====
	local hue = 0
	local running = true
	RunService.RenderStepped:Connect(function(dt)
		if not running then return end
		hue = (hue + dt*0.1) % 1
		local rainbowColor = Color3.fromHSV(hue, 1, 1)
		if keyButton and glow then
			keyButton.BackgroundColor3 = Color3.fromHSV(hue, 0.15, 0.3)
			stroke.Color = rainbowColor
			glowStroke.Color = rainbowColor
			glow.BackgroundColor3 = rainbowColor
		end
	end)

	-- ✨ Animação hover
	local function tweenColor(obj, color)
		TweenService:Create(obj, TweenInfo.new(0.15), { BackgroundColor3 = color }):Play()
	end

	keyButton.MouseEnter:Connect(function()
		if not listening then
			tweenColor(keyButton, Color3.fromRGB(55, 55, 55))
		end
	end)
	keyButton.MouseLeave:Connect(function()
		if not listening then
			tweenColor(keyButton, Color3.fromRGB(40, 40, 40))
		end
	end)

	-- 🧠 Capturar nova tecla
	keyButton.MouseButton1Click:Connect(function()
		if listening then return end
		listening = true
		keyButton.Text = "Press any key..."
		tweenColor(keyButton, Color3.fromRGB(85, 85, 85))

		local temp
		temp = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				selectedKey = input.KeyCode
				keyButton.Text = selectedKey.Name
				listening = false
				tweenColor(keyButton, Color3.fromRGB(40, 40, 40))
				temp:Disconnect()
			end
		end)
	end)

	-- ⚡ Execução da tecla
	local keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if not listening and input.KeyCode == selectedKey then
			-- efeito visual na letra
			local originalColor = keyButton.TextColor3
			local tween1 = TweenService:Create(keyButton, TweenInfo.new(0.08), {TextColor3 = Color3.fromHSV(math.random(),1,1)})
			local tween2 = TweenService:Create(keyButton, TweenInfo.new(0.2), {TextColor3 = originalColor})
			tween1:Play()
			tween1.Completed:Wait()
			tween2:Play()

			task.spawn(function()
				if callback then
					pcall(callback, input.KeyCode) -- passa a tecla pressionada
				end
			end)
		end
	end)
	table.insert(connections, keyConn)

	self:UpdateScrolling(tab)

	-- ✅ Retornar manipulador apenas com Set e Disconnect
	local api = {}

	function api:Set(newKey)
		if typeof(newKey) == "EnumItem" and newKey.EnumType == Enum.KeyCode then
			selectedKey = newKey
			keyButton.Text = newKey.Name
		end
	end

	function api:Disconnect()
		running = false -- parar animação rainbow
		for _, conn in ipairs(connections) do
			if conn.Disconnect then
				conn:Disconnect()
			end
		end
	end

	return api
end

function SawMillHub:Notify(title, message, duration, type)
	duration = duration or 3
	type = type or "info"
	local isTouch = UserInputService.TouchEnabled
	self.ActiveNotifications = self.ActiveNotifications or {}
	local MAX_NOTIFS = self.MaxNotifs or 5

	local ICONS = {
		info = "rbxassetid://6034509993",
		success = "rbxassetid://6023426926",
		error = "rbxassetid://6023426921",
		warning = "rbxassetid://6031071057"
	}

	local COLORS = {
		info = Color3.fromRGB(100, 150, 255),
		success = Color3.fromRGB(100, 255, 170),
		error = Color3.fromRGB(255, 90, 90),
		warning = Color3.fromRGB(255, 210, 100)
	}

	local iconId = ICONS[type]
	local baseColor = COLORS[type] or Color3.fromRGB(255, 255, 255)

	-- Criar holder se não existir
	if not self.NotificationHolder then
		local holder = Instance.new("Frame")
		holder.Name = "NotificationHolder"
		holder.Parent = self.Gui
		holder.AnchorPoint = Vector2.new(1, 1)
		holder.Position = UDim2.new(1, -20, 1, -20)
		holder.Size = UDim2.new(0, 360, 1, -30)
		holder.BackgroundTransparency = 1

		local layout = Instance.new("UIListLayout", holder)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 10)
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom

		self.NotificationHolder = holder
	end

	-- Remove notificações antigas se já atingiu o limite
	while #self.ActiveNotifications >= MAX_NOTIFS do
		local old = table.remove(self.ActiveNotifications, 1)
		if old then
			TweenService:Create(old, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
				Position = old.Position + UDim2.new(1, 50, 0, 0),
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 340, 0, 0)
			}):Play()
			task.delay(0.35, function()
				if old and old.Parent then old:Destroy() end
			end)
		end
	end

	-- Criar notificação
	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(0, 340, 0, isTouch and 75 or 95)
	notif.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	notif.BackgroundTransparency = 0.05
	notif.BorderSizePixel = 0
	notif.ClipsDescendants = true
	notif.LayoutOrder = #self.ActiveNotifications + 1
	notif.Parent = self.NotificationHolder
	Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 14)

	-- Sombra
	local shadow = Instance.new("ImageLabel", notif)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
	shadow.Size = UDim2.new(1.2, 14, 1.4, 14)
	shadow.Image = "rbxassetid://5028857084"
	shadow.ImageTransparency = 0.8
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(24, 24, 276, 276)
	shadow.ZIndex = 0
	shadow.BackgroundTransparency = 1

	-- Glass gradient
	local blur = Instance.new("Frame", notif)
	blur.Size = UDim2.new(1,0,1,0)
	blur.BackgroundTransparency = 1
	local blurEffect = Instance.new("UIGradient", blur)
	blurEffect.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(210,210,210))})
	blurEffect.Rotation = 90
	blurEffect.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.92),NumberSequenceKeypoint.new(1,1)})

	-- Stroke rainbow
	local stroke = Instance.new("UIStroke", notif)
	stroke.Thickness = 2
	stroke.Transparency = 0.55
	local hue = 0
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if stroke.Parent then
			hue = (hue + dt*0.25) % 1
			stroke.Color = Color3.fromHSV(hue,0.9,1)
		else
			if conn then conn:Disconnect() end
		end
	end)

	-- Barra inferior animada
	local bar = Instance.new("Frame", notif)
	bar.AnchorPoint = Vector2.new(0,1)
	bar.Position = UDim2.new(0,0,1,0)
	bar.Size = UDim2.new(0,0,0,5)
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = baseColor
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0,3)
	TweenService:Create(bar,TweenInfo.new(duration,Enum.EasingStyle.Linear),{Size=UDim2.new(1,0,0,5)}):Play()

	-- Conteúdo
	local content = Instance.new("Frame", notif)
	content.Size = UDim2.new(1,-24,1,-20)
	content.Position = UDim2.new(0,12,0,10)
	content.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout", content)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0,10)

	-- Ícone com pulsação
	if iconId then
		local icon = Instance.new("ImageLabel", content)
		icon.Size = UDim2.new(0,32,0,32)
		icon.Image = iconId
		icon.ImageColor3 = baseColor
		icon.BackgroundTransparency = 1
		task.spawn(function()
			while icon and icon.Parent do
				TweenService:Create(icon, TweenInfo.new(0.6,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,36,0,36)}):Play()
				task.wait(0.6)
				TweenService:Create(icon, TweenInfo.new(0.6,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(0,32,0,32)}):Play()
				task.wait(0.6)
			end
		end)
	end

	-- Texto
	local textFrame = Instance.new("Frame", content)
	textFrame.Size = UDim2.new(1,-50,1,0)
	textFrame.BackgroundTransparency = 1
	local vLayout = Instance.new("UIListLayout", textFrame)
	vLayout.FillDirection = Enum.FillDirection.Vertical
	vLayout.Padding = UDim.new(0,3)

	local titleLabel = Instance.new("TextLabel", textFrame)
	titleLabel.Text = string.upper(tostring(title or "NOTIFICAÇÃO"))
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = baseColor
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Size = UDim2.new(1,0,0,22)

	local msgLabel = Instance.new("TextLabel", textFrame)
	msgLabel.Text = tostring(message or "")
	msgLabel.TextSize = 16
	msgLabel.Font = Enum.Font.Gotham
	msgLabel.TextColor3 = Color3.fromRGB(235,235,235)
	msgLabel.TextWrapped = true
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.BackgroundTransparency = 1
	msgLabel.Size = UDim2.new(1,0,1,-24)

	-- Botão close X
	local closeBtn = Instance.new("TextButton", notif)
	closeBtn.Size = UDim2.new(0,22,0,22)
	closeBtn.Position = UDim2.new(1,-28,0,6)
	closeBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.AutoButtonColor = false
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)

	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn,TweenInfo.new(0.15),{BackgroundColor3=baseColor}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(35,35,35)}):Play()
	end)

	local function removeNotif()
		if notif and notif.Parent then
			TweenService:Create(notif,TweenInfo.new(0.4,Enum.EasingStyle.Cubic,Enum.EasingDirection.In),{
				Position = notif.Position + UDim2.new(1,50,0,0),
				BackgroundTransparency = 1,
				Size = UDim2.new(0,340,0,0)
			}):Play()
			task.delay(0.4,function()
				for i,v in ipairs(self.ActiveNotifications) do
					if v==notif then table.remove(self.ActiveNotifications,i) break end
				end
				notif:Destroy()
			end)
		end
	end

	closeBtn.MouseButton1Click:Connect(removeNotif)

	-- Entrada animada
	notif.Position = UDim2.new(1,80,0,0)
	notif.Size = UDim2.new(0,340,0,0)
	notif.BackgroundTransparency = 1
	TweenService:Create(notif,TweenInfo.new(0.55,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{
		Position=UDim2.new(0,0,0,0),
		BackgroundTransparency=0.05,
		Size=UDim2.new(0,340,0,isTouch and 75 or 95)
	}):Play()

	table.insert(self.ActiveNotifications,notif)

	-- Auto remove
	task.delay(duration, removeNotif)
end
return SawMillHub
