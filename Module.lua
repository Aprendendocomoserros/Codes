--[[
LastOneHub Premium - GUI Moderna e Animada (Completo)
Sistema inspirado em Rayfield, com todos os elementos:
Botões, Sliders, Toggles, Dropdowns, Inputs, Keybinds, Notificações
]]--

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LastOneHub = {}
LastOneHub.__index = LastOneHub

local function create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        pcall(function() inst[k] = v end)
    end
    return inst
end

-- Função para criar sombra bonita
local function addShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Parent = parent
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = parent.ZIndex - 1
end

----------------------------
-- Criação da GUI Principal
----------------------------
function LastOneHub.new(title)
    -- Remove GUIs anteriores
    local oldGui = game:GetService("CoreGui"):FindFirstChild("LastoneHub")
    if oldGui then
        oldGui:Destroy()
    end

    self = setmetatable({}, LastOneHub)

self.Gui = create("ScreenGui", {
    Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
    ResetOnSpawn = false,
    Name = "LastoneHub"
})

    -- Janela Principal
    self.Main = create("Frame", {
        Parent = self.Gui,
        Size = UDim2.new(0, 550, 0, 400),
        Position = UDim2.new(0.5, -275, 0.5, -200),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        ClipsDescendants = true
    })
    addShadow(self.Main)
    create("UICorner", { Parent = self.Main, CornerRadius = UDim.new(0, 12) })

    -- Topo
    local top = create("Frame", {
        Parent = self.Main,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    })
    create("UICorner", { Parent = top, CornerRadius = UDim.new(0, 12) })

    -- Título
    create("TextLabel", {
        Parent = top,
        Text = title or "LastOneHub Premium",
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 18
    })

    -- Botão de fechar
    local closeBtn = create("TextButton", {
        Parent = top,
        Text = "✖",
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(1, -40, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(255, 70, 70),
        Font = Enum.Font.GothamBold,
        TextSize = 20
    })
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(self.Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1}):Play()
        wait(0.4)
        self.Gui:Destroy()
    end)

    -- Sistema de arrastar
    local dragging, dragStart, startPos
    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.Main.Position
        end
    end)
    top.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Sidebar (Abas)
    self.Sidebar = create("Frame", {
        Parent = self.Main,
        Size = UDim2.new(0, 140, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    })
    create("UICorner", { Parent = self.Sidebar, CornerRadius = UDim.new(0, 12) })
    create("UIListLayout", {
        Parent = self.Sidebar,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6)
    })

    -- Conteúdo da aba
    self.TabHolder = create("Frame", {
        Parent = self.Main,
        Size = UDim2.new(1, -140, 1, -40),
        Position = UDim2.new(0, 140, 0, 40),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    })
    create("UICorner", { Parent = self.TabHolder, CornerRadius = UDim.new(0, 12) })

    self.Tabs = {}
    self.Keybinds = {}
    self.Notifs = {}
    self.MaxNotifs = 5

    return self
end

----------------------------
-- Criação de Abas
----------------------------
function LastOneHub:CreateTab(name)
    local tabBtn = create("TextButton", {
        Parent = self.Sidebar,
        Text = name,
        Size = UDim2.new(1, -12, 0, 36),
        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.Gotham,
        TextSize = 14
    })
    create("UICorner", { Parent = tabBtn, CornerRadius = UDim.new(0, 8) })

    local container = create("ScrollingFrame", {
        Parent = self.TabHolder,
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        Visible = false,
        BackgroundTransparency = 1,
        ScrollBarThickness = 6,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
    create("UIListLayout", {
        Parent = container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })

    local tab = { Name = name, Button = tabBtn, Container = container }
    self.Tabs[name] = tab

    -- Evento de clique
    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(self.Tabs) do
            t.Container.Visible = false
            TweenService:Create(t.Button, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
        end
        container.Visible = true
        TweenService:Create(tabBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(70,70,70)}):Play()
        self.CurrentTab = tab
    end)

    -- Primeira aba visível
    if not self.CurrentTab then
        container.Visible = true
        self.CurrentTab = tab
        tabBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end

    return tab
end

function LastOneHub:UpdateScrolling(tabName)
    local tab = (type(tabName) == "table" and tabName) or self.Tabs[tabName]
    if not tab or not tab.Container then return end
    local layout = tab.Container:FindFirstChildOfClass("UIListLayout")
    if not layout then return end
    local total = 0
    for _, child in ipairs(tab.Container:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextBox") then
            total = total + child.Size.Y.Offset + layout.Padding.Offset
        end
    end
    tab.Container.CanvasSize = UDim2.new(0, 0, 0, total)
end
----------------------------
-- ELEMENTOS INTERATIVOS
----------------------------

-- Botão com animação
function LastOneHub:CreateButton(tab, text, callback)
    if not self.Tabs[tab] then return end
    local btn = create("TextButton", {
        Parent = self.Tabs[tab].Container,
        Text = tostring(text or ""),
        Size = UDim2.new(1, -10, 0, 36),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 14
    })
    create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 8) })

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)

    self:UpdateScrolling(tab)
    return btn
end

-- Toggle estilo interruptor animado
function LastOneHub:CreateToggle(tab, text, default, callback)
    if not self.Tabs[tab] then return end
    default = (default == true)

    local frame = create("Frame", {
        Parent = self.Tabs[tab].Container,
        Size = UDim2.new(1, -10, 0, 36),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    })
    create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 8) })

    local lbl = create("TextLabel", {
        Parent = frame,
        Text = tostring(text or ""),
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Interruptor
    local switch = create("Frame", {
        Parent = frame,
        Size = UDim2.new(0, 50, 0, 20),
        Position = UDim2.new(1, -60, 0.5, -10),
        BackgroundColor3 = Color3.fromRGB(80, 80, 80),
        ClipsDescendants = true
    })
    create("UICorner", { Parent = switch, CornerRadius = UDim.new(1, 0) })

    local knob = create("Frame", {
        Parent = switch,
        Size = UDim2.new(0, 22, 0, 22),
        Position = default and UDim2.new(1, -22, 0.5, -11) or UDim2.new(0, 0, 0.5, -11),
        BackgroundColor3 = default and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
    })
    create("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })

    local state = default

    local function updateToggle(animated)
        if animated then
            TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = state and UDim2.new(1, -22, 0.5, -11) or UDim2.new(0, 0, 0.5, -11),
                BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
            }):Play()
        else
            knob.Position = state and UDim2.new(1, -22, 0.5, -11) or UDim2.new(0, 0, 0.5, -11)
            knob.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
        end
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            updateToggle(true)
            if callback then pcall(callback, state) end
        end
    end)

    updateToggle(false)
    self:UpdateScrolling(tab)

    return {
        Set = function(_, val)
            state = (val == true)
            updateToggle(true)
            if callback then pcall(callback, state) end
        end,
        Get = function() return state end
    }
end

-- Slider moderno animado
function LastOneHub:CreateSlider(tab, text, min, max, default, callback)
    if not self.Tabs[tab] then return end
    min = tonumber(min) or 0
    max = tonumber(max) or 100
    default = math.clamp(tonumber(default) or min, min, max)

    local frame = create("Frame", {
        Parent = self.Tabs[tab].Container,
        Size = UDim2.new(1, -10, 0, 60),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    })
    create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 8) })

    local lbl = create("TextLabel", {
        Parent = frame,
        Text = tostring(text) .. ": " .. default,
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local bar = create("Frame", {
        Parent = frame,
        Size = UDim2.new(1, -20, 0, 8),
        Position = UDim2.new(0, 10, 0, 35),
        BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    })
    create("UICorner", { Parent = bar, CornerRadius = UDim.new(1, 0) })

    local fill = create("Frame", {
        Parent = bar,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    })
    create("UICorner", { Parent = fill, CornerRadius = UDim.new(1, 0) })

    local knob = create("Frame", {
        Parent = bar,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new((default - min) / (max - min), -9, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    })
    create("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })

    local dragging = false
    local value = default

    local function updateSlider(val)
        val = math.clamp(val, min, max)
        value = val
        local pct = (val - min) / (max - min)
        TweenService:Create(fill, TweenInfo.new(0.15), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(pct, -9, 0.5, -9)}):Play()
        lbl.Text = tostring(text) .. ": " .. tostring(math.floor(val))
        if callback then pcall(callback, val) end
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local newVal = math.floor(min + rel * (max - min))
            updateSlider(newVal)
        end
    end)

    updateSlider(default)
    self:UpdateScrolling(tab)

    return {
        Set = function(_, val)
            updateSlider(val)
        end,
        Get = function()
            return value
        end
    }
end
----------------------------
-- DROPDOWN ANIMADO
----------------------------
function LastOneHub:CreateDropdown(tab, text, list, default, callback)
    if not self.Tabs[tab] then return end
    list = list or {}

    local frame = create("Frame", {
        Parent = self.Tabs[tab].Container,
        Size = UDim2.new(1, -10, 0, 40),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        ClipsDescendants = true
    })
    create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 8) })

    local title = create("TextLabel", {
        Parent = frame,
        Text = tostring(text or "Dropdown"),
        Size = UDim2.new(1, -30, 0, 40),
        Position = UDim2.new(0, 10, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.Gotham,
        TextSize = 14
    })

    local arrow = create("TextLabel", {
        Parent = frame,
        Text = "▼",
        Size = UDim2.new(0, 30, 0, 40),
        Position = UDim2.new(1, -30, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Font = Enum.Font.GothamBold,
        TextSize = 18
    })

    local optionsFrame = create("Frame", {
        Parent = frame,
        Size = UDim2.new(1, -20, 0, #list * 30),
        Position = UDim2.new(0, 10, 0, 40),
        BackgroundTransparency = 1
    })
    local layout = create("UIListLayout", {
        Parent = optionsFrame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })

    local selected = default or list[1]
    local open = false
    local optionButtons = {}

    -- Função para abrir/fechar
    local function toggleDropdown()
        open = not open
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = open and UDim2.new(1, -10, 0, 40 + (#list * 35)) or UDim2.new(1, -10, 0, 40)
        }):Play()
        TweenService:Create(arrow, TweenInfo.new(0.3), {
            Rotation = open and 180 or 0
        }):Play()
    end

    -- Criar botões
    for _, option in ipairs(list) do
        local btn = create("TextButton", {
            Parent = optionsFrame,
            Text = option,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = Color3.fromRGB(70, 70, 70),
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.Gotham,
            TextSize = 14
        })
        create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 6) })

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 90, 90)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
        end)

        btn.MouseButton1Click:Connect(function()
            selected = option
            title.Text = text .. ": " .. option
            toggleDropdown()
            if callback then pcall(callback, option) end
        end)

        table.insert(optionButtons, btn)
    end

    -- Evento de clique para abrir/fechar
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not open then
            toggleDropdown()
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 and open then
            toggleDropdown()
        end
    end)

    self:UpdateScrolling(tab)
    return {
        Get = function() return selected end,
        Set = function(_, val)
            if table.find(list, val) then
                selected = val
                title.Text = text .. ": " .. val
            end
        end
    }
end

----------------------------
-- INPUT BOX (Campo de Texto)
----------------------------
function LastOneHub:CreateInput(tab, text, placeholder, callback)
    if not self.Tabs[tab] then return end

    local frame = create("Frame", {
        Parent = self.Tabs[tab].Container,
        Size = UDim2.new(1, -10, 0, 40),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    })
    create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 8) })

    local label = create("TextLabel", {
        Parent = frame,
        Text = tostring(text or "Input"),
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local box = create("TextBox", {
        Parent = frame,
        PlaceholderText = placeholder or "",
        Size = UDim2.new(1, -100, 1, -10),
        Position = UDim2.new(0, 90, 0, 5),
        BackgroundColor3 = Color3.fromRGB(70, 70, 70),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        ClipsDescendants = true
    })
    create("UICorner", { Parent = box, CornerRadius = UDim.new(0, 6) })

    box.FocusLost:Connect(function(enterPressed)
        if enterPressed and callback then
            pcall(callback, box.Text)
        end
    end)

    self:UpdateScrolling(tab)
    return box
end

----------------------------
-- KEYBIND CONFIGURÁVEL
----------------------------
function LastOneHub:CreateKeybind(tab, text, defaultKey, callback)
    if not self.Tabs[tab] then return end
    defaultKey = defaultKey or Enum.KeyCode.E

    local frame = create("Frame", {
        Parent = self.Tabs[tab].Container,
        Size = UDim2.new(1, -10, 0, 40),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    })
    create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 8) })

    local lbl = create("TextLabel", {
        Parent = frame,
        Text = tostring(text or "Keybind"),
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local btn = create("TextButton", {
        Parent = frame,
        Text = defaultKey.Name,
        Size = UDim2.new(0.25, 0, 0.8, 0),
        Position = UDim2.new(0.7, 5, 0.1, 0),
        BackgroundColor3 = Color3.fromRGB(70, 70, 70),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 14
    })
    create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 6) })

    local binding = false
    local currentKey = defaultKey

    btn.MouseButton1Click:Connect(function()
        binding = true
        btn.Text = "..."
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if binding then
            currentKey = input.KeyCode
            btn.Text = currentKey.Name
            binding = false
            if callback then pcall(callback, currentKey) end
        elseif input.KeyCode == currentKey then
            if callback then pcall(callback, currentKey, true) end
        end
    end)

    self:UpdateScrolling(tab)
    return {
        Set = function(_, key)
            currentKey = key
            btn.Text = key.Name
        end,
        Get = function() return currentKey end
    }
end

----------------------------
-- SISTEMA DE NOTIFICAÇÕES
----------------------------
function LastOneHub:Notify(title, text, duration)
    duration = duration or 3

    -- Container para notificações
    local notifContainer = self.Gui:FindFirstChild("NotifContainer")
    if not notifContainer then
        notifContainer = create("Frame", {
            Parent = self.Gui,
            Name = "NotifContainer",
            Size = UDim2.new(0, 300, 1, -20),
            Position = UDim2.new(1, -310, 0, 10),
            BackgroundTransparency = 1
        })
        create("UIListLayout", {
            Parent = notifContainer,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            VerticalAlignment = Enum.VerticalAlignment.Top
        })
    end

    -- Notificação individual
    local notif = create("Frame", {
        Parent = notifContainer,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        ClipsDescendants = true
    })
    create("UICorner", { Parent = notif, CornerRadius = UDim.new(0, 8) })
    addShadow(notif)

    local notifTitle = create("TextLabel", {
        Parent = notif,
        Text = tostring(title),
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local notifText = create("TextLabel", {
        Parent = notif,
        Text = tostring(text),
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 10, 0, 28),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Animação de entrada
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 60)
    }):Play()

    -- Remover após o tempo
    task.delay(duration, function()
        TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(1, 0, 0, 0)
        }):Play()
        wait(0.3)
        notif:Destroy()
    end)
end
return LastOneHub
