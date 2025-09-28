local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local CoreGui = LocalPlayer:WaitForChild("PlayerGui") 
local Mouse = LocalPlayer:GetMouse() -- Objeto Mouse para posição absoluta

local SawMillHub = {}
SawMillHub.__index = SawMillHub

-----------------------------------------------------
-- CONSTANTES DE COR ESSENCIAIS PARA O SISTEMA
-----------------------------------------------------
local NEON_COLOR = Color3.fromRGB(0, 170, 255)
local TEXT_COLOR = Color3.fromRGB(235, 235, 235)
local BG_COLOR = Color3.fromRGB(35, 35, 35)
local BORDER_COLOR = Color3.fromRGB(70, 70, 70)


-----------------------------------------------------
-- Criador seguro de Instâncias
-----------------------------------------------------
local function create(class, props)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			pcall(function() inst[k] = v end)
		end
	end
	return inst
end

-----------------------------------------------------
-- Função de Fechamento (Corrigida e Reforçada)
-----------------------------------------------------
function SawMillHub:Close(skipOnCloseEvent)
	local self = self
	if not self.Gui or not self.Gui.Parent or not self.Main then return end

	-- 1. Dispara o evento de fechar
	if not skipOnCloseEvent and self.OnClose and type(self.OnClose) == "function" then
		pcall(self.OnClose)
	end

	local currentSize = self.Main.Size
	local currentPos = self.Main.Position

	-- 2. Animação de Fechamento
	local targetXOffset = currentPos.X.Offset + currentSize.X.Offset * 0.05
	local targetYOffset = currentPos.Y.Offset + currentSize.Y.Offset * 0.05

	-- Animação de escala e fade out do frame principal
	TweenService:Create(self.Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(currentSize.X.Scale, currentSize.X.Offset * 0.9, currentSize.Y.Scale, currentSize.Y.Offset * 0.9),
		Position = UDim2.new(currentPos.X.Scale, targetXOffset, currentPos.Y.Scale, targetYOffset),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.new(0, 0, 0)
	}):Play()

	-- Anima o fade out dos elementos internos de forma segura
	for _, child in ipairs(self.Main:GetDescendants()) do
		if child:IsA("GuiObject") then
			local properties = {}

			-- Animação de Background
			if pcall(function() local t = child.BackgroundTransparency end) then
				properties.BackgroundTransparency = 1
			end

			-- Animação de Text
			if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
				if pcall(function() local t = child.TextTransparency end) then
					properties.TextTransparency = 1
				end
			end

			-- Animação de Imagem
			if child:IsA("ImageLabel") or child:IsA("ImageButton") then
				if pcall(function() local t = child.ImageTransparency end) then
					properties.ImageTransparency = 1
				end
			end

			if next(properties) then -- Verifica se alguma propriedade foi definida
				TweenService:Create(child, TweenInfo.new(0.25), properties):Play()
			end
		end
	end

	-- 3. Destrói a GUI após a animação
	task.delay(0.35, function()
		if self.Gui and self.Gui.Parent then
			self.Gui:Destroy()
		end
	end)
end

-----------------------------------------------------
-- Construtor Principal
-----------------------------------------------------
function SawMillHub.new(title, dragSpeed)
	-- dragSpeed: "Default" ou "Slow"
	dragSpeed = dragSpeed or "Default"

	-- -----------------------------------------------------
	-- Fechamento da GUI Antiga (com OnClose)
	-- -----------------------------------------------------
	local oldGui = CoreGui:FindFirstChild("SawMillHub")
	if oldGui then
		local oldHub = oldGui:FindFirstChild("SawMillHubObject")
		if oldHub and oldHub.Value then
			local oldHubInstance = oldHub.Value
			if oldHubInstance and oldHubInstance.Close then
				task.spawn(function()
					oldHubInstance:Close()
				end)
			else
				pcall(function() oldGui:Destroy() end)
			end
		else
			pcall(function() oldGui:Destroy() end)
		end
	end
	-- -----------------------------------------------------

	local self = setmetatable({}, SawMillHub)
	local isTouch = UserInputService.TouchEnabled

	self.OnClose = nil

	self.Gui = create("ScreenGui", {
		Parent = CoreGui,
		ResetOnSpawn = false,
		Name = "SawMillHub"
	})

	local hubRef = create("ObjectValue", {
		Parent = self.Gui,
		Name = "SawMillHubObject",
		Value = self,
		Archivable = false
	})


	local mainSize = isTouch and UDim2.new(0, 380, 0, 300) or UDim2.new(0, 560, 0, 400)
	local mainPos = UDim2.new(0.5, -(mainSize.X.Offset/2), 0.5, -(mainSize.Y.Offset/2))

	-- Janela Principal
	self.Main = create("Frame", {
		Parent = self.Gui,
		Size = mainSize,
		Position = mainPos,
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		ClipsDescendants = true
	})
	create("UICorner", { Parent = self.Main, CornerRadius = UDim.new(0, 12) })
	create("UIStroke", { Parent = self.Main, Color = Color3.fromRGB(70, 70, 70), Thickness = 1.5 })

	-----------------------------------------------------
	-- Barra Superior
	-----------------------------------------------------
	local topBar = create("Frame", {
		Parent = self.Main,
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Color3.fromRGB(18, 18, 18),
		Name = "TopBar"
	})
	create("UICorner", { Parent = topBar, CornerRadius = UDim.new(0, 12) })
	create("UIStroke", { Parent = topBar, Color = Color3.fromRGB(50, 50, 50), Thickness = 1 })

	create("TextLabel", {
		Parent = topBar,
		Text = title or "SawMillHub",
		Size = UDim2.new(1, -50, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 18
	})
    
	-- CORES DO BOTÃO DE FECHAR (mantidas)
	local baseRed = Color3.fromRGB(255, 60, 60)
	local hoverRed = Color3.fromRGB(255, 100, 100)
	local clickRed = Color3.fromRGB(180, 0, 0)
	local neonRed = Color3.fromRGB(255, 0, 0)

	-----------------------------------------------------
	-- Botão de Fechar GUI (X) ❌ (Simples, para reduzir o código)
	-----------------------------------------------------
	local closeButton = create("TextButton", {
		Parent = topBar,
		Text = "X",
		Size = UDim2.new(0, 32, 0, 32),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		BackgroundColor3 = baseRed,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		AutoButtonColor = false,
		ZIndex = 2
	})
	create("UICorner", { Parent = closeButton, CornerRadius = UDim.new(0, 8) })
	
    -- Lógica para fechar
	closeButton.MouseButton1Click:Connect(function()
		self:Close()
	end)
	-----------------------------------------------------
	-- Fim Botão de Fechar
	-----------------------------------------------------

	-----------------------------------------------------
	-- Sistema de Drag Principal (Força Mouse Absoluto)
	-----------------------------------------------------
	local dragging = false
	local dragStartOffset = Vector2.new(0, 0) 
	local targetPos = self.Main.Position -- Posição alvo para o Lerp
    
	-- Define quão rápido o frame segue o mouse/alvo
	local lerpSpeed = (dragSpeed == "Slow") and 0.1 or 1 

    -- Inicia o arrasto
	topBar.InputBegan:Connect(function(input)
        -- Apenas para Mouse ou Touch
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			
			-- Calcula a distância do clique até o canto superior esquerdo da Main
			local mainPos = self.Main.AbsolutePosition
			dragStartOffset = input.Position - mainPos 
		end
	end)

    -- Finaliza o arrasto
	topBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

    ----------------------------------------------------------------
    -- RenderLoop (Execução do Movimento de Arrasto)
    ----------------------------------------------------------------
	RunService.RenderStepped:Connect(function(dt)
		if dragging then
            -- Obtém a posição absoluta do mouse (funciona mesmo que o cursor seja resetado)
            local currentMousePos = Vector2.new(Mouse.X, Mouse.Y)
            
            -- O novo canto da GUI é a posição do mouse menos o offset inicial
            local newXOffset = currentMousePos.X - dragStartOffset.X
            local newYOffset = currentMousePos.Y - dragStartOffset.Y

			-- Define a posição alvo
			targetPos = UDim2.new(
				0, newXOffset, -- Sempre 0 Scale, movemos por Offset
				0, newYOffset
			)
            
            -- Animação (Lerp)
			self.Main.Position = self.Main.Position:Lerp(targetPos, lerpSpeed)
            
		elseif not dragging and (self.Main.Position ~= targetPos) then
            -- Garante que o Lerp finalize a animação quando parar de arrastar
			self.Main.Position = self.Main.Position:Lerp(targetPos, lerpSpeed)
		end
	end)
	-----------------------------------------------------
	-- Fim Sistema de Drag
	-----------------------------------------------------


	-----------------------------------------------------
	-- Sidebar + TabHolder
	-----------------------------------------------------
	self.Sidebar = create("Frame", {
		Parent = self.Main,
		Size = UDim2.new(0, 140, 1, -42),
		Position = UDim2.new(0, 0, 0, 42),
		BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	})
	create("UICorner", { Parent = self.Sidebar, CornerRadius = UDim.new(0, 8) })
	local sideLayout = create("UIListLayout", { Parent = self.Sidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
	sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	self.TabHolder = create("Frame", {
		Parent = self.Main,
		Size = UDim2.new(1, -140, 1, -42),
		Position = UDim2.new(0, 140, 0, 42),
		BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	})
	create("UICorner", { Parent = self.TabHolder, CornerRadius = UDim.new(0, 8) })

	-- Inicialização
	self.Tabs = {}
	self.Keybinds = {}
	self.Notifs = {}
	self.MaxNotifs = 5

	return self
end
-----------------------------------------------------
-- Criar Tab com scroll automático e hover suave
-----------------------------------------------------
function SawMillHub:CreateTab(tabName, icon)
	if not self.TabScroll then
		local scroll = create("ScrollingFrame", {
			Parent = self.Sidebar,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y
		})
		local layout = create("UIListLayout", { Parent = scroll, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
		create("UIPadding", { Parent = scroll, PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) })
		self.TabScroll = scroll
	end

	local btn = create("TextButton", {
		Parent = self.TabScroll,
		Text = (icon and icon.." " or "") .. tabName,
		Size = UDim2.new(1, -10, 0, 34),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamSemibold,
		TextSize = 14
	})
	create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 8) })

	local cont = create("ScrollingFrame", {
		Parent = self.TabHolder,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y
	})
	create("UIListLayout", { Parent = cont, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
	create("UIPadding", { Parent = cont, PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) })

	local tab = { Name = tabName, Button = btn, Container = cont }
	self.Tabs[tabName] = tab

	btn.MouseButton1Click:Connect(function()
		for _, t in pairs(self.Tabs) do
			t.Container.Visible = false
			TweenService:Create(t.Button, TweenInfo.new(0.25), { BackgroundColor3 = Color3.fromRGB(40, 40, 40) }):Play()
		end
		cont.Visible = true
		TweenService:Create(btn, TweenInfo.new(0.25), { BackgroundColor3 = Color3.fromRGB(70, 70, 70) }):Play()
		self.CurrentTab = tab
	end)

	if not self.CurrentTab then
		cont.Visible = true
		self.CurrentTab = tab
		btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	end

	return tab
end

-----------------------------------------------------
-- Atualizar Scroll
-----------------------------------------------------
function SawMillHub:UpdateScrolling(tabName)
	local tab = (type(tabName) == "table" and tabName) or self.Tabs[tabName]
	if not tab or not tab.Container then return end

	local layout = tab.Container:FindFirstChildOfClass("UIListLayout")
	if not layout then return end

	local total = 0
	for _, child in ipairs(tab.Container:GetChildren()) do
		if child:IsA("GuiObject") and child.Visible then
			total = total + child.Size.Y.Offset + layout.Padding.Offset
		end
	end
	tab.Container.CanvasSize = UDim2.new(0, 0, 0, total + 10)
end

-----------------------------------------------------
-- Label (Corrigido para aceitar {Content, Color})
-----------------------------------------------------

-- Alteração: Adicionado 'initialContent' como terceiro parâmetro
function SawMillHub:CreateLabel(tab, text, initialContent)
	if not self.Tabs[tab] then return end

	local frame = create("Frame", {
		Parent = self.Tabs[tab].Container,
		Size = UDim2.new(1, -10, 0, 40),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BorderSizePixel = 0,
	})
	create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 10) })
	create("UIStroke", { Parent = frame, Color = Color3.fromRGB(60, 60, 60), Thickness = 1 })

	local lbl = create("TextLabel", {
		Parent = frame,
		-- Define o texto inicial
		Text = tostring(text or "") .. ": " .. tostring(initialContent or "N/A"), 
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(220, 220, 220), -- Cor padrão para o texto
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextWrapped = true
	})
	
	-- Captura o nome da propriedade para uso no Set()
	local propertyName = tostring(text or "Propriedade")

	-- Efeito sutil ao passar o mouse (PC)
	lbl.MouseEnter:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
	end)
	lbl.MouseLeave:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
	end)

	self:UpdateScrolling(tab)

	-- Retornar objeto com função Set
	local labelObject = {}

	-- CORREÇÃO AQUI: Agora aceita uma table {Content=string, Color=Color3}
	function labelObject:Set(data)
        -- Assume que 'data' é uma table, mas aceita string para compatibilidade simples
        local newContent = type(data) == "table" and tostring(data.Content or "N/A") or tostring(data or "N/A")
        local newColor = type(data) == "table" and data.Color
        
        -- Atualiza o texto: "Propriedade: Conteúdo Novo"
        lbl.Text = propertyName .. ": " .. newContent
        
        -- Se uma cor for fornecida, ela é aplicada
        if newColor and newColor:IsA("Color3") then
            lbl.TextColor3 = newColor
        else
            -- Se não houver cor, volta para o padrão (ou mantém a anterior se for nil)
            lbl.TextColor3 = TEXT_COLOR -- TEXT_COLOR é a constante que você definiu
        end
	end

	-- Caso você queira acessar o próprio frame
	labelObject.Frame = frame
	labelObject.Label = lbl

	return labelObject
end

-----------------------------------------------------
-- Botão Profissional Moderno (Corrigido com :Set)
-----------------------------------------------------
function SawMillHub:CreateButton(tab, text, callback)
	if not self.Tabs[tab] then return end

	local initialText = tostring(text or "")

	local btn = create("TextButton", {
		Parent = self.Tabs[tab].Container,
		Text = initialText,
		Size = UDim2.new(1, -10, 0, 42),
		BackgroundColor3 = Color3.fromRGB(45, 45, 45),
		TextColor3 = Color3.fromRGB(235, 235, 235),
		Font = Enum.Font.GothamSemibold,
		TextSize = 15,
		AutoButtonColor = false
	})
	create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 10) })

	-- Stroke que muda de cor ao clicar
	local stroke = create("UIStroke", {
		Parent = btn,
		Color = Color3.fromRGB(70, 70, 70),
		Thickness = 1.5,
		Transparency = 0.3
	})

	-- Sombra leve
	local shadow = create("ImageLabel", {
		Parent = btn,
		Size = UDim2.new(1, 10, 1, 10),
		Position = UDim2.new(0, -5, 0, -2),
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217", -- sombra suave
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.8,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		ZIndex = 0
	})

	-----------------------------------------------------
	-- Hover Effect (PC e Mobile)
	-----------------------------------------------------
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		}):Play()
	end)

	-----------------------------------------------------
	-- Click Feedback (toque/click)
	-----------------------------------------------------
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			TextColor3 = Color3.fromRGB(180, 220, 255)
		}):Play()

		TweenService:Create(stroke, TweenInfo.new(0.15), {
			Color = Color3.fromRGB(100, 160, 255),
			Transparency = 0
		}):Play()
	end)

	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.25), {
			BackgroundColor3 = Color3.fromRGB(60, 60, 60),
			TextColor3 = Color3.fromRGB(235, 235, 235)
		}):Play()

		TweenService:Create(stroke, TweenInfo.new(0.25), {
			Color = Color3.fromRGB(70, 70, 70),
			Transparency = 0.3
		}):Play()
	end)

	-----------------------------------------------------
	-- Execução do callback
	-----------------------------------------------------
	btn.MouseButton1Click:Connect(function()
		if callback then
			pcall(callback)
		end
	end)

	self:UpdateScrolling(tab)

	-- Retorna o objeto de controle
	return {
		Button = btn, -- O objeto nativo para acesso direto

		-- Método Get (obter o texto atual)
		Get = function() 
			return btn.Text 
		end,

		-- Método Set (alterar o texto)
		Set = function(_, newText) 
			btn.Text = tostring(newText)
		end
	}
end

function SawMillHub:CreateToggle(tab, text, default, callback)
	local TweenService = game:GetService("TweenService")
	local DebrisService = game:GetService("Debris")

	if not self.Tabs[tab] then return end
	local container = self.Tabs[tab].Container

	-- CORES NEON VIBRANTES
	local NEON_ON = Color3.fromRGB(0, 255, 120)    -- Fundo Verde Neon
	local NEON_OFF_BG = Color3.fromRGB(150, 40, 40) -- Fundo Vermelho Sutil
	local NEON_OFF_GLOW = Color3.fromRGB(255, 50, 50) -- Vermelho Neon puro
	local TEXT_COLOR_OFF = Color3.fromRGB(180, 180, 180)

	-- Estado inicial
	local currentState = default == true

	-- Posições
	local ON_POS = UDim2.new(1, -25, 0.5, -12)
	local OFF_POS = UDim2.new(0, 1, 0.5, -12)

	-- Container principal
	local toggle = create("Frame", {
		Parent = container,
		Size = UDim2.new(1, -10, 0, 45),
		BackgroundTransparency = 1
	})

	-- Label
	local label = create("TextLabel", {
		Parent = toggle,
		Size = UDim2.new(0.7, 0, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = currentState and NEON_ON or TEXT_COLOR_OFF,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	-- Switch base
	local switch = create("Frame", {
		Parent = toggle,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 55, 0, 26),
		BackgroundColor3 = currentState and NEON_ON or NEON_OFF_BG,
		BorderSizePixel = 0,
	})
	create("UICorner", {Parent = switch, CornerRadius = UDim.new(1, 0)})

	-- Glow neon
	local glow = create("UIStroke", {
		Parent = switch,
		Color = currentState and NEON_ON or NEON_OFF_GLOW,
		Transparency = currentState and 0.2 or 0.4,
		Thickness = 2
	})

	-- Handle
	local handle = create("Frame", {
		Parent = switch,
		Size = UDim2.new(0, 24, 0, 24),
		Position = currentState and ON_POS or OFF_POS,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	})
	create("UICorner", {Parent = handle, CornerRadius = UDim.new(1, 0)})

	-- Gradiente animado no handle
	local gradient = create("UIGradient", {
		Parent = handle,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200,200,200))
		}),
		Rotation = 45
	})

	task.spawn(function()
		while handle.Parent do
			gradient.Rotation = (gradient.Rotation + 1) % 360
			task.wait(0.016)
		end
	end)

	-- Função de pulso
	local function createPulse(color)
		local pulse = create("Frame", {
			Parent = switch,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.9, 0, 0.9, 0),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			ZIndex = -1
		})
		create("UICorner", {Parent = pulse, CornerRadius = UDim.new(1, 0)})

		TweenService:Create(pulse, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1.8, 0, 1.8, 0),
			BackgroundTransparency = 1
		}):Play()
		DebrisService:AddItem(pulse, 0.5)
	end

	-- Função principal de toggle
	local function updateToggle(state, triggerCallback)
		currentState = state

		-- Animação de click
		TweenService:Create(switch, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 52, 0, 24)}
		):Play()
		task.delay(0.1, function()
			TweenService:Create(switch, TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
				{Size = UDim2.new(0, 55, 0, 26)}
			):Play()
		end)

		-- Define cores
		local targetGlowColor = currentState and NEON_ON or NEON_OFF_GLOW
		local targetBGColor = currentState and NEON_ON or NEON_OFF_BG
		local targetLabelColor = currentState and NEON_ON or TEXT_COLOR_OFF

		-- Atualiza visuais
		TweenService:Create(switch, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = targetBGColor}
		):Play()
		TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{TextColor3 = targetLabelColor}
		):Play()
		TweenService:Create(glow, TweenInfo.new(0.35),
			{Color = targetGlowColor, Transparency = currentState and 0.2 or 0.4}
		):Play()

		-- Move handle
		TweenService:Create(handle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Position = currentState and ON_POS or OFF_POS}
		):Play()

		-- Pulso visual
		createPulse(targetGlowColor)

		-- Callback
		if callback and triggerCallback then
			task.spawn(callback, currentState)
		end
	end

	-- Alternar estado
	local function toggleSwitch()
		updateToggle(not currentState, true)
	end

	-- Dispara callback inicial
	if currentState and callback then
		task.spawn(callback, currentState)
	end

	-- Clique do usuário
	local isHolding = false
	switch.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if isHolding then return end
			isHolding = true
			toggleSwitch()
		end
	end)
	switch.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isHolding = false
		end
	end)

	-- Hover animado
	switch.MouseEnter:Connect(function()
		TweenService:Create(glow, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{Thickness = 3, Transparency = 0.1}
		):Play()
	end)
	switch.MouseLeave:Connect(function()
		TweenService:Create(glow, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{Thickness = 2, Transparency = currentState and 0.2 or 0.4}
		):Play()
	end)

	self:UpdateScrolling(tab)

	-- Retorna um objeto com controle manual
	local toggleObject = {}

	-- Define o estado manualmente (true = ligado, false = desligado)
	function toggleObject:Set(state)
		updateToggle(state, true)
	end

	-- Pega o estado atual
	function toggleObject:Get()
		return currentState
	end

	-- Referências úteis
	toggleObject.Frame = toggle
	toggleObject.Switch = switch

	return toggleObject
end

function SawMillHub:CreateSlider(tab, text, min, max, default, increment, callback)
	if not self.Tabs[tab] then return end
	min, max = tonumber(min) or 0, tonumber(max) or 100
	increment = tonumber(increment) or 1

	local currentValue = default or min -- Armazena o valor atual

	if increment > (max - min) then
		increment = max - min
		if increment <= 0 then increment = max end
	end

	default = math.clamp(default or min, min, max)
	currentValue = default -- Define o valor inicial

	local frame = create("Frame", {
		Parent = self.Tabs[tab].Container,
		Size = UDim2.new(1, -10, 0, 70),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BackgroundTransparency = 0.05
	})
	create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 10) })
	create("UIStroke", { Parent = frame, Color = Color3.fromRGB(70, 70, 70), Thickness = 1.2, Transparency = 0.3 })

	-- LABEL
	local lbl = create("TextLabel", {
		Parent = frame,
		Text = string.format("%s: %d", tostring(text or "Slider"), default),
		Size = UDim2.new(0.75, 0, 0, 20),
		Position = UDim2.new(0, 8, 0, 6),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(235, 235, 235),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 15
	})

	-- INPUT CIRCULAR
	local inputCircle = create("TextBox", {
		Parent = frame,
		Size = UDim2.new(0, 38, 0, 38),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 6),
		Text = tostring(default),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		TextColor3 = Color3.fromRGB(220, 220, 220),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		ClearTextOnFocus = false
	})
	create("UICorner", { Parent = inputCircle, CornerRadius = UDim.new(1, 0) })
	create("UIStroke", { Parent = inputCircle, Color = Color3.fromRGB(100, 100, 100), Thickness = 1.5, Transparency = 0.4 })

	-- Glow do input
	local glow = create("ImageLabel", {
		Parent = inputCircle,
		Size = UDim2.new(2.5, 0, 2.5, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://5028857472",
		ImageColor3 = Color3.fromRGB(0, 200, 255),
		ImageTransparency = 0.8,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		ZIndex = 0
	})

	local function clampToIncrement(val)
		val = math.clamp(val, min, max)
		return math.floor(val / increment + 0.5) * increment
	end

	-- BARRA
	local bar = create("Frame", {
		Parent = frame,
		Size = UDim2.new(1, -65, 0, 10),
		Position = UDim2.new(0, 10, 0, 40),
		BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	})
	create("UICorner", { Parent = bar, CornerRadius = UDim.new(0, 5) })

	-- FILL
	local fill = create("Frame", {
		Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
		Parent = bar,
		BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	})
	create("UICorner", { Parent = fill, CornerRadius = UDim.new(0, 5) })
	local gradient = create("UIGradient", {
		Parent = fill,
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 200))
		}
	})

	task.spawn(function()
		while fill.Parent do
			for i = 0, 360, 2 do
				gradient.Rotation = i
				task.wait(0.05)
			end
		end
	end)

	-- THUMB
	local thumb = create("Frame", {
		Parent = bar,
		Size = UDim2.new(0, 18, 0, 18),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	})
	create("UICorner", { Parent = thumb, CornerRadius = UDim.new(1, 0) })
	create("UIStroke", { Parent = thumb, Color = Color3.fromRGB(255, 255, 255), Thickness = 1.5, Transparency = 0.4 })

	-- Glow no thumb
	local thumbGlow = create("ImageLabel", {
		Parent = thumb,
		Size = UDim2.new(2.5, 0, 2.5, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://5028857472",
		ImageColor3 = Color3.fromRGB(0, 170, 255),
		ImageTransparency = 0.6,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		ZIndex = 0
	})

	task.spawn(function()
		while thumbGlow.Parent do
			TweenService:Create(thumbGlow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				Size = UDim2.new(2.8,0,2.8,0),
				ImageTransparency = 0.45
			}):Play()
			task.wait(1.2)
		end
	end)

	local dragging = false

	-- FUNÇÃO UPDATE SLIDER (definida ANTES do inputCircle.FocusLost)
	local function updateSlider(val, instant)
		val = clampToIncrement(val)
		if val > max then val = max end

		-- Somente atualiza se o valor mudou
		if val == currentValue then return end
		currentValue = val

		local pct = (val - min) / (max - min)

		TweenService:Create(fill, TweenInfo.new(instant and 0 or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(pct, 0, 1, 0)
		}):Play()

		TweenService:Create(thumb, TweenInfo.new(instant and 0 or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(pct, 0, 0.5, 0)
		}):Play()

		lbl.Text = string.format("%s: %d", text, val)
		inputCircle.Text = tostring(val)

		if callback then task.spawn(callback, val) end
	end

	inputCircle.Focused:Connect(function()
		TweenService:Create(glow, TweenInfo.new(0.3), {ImageTransparency = 0.3}):Play()
	end)
	inputCircle.FocusLost:Connect(function()
		TweenService:Create(glow, TweenInfo.new(0.4), {ImageTransparency = 0.8}):Play()
		local num = tonumber(inputCircle.Text)
		if num then
			num = clampToIncrement(num)
			if num > max then num = max end
			inputCircle.Text = tostring(num)
			updateSlider(num, true)
		else
			-- Se o usuário digitou algo inválido, retorna ao valor atual.
			inputCircle.Text = tostring(currentValue) 
		end
	end)

	-- DRAGGING
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateSlider((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X * (max-min) + min)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateSlider((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X * (max-min) + min)
		end
	end)

	-- Inicializa o estado visual
	updateSlider(default, true)
	self:UpdateScrolling(tab)

	-- CORREÇÃO APLICADA AQUI: Retorna um objeto de controle com Set/Get.
	return {
		Get = function() return currentValue end,
		Set = function(_, newValue) updateSlider(newValue) end
	}
end

function SawMillHub:CreateDropdown(tab, text, options, callback)
	-- Garante acesso direto aos serviços e variáveis do módulo
	local TweenService = game:GetService("TweenService")
	local NEON_BLUE = Color3.fromRGB(0, 170, 255)

	if not self.Tabs[tab] then return end
	options = options or {}

	-- Definição de Cores
	local neonBlue = NEON_BLUE
	local darkBackground = Color3.fromRGB(25, 25, 25)
	local selectedBackground = Color3.fromRGB(45, 45, 45)
	local optionBackground = Color3.fromRGB(35, 35, 35)
	local optionHover = Color3.fromRGB(50, 50, 50)

	local selectedValue = nil -- Variável para armazenar o valor selecionado
	local optionMap = {} -- Mapeamento para acessar as opções por nome

	-- CONTAINER PRINCIPAL
	local frame = create("Frame", {
		Parent = self.Tabs[tab].Container,
		Size = UDim2.new(1, -10, 0, 50),
		BackgroundColor3 = darkBackground,
		ClipsDescendants = true
	})
	create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 14) })

	-- UIStroke inicial sutil para borda
	local mainStroke = create("UIStroke", {
		Parent = frame,
		Color = Color3.fromRGB(70, 70, 70),
		Thickness = 1,
		Transparency = 0.5
	})

	-- BOTÃO PRINCIPAL (HEADER)
	local btn = create("TextButton", {
		Parent = frame,
		Text = "",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		AutoButtonColor = false
	})

	local btnLabel = create("TextLabel", {
		Parent = btn,
		Text = text,
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	-- SETA MAIOR + ANIMAÇÃO DE ROTAÇÃO
	local arrow = create("TextLabel", {
		Parent = btn,
		Text = "▼",
		Size = UDim2.new(0, 30, 0, 30),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		BackgroundTransparency = 1,
		TextColor3 = neonBlue,
		Font = Enum.Font.GothamBlack,
		TextSize = 25,
		ZIndex = 2
	})

	-- Efeito de HOVER no botão principal
	btn.MouseEnter:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.2), { BackgroundColor3 = selectedBackground }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.3), { BackgroundColor3 = darkBackground }):Play()
	end)


	-- LISTA DE OPÇÕES
	local listHeight = #options * 38 + 8 -- Altura de 38 por opção + 8 de padding
	local list = create("Frame", {
		Parent = frame,
		Size = UDim2.new(1, 0, 0, listHeight),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		Visible = false
	})
	create("UICorner", { Parent = list, CornerRadius = UDim.new(0, 14) })
	-- Movemos o stroke para a lista e a deixamos com a cor Neon
	local listStroke = create("UIStroke", { Parent = list, Color = neonBlue, Thickness = 1.2, Transparency = 1 })

	-- Layout e Padding internos
	create("UIListLayout", { Parent = list, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
	create("UIPadding", { Parent = list, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) })


	local open = false
	local selectedCheck = nil -- Renomeado para evitar conflito com 'selected' da função

	-- ABRIR / FECHAR DROPDOWN (Com Animação de Altura)
	local function toggleDropdown()
		open = not open
		list.Visible = true

		-- Animação da Seta
		TweenService:Create(arrow, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			Rotation = open and 180 or 0
		}):Play()

		-- Animação do Stroke da Borda
		TweenService:Create(mainStroke, TweenInfo.new(0.3), { Transparency = open and 1 or 0.5 }):Play()
		TweenService:Create(listStroke, TweenInfo.new(0.3), { Transparency = open and 0.5 or 1 }):Play()

		-- Animação do Frame Principal (Tamanho)
		local goalSize = open and UDim2.new(1, -10, 0, 50 + listHeight) or UDim2.new(1, -10, 0, 50)
		TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = goalSize}):Play()

		-- Animação de Fade da Lista
		TweenService:Create(list, TweenInfo.new(0.2), {BackgroundTransparency = open and 0 or 1}):Play()

		if not open then
			task.delay(0.4, function() -- Atraso maior para coincidir com a animação de tamanho
				if not open and frame.Size.Y.Offset <= 50 then list.Visible = false end
			end)
		end

		self:UpdateScrolling(tab)
	end

	btn.MouseButton1Click:Connect(toggleDropdown)

	-- FUNÇÃO CENTRAL DE SELEÇÃO
	local function selectOption(opt)
		if selectedCheck then selectedCheck.Visible = false end

		local item = optionMap[opt]
		if not item then return end -- Opção não existe

		local check = item.Check

		check.Visible = true
		selectedCheck = check
		selectedValue = opt -- Atualiza o valor armazenado

		btnLabel.Text = text .. ": " .. opt -- Atualiza o texto do botão principal
		TweenService:Create(btnLabel, TweenInfo.new(0.1), { TextColor3 = neonBlue }):Play() -- Destaca o texto selecionado
		task.delay(0.5, function()
			TweenService:Create(btnLabel, TweenInfo.new(0.3), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
		end)

		-- Executa o callback, se existir
		if callback then pcall(callback, opt) end
	end

	-- FUNÇÃO DE CLIQUE (para ser usada pelos botões)
	local function handleOptionClick(opt)
		selectOption(opt)
		toggleDropdown() -- Fecha o dropdown após a seleção
	end

	-- CRIAR OPÇÕES
	for _, opt in ipairs(options) do
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
			TextColor3 = Color3.fromRGB(230, 230, 230),
			Font = Enum.Font.Gotham,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left
		})

		-- Ícone de Seleção Neon
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

		-- Mapeia a opção
		optionMap[opt] = {
			Button = optBtn,
			Check = check,
			Callback = function() handleOptionClick(opt) end -- Função de clique mapeada
		}

		-- HOVER ANIMADO
		optBtn.MouseEnter:Connect(function()
			TweenService:Create(optBtn, TweenInfo.new(0.15), {BackgroundColor3 = optionHover}):Play()
		end)
		optBtn.MouseLeave:Connect(function()
			TweenService:Create(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = optionBackground}):Play()
		end)

		-- CONECTA A SELEÇÃO
		optBtn.MouseButton1Click:Connect(optionMap[opt].Callback)
	end

	-- Inicializa o texto
	btnLabel.Text = text .. ": (Selecione)"

	self:UpdateScrolling(tab)

	-- RETORNA O OBJETO DE CONTROLE CORRIGIDO
	return {
		Frame = frame, -- Para acesso direto, se necessário
		Get = function() return selectedValue end,
		Set = function(_, optionName) selectOption(optionName) end -- O método Set corrigido
	}
end

function SawMillHub:CreateInput(tab, text, placeholder, callback)
	local TweenService = game:GetService("TweenService")
	if not self.Tabs[tab] then return end

	-- FRAME PRINCIPAL
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

	-- GLASS SIMULADO + GRADIENT (Mantido)
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

	-- LABEL FIXO (Mantido)
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

	-- INPUT BOX (Mantido)
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

	-- PLACEHOLDER ANIMADO (Mantido)
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

	-- FUNÇÃO PARA PLACEHOLDER (Mantida)
	local function updatePlaceholder()
		if box.Text == "" and not box:IsFocused() then
			TweenService:Create(placeholderLbl, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
		else
			TweenService:Create(placeholderLbl, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
		end
	end
	updatePlaceholder()

	-- FOCO ANIMADO (Mantido)
	local function focusAnim(focused)
		if focused then
			TweenService:Create(stroke, TweenInfo.new(0.25), {
				Color = Color3.fromRGB(0, 255, 180),
				Thickness = 2,
				Transparency = 0
			}):Play()
			-- Pulse sutil
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
			-- efeito pulse ao confirmar
			TweenService:Create(frame, TweenInfo.new(0.15), {Size = UDim2.new(1, -10, 0, 57)}):Play()
			task.delay(0.15, function()
				TweenService:Create(frame, TweenInfo.new(0.15), {Size = UDim2.new(1, -10, 0, 55)}):Play()
			end)
		end
	end)

	box:GetPropertyChangedSignal("Text"):Connect(updatePlaceholder)

	self:UpdateScrolling(tab)

	-- RETORNO CORRIGIDO
	return {
		Box = box,

		Get = function()
			return box.Text
		end,

		Set = function(_, newText, newPlaceholder)
			-- 1. Se newText NÃO for nil, atualiza o texto principal
			if newText ~= nil then
				box.Text = tostring(newText)
			end

			-- 2. Se newPlaceholder NÃO for nil, atualiza o placeholder
			if newPlaceholder ~= nil then
				placeholderLbl.Text = tostring(newPlaceholder)
			end

			-- Garante que o placeholder seja atualizado após a mudança de texto
			updatePlaceholder()
		end
	}
end
-----------------------------------------------------
-- KEYBIND NEON ÉPICO (Animado + Pulse + Glow)
-----------------------------------------------------
function SawMillHub:CreateKeybind(tab, text, defaultKey, callback)
	if not self.Tabs[tab] then return end

	-- FRAME
	local frame = create("Frame", {
		Parent = self.Tabs[tab].Container,
		Size = UDim2.new(1, -10, 0, 55),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		ClipsDescendants = true
	})
	create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 12) })
	local stroke = create("UIStroke", { Parent = frame, Color = Color3.fromRGB(80, 80, 80), Thickness = 1, Transparency = 0.5 })

	-- LABEL
	local lbl = create("TextLabel", {
		Parent = frame,
		Text = tostring(text or "Keybind"),
		Size = UDim2.new(1, -12, 0, 20),
		Position = UDim2.new(0, 8, 0, 6),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	-- BOTÃO DE KEYBIND
	local btn = create("TextButton", {
		Parent = frame,
		Text = defaultKey and defaultKey.Name or "Nenhuma",
		Size = UDim2.new(0, 130, 0, 30),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.65, 0),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 15
	})
	create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 8) })

	-- NEON GLOW
	local btnStroke = create("UIStroke", {
		Parent = btn,
		Color = Color3.fromRGB(0, 255, 255),
		Thickness = 2,
		Transparency = 0.5
	})

	local gradient = create("UIGradient", {
		Parent = btn,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255))
		}),
		Rotation = 45,
		Transparency = NumberSequence.new(0.5, 0.5)
	})

	local selectedKey = defaultKey or Enum.KeyCode.Unknown
	local waiting = false

	local function setKey(newKey)
		selectedKey = newKey
		btn.Text = newKey.Name

		-- pulse neon
		TweenService:Create(btnStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {Transparency = 0}):Play()
		TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(0, 135, 0, 33)}):Play()
		task.delay(0.2, function()
			TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(0, 130, 0, 30)}):Play()
		end)

		if callback then pcall(callback, selectedKey) end
	end

	btn.MouseEnter:Connect(function()
		TweenService:Create(btnStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
		TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		if not waiting then
			TweenService:Create(btnStroke, TweenInfo.new(0.3), {Transparency = 0.5}):Play()
			TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
		end
	end)

	btn.MouseButton1Click:Connect(function()
		if waiting then return end
		waiting = true
		btn.Text = "Pressione..."
		TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(0, 255, 120), Transparency = 0}):Play()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 50, 100)}):Play()

		local conn
		conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
				setKey(input.KeyCode)
				waiting = false
				conn:Disconnect()
				TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(0, 255, 255), Transparency = 0.5}):Play()
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35,35,35)}):Play()
			end
		end)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == selectedKey and not waiting then
			if callback then pcall(callback, selectedKey) end
		end
	end)

	-- NEON PULSE CONTÍNUO
	task.spawn(function()
		while true do
			if not waiting then
				TweenService:Create(btnStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.3}):Play()
				TweenService:Create(gradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = gradient.Rotation + 45}):Play()
			end
			task.wait(0.1)
		end
	end)

	self:UpdateScrolling(tab)
	return {
		Get = function() return selectedKey end,
		Set = function(_, newKey) setKey(newKey) end
	}
end

-----------------------------------------------------
-- SISTEMA DE NOTIFY (Versão Estável com Animação)
-----------------------------------------------------
function SawMillHub:Notify(title, message, duration)
	local self = self
	duration = duration or 3
	local TweenService = game:GetService("TweenService")
	local DebrisService = game:GetService("Debris")
	local NEON_BLUE = Color3.fromRGB(0, 170, 255)
	local BASE_BG = Color3.fromRGB(30, 30, 30)

	-- 1. Inicializa lista e Holder (Verificação de Escopo)
	if not self.ActiveNotifications then
		self.ActiveNotifications = {}
	end

	local MAX_NOTIFS = self.MaxNotifs or 5

	if not self.NotificationHolder then
		local holder = create("Frame", {
			Parent = self.Gui,
			Name = "NotificationHolder",
			Size = UDim2.new(0, 320, 1, -20),
			Position = UDim2.new(1, -330, 1, -10), -- Inferior Direito
			AnchorPoint = Vector2.new(0, 1), 
			BackgroundTransparency = 1,
			ClipsDescendants = false,
		})
		self.NotificationHolder = holder

		-- UIListLayout faz o trabalho de ajuste
		create("UIListLayout", {
			Parent = holder,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			VerticalAlignment = Enum.VerticalAlignment.Bottom 
		})
	end

	-- 2. Sistema de Remoção por Limite (Animação de "Morte" elegante)
	while #self.ActiveNotifications >= MAX_NOTIFS do
		local oldest = table.remove(self.ActiveNotifications, 1) -- Pega e remove o mais antigo (que está no topo visual)
		if oldest and oldest.Parent then
			-- Animação de saída para BAIXO e para FORA
			local tweenOut = TweenService:Create(oldest, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
				Position = oldest.Position + UDim2.new(0, 320, 0, 0) -- Move para a direita (fora da tela)
			})
			tweenOut:Play()

			-- Destrói somente após a animação de saída
			DebrisService:AddItem(oldest, 0.5)
		end
	end

	-- 3. Criação da Notificação (Design Animado)
	local notif = create("Frame", {
		Parent = self.NotificationHolder,
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundColor3 = BASE_BG,
		BackgroundTransparency = 1, 
		ClipsDescendants = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.ActiveNotifications + 1 -- Garante que o novo vá para o final da lista (base)
	})

	create("UICorner", {Parent = notif, CornerRadius = UDim.new(0, 12)})
	create("UIStroke", {
		Parent = notif, 
		Color = NEON_BLUE, 
		Thickness = 1.5,
		Transparency = 0.6 
	})
	create("UIPadding", {
		Parent = notif,
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10)
	})

	local contentLayout = create("UIListLayout", {
		Parent = notif,
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4)
	})

	-- Título (NEON)
	local titleLbl = create("TextLabel", {
		Parent = notif,
		Text = tostring(title or "Notificação"),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = NEON_BLUE, 
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true
	})

	-- Mensagem
	local msgLbl = create("TextLabel", {
		Parent = notif,
		Text = tostring(message or ""),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top
	})

	-- Barra de progresso
	local barHolder = create("Frame", {Parent = notif, Size = UDim2.new(1, 0, 0, 4), BackgroundTransparency = 1})
	local bar = create("Frame", {Parent = barHolder, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = NEON_BLUE, BorderSizePixel = 0})
	create("UICorner", {Parent = bar, CornerRadius = UDim.new(0, 3)})

	-- 4. Entrada Animada
	notif.Position = UDim2.new(0, 320, 0, 0) -- Começa fora (direita)

	-- Animação Slide-In elegante e fade do background
	TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
		Position = UDim2.new(0, 0, 0, 0)
	}):Play()

	-- 5. Animação da barra de progresso
	TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 0, 1, 0)
	}):Play()

	-- 6. Salva e Ajusta Posição
	table.insert(self.ActiveNotifications, notif)

	-- 7. Remoção por Duração (Animação de "Expiração")
	task.delay(duration, function()
		if notif and notif.Parent then
			-- Animação de saída
			local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = notif.Position + UDim2.new(0, 320, 0, 0), -- Desliza para fora (direita)
				BackgroundTransparency = 1
			})
			tweenOut:Play()

			tweenOut.Completed:Connect(function()
				-- Remove da tabela
				for i, v in ipairs(self.ActiveNotifications) do
					if v == notif then
						table.remove(self.ActiveNotifications, i)
						break
					end
				end

				-- O UIListLayout faz o ajuste de subida automático
				if notif and notif.Parent then
					notif:Destroy()
				end
			end)
		end
	end)
end
return SawMillHub
