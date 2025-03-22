LastOneLib = {}
LastOneLib.__index = LastOneLib

local function createInstance(className, properties)
	local instance = Instance.new(className)
	for prop, value in pairs(properties) do
		instance[prop] = value
	end
	return instance
end

-- Função para selecionar a cor do background
local function setBackgroundColor(colorChoice)
	local colorOptions = {
		Default = Color3.fromRGB(25, 25, 25),
		AmberGlow = Color3.fromRGB(255, 191, 0),
		Amethyst = Color3.fromRGB(153, 102, 204),
		Bloom = Color3.fromRGB(255, 182, 193),
		DarkBlue = Color3.fromRGB(0, 0, 139),
		Green = Color3.fromRGB(0, 255, 0),
		Light = Color3.fromRGB(255, 255, 255),
		Ocean = Color3.fromRGB(0, 105, 148),
		Serenity = Color3.fromRGB(191, 191, 255)
	}
	return colorOptions[colorChoice] or colorOptions.Default
end

function LastOneLib.new(title, colorChoice)
	local self = setmetatable({}, LastOneLib)

	local player = game.Players.LocalPlayer
	local gui = createInstance("ScreenGui", { Parent = game:GetService("CoreGui") })


	local isMobile = game:GetService("UserInputService").TouchEnabled
	local mainFrame
	local backgroundColor = setBackgroundColor(colorChoice)

	if isMobile then
		mainFrame = createInstance("Frame", {
			Size = UDim2.new(0, 320, 0, 320),
			Position = UDim2.new(0.5, -160, 0.5, -160),
			BackgroundColor3 = backgroundColor,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = gui
		})
	else
		mainFrame = createInstance("Frame", {
			Size = UDim2.new(0, 700, 0, 500),
			Position = UDim2.new(0.5, -350, 0.5, -250),
			BackgroundColor3 = backgroundColor,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = gui
		})
	end

	createInstance("UICorner", { CornerRadius = UDim.new(0, 10), Parent = mainFrame })

	self.sideBar = createInstance("Frame", {
		Size = UDim2.new(0, 120, 1, 0),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BorderSizePixel = 0,
		Parent = mainFrame
	})

	createInstance("UICorner", { CornerRadius = UDim.new(0, 10), Parent = self.sideBar })

	local contentFrame = createInstance("Frame", {
		Size = UDim2.new(1, -130, 1, -50),
		Position = UDim2.new(0, 130, 0, 50),
		BackgroundTransparency = 1,
		Parent = mainFrame
	})

	local listLayout = createInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5),
		Parent = contentFrame
	})

	-- Criar botão de fechar com animação
	local closeButton = createInstance("TextButton", {
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -40, 0, 10),
		Text = "X",
		TextSize = 20,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(200, 0, 0),
		Parent = mainFrame
	})

	closeButton.MouseButton1Click:Connect(function()
		-- Animação para fechar a GUI
		mainFrame:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true, function()
			gui:Destroy()  -- Remove a GUI quando animação termina
		end)
	end)

	local titleLabel = createInstance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		Text = title,
		TextSize = 24,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		Parent = mainFrame
	})

	self.tabs = {}
	self.contentFrame = contentFrame
	self.mainFrame = mainFrame

	-- Função para tornar a GUI arrastável em PC e celular
	local function makeDraggable(frame, titleLabel)
		local dragging = false
		local dragStart
		local startPos

		local function startDrag(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = frame.Position
			end
		end

		local function stopDrag(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end

		local function dragFrame(input)
			if dragging then
				local delta = input.Position - dragStart
				frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end

		titleLabel.InputBegan:Connect(startDrag)
		titleLabel.InputEnded:Connect(stopDrag)
		titleLabel.InputChanged:Connect(dragFrame)

		game:GetService("UserInputService").InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				dragFrame(input)
			end
		end)

		game:GetService("UserInputService").InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end

	-- Tornar a GUI arrastável
	makeDraggable(self.mainFrame, titleLabel)

	print(isMobile and "Celular detectado!" or "PC detectado!")

	return self
end

function LastOneLib:CreateTab(name)
	if not self.sideBar then
		warn("sideBar is nil!")
		return
	end

	-- Adiciona o botão da aba
	local tabButton = createInstance("TextButton", {
		Size = UDim2.new(1, -20, 0, 40),
		Position = UDim2.new(0, 10, 0, 10 + (#self.sideBar:GetChildren() * 45)),
		BackgroundColor3 = Color3.fromRGB(45, 45, 45),
		Text = name,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		Parent = self.sideBar
	})

	-- Efeito de Hover para os botões de tab
	tabButton.MouseEnter:Connect(function()
		tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end)

	tabButton.MouseLeave:Connect(function()
		tabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	end)

	createInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = tabButton })

	-- Cria o conteúdo da aba dentro de um ScrollingFrame
	local tabContent = createInstance("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 8,  -- Espessura da barra de rolagem
		Parent = self.contentFrame,
		Visible = false  -- Começa invisível, será exibido quando a aba for clicada
	})

	-- Layout para o conteúdo das abas
	local listLayout = createInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5),
		Parent = tabContent
	})

	-- Definindo o tamanho inicial grande para o Canvas (feito de forma fixa)
	tabContent.CanvasSize = UDim2.new(0, 0, 0, 1000)  -- Defina o tamanho inicial grande

	-- Animação de transição suave quando a aba for clicada
	tabButton.MouseButton1Click:Connect(function()
		-- Esconde todas as abas e exibe apenas a selecionada
		for _, content in pairs(self.contentFrame:GetChildren()) do
			if content:IsA("ScrollingFrame") then
				content.Visible = false
			end
		end

		-- Exibe o conteúdo da aba selecionada e aplica a animação
		tabContent.Visible = true
		tabContent.Position = UDim2.new(0, self.contentFrame.AbsoluteSize.X, 0, 0)
		tabContent:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
	end)

	self.tabs[name] = tabContent
	return tabContent
end

-- Criar um Label (Texto fixo) com fundo mais visível
function LastOneLib:CreateLabel(tabName, text)
	local label = createInstance("TextLabel", {
		Size = UDim2.new(0.8, 0, 0, 50),
		Position = UDim2.new(0.1, 0, 0, #self.tabs[tabName]:GetChildren() * 55),
		BackgroundColor3 = Color3.fromRGB(60, 60, 60), -- Cinza mais visível
		BorderSizePixel = 0, -- Sem borda para um visual mais limpo
		Text = text,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.Gotham,
		TextWrapped = true,  -- Permitir quebra de linha
		Parent = self.tabs[tabName]
	})

	createInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = label }) -- Bordas arredondadas

	return label
end

function LastOneLib:CreateButton(tabName, text, callback)
	local button = createInstance("TextButton", {
		Size = UDim2.new(0.8, 0, 0, 50),
		Position = UDim2.new(0.1, 0, 0, #self.tabs[tabName]:GetChildren() * 55),
		BackgroundColor3 = Color3.fromRGB(100, 100, 100), -- Cinza
		Text = text,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		Parent = self.tabs[tabName]
	})

	button.MouseButton1Click:Connect(callback)
end

function LastOneLib:CreateToggle(tabName, text, default, callback)
	local toggleFrame = createInstance("Frame", {
		Size = UDim2.new(0.8, 0, 0, 50),
		Position = UDim2.new(0.1, 0, 0, #self.tabs[tabName]:GetChildren() * 55),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		Parent = self.tabs[tabName]
	})

	local toggleLabel = createInstance("TextLabel", {
		Size = UDim2.new(0.7, 0, 1, 0), -- Maior para evitar sobreposição
		BackgroundTransparency = 1,
		Text = text,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.Gotham,
		Parent = toggleFrame
	})

	local toggleButton = createInstance("TextButton", {
		Size = UDim2.new(0, 60, 0, 25), -- Aumentei o tamanho do botão
		Position = UDim2.new(1, -70, 0.5, -12), -- Melhor alinhamento vertical
		BackgroundColor3 = default and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0),
		Text = default and "ON" or "OFF",
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Parent = toggleFrame
	})

	local state = default

	toggleButton.MouseButton1Click:Connect(function()
		state = not state
		toggleButton.BackgroundColor3 = state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
		toggleButton.Text = state and "ON" or "OFF"
		callback(state)
	end)

	return toggleFrame
end

-- Criar o Input (campo de texto)
function LastOneLib:CreateInput(tabName, placeholderText, callback)
	local inputFrame = createInstance("Frame", {
		Size = UDim2.new(0.8, 0, 0, 50),
		Position = UDim2.new(0.1, 0, 0, #self.tabs[tabName]:GetChildren() * 55),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		Parent = self.tabs[tabName]
	})

	local inputBox = createInstance("TextBox", {
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		PlaceholderText = placeholderText,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		Font = Enum.Font.Gotham,
		Parent = inputFrame
	})

	inputBox.FocusLost:Connect(function()
		if inputBox.Text ~= "" then
			callback(inputBox.Text)
		end
	end)
end

function LastOneLib:CreateSlider(tabName, text, min, max, default, callback)
	local sliderFrame = createInstance("Frame", {
		Size = UDim2.new(0.8, 0, 0, 70),  -- Aumentei a altura para encaixar tudo melhor
		Position = UDim2.new(0.1, 0, 0, #self.tabs[tabName]:GetChildren() * 60),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		Parent = self.tabs[tabName]
	})

	createInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = sliderFrame }) -- Borda arredondada

	-- Texto do Slider
	local sliderLabel = createInstance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = text .. ": " .. default,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		Parent = sliderFrame
	})

	-- Barra do Slider
	local sliderBar = createInstance("Frame", {
		Size = UDim2.new(1, -20, 0, 8),
		Position = UDim2.new(0, 10, 0, 40),
		BackgroundColor3 = Color3.fromRGB(100, 100, 100), -- Cinza para contrastar com o botão
		Parent = sliderFrame
	})

	createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = sliderBar }) -- Borda arredondada

	-- Botão que desliza
	local sliderButton = createInstance("Frame", {
		Size = UDim2.new(0, 15, 0, 15),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7), -- Ajusta a posição inicial
		Parent = sliderBar
	})

	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderButton }) -- Borda arredondada

	local dragging = false

	-- Atualiza o slider conforme o usuário arrasta
	local function updateSlider(input)
		local barSize = sliderBar.AbsoluteSize.X
		local barPosX = sliderBar.AbsolutePosition.X
		local pos = math.clamp((input.Position.X - barPosX) / barSize, 0, 1)
		local value = math.floor(min + (max - min) * pos)

		sliderButton.Position = UDim2.new(pos, -7, 0.5, -7)
		sliderLabel.Text = text .. ": " .. value
		callback(value)
	end

	-- Eventos para PC e celular
	sliderButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateSlider(input)
		end
	end)

	game:GetService("UserInputService").InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
		end
	end)

	return sliderFrame
end
return LastOneLib
