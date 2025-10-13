-- SawMillHub.lua (LocalScript)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SawMillHub = {}
SawMillHub.__index = SawMillHub

-- ======== FUNÇÕES AUXILIARES ========
local function create(class, props)
	local inst = Instance.new(class)
	if props then
		for k,v in pairs(props) do
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

	-- Redimensionamento manual
	local resizeHandle = create("Frame", {
		Parent = mainFrame,
		Size = UDim2.new(0,16,0,16),
		AnchorPoint = Vector2.new(1,1),
		Position = UDim2.new(1,-3,1,-3),
		BackgroundColor3 = Color3.fromRGB(80,80,80),
		BackgroundTransparency = 0.4,
		Name = "ResizeHandle",
		ZIndex = 20
	})
	create("UICorner",{Parent=resizeHandle, CornerRadius=UDim.new(0,4)})
	create("UIStroke",{Parent=resizeHandle, Color=Color3.fromRGB(130,130,130), Thickness=1.2})

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

	-- Hover visual
	resizeHandle.MouseEnter:Connect(function()
		TweenService:Create(resizeHandle, TweenInfo.new(0.15), {BackgroundTransparency=0.2, BackgroundColor3=Color3.fromRGB(100,100,100)}):Play()
	end)
	resizeHandle.MouseLeave:Connect(function()
		if not resizing then
			TweenService:Create(resizeHandle, TweenInfo.new(0.15), {BackgroundTransparency=0.4, BackgroundColor3=Color3.fromRGB(80,80,80)}):Play()
		end
	end)

	-- Arrastar
	local dragging, dragStart, startPos
	dragging = false
	dragStart = false
	startPos = false
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
			local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			if speed < 1 then
				tween(mainFrame, speed, {Position=newPos})
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

	tween(self.Main,0.28,{
		Size=UDim2.new(self.Main.Size.X.Scale, math.max(2, math.floor(self.Main.Size.X.Offset*0.9)),
			self.Main.Size.Y.Scale, math.max(2, math.floor(self.Main.Size.Y.Offset*0.9))),
		BackgroundTransparency=1
	})

	for _,child in ipairs(self.Main:GetDescendants()) do
		if child:IsA("GuiObject") then
			local props={}
			if safePropertyExists(child,"BackgroundTransparency") then props.BackgroundTransparency=1 end
			if (child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox"))
				and safePropertyExists(child,"TextTransparency") then props.TextTransparency=1 end
			if (child:IsA("ImageLabel") or child:IsA("ImageButton")) and safePropertyExists(child,"ImageTransparency") then props.ImageTransparency=1 end
			if child:IsA("UIStroke") and safePropertyExists(child,"Transparency") then props.Transparency=1 end
			if next(props) then tween(child,0.22,props) end
		end
	end

	task.delay(0.34,function()
		if self.Gui and self.Gui.Parent then pcall(function() self.Gui:Destroy() end) end
		self._IsClosing=false
	end)
end

-- ======== MINIMIZAR / RESTAURAR ========
function SawMillHub:ToggleMinimize()
	if not self.Main then return end
	if self._Minimized then
		tween(self.Main,0.28,{Size=self._OriginalSize})
		if self.MinimizeButton and self.MinimizeButton:IsA("TextButton") then
			self.MinimizeButton.Text="–"
			pcall(function() self.MinimizeButton.BackgroundColor3=Color3.fromRGB(255,190,60) end)
		end
		self._Minimized=false
	else
		if not self._OriginalSize then self._OriginalSize=self.Main.Size end
		local newSize=UDim2.new(self._OriginalSize.X.Scale,self._OriginalSize.X.Offset,0,42)
		tween(self.Main,0.28,{Size=newSize})
		if self.MinimizeButton and self.MinimizeButton:IsA("TextButton") then
			self.MinimizeButton.Text="+" 
			pcall(function() self.MinimizeButton.BackgroundColor3=Color3.fromRGB(0,170,255) end)
		end
		self._Minimized=true
	end
end

-- ======== CONSTRUTOR ========
function SawMillHub.new(title, dragSpeed)
	dragSpeed = dragSpeed or "Default"
	local self = setmetatable({}, SawMillHub)
	self.OnClose = Instance.new("BindableEvent")

	self.Gui = create("ScreenGui",{Name="SawMillHub", ResetOnSpawn=false, Parent=PlayerGui})
	create("ObjectValue",{Parent=self.Gui, Name="SawMillHubObject", Value=self, Archivable=false})

	-- Tamanho padrão inicial
	local mainSize = UDim2.new(0,450,0,300)
	local mainPos = UDim2.new(0.5,-mainSize.X.Offset/2,0.5,-mainSize.Y.Offset/2)

	self.Main = create("Frame",{Parent=self.Gui, Size=mainSize, Position=mainPos, BackgroundColor3=Color3.fromRGB(28,28,28), ClipsDescendants=true, Name="Main"})
	create("UICorner",{Parent=self.Main, CornerRadius=UDim.new(0,12)})
	create("UIStroke",{Parent=self.Main, Color=Color3.fromRGB(90,90,90), Thickness=1.6})
	self._OriginalSize = mainSize
	self._Minimized=false

	-- TopBar + botões
	local topBar = create("Frame",{Parent=self.Main, Size=UDim2.new(1,0,0,42), BackgroundColor3=Color3.fromRGB(20,20,20), Name="TopBar"})
	create("UICorner",{Parent=topBar, CornerRadius=UDim.new(0,12)})
	local titleLabel = create("TextLabel",{Parent=topBar, Text=title or "SawMillHub", Size=UDim2.new(1,-110,1,0), Position=UDim2.new(0,12,0,0), TextColor3=Color3.fromRGB(245,245,245), BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, Font=Enum.Font.GothamBold, TextSize=18, Name="TitleLabel"})

	-- Botões
	local minimizeButton = create("TextButton",{Parent=topBar, Text="–", Size=UDim2.new(0,32,0,32), AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-44,0.5,0), BackgroundColor3=Color3.fromRGB(255,190,60), TextColor3=Color3.fromRGB(10,10,10), Font=Enum.Font.GothamBold, TextSize=24, AutoButtonColor=false, Name="MinimizeButton"})
	create("UICorner",{Parent=minimizeButton, CornerRadius=UDim.new(0,8)})
	minimizeButton.MouseButton1Click:Connect(function() self:ToggleMinimize() end)
	self.MinimizeButton = minimizeButton

	local closeButton = create("TextButton",{Parent=topBar, Text="X", Size=UDim2.new(0,32,0,32), AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-6,0.5,0), BackgroundColor3=Color3.fromRGB(235,75,75), TextColor3=Color3.fromRGB(255,255,255), Font=Enum.Font.GothamBold, TextSize=20, AutoButtonColor=false, Name="CloseButton"})
	create("UICorner",{Parent=closeButton, CornerRadius=UDim.new(0,8)})
	closeButton.MouseButton1Click:Connect(function() self:Close() end)

	local resetButton = create("TextButton",{Parent=topBar, Size=UDim2.new(0,32,0,32), AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-82,0.5,0), BackgroundColor3=Color3.fromRGB(90,170,255), Text="R", TextColor3=Color3.fromRGB(10,10,10), Font=Enum.Font.GothamBold, TextSize=20, AutoButtonColor=false, Name="ResetButton"})
	create("UICorner",{Parent=resetButton, CornerRadius=UDim.new(0,8)})
	resetButton.MouseButton1Click:Connect(function()
		if self._Minimized then
			self.Main.Position = mainPos
		else
			tween(self.Main,0.35,{Size=mainSize,Position=mainPos})
			self._OriginalSize = mainSize
		end
	end)

	-- Sidebar e TabHolder
	self.Sidebar = create("Frame",{Parent=self.Main, Size=UDim2.new(0,140,1,-42), Position=UDim2.new(0,0,0,42), BackgroundColor3=Color3.fromRGB(22,22,22), Name="Sidebar"})
	create("UICorner",{Parent=self.Sidebar, CornerRadius=UDim.new(0,8)})
	self.TabHolder = create("Frame",{Parent=self.Main, Size=UDim2.new(1,-140,1,-42), Position=UDim2.new(0,140,0,42), BackgroundColor3=Color3.fromRGB(35,35,35), Name="TabHolder"})
	create("UICorner",{Parent=self.TabHolder, CornerRadius=UDim.new(0,8)})

	self.Tabs = {}
	self.Keybinds = {}
	self.Notifs = {}
	self.MaxNotifs = 5

	-- Ativa drag e resize
	enableDragging(topBar,self.Main,dragSpeed)

	return self
end

-----------------------------------------------------
-- 🌌 SawMillHub: Premium Tab System (Ultra Style)
-- Visual inspirado em Rayfield / Fluent / Synapse
-----------------------------------------------------

function SawMillHub:CreateTab(tabName, icon)
	-- Cria o container lateral uma única vez
	if not self.TabScroll then
		local scroll = create("ScrollingFrame", {
			Parent = self.Sidebar,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
		})

		local layout = create("UIListLayout", {
			Parent = scroll,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		})

		create("UIPadding", {
			Parent = scroll,
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
		})

		self.TabScroll = scroll
	end

	-----------------------------------------------------
	-- 🎛️ Botão da Aba
	-----------------------------------------------------
	local btn = create("TextButton", {
		Parent = self.TabScroll,
		Text = (icon and icon .. "  " or "") .. tabName,
		Size = UDim2.new(1, -10, 0, 38),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		TextColor3 = Color3.fromRGB(185, 185, 185),
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	})

	create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 8) })

	-- Sombra e brilho sutil
	create("UIStroke", {
		Parent = btn,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Color3.fromRGB(50, 50, 50),
		Transparency = 0.65,
		Thickness = 1,
	})

	-----------------------------------------------------
	-- ✨ Underline dinâmico com gradiente
	-----------------------------------------------------
	local underline = create("Frame", {
		Parent = btn,
		Size = UDim2.new(0, 0, 0, 2),
		Position = UDim2.new(0.5, 0, 1, -2),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
	})

	local gradient = create("UIGradient", {
		Parent = underline,
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 255))
		},
		Rotation = 0,
	})

	create("UICorner", { Parent = underline, CornerRadius = UDim.new(1, 0) })

	-- Anima o gradiente (movimento suave)
	task.spawn(function()
		while task.wait(0.03) do
			gradient.Rotation = (gradient.Rotation + 1) % 360
		end
	end)

	-----------------------------------------------------
	-- 🧱 Conteúdo da Aba
	-----------------------------------------------------
	local cont = create("ScrollingFrame", {
		Parent = self.TabHolder,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	})

	create("UIListLayout", {
		Parent = cont,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
	})

	create("UIPadding", {
		Parent = cont,
		PaddingTop = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
	})

	-----------------------------------------------------
	-- 🪄 Interações Suaves
	-----------------------------------------------------
	local tab = { Name = tabName, Button = btn, Container = cont }
	self.Tabs[tabName] = tab

	-- Hover profissional
	btn.MouseEnter:Connect(function()
		if self.CurrentTab ~= tab then
			tween(btn, 0.25, {
				BackgroundColor3 = Color3.fromRGB(28, 28, 28),
				TextColor3 = Color3.fromRGB(235, 235, 235),
			})
		end
	end)

	btn.MouseLeave:Connect(function()
		if self.CurrentTab ~= tab then
			tween(btn, 0.3, {
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				TextColor3 = Color3.fromRGB(185, 185, 185),
			})
		end
	end)

	-- Clique → alternar abas
	btn.MouseButton1Click:Connect(function()
		for _, t in pairs(self.Tabs) do
			t.Container.Visible = false
			tween(t.Button, 0.25, {
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				TextColor3 = Color3.fromRGB(185, 185, 185),
			})
			tween(t.Button:FindFirstChildOfClass("Frame"), 0.25, { Size = UDim2.new(0, 0, 0, 2) })
		end

		cont.Visible = true
		tween(btn, 0.3, {
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			TextColor3 = Color3.fromRGB(255, 255, 255),
		})
		tween(underline, 0.35, { Size = UDim2.new(0.7, 0, 0, 2) })
		self.CurrentTab = tab
	end)

	-- Define a primeira aba
	if not self.CurrentTab then
		cont.Visible = true
		self.CurrentTab = tab
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		underline.Size = UDim2.new(0.7, 0, 0, 2)
	end

	self:UpdateScrolling(tab)
	return tab
end

-----------------------------------------------------
-- ⚙️ Update Scrolling
-----------------------------------------------------
function SawMillHub:UpdateScrolling(tab)
	if type(tab) == "string" then
		tab = self.Tabs[tab]
	end
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
			local total = contentSize + topPad + bottomPad + 10
			applyCanvas(total)
		else
			local total = topPad + bottomPad + 10
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("GuiObject") and child.Visible then
					total += child.AbsoluteSize.Y > 0 and child.AbsoluteSize.Y or (child.Size.Y.Offset or 0)
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
	min, max = tonumber(min) or 0, tonumber(max) or 100
	increment = tonumber(increment) or 0
	default = math.clamp(default or min, min, max)
	local currentValue = default

	local function roundIncrement(val)
		if increment > 0 then
			return math.clamp(math.floor((val + increment / 2) / increment) * increment, min, max)
		else
			return math.clamp(val, min, max)
		end
	end

	-- Container principal
	local frame = create("Frame", {
		Parent = self.Tabs[tab].Container,
		Size = UDim2.new(1, -10, 0, 65),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
	})
	create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 10) })
	create("UIStroke", { Parent = frame, Color = Color3.fromRGB(40, 40, 40), Thickness = 1.4, Transparency = 0.4 })

	-- Nome do slider
	local lbl = create("TextLabel", {
		Parent = frame,
		Text = string.format("%s: %d", text or "Slider", default),
		Size = UDim2.new(0.75, 0, 0, 20),
		Position = UDim2.new(0, 12, 0, 8),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 15
	})

	-- Campo numérico lateral
	local inputCircle = create("TextBox", {
		Parent = frame,
		Size = UDim2.new(0, 42, 0, 38),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 10),
		Text = tostring(default),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		TextColor3 = Color3.fromRGB(220, 220, 220),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		ClearTextOnFocus = false
	})
	create("UICorner", { Parent = inputCircle, CornerRadius = UDim.new(1, 0) })
	create("UIStroke", { Parent = inputCircle, Color = Color3.fromRGB(70, 70, 70), Thickness = 1.3, Transparency = 0.3 })

	-- Barra base
	local bar = create("Frame", {
		Parent = frame,
		Size = UDim2.new(1, -70, 0, 10),
		Position = UDim2.new(0, 10, 0, 42),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	})
	create("UICorner", { Parent = bar, CornerRadius = UDim.new(0, 5) })

	-- Preenchimento dinâmico
	local fill = create("Frame", {
		Parent = bar,
		Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(0, 120, 255)
	})
	create("UICorner", { Parent = fill, CornerRadius = UDim.new(0, 5) })
	create("UIGradient", {
		Parent = fill,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 140, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 180, 255))
		})
	})

	-- Botão/Thumb
	local thumb = create("Frame", {
		Parent = bar,
		Size = UDim2.new(0, 18, 0, 18),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(0, 160, 255)
	})
	create("UICorner", { Parent = thumb, CornerRadius = UDim.new(1, 0) })
	create("UIStroke", { Parent = thumb, Color = Color3.fromRGB(255, 255, 255), Thickness = 1.2, Transparency = 0.6 })
	create("UIGradient", {
		Parent = thumb,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255))
		})
	})

	local dragging = false

	-- Atualiza valor
	local function updateSlider(val, instant, fromThumb)
		if fromThumb then
			val = roundIncrement(val)
		else
			val = math.clamp(val, min, max)
		end

		if val == currentValue then return end
		currentValue = val

		local pct = (val - min) / (max - min)
		TweenService:Create(fill, TweenInfo.new(instant and 0 or 0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
		TweenService:Create(thumb, TweenInfo.new(instant and 0 or 0.25, Enum.EasingStyle.Quad), {Position = UDim2.new(pct, 0, 0.5, 0)}):Play()
		lbl.Text = string.format("%s: %d", text, val)
		inputCircle.Text = tostring(val)

		if callback then task.spawn(callback, val) end
	end

	-- Input manual
	inputCircle.FocusLost:Connect(function()
		local num = tonumber(inputCircle.Text)
		if num then
			updateSlider(num, true, false)
		else
			inputCircle.Text = tostring(currentValue)
		end
	end)

	-- Arrastar slider
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateSlider((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X * (max - min) + min, false, true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateSlider((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X * (max - min) + min, false, true)
		end
	end)

	updateSlider(default, true, false)
	self:UpdateScrolling(tab)

	return {
		Get = function() return currentValue end,
		Set = function(_, newValue) updateSlider(newValue, true, false) end
	}
end

function SawMillHub:CreateLabel(tab, text)
	if not self.Tabs[tab] then return end

	-- Container principal
	local frame = create("Frame", {
		Parent = self.Tabs[tab].Container,
		Size = UDim2.new(1, -10, 0, 55),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		ClipsDescendants = true,
		ZIndex = 2
	})
	create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 12) })
	create("UIStroke", {
		Parent = frame,
		Color = Color3.fromRGB(40, 40, 40),
		Thickness = 1.3,
		Transparency = 0.35
	})

	-- Glow sutil (base luminosa)
	local glow = create("Frame", {
		Parent = frame,
		Size = UDim2.new(1, 8, 1, 8),
		Position = UDim2.new(0, -4, 0, -4),
		BackgroundColor3 = Color3.fromRGB(0, 100, 255),
		BackgroundTransparency = 1,
		ZIndex = 1
	})
	create("UICorner", { Parent = glow, CornerRadius = UDim.new(0, 14) })
	create("UIGradient", {
		Parent = glow,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 140, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 80, 180))
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.7),
			NumberSequenceKeypoint.new(1, 1)
		})
	})

	-- Texto principal
	local lbl = create("TextLabel", {
		Parent = frame,
		Text = tostring(text or "Label"),
		Size = UDim2.new(1, -20, 1, -10),
		Position = UDim2.new(0, 10, 0, 5),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(230, 230, 230),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
		ZIndex = 3
	})

	-- Linha decorativa lateral (detalhe de design)
	local accent = create("Frame", {
		Parent = frame,
		Size = UDim2.new(0, 3, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(0, 120, 255),
		BackgroundTransparency = 0.3,
		ZIndex = 3
	})
	create("UICorner", { Parent = accent, CornerRadius = UDim.new(0, 3) })
	create("UIGradient", {
		Parent = accent,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255))
		})
	})

	-- Animação Hover
	frame.MouseEnter:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(28, 28, 28)
		}):Play()

		TweenService:Create(accent, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0
		}):Play()

		TweenService:Create(glow, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 0.8
		}):Play()
	end)

	frame.MouseLeave:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		}):Play()

		TweenService:Create(accent, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.3
		}):Play()

		TweenService:Create(glow, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1
		}):Play()
	end)

	-- Efeito de clique (press down)
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
				Position = frame.Position + UDim2.new(0, 0, 0, 2)
			}):Play()
		end
	end)
	frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
				Position = frame.Position - UDim2.new(0, 0, 0, 2)
			}):Play()
		end
	end)

	self:UpdateScrolling(tab)

	return {
		Frame = frame,
		Label = lbl,
		SetText = function(self, newText)
			lbl.Text = tostring(newText)
		end,
		GetText = function(self)
			return lbl.Text
		end,
		Destroy = function(self)
			frame:Destroy()
		end
	}
end

-----------------------------------------------------
-- Botão Premium Moderno (Estilo Rayfield Cinza/Preto)
-----------------------------------------------------
function SawMillHub:CreateButton(tab, text, callback)
	if not self.Tabs[tab] then return end

	local initialText = tostring(text or "Button")

	-- Frame base (para sombra leve e profundidade)
	local frame = create("Frame", {
		Parent = self.Tabs[tab].Container,
		Size = UDim2.new(1, -10, 0, 42),
		BackgroundTransparency = 1,
		ZIndex = 1
	})

	-- Sombra de fundo suave
	local shadow = create("ImageLabel", {
		Parent = frame,
		Size = UDim2.new(1, 8, 1, 8),
		Position = UDim2.new(0, -4, 0, -2),
		BackgroundTransparency = 1,
		Image = "rbxassetid://5028857084",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.7,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(24, 24, 276, 276),
		ZIndex = 0
	})

	-- Botão principal
	local btn = create("TextButton", {
		Parent = frame,
		Text = initialText,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(28, 28, 28), -- Preto grafite
		TextColor3 = Color3.fromRGB(235, 235, 235),
		Font = Enum.Font.GothamSemibold,
		TextSize = 15,
		AutoButtonColor = false,
		ClipsDescendants = true,
		ZIndex = 2
	})
	create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 10)})

	-- Stroke com leve brilho metálico
	local stroke = create("UIStroke", {
		Parent = btn,
		Color = Color3.fromRGB(80, 80, 80),
		Thickness = 1.2,
		Transparency = 0.45
	})

	-- Efeito hover (transição suave e discreta)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		}):Play()

		TweenService:Create(stroke, TweenInfo.new(0.25), {
			Color = Color3.fromRGB(100, 100, 100),
			Transparency = 0.3
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(28, 28, 28)
		}):Play()

		TweenService:Create(stroke, TweenInfo.new(0.25), {
			Color = Color3.fromRGB(80, 80, 80),
			Transparency = 0.45
		}):Play()
	end)

	-- Efeito de clique com feedback visual elegante
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(18, 18, 18),
			TextColor3 = Color3.fromRGB(210, 210, 210)
		}):Play()
	end)

	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			TextColor3 = Color3.fromRGB(235, 235, 235)
		}):Play()
	end)

	-- Execução segura do callback
	btn.MouseButton1Click:Connect(function()
		if callback then
			task.spawn(function()
				pcall(callback)
			end)
		end
	end)

	self:UpdateScrolling(tab)

	return {
		Button = btn,
		Set = function(_, newText)
			btn.Text = tostring(newText)
		end,
		Get = function()
			return btn.Text
		end,
		Destroy = function()
			frame:Destroy()
		end
	}
end

function SawMillHub:CreateToggle(tab, text, default, callback)
	local TweenService = game:GetService("TweenService")
	local Debris = game:GetService("Debris")

	if not self.Tabs[tab] then return end
	local container = self.Tabs[tab].Container

	-- Paleta profissional
	local COLOR_ON = Color3.fromRGB(0, 255, 160)
	local COLOR_OFF = Color3.fromRGB(40, 40, 40)
	local GLOW_ON = Color3.fromRGB(0, 255, 160)
	local GLOW_OFF = Color3.fromRGB(100, 100, 100)
	local TEXT_ON = Color3.fromRGB(240, 240, 240)
	local TEXT_OFF = Color3.fromRGB(180, 180, 180)

	local currentState = default == true
	local ON_POS = UDim2.new(1, -27, 0.5, -12)
	local OFF_POS = UDim2.new(0, 2, 0.5, -12)

	-- Container principal
	local toggle = create("Frame", {
		Parent = container,
		Size = UDim2.new(1, -10, 0, 46),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderSizePixel = 0,
	})
	create("UICorner", {Parent = toggle, CornerRadius = UDim.new(0, 10)})
	create("UIStroke", {Parent = toggle, Color = Color3.fromRGB(70, 70, 70), Transparency = 0.4})

	local shadow = create("ImageLabel", {
		Parent = toggle,
		Size = UDim2.new(1, 10, 1, 10),
		Position = UDim2.new(0, -5, 0, -2),
		BackgroundTransparency = 1,
		Image = "rbxassetid://5028857084",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.85,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(24, 24, 276, 276),
		ZIndex = 0
	})

	-- Label
	local label = create("TextLabel", {
		Parent = toggle,
		Size = UDim2.new(0.7, 0, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = currentState and TEXT_ON or TEXT_OFF,
		Font = Enum.Font.GothamSemibold,
		TextSize = 16,
	})

	-- Switch
	local switch = create("Frame", {
		Parent = toggle,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 60, 0, 28),
		BackgroundColor3 = currentState and COLOR_ON or COLOR_OFF,
		BorderSizePixel = 0
	})
	create("UICorner", {Parent = switch, CornerRadius = UDim.new(1, 0)})

	local glow = create("UIStroke", {
		Parent = switch,
		Color = currentState and GLOW_ON or GLOW_OFF,
		Transparency = currentState and 0.25 or 0.55,
		Thickness = 2
	})

	local handle = create("Frame", {
		Parent = switch,
		Size = UDim2.new(0, 24, 0, 24),
		Position = currentState and ON_POS or OFF_POS,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})
	create("UICorner", {Parent = handle, CornerRadius = UDim.new(1, 0)})

	local reflection = create("UIGradient", {
		Parent = handle,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(230, 230, 230)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 210, 210))
		}),
		Rotation = 45
	})

	task.spawn(function()
		while handle.Parent do
			reflection.Rotation = (reflection.Rotation + 0.4) % 360
			task.wait(0.016)
		end
	end)

	local function createPulse(color)
		local pulse = create("Frame", {
			Parent = switch,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.9, 0, 0.9, 0),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.6,
			ZIndex = -1,
			BorderSizePixel = 0
		})
		create("UICorner", {Parent = pulse, CornerRadius = UDim.new(1, 0)})

		TweenService:Create(pulse, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1.8, 0, 1.8, 0),
			BackgroundTransparency = 1
		}):Play()
		Debris:AddItem(pulse, 0.5)
	end

	local function updateToggle(state, triggerCallback)
		currentState = state

		local colorBG = state and COLOR_ON or COLOR_OFF
		local colorGlow = state and GLOW_ON or GLOW_OFF
		local colorText = state and TEXT_ON or TEXT_OFF

		TweenService:Create(switch, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = colorBG}):Play()
		TweenService:Create(glow, TweenInfo.new(0.25), {Color = colorGlow, Transparency = state and 0.25 or 0.55}):Play()
		TweenService:Create(label, TweenInfo.new(0.25), {TextColor3 = colorText}):Play()
		TweenService:Create(handle, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = state and ON_POS or OFF_POS
		}):Play()

		createPulse(colorGlow)
		if callback and triggerCallback then
			task.spawn(callback, currentState)
		end
	end

	switch.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			updateToggle(not currentState, true)
		end
	end)

	self:UpdateScrolling(tab)

	local toggleObject = {}
	toggleObject.Frame = toggle
	toggleObject.Switch = switch
	-- Só Set, callback é disparado automaticamente
	function toggleObject:Set(state) updateToggle(state, true) end

	return toggleObject
end


function SawMillHub:CreateDropdown(tab, text, options, callback)
	local TweenService = game:GetService("TweenService")
	local NEON_BLUE = Color3.fromRGB(0, 170, 255)

	if not self.Tabs[tab] then return end
	options = options or {}

	local neonBlue = NEON_BLUE
	local darkBackground = Color3.fromRGB(25, 25, 25)
	local optionBackground = Color3.fromRGB(35, 35, 35)
	local optionHover = Color3.fromRGB(50, 50, 50)

	local selectedValue = nil
	local optionMap = {}

	-----------------------------------------------------
	-- Container principal
	-----------------------------------------------------
	local frame = create("Frame", {
		Parent = self.Tabs[tab].Container,
		Size = UDim2.new(1, -10, 0, 50),
		BackgroundColor3 = darkBackground,
		ClipsDescendants = true
	})
	create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 12) })
	create("UIStroke", { Parent = frame, Color = Color3.fromRGB(70, 70, 70), Thickness = 1, Transparency = 0.5 })

	local btn = create("TextButton", {
		Parent = frame,
		Text = "",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		AutoButtonColor = false
	})

	local btnLabel = create("TextLabel", {
		Parent = btn,
		Text = text .. ": (Selecione)",
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(240, 240, 240),
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	local arrow = create("TextLabel", {
		Parent = btn,
		Text = "▼",
		Size = UDim2.new(0, 28, 0, 28),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		BackgroundTransparency = 1,
		TextColor3 = neonBlue,
		Font = Enum.Font.GothamBlack,
		TextSize = 22,
		ZIndex = 2
	})

	-----------------------------------------------------
	-- Lista de opções
	-----------------------------------------------------
	local list = create("ScrollingFrame", {
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		Visible = false,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y
	})
	create("UICorner", { Parent = list, CornerRadius = UDim.new(0, 10) })
	create("UIStroke", { Parent = list, Color = neonBlue, Thickness = 1, Transparency = 1 })
	create("UIListLayout", { Parent = list, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
	create("UIPadding", { Parent = list, PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) })

	local open = false
	local selectedCheck = nil

	-----------------------------------------------------
	-- Atualização automática do dropdown
	-----------------------------------------------------
	local function updateDropdownSize(animated)
		local layout = list:FindFirstChildOfClass("UIListLayout")
		if not layout then return end

		task.wait(0.02)
		local totalHeight = layout.AbsoluteContentSize.Y + 8
		list.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
		local goalY = open and (50 + math.min(totalHeight, 180)) or 50

		if animated then
			TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, -10, 0, goalY) }):Play()
		else
			frame.Size = UDim2.new(1, -10, 0, goalY)
		end

		self:UpdateScrolling(self.Tabs[tab])
	end

	-----------------------------------------------------
	-- Toggle abrir/fechar
	-----------------------------------------------------
	local function toggleDropdown()
		open = not open
		list.Visible = true

		TweenService:Create(arrow, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			Rotation = open and 180 or 0
		}):Play()

		TweenService:Create(list, TweenInfo.new(0.3), { BackgroundTransparency = open and 0 or 1 }):Play()

		if open then
			TweenService:Create(list, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, 180) }):Play()
		else
			TweenService:Create(list, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, 0) }):Play()
		end

		task.defer(function()
			updateDropdownSize(true)
		end)

		if not open then
			task.delay(0.4, function()
				if not open then list.Visible = false end
			end)
		end
	end

	btn.MouseButton1Click:Connect(toggleDropdown)

	-----------------------------------------------------
	-- Selecionar opção
	-----------------------------------------------------
	local function selectOption(opt)
		if selectedCheck then selectedCheck.Visible = false end
		local item = optionMap[opt]
		if not item then return end

		item.Check.Visible = true
		selectedCheck = item.Check
		selectedValue = opt
		btnLabel.Text = text .. ": " .. opt

		TweenService:Create(btnLabel, TweenInfo.new(0.15), { TextColor3 = neonBlue }):Play()
		task.delay(0.4, function()
			TweenService:Create(btnLabel, TweenInfo.new(0.25), { TextColor3 = Color3.fromRGB(240, 240, 240) }):Play()
		end)

		if callback then pcall(callback, opt) end
	end

	-----------------------------------------------------
	-- Criar opção
	-----------------------------------------------------
	local function createOption(opt)
		if optionMap[opt] then return end

		local optBtn = create("TextButton", {
			Parent = list,
			Text = "",
			Size = UDim2.new(1, -10, 0, 34),
			BackgroundColor3 = optionBackground,
			AutoButtonColor = false
		})
		create("UICorner", { Parent = optBtn, CornerRadius = UDim.new(0, 8) })

		local lbl = create("TextLabel", {
			Parent = optBtn,
			Text = opt,
			Size = UDim2.new(1, -50, 1, 0),
			Position = UDim2.new(0, 12, 0, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(235, 235, 235),
			Font = Enum.Font.Gotham,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left
		})

		local check = create("TextLabel", {
			Parent = optBtn,
			Text = "✓",
			Size = UDim2.new(0, 24, 0, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			BackgroundTransparency = 1,
			TextColor3 = neonBlue,
			Font = Enum.Font.GothamBlack,
			TextSize = 22,
			Visible = false
		})

		optionMap[opt] = { Button = optBtn, Check = check }

		optBtn.MouseEnter:Connect(function()
			TweenService:Create(optBtn, TweenInfo.new(0.15), { BackgroundColor3 = optionHover }):Play()
		end)
		optBtn.MouseLeave:Connect(function()
			TweenService:Create(optBtn, TweenInfo.new(0.25), { BackgroundColor3 = optionBackground }):Play()
		end)
		optBtn.MouseButton1Click:Connect(function()
			selectOption(opt)
			toggleDropdown()
		end)

		updateDropdownSize(false)
	end

	-----------------------------------------------------
	-- Setar lista de opções preservando scroll
	-----------------------------------------------------
	local function setOptions(newOptions)
		local currentScroll = list.CanvasPosition.Y -- salva posição atual
		local oldOptionMap = optionMap
		optionMap = {}

		local added = {}
		local removed = {}

		-- Identifica opções novas e removidas
		local lookupNew = {}
		for _, opt in ipairs(newOptions) do lookupNew[opt] = true end
		for opt, _ in pairs(oldOptionMap) do
			if not lookupNew[opt] then
				removed[#removed + 1] = opt
			else
				-- mantém item existente
				optionMap[opt] = oldOptionMap[opt]
			end
		end
		for _, opt in ipairs(newOptions) do
			if not optionMap[opt] then
				added[#added + 1] = opt
			end
		end

		-- Remove opções que não existem mais
		for _, opt in ipairs(removed) do
			oldOptionMap[opt].Button:Destroy()
		end

		-- Cria opções novas
		for _, opt in ipairs(added) do
			createOption(opt)
		end

		options = newOptions
		updateDropdownSize(true)

		-- restaura scroll suavemente
		task.defer(function()
			list.CanvasPosition = Vector2.new(0, currentScroll)
		end)
	end

	-----------------------------------------------------
	-- Inicialização
	-----------------------------------------------------
	for _, opt in ipairs(options) do
		createOption(opt)
	end
	updateDropdownSize(false)
	self:UpdateScrolling(self.Tabs[tab])

	return {
		SetOptions = function(_, newOptions) setOptions(newOptions) end,
		Frame = frame
	}
end



function SawMillHub:CreateInput(tab, text, placeholder, callback)
	local TweenService = game:GetService("TweenService")
	if not self.Tabs[tab] then return end
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
	local function updatePlaceholder()
		if box.Text == "" and not box:IsFocused() then
			TweenService:Create(placeholderLbl, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
		else
			TweenService:Create(placeholderLbl, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
		end
	end
	updatePlaceholder()
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

	self:UpdateScrolling(tab)
	return {
		Box = box,

		Get = function()
			return box.Text
		end,

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

-----------------------------------------------------
-- 🔑 Criar Keybind (visual moderno e otimizado)
-----------------------------------------------------
function SawMillHub:CreateKeybind(tab, text, defaultKey, callback)
	if not self.Tabs[tab] then return end

	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
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

	-- Sombra leve
	local shadow = Instance.new("ImageLabel")
	shadow.Parent = frame
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
	shadow.Size = UDim2.new(1, 8, 1, 8)
	shadow.Image = "rbxassetid://5028857084"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.85
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(24, 24, 276, 276)
	shadow.ZIndex = 0

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

	local stroke = Instance.new("UIStroke", keyButton)
	stroke.Color = Color3.fromRGB(90, 90, 90)
	stroke.Thickness = 1
	stroke.Transparency = 0.25

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
			TweenService:Create(keyButton, TweenInfo.new(0.08), {
				BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			}):Play()

			task.delay(0.12, function()
				if not listening then
					tweenColor(keyButton, Color3.fromRGB(40, 40, 40))
				end
			end)

			task.spawn(function()
				if callback then
					pcall(callback)
				end
			end)
		end
	end)
	table.insert(connections, keyConn)

	self:UpdateScrolling(tab)

	-- ✅ Retornar manipulador
	local api = {}

	function api:Get()
		return selectedKey
	end

	function api:Set(newKey)
		if typeof(newKey) == "EnumItem" and newKey.EnumType == Enum.KeyCode then
			selectedKey = newKey
			keyButton.Text = newKey.Name
		end
	end

	function api:Disconnect()
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
	local TweenService = game:GetService("TweenService")
	local DebrisService = game:GetService("Debris")
	local UserInputService = game:GetService("UserInputService")
	local isTouch = UserInputService.TouchEnabled

	-- Cores e ícones
	local COLORS = {
		info = Color3.fromRGB(0, 170, 255),
		success = Color3.fromRGB(0, 200, 100),
		error = Color3.fromRGB(255, 70, 70),
		warning = Color3.fromRGB(255, 180, 0),
		default = Color3.fromRGB(180, 180, 180)
	}
	local ICONS = {
		info = "rbxassetid://6034509993",
		success = "rbxassetid://6023426926",
		error = "rbxassetid://6023426921",
		warning = "rbxassetid://6023426921"
	}

	local color = COLORS[type] or COLORS.default
	local iconId = ICONS[type]

	-- Proporcionalidade
	local screenSize = workspace.CurrentCamera.ViewportSize
	local notifWidth = math.clamp(screenSize.X * 0.25, 240, 360)
	local notifPadding = 8
	local notifHeight = isTouch and 70 or 100

	self.ActiveNotifications = self.ActiveNotifications or {}
	local MAX_NOTIFS = self.MaxNotifs or 5

	-- Criar holder se não existir
	if not self.NotificationHolder then
		local holder = Instance.new("Frame")
		holder.Name = "NotificationHolder"
		holder.Parent = self.Gui
		holder.AnchorPoint = Vector2.new(1, 1)
		holder.Position = UDim2.new(1, -10, 1, -10)
		holder.Size = UDim2.new(0, notifWidth, 1, -20)
		holder.BackgroundTransparency = 1

		local layout = Instance.new("UIListLayout", holder)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, notifPadding)
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom

		self.NotificationHolder = holder
	end

	-- Remover notificações antigas se exceder
	while #self.ActiveNotifications >= MAX_NOTIFS do
		local oldest = table.remove(self.ActiveNotifications, 1)
		if oldest and oldest.Parent then
			TweenService:Create(oldest, TweenInfo.new(0.25), {Position = oldest.Position + UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1}):Play()
			DebrisService:AddItem(oldest, 0.4)
		end
	end

	-- Criar notificação
	local notif = Instance.new("Frame")
	notif.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	notif.Size = UDim2.new(0, notifWidth, 0, notifHeight)
	notif.BorderSizePixel = 0
	notif.ClipsDescendants = true
	notif.LayoutOrder = #self.ActiveNotifications + 1
	notif.Parent = self.NotificationHolder
	Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke", notif)
	stroke.Color = color
	stroke.Thickness = 1.2
	stroke.Transparency = 0.5

	-- Conteúdo interno
	local content = Instance.new("Frame", notif)
	content.Size = UDim2.new(1, -notifPadding*2, 1, -notifPadding*2)
	content.Position = UDim2.new(0, notifPadding, 0, notifPadding)
	content.BackgroundTransparency = 1
	content.ClipsDescendants = true

	local contentLayout = Instance.new("UIListLayout", content)
	contentLayout.FillDirection = Enum.FillDirection.Horizontal
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	contentLayout.Padding = UDim.new(0, 8)

	-- Ícone
	if iconId then
		local icon = Instance.new("ImageLabel", content)
		icon.Size = UDim2.new(0, 28, 0, 28)
		icon.Image = iconId
		icon.BackgroundTransparency = 1
		icon.ImageColor3 = color
	end

	-- Texto (título + mensagem)
	local textContainer = Instance.new("Frame", content)
	textContainer.BackgroundTransparency = 1
	textContainer.Size = UDim2.new(1, -36, 1, 0)
	textContainer.ClipsDescendants = true

	local textLayout = Instance.new("UIListLayout", textContainer)
	textLayout.FillDirection = Enum.FillDirection.Vertical
	textLayout.SortOrder = Enum.SortOrder.LayoutOrder
	textLayout.Padding = UDim.new(0, 2)

	local titleLabel = Instance.new("TextLabel", textContainer)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = tostring(title or "Notificação")
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = color
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Top
	titleLabel.Size = UDim2.new(1, 0, 0, 24)
	titleLabel.AutomaticSize = Enum.AutomaticSize.Y
	titleLabel.TextSize = isTouch and 16 or 18

	local msgLabel = Instance.new("TextLabel", textContainer)
	msgLabel.BackgroundTransparency = 1
	msgLabel.Text = tostring(message or "")
	msgLabel.Font = Enum.Font.Gotham
	msgLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	msgLabel.TextWrapped = true
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.TextYAlignment = Enum.TextYAlignment.Top
	msgLabel.Size = UDim2.new(1, 0, 1, 0)
	msgLabel.AutomaticSize = Enum.AutomaticSize.Y
	msgLabel.TextSize = isTouch and 16 or 20

	-- Barra de progresso (sempre abaixo do texto)
	local barHeight = math.clamp(notifHeight*0.06, 4, 6)
	local bar = Instance.new("Frame", notif)
	bar.AnchorPoint = Vector2.new(0,1)
	bar.Position = UDim2.new(0, 0, 1, -barHeight)
	bar.Size = UDim2.new(0, 0, 0, barHeight)
	bar.BackgroundColor3 = color
	bar.BorderSizePixel = 0
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

	-- Animação barra
	TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 0, barHeight)}):Play()

	-- Animação entrada
	notif.Position = UDim2.new(1, 40, 0, 0)
	TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 0
	}):Play()

	table.insert(self.ActiveNotifications, notif)

	-- Remoção automática
	task.delay(duration, function()
		if notif and notif.Parent then
			local tweenOut = TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = notif.Position + UDim2.new(1, 40, 0, 0),
				BackgroundTransparency = 1
			})
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				for i, v in ipairs(self.ActiveNotifications) do
					if v == notif then table.remove(self.ActiveNotifications, i); break end
				end
				if notif then notif:Destroy() end
			end)
		end
	end)
end

return SawMillHub
