--// SawMillHub.lua (LocalScript) - FULL CORE IMPROVED

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

--------------------------------------------------------------------
-- 🔥 REMOVE HUB ANTIGO COM SEGURANÇA TOTAL
--------------------------------------------------------------------
do
	local old = PlayerGui:FindFirstChild("SawMillHub")
	if old then
		local objVal = old:FindFirstChild("SawMillHubObject")
		if objVal and objVal.Value and objVal.Value.OnClose then
			pcall(function()
				objVal.Value.OnClose:Fire()
			end)
		end
		old:Destroy()
	end
end
--------------------------------------------------------------------

local SawMillHub = {}
SawMillHub.__index = SawMillHub

--//////////////////////////////////////////////////////////////
-- 🛠️ UTILITÁRIOS
--//////////////////////////////////////////////////////////////

local function Create(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

local function Tween(obj, time, props, style, direction)
	style = style or Enum.EasingStyle.Quint
	direction = direction or Enum.EasingDirection.Out
	
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(time, style, direction),
		props
	)
	tw:Play()
	return tw
end

--//////////////////////////////////////////////////////////////
-- 🖱️ DRAG + RESIZE PROFISSIONAL
--//////////////////////////////////////////////////////////////

local function EnableDragAndResize(topBar, mainFrame)

	------------------ DRAG ------------------

	local dragging = false
	local dragStart, startPos

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart

			mainFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	------------------ RESIZE ------------------

	local resizeHandle = Create("Frame", {
		Parent = mainFrame,
		Size = UDim2.new(0, 18, 0, 18),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(90, 90, 90),
		BackgroundTransparency = 0.2,
		ZIndex = 50
	})

	Create("UICorner", {
		Parent = resizeHandle,
		CornerRadius = UDim.new(0, 6)
	})

	local resizing = false
	local startSize, startInput

	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			startSize = mainFrame.Size
			startInput = input.Position
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then

			local delta = input.Position - startInput
			local viewport = Camera.ViewportSize

			local minW, minH = 350, 220
			local maxW = viewport.X - 40
			local maxH = viewport.Y - 40

			local newW = math.clamp(startSize.X.Offset + delta.X, minW, maxW)
			local newH = math.clamp(startSize.Y.Offset + delta.Y, minH, maxH)

			mainFrame.Size = UDim2.new(0, newW, 0, newH)
		end
	end)
end

--//////////////////////////////////////////////////////////////
-- ❌ CLOSE HUB (SEM MEMORY LEAK)
--//////////////////////////////////////////////////////////////

function SawMillHub:Close()
	if not self.Gui or self._Closing then return end
	self._Closing = true

	if self._RainbowConnection then
		self._RainbowConnection:Disconnect()
	end

	if self.OnClose then
		pcall(function()
			self.OnClose:Fire()
		end)
	end

	Tween(self.Main, 0.25, {
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1
	})

	task.delay(0.3, function()
		if self.Gui then
			self.Gui:Destroy()
		end
	end)
end

--//////////////////////////////////////////////////////////////
-- ➖ MINIMIZE
--//////////////////////////////////////////////////////////////

function SawMillHub:ToggleMinimize()
	if not self.Main then return end

	if self._Minimized then
		Tween(self.Main, 0.4, { Size = self._OriginalSize }, Enum.EasingStyle.Elastic)
		self._Minimized = false
	else
		self._OriginalSize = self.Main.Size
		Tween(self.Main, 0.3, {
			Size = UDim2.new(0, self._OriginalSize.X.Offset, 0, 42)
		})
		self._Minimized = true
	end
end

--//////////////////////////////////////////////////////////////
-- 🏗️ CONSTRUTOR COMPLETO
--//////////////////////////////////////////////////////////////

function SawMillHub.new(title, dragSpeed)

	local self = setmetatable({}, SawMillHub)

	self.OnClose = Instance.new("BindableEvent")

	self.Gui = Create("ScreenGui", {
		Name = "SawMillHub",
		ResetOnSpawn = false,
		Parent = PlayerGui
	})

	Create("ObjectValue", {
		Parent = self.Gui,
		Name = "SawMillHubObject",
		Value = self,
		Archivable = false
	})

	local mainSize = UDim2.new(0, 450, 0, 300)

	self.Main = Create("Frame", {
		Parent = self.Gui,
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, -225, 0.5, -150),
		BackgroundColor3 = Color3.fromRGB(28, 28, 28),
		ClipsDescendants = true
	})

	Create("UICorner", {
		Parent = self.Main,
		CornerRadius = UDim.new(0, 12)
	})

	local stroke = Create("UIStroke", {
		Parent = self.Main,
		Color = Color3.fromRGB(90, 90, 90),
		Thickness = 1.6
	})

	self._OriginalSize = mainSize
	self._Minimized = false

	---------------- TOPBAR ----------------

	local topBar = Create("Frame", {
		Parent = self.Main,
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	})

	Create("UICorner", {
		Parent = topBar,
		CornerRadius = UDim.new(0, 12)
	})

	local titleLabel = Create("TextLabel", {
		Parent = topBar,
		Text = title or "SawMillHub",
		Size = UDim2.new(1, -110, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 18
	})

	---------------- BUTTONS ----------------

	local function CreateTopButton(text, color, posX, callback)
		local btn = Create("TextButton", {
			Parent = topBar,
			Text = text,
			Size = UDim2.new(0, 32, 0, 32),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, posX, 0.5, 0),
			BackgroundColor3 = color,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			TextSize = 20,
			AutoButtonColor = false
		})

		Create("UICorner", {
			Parent = btn,
			CornerRadius = UDim.new(0, 8)
		})

		btn.MouseButton1Click:Connect(callback)

		btn.MouseEnter:Connect(function()
			Tween(btn, 0.15, { Size = UDim2.new(0, 36, 0, 36) })
		end)

		btn.MouseLeave:Connect(function()
			Tween(btn, 0.15, { Size = UDim2.new(0, 32, 0, 32) })
		end)

		return btn
	end

	self.MinimizeButton = CreateTopButton("–", Color3.fromRGB(255,190,60), -44, function()
		self:ToggleMinimize()
	end)

	CreateTopButton("X", Color3.fromRGB(235,75,75), -6, function()
		self:Close()
	end)

	CreateTopButton("R", Color3.fromRGB(90,170,255), -82, function()
		Tween(self.Main, 0.25, { Size = UDim2.new(0, 500, 0, 340) })
		task.delay(0.25, function()
			Tween(self.Main, 0.35, { Size = mainSize }, Enum.EasingStyle.Elastic)
		end)
	end)

	---------------- SIDEBAR ----------------

	self.Sidebar = Create("Frame", {
		Parent = self.Main,
		Size = UDim2.new(0, 140, 1, -42),
		Position = UDim2.new(0, 0, 0, 42),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	})

	Create("UICorner", {
		Parent = self.Sidebar,
		CornerRadius = UDim.new(0, 8)
	})

	self.TabHolder = Create("Frame", {
		Parent = self.Main,
		Size = UDim2.new(1, -140, 1, -42),
		Position = UDim2.new(0, 140, 0, 42),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	})

	Create("UICorner", {
		Parent = self.TabHolder,
		CornerRadius = UDim.new(0, 8)
	})

	---------------- DRAG ----------------

	EnableDragAndResize(topBar, self.Main)

	---------------- RAINBOW CONTROLADO ----------------

	local hue = 0
	self._RainbowConnection = RunService.RenderStepped:Connect(function(dt)
		hue = (hue + dt * 0.08) % 1
		stroke.Color = Color3.fromHSV(hue, 0.9, 1)
		titleLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
	end)

	---------------- OPEN ANIMATION ----------------

	Tween(self.Main, 0.4, { Size = mainSize }, Enum.EasingStyle.Elastic)

	return self
end

--// 🌙 SawMillHub:CreateTab - Abas modernas, dark e sem bugs
function SawMillHub:CreateTab(tabName, icon)
	local TweenService = game:GetService("TweenService")

	local function tween(obj, time, props)
		TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
	end

	-- 🧱 Cria a sidebar apenas uma vez
	if not self.TabScroll then
		local sidebar = create("Frame", {
			Parent = self.Sidebar,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(15, 15, 15),
			BorderSizePixel = 0,
			Name = "SidebarRounded"
		})

		create("UICorner", { Parent = sidebar, CornerRadius = UDim.new(0, 18) })
		create("UIStroke", {
			Parent = sidebar,
			Color = Color3.fromRGB(40, 40, 40),
			Thickness = 2,
			Transparency = 0.5
		})

		local scroll = create("ScrollingFrame", {
			Parent = sidebar,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ScrollBarThickness = 4,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y
		})

		create("UIListLayout", {
			Parent = scroll,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
			HorizontalAlignment = Enum.HorizontalAlignment.Center
		})

		create("UIPadding", {
			Parent = scroll,
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10)
		})

		self.TabScroll = scroll
	end

	-- 🧩 Cria o botão da aba
	local btn = create("TextButton", {
		Parent = self.TabScroll,
		Text = (icon and icon .. " " or "") .. tabName,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -10, 0, 44),
		BackgroundColor3 = Color3.fromRGB(28, 28, 28),
		TextColor3 = Color3.fromRGB(240, 240, 240),
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutoButtonColor = false,
		Name = "TabButton_" .. tabName
	})

	create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 12) })
	create("UIStroke", {
		Parent = btn,
		Color = Color3.fromRGB(70, 70, 70),
		Transparency = 0.5
	})

	-- 🪟 Container interno da aba
	local cont = create("Frame", {
		Parent = self.TabHolder,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		Visible = false,
		Name = "TabContent_" .. tabName
	})

	create("UICorner", { Parent = cont, CornerRadius = UDim.new(0, 16) })
	create("UIStroke", {
		Parent = cont,
		Color = Color3.fromRGB(55, 55, 55),
		Transparency = 0.5
	})

	-- Scrolling interno (conteúdo)
	local scroll = create("ScrollingFrame", {
		Parent = cont,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y
	})

	create("UIListLayout", {
		Parent = scroll,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10)
	})

	create("UIPadding", {
		Parent = scroll,
		PaddingTop = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12)
	})

	-- 🔗 Registro da aba
	local tab = {
		Name = tabName,
		Button = btn,
		Container = scroll,
		Frame = cont
	}
	self.Tabs[tabName] = tab

	-- 🔮 Alternância de abas sem efeitos extras
	local function showTab(targetTab)
		for _, t in pairs(self.Tabs) do
			t.Frame.Visible = (t == targetTab)
		end
		self.CurrentTab = targetTab
	end

	-- ✨ Clique direto para trocar aba
	btn.MouseButton1Click:Connect(function()
		if self.CurrentTab ~= tab then
			showTab(tab)
		end
	end)

	-- 🟢 Primeira aba ativa automaticamente
	if not self.CurrentTab then
		showTab(tab)
	end

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

--//////////////////////////////////////////////////////////////
-- 🎚️ CREATE SLIDER (NO LAG + NO MEMORY LEAK)
--//////////////////////////////////////////////////////////////

function SawMillHub:CreateSlider(tabName, text, min, max, increment, default, callback)

	local tab = self.Tabs[tabName]
	if not tab then return end

	min = tonumber(min) or 0
	max = tonumber(max) or 100
	increment = tonumber(increment) or 1
	default = math.clamp(default or min, min, max)

	local value = default
	local dragging = false

	local frame = Create("Frame", {
		Parent = tab.Container,
		Size = UDim2.new(1,-10,0,60),
		BackgroundColor3 = Color3.fromRGB(18,18,26)
	})

	Create("UICorner",{Parent = frame, CornerRadius = UDim.new(0,10)})

	local label = Create("TextLabel", {
		Parent = frame,
		Text = text..": "..default,
		Size = UDim2.new(1,-20,0,20),
		Position = UDim2.new(0,10,0,5),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(150,120,255),
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	local bar = Create("Frame", {
		Parent = frame,
		Size = UDim2.new(1,-20,0,8),
		Position = UDim2.new(0,10,0,38),
		BackgroundColor3 = Color3.fromRGB(30,30,40)
	})

	Create("UICorner",{Parent = bar, CornerRadius = UDim.new(0,4)})

	local fill = Create("Frame", {
		Parent = bar,
		Size = UDim2.new((default-min)/(max-min),0,1,0),
		BackgroundColor3 = Color3.fromRGB(120,90,255)
	})

	Create("UICorner",{Parent = fill, CornerRadius = UDim.new(0,4)})

	local function Round(v)
		return math.clamp(math.floor((v/increment)+0.5)*increment,min,max)
	end

	local function Update(v)
		v = Round(v)
		value = v

		local pct = (v-min)/(max-min)
		Tween(fill,0.15,{Size = UDim2.new(pct,0,1,0)})
		label.Text = text..": "..v

		if callback then
			task.spawn(callback,v)
		end
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			Update(((input.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X)*(max-min)+min)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			Update(((input.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X)*(max-min)+min)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	self:UpdateScrolling(tabName)

	return {
		Set = function(_,newVal)
			Update(newVal)
		end
	}
end

--//////////////////////////////////////////////////////////////
-- 🏷️ CREATE LABEL (RAINBOW OTIMIZADO)
--//////////////////////////////////////////////////////////////

function SawMillHub:CreateLabel(tab, text)
	if not self.Tabs[tab] then return end

	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")

	local frame = create("Frame", {
		Parent = self.Tabs[tab].Container,
		Size = UDim2.new(1, -10, 0, 50),
		BackgroundColor3 = Color3.fromRGB(25,25,25),
		ClipsDescendants = true
	})
	create("UICorner",{Parent = frame, CornerRadius = UDim.new(0,14)})

	local stroke = create("UIStroke",{
		Parent = frame,
		Color = Color3.fromRGB(80,80,80),
		Thickness = 1,
		Transparency = 0.5
	})

	local lbl = create("TextLabel",{
		Parent = frame,
		Text = tostring(text or "Label"),
		Size = UDim2.new(1,-20,1,-10),
		Position = UDim2.new(0,10,0,5),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(240,240,240),
		Font = Enum.Font.Gotham,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	-- 🌈 Rainbow controlado
	local hue = math.random()
	local connection

	connection = RunService.Heartbeat:Connect(function(dt)
		if not frame.Parent then
			connection:Disconnect()
			return
		end

		hue = (hue + dt * 0.15) % 1
		local c = Color3.fromHSV(hue,0.6,1)

		stroke.Color = c
		frame.BackgroundColor3 = Color3.fromHSV(hue,0.1,0.15)
	end)

	-- Hover
	frame.MouseEnter:Connect(function()
		TweenService:Create(frame,TweenInfo.new(0.2),{
			Size = UDim2.new(1,-6,0,52)
		}):Play()
	end)

	frame.MouseLeave:Connect(function()
		TweenService:Create(frame,TweenInfo.new(0.2),{
			Size = UDim2.new(1,-10,0,50)
		}):Play()
	end)

	self:UpdateScrolling(tab)

	return {
		Frame = frame,
		SetText = function(_,t)
			lbl.Text = tostring(t)
		end,
		Destroy = function()
			if connection then connection:Disconnect() end
			frame:Destroy()
		end
	}
end

--//////////////////////////////////////////////////////////////
-- 🔘 CREATE BUTTON (NEON OTIMIZADO)
--//////////////////////////////////////////////////////////////

function SawMillHub:CreateButton(tab, text, callback)
	if not self.Tabs[tab] then return end

	local TweenService = game:GetService("TweenService")

	local btn = create("TextButton",{
		Parent = self.Tabs[tab].Container,
		Text = tostring(text or ""),
		Size = UDim2.new(1,-10,0,40),
		BackgroundColor3 = Color3.fromRGB(28,28,38),
		TextColor3 = Color3.fromRGB(235,235,235),
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		AutoButtonColor = false
	})
	create("UICorner",{Parent = btn, CornerRadius = UDim.new(0,10)})

	local stroke = create("UIStroke",{
		Parent = btn,
		Color = Color3.fromRGB(70,70,100),
		Thickness = 2,
		Transparency = 0.4
	})

	-- 🌈 Tween rainbow (sem RenderStepped)
	local function rainbow()
		local hue = math.random()
		while btn.Parent do
			hue = (hue + 0.05) % 1
			local color = Color3.fromHSV(hue,0.9,1)

			TweenService:Create(stroke,TweenInfo.new(0.5),{
				Color = color
			}):Play()

			task.wait(0.5)
		end
	end

	task.spawn(rainbow)

	-- Hover
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn,TweenInfo.new(0.2),{
			BackgroundColor3 = Color3.fromRGB(45,45,60),
			Size = UDim2.new(1,-8,0,42)
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn,TweenInfo.new(0.2),{
			BackgroundColor3 = Color3.fromRGB(28,28,38),
			Size = UDim2.new(1,-10,0,40)
		}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		TweenService:Create(btn,TweenInfo.new(0.1),{
			BackgroundColor3 = Color3.fromRGB(20,20,28)
		}):Play()

		task.delay(0.1,function()
			TweenService:Create(btn,TweenInfo.new(0.2),{
				BackgroundColor3 = Color3.fromRGB(45,45,60)
			}):Play()
		end)

		if callback then
			pcall(callback)
		end
	end)

	self:UpdateScrolling(tab)

	return {
		Button = btn,
		Set = function(_,t)
			btn.Text = tostring(t)
		end
	}
end

function SawMillHub:CreateToggle(tab, text, default, callback)
	if not self.Tabs[tab] then return end
	local container = self.Tabs[tab].Container

	local TweenService = game:GetService("TweenService")
	-- O RunService e o RenderStepped que causavam os efeitos contínuos foram removidos.

	-- Cores (Mantidas as originais NEON)
	local NEON_ON = Color3.fromRGB(0, 255, 120)
	local NEON_OFF_BG = Color3.fromRGB(30, 30, 30)
	local NEON_OFF_GLOW = Color3.fromRGB(255, 50, 50)
	local TEXT_COLOR_OFF = Color3.fromRGB(180, 180, 180)

	local currentState = default == true
	local HANDLE_SIZE = 24
	-- Posições baseadas no código original
	local ON_POS = UDim2.new(1, -25, 0.5, -HANDLE_SIZE/2)
	local OFF_POS = UDim2.new(0, 1, 0.5, -HANDLE_SIZE/2)

	-- Container do toggle
	local toggle = Instance.new("Frame")
	toggle.Parent = container
	toggle.Size = UDim2.new(1, -10, 0, 44)
	toggle.BackgroundTransparency = 1

	-- Label
	local label = Instance.new("TextLabel")
	label.Parent = toggle
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextColor3 = currentState and NEON_ON or TEXT_COLOR_OFF
	label.TextXAlignment = Enum.TextXAlignment.Left

	local labelGradient = Instance.new("UIGradient", label)
	labelGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 120, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 200))
	}
	labelGradient.Rotation = 0 -- Fixo (parou de girar)

	-- Switch
	local switch = Instance.new("Frame")
	switch.Parent = toggle
	switch.AnchorPoint = Vector2.new(1, 0.5)
	switch.Position = UDim2.new(1, -10, 0.5, 0)
	switch.Size = UDim2.new(0, 55, 0, 26)
	switch.BackgroundColor3 = currentState and NEON_ON or NEON_OFF_BG
	switch.BorderSizePixel = 0
	local switchCorner = Instance.new("UICorner", switch)
	switchCorner.CornerRadius = UDim.new(1, 0)

	local glow = Instance.new("UIStroke")
	glow.Parent = switch
	glow.Color = currentState and NEON_ON or NEON_OFF_GLOW
	glow.Thickness = 3
	glow.Transparency = 0.3 -- Fixo (parou de pulsar)

	-- Handle
	local handle = Instance.new("Frame")
	handle.Parent = switch
	handle.Size = UDim2.new(0, 24, 0, 24)
	handle.Position = currentState and ON_POS or OFF_POS
	handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	handle.BorderSizePixel = 0
	local handleCorner = Instance.new("UICorner", handle)
	handleCorner.CornerRadius = UDim.new(1, 0)

	local handleGradient = Instance.new("UIGradient", handle)
	handleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200,200,255))
	})
	handleGradient.Rotation = 30 -- Fixo (parou de girar)

	-- Partículas pré-criadas
	local particleCount = 6
	local particles = {}
	for i = 1, particleCount do
		local part = Instance.new("Frame")
		part.Size = UDim2.new(0,4,0,4)
		part.Position = UDim2.new(math.random(),0,math.random(),0)
		part.AnchorPoint = Vector2.new(0.5,0.5)
		part.BackgroundColor3 = currentState and NEON_ON or NEON_OFF_GLOW
		part.BorderSizePixel = 0
		part.ZIndex = 2
		part.Parent = switch
		part.Visible = false -- Inicia invisível
		table.insert(particles, part)
	end

    -- Função de Animação das Partículas (acorre APENAS no clique)
    local function animateParticles(state)
        local color = state and NEON_ON or NEON_OFF_GLOW
        
        for _, part in ipairs(particles) do
            part.BackgroundColor3 = color
            part.Visible = true
            
            -- Tweens para fazer a partícula "voar" para fora
            local targetX = math.random() * 2 - 1.5
            local targetY = math.random() * 2 - 1.5
            local targetPos = UDim2.new(0.5, targetX * 30, 0.5, targetY * 30)
            
            TweenService:Create(part, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = targetPos,
                BackgroundTransparency = 1,
            }):Play()
            
            task.delay(0.4, function()
                part.BackgroundTransparency = 0
                -- Reposiciona para o próximo uso
                part.Position = UDim2.new(math.random(),0,math.random(),0) 
                part.Visible = false
            end)
        end
    end

	-- Pulso expandido (acorre APENAS no clique)
	local function createPulse(color)
		local pulse = Instance.new("Frame")
		pulse.Parent = switch
		pulse.AnchorPoint = Vector2.new(0.5, 0.5)
		pulse.Position = UDim2.new(0.5,0,0.5,0)
		pulse.Size = UDim2.new(0.9,0,0.9,0)
		pulse.BackgroundColor3 = color
		pulse.BackgroundTransparency = 0.7
		pulse.BorderSizePixel = 0
		pulse.ZIndex = -1
		local pulseCorner = Instance.new("UICorner", pulse)
		pulseCorner.CornerRadius = UDim.new(1,0)
        
        -- Efeito de expansão
		TweenService:Create(pulse, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size=UDim2.new(2.5,0,2.5,0),
			BackgroundTransparency=1
		}):Play()
		game:GetService("Debris"):AddItem(pulse,0.6)
	end

	-- Função para atualizar estado
	local function updateToggle(state)
		currentState = state
		local colorBG = state and NEON_ON or NEON_OFF_BG
		local colorGlow = state and NEON_ON or NEON_OFF_GLOW
		local colorText = state and NEON_ON or TEXT_COLOR_OFF

		-- Transições de Cor e Posição (Mantidas)
		TweenService:Create(switch, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3=colorBG}):Play()
		TweenService:Create(glow, TweenInfo.new(0.35), {Color=colorGlow}):Play()
		TweenService:Create(label, TweenInfo.new(0.35), {TextColor3=colorText}):Play()
		TweenService:Create(handle, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position=state and ON_POS or OFF_POS}):Play()

        -- Efeitos que acontecem no clique (Pulse e Partículas)
		createPulse(colorGlow)
        animateParticles(state)

		-- Bounce elegante do handle (Mantido)
		TweenService:Create(handle, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0,30,0,30)}):Play()
		task.delay(0.2,function()
			TweenService:Create(handle, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0,24,0,24)}):Play()
		end)

		if callback then task.spawn(callback, currentState) end
	end

	local function onToggle()
		updateToggle(not currentState)
	end

    -- Inicializa o estado visual corretamente (Chama o update para definir as cores e posições iniciais)
    updateToggle(currentState)
    -- Se o estado inicial for true e houver callback, chama-o
    if callback and default then
        task.spawn(callback, true)
    end
    
	switch.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			onToggle()
		end
	end)

	-- Hover (Mantido)
	switch.MouseEnter:Connect(function()
		TweenService:Create(switch, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundTransparency=0.05}):Play()
	end)
	switch.MouseLeave:Connect(function()
		TweenService:Create(switch, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundTransparency=0}):Play()
	end)

	-- *** O código original de animação contínua (RenderStepped) está ausente ***

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
