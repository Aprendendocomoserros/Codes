-- LastOneHub v2.0 — UI melhorada (PC + Mobile/Touch)
-- Uso: local LastOneHub = require(path_to_module)
-- local hub = LastOneHub.new("Meu Hub")
-- Cria abas: local tab = hub:CreateTab("Main")
-- Elementos: hub:CreateButton("Main", "Clique", fn)

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LastOneHub = {}
LastOneHub.__index = LastOneHub

local function create(class, props)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            pcall(function() inst[k] = v end)
        end
    end
    return inst
end

local function sanitizeName(name)
    return tostring(name or "LastOneHub"):gsub("%W", "_")
end

----------------------------
-- Constructor
----------------------------
function LastOneHub.new(title)
    local name = sanitizeName(title or "LastOneHub")
    local oldGui = CoreGui:FindFirstChild(name)
    if oldGui then pcall(function() oldGui:Destroy() end)

    local self = setmetatable({}, LastOneHub)

    -- Device detection
    local isTouch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    self.IsTouch = isTouch

    -- Root GUI
    self.Gui = create("ScreenGui", { Parent = CoreGui, ResetOnSpawn = false, Name = name, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })

    -- Responsive sizes
    local mainSize = isTouch and UDim2.new(0, 360, 0, 420) or UDim2.new(0, 620, 0, 420)
    local mainPos = UDim2.new(0.5, -mainSize.X.Offset/2, 0.5, -mainSize.Y.Offset/2)

    self.Main = create("Frame", { Parent = self.Gui, Size = mainSize, Position = mainPos, BackgroundColor3 = Color3.fromRGB(23, 23, 28), ClipsDescendants = true, AnchorPoint = Vector2.new(0,0) })
    create("UICorner", { Parent = self.Main, CornerRadius = UDim.new(0, 10) })

    -- Background gradient subtle
    local bgGradient = create("UIGradient", { Parent = self.Main, Rotation = 0 })
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 33)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 22)),
    })

    -- Top bar
    local top = create("Frame", { Parent = self.Main, Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Name = "TopBar" })
    local titleLbl = create("TextLabel", { Parent = top, Text = tostring(title or "LastOneHub"), Size = UDim2.new(0.7, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(240,240,240), Font = Enum.Font.GothamSemibold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left })

    local subtitle = create("TextLabel", { Parent = top, Text = isTouch and "Touch Mode" or "Desktop Mode", Size = UDim2.new(0.3, -12, 1, 0), Position = UDim2.new(0.7, 12, 0, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(170,170,170), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })

    -- Close & minimize
    local controls = create("Frame", { Parent = top, Size = UDim2.new(0, 110, 1, 0), Position = UDim2.new(1, -122, 0, 0), BackgroundTransparency = 1 })
    local closeBtn = create("TextButton", { Parent = controls, Text = "✕", Size = UDim2.new(0, 36, 1, -12), Position = UDim2.new(1, -36, 0, 6), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(200,60,60), TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 16 })
    create("UICorner", { Parent = closeBtn, CornerRadius = UDim.new(0,8) })

    local miniBtn = create("TextButton", { Parent = controls, Text = "—", Size = UDim2.new(0, 36, 1, -12), Position = UDim2.new(1, -76, 0, 6), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(120,120,120), TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 14 })
    create("UICorner", { Parent = miniBtn, CornerRadius = UDim.new(0,8) })

    closeBtn.MouseButton1Click:Connect(function()
        pcall(function() self.Gui.Enabled = false end)
        if self.OnClose then pcall(self.OnClose) end
    end)
    miniBtn.MouseButton1Click:Connect(function()
        local visible = not self.ContentVisible
        self.ContentVisible = visible
        self.Sidebar.Visible = visible
        self.TabHolder.Visible = visible
        if visible then
            TweenService:Create(self.Main, TweenInfo.new(0.25), { Size = mainSize }):Play()
        else
            TweenService:Create(self.Main, TweenInfo.new(0.25), { Size = UDim2.new(mainSize.X.Scale, mainSize.X.Offset, 0, 46) }):Play()
        end
    end)

    -- Draggable by top (smooth)
    do
        local dragging, dragInput, dragStart, startPos
        local function update(input)
            local delta = input.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            self.Main.Position = newPos
        end
        top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = self.Main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        top.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input == dragInput then
                pcall(update, input)
            end
        end)
    end

    -- Sidebar & Tabs
    self.Sidebar = create("Frame", { Parent = self.Main, Size = UDim2.new(0, 140, 1, -46), Position = UDim2.new(0, 0, 0, 46), BackgroundTransparency = 1 })
    local sbBg = create("Frame", { Parent = self.Sidebar, Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(28,28,33) })
    create("UICorner", { Parent = sbBg, CornerRadius = UDim.new(0,8) })
    local sbLayout = create("UIListLayout", { Parent = self.Sidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8) })
    sbLayout.Padding = UDim.new(0,8)

    self.TabHolder = create("Frame", { Parent = self.Main, Size = UDim2.new(1, -140, 1, -46), Position = UDim2.new(0, 140, 0, 46), BackgroundTransparency = 1 })
    local holderBg = create("Frame", { Parent = self.TabHolder, Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(20,20,24) })
    create("UICorner", { Parent = holderBg, CornerRadius = UDim.new(0,8) })

    -- Containers
    self.Tabs = {}
    self.Keybinds = {}
    self.Notifs = {}
    self.MaxNotifs = 5
    self.ContentVisible = true

    return self
end

----------------------------
-- Tabs + scrolling utilities
----------------------------
function LastOneHub:CreateTab(name, icon)
    assert(name, "Tab precisa de nome")
    local btn = create("TextButton", { Parent = self.Sidebar, Text = name, Size = UDim2.new(1, -16, 0, 40), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(230,230,230), Font = Enum.Font.GothamSemibold, TextSize = 14 })
    create("UICorner", { Parent = btn, CornerRadius = UDim.new(0,8) })

    local cont = create("ScrollingFrame", { Parent = self.TabHolder, Size = UDim2.new(1, 0, 1, 0), Visible = false, BackgroundTransparency = 1, ScrollBarThickness = 8, CanvasSize = UDim2.new(0,0,0,0) })
    create("UIPadding", { Parent = cont, PaddingLeft = UDim.new(0,8), PaddingTop = UDim.new(0,8), PaddingRight = UDim.new(0,8) })
    local layout = create("UIListLayout", { Parent = cont, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8) })

    local tab = { Name = name, Button = btn, Container = cont }
    self.Tabs[name] = tab

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(self.Tabs) do
            if t.Container then t.Container.Visible = false end
        end
        cont.Visible = true
        self.CurrentTab = tab
        -- highlight
        for _, child in ipairs(self.Sidebar:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundTransparency = 1
                child.TextColor3 = Color3.fromRGB(220,220,220)
            end
        end
        btn.BackgroundTransparency = 0
        btn.BackgroundColor3 = Color3.fromRGB(36,36,42)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
    end)

    if not self.CurrentTab then
        cont.Visible = true
        self.CurrentTab = tab
        btn.BackgroundTransparency = 0
        btn.BackgroundColor3 = Color3.fromRGB(36,36,42)
    end

    -- auto update canvas size
    spawn(function()
        while cont and cont.Parent do
            local total = 0
            local padding = layout.Padding and layout.Padding.Offset or 8
            for _, child in ipairs(cont:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") or child:IsA("ScrollingFrame") then
                    local ok, sizeY = pcall(function() return child.Size.Y.Offset end)
                    if ok and sizeY then
                        total = total + sizeY + padding
                    end
                end
            end
            cont.CanvasSize = UDim2.new(0,0,0, math.max(0, total))
            task.wait(0.35)
        end
    end)

    return tab
end

----------------------------
-- Create common elements
----------------------------
function LastOneHub:CreateLabel(tabName, text)
    local tab = self.Tabs[tabName]
    if not tab then return end
    local lbl = create("TextLabel", { Parent = tab.Container, Text = tostring(text or ""), Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(220,220,220), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
    return { Set = function(_, new) lbl.Text = tostring(new) end }
end

function LastOneHub:CreateButton(tabName, text, callback)
    local tab = self.Tabs[tabName]
    if not tab then return end
    local btn = create("TextButton", { Parent = tab.Container, Text = tostring(text or "Button"), Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.fromRGB(58,116,255), TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamSemibold, TextSize = 14 })
    create("UICorner", { Parent = btn, CornerRadius = UDim.new(0,8) })
    btn.MouseEnter:Connect(function() pcall(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(73,135,255) }):Play() end) end)
    btn.MouseLeave:Connect(function() pcall(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(58,116,255) }):Play() end) end)
    btn.Activated:Connect(function() if callback then pcall(callback) end end)
    return { Set = function(_, new) btn.Text = tostring(new) end }
end

function LastOneHub:CreateToggle(tabName, text, default, callback)
    local tab = self.Tabs[tabName]
    if not tab then return end
    default = (default == true)
    local frame = create("Frame", { Parent = tab.Container, Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1 })
    local lbl = create("TextLabel", { Parent = frame, Text = tostring(text or "Toggle"), Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(220,220,220), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
    local switch = create("Frame", { Parent = frame, Size = UDim2.new(0, 50, 0, 24), Position = UDim2.new(1, -58, 0.5, -12), BackgroundColor3 = default and Color3.fromRGB(94,214,94) or Color3.fromRGB(140,140,140) })
    create("UICorner", { Parent = switch, CornerRadius = UDim.new(0,12) })
    local knob = create("Frame", { Parent = switch, Size = UDim2.new(0, 22, 0, 22), Position = default and UDim2.new(1, -22, 0, 0) or UDim2.new(0,0,0,0), BackgroundColor3 = Color3.fromRGB(255,255,255) })
    create("UICorner", { Parent = knob, CornerRadius = UDim.new(0,11) })
    local state = default
    local function toggle()
        state = not state
        if state then
            TweenService:Create(switch, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(94,214,94) }):Play()
            TweenService:Create(knob, TweenInfo.new(0.18), { Position = UDim2.new(1, -22, 0, 0) }):Play()
        else
            TweenService:Create(switch, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(140,140,140) }):Play()
            TweenService:Create(knob, TweenInfo.new(0.18), { Position = UDim2.new(0, 0, 0, 0) }):Play()
        end
        if callback then pcall(callback, state) end
    end
    switch.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            toggle()
        end
    end)
    return { Set = function(_, val) if type(val) == "boolean" then state = val if state then switch.BackgroundColor3 = Color3.fromRGB(94,214,94) knob.Position = UDim2.new(1, -22, 0, 0) else switch.BackgroundColor3 = Color3.fromRGB(140,140,140) knob.Position = UDim2.new(0, 0, 0, 0) end if callback then pcall(callback, state) end end end, Get = function() return state end }
end

function LastOneHub:CreateSlider(tabName, text, min, max, default, callback)
    local tab = self.Tabs[tabName]
    if not tab then return end
    min = tonumber(min) or 0
    max = tonumber(max) or 100
    if max == min then max = min + 1 end
    default = tonumber(default) or min

    local frame = create("Frame", { Parent = tab.Container, Size = UDim2.new(1,0,0,56), BackgroundTransparency = 1 })
    local lbl = create("TextLabel", { Parent = frame, Text = tostring(text or "Slider") .. ": " .. tostring(default), Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(220,220,220), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
    local bar = create("Frame", { Parent = frame, Size = UDim2.new(1, -24, 0, 12), Position = UDim2.new(0,12,0,32), BackgroundColor3 = Color3.fromRGB(60,60,60) })
    create("UICorner", { Parent = bar, CornerRadius = UDim.new(0,6) })
    local fill = create("Frame", { Parent = bar, Size = UDim2.new(0,0,1,0), BackgroundColor3 = Color3.fromRGB(88,154,255) })
    create("UICorner", { Parent = fill, CornerRadius = UDim.new(0,6) })
    local knob = create("ImageButton", { Parent = bar, Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, -9, 0.5, -9), BackgroundTransparency = 1, AutoButtonColor = false })
    local dragging = false
    local value = math.clamp(default, min, max)
    local function localSet(v)
        value = math.clamp(math.floor(v), min, max)
        local pct = (value - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, -9, 0.5, -9)
        lbl.Text = tostring(text or "Slider") .. ": " .. tostring(value)
        if callback then pcall(callback, value) end
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
            localSet(min + rel * (max - min))
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and bar.AbsoluteSize.X > 0 then
            local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
            localSet(min + rel * (max - min))
        end
    end)
    localSet(value)
    return { Set = function(_, v) localSet(v) end, Get = function() return value end }
end

function LastOneHub:CreateInput(tabName, placeholder, callback)
    local tab = self.Tabs[tabName]
    if not tab then return end
    local box = create("TextBox", { Parent = tab.Container, Text = "", PlaceholderText = tostring(placeholder or "..."), Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.fromRGB(32,32,36), TextColor3 = Color3.fromRGB(230,230,230), Font = Enum.Font.Gotham, TextSize = 14 })
    create("UICorner", { Parent = box, CornerRadius = UDim.new(0,8) })
    box.ClearTextOnFocus = false
    box.FocusLost:Connect(function(enter)
        if enter and callback then pcall(callback, box.Text) end
    end)
    return { Set = function(_, txt, isText) if isText then box.Text = tostring(txt or "") else box.PlaceholderText = tostring(txt or "") end if isText and callback then pcall(callback, box.Text) end end, Get = function() return box.Text end }
end

-- Dropdown redesigned: works as an overlay, supports touch scroll and search optionally
function LastOneHub:CreateDropdown(tabName, labelText, options, callback)
    local tab = self.Tabs[tabName]
    if not tab then return end
    options = options or {}

    local frame = create("Frame", { Parent = tab.Container, Size = UDim2.new(1,0,0,38), BackgroundTransparency = 1 })
    local label = create("TextLabel", { Parent = frame, Text = tostring(labelText or "Dropdown") .. ": Nenhum", Size = UDim2.new(1, -120, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(220,220,220), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
    local openBtn = create("TextButton", { Parent = frame, Text = "▼", Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(1, -100, 0, 0), BackgroundColor3 = Color3.fromRGB(40,40,44), TextColor3 = Color3.fromRGB(240,240,240), Font = Enum.Font.GothamSemibold, TextSize = 14 })
    create("UICorner", { Parent = openBtn, CornerRadius = UDim.new(0,8) })

    -- overlay list
    local list = create("Frame", { Parent = self.Gui, Visible = false, BackgroundColor3 = Color3.fromRGB(28,28,33), Size = UDim2.new(0, 240, 0, 0), ZIndex = 50 })
    create("UICorner", { Parent = list, CornerRadius = UDim.new(0,8) })
    local pad = create("UIPadding", { Parent = list, PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,6), PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6) })
    local sc = create("ScrollingFrame", { Parent = list, Size = UDim2.new(1,-12,1,-12), Position = UDim2.new(0,6,0,6), BackgroundTransparency = 1, ScrollBarThickness = 8 })
    local scLayout = create("UIListLayout", { Parent = sc, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6) })

    local selected = nil
    local isOpen = false

    local function open()
        list:ClearAllChildren()
        create("UICorner", { Parent = list, CornerRadius = UDim.new(0,8) })
        sc = create("ScrollingFrame", { Parent = list, Size = UDim2.new(1,-12,1,-12), Position = UDim2.new(0,6,0,6), BackgroundTransparency = 1, ScrollBarThickness = 8 })
        scLayout = create("UIListLayout", { Parent = sc, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6) })
        for i, opt in ipairs(options) do
            local optBtn = create("TextButton", { Parent = sc, Text = tostring(opt), Size = UDim2.new(1,0,0,34), BackgroundColor3 = Color3.fromRGB(36,36,40), TextColor3 = Color3.fromRGB(240,240,240), Font = Enum.Font.Gotham, TextSize = 14 })
            create("UICorner", { Parent = optBtn, CornerRadius = UDim.new(0,6) })
            optBtn.Activated:Connect(function()
                selected = opt
                label.Text = tostring(labelText or "Dropdown") .. ": " .. tostring(opt)
                list.Visible = false
                isOpen = false
                if callback then pcall(callback, opt) end
            end)
        end
        list.Size = UDim2.new(0, math.max(160, frame.AbsoluteSize.X), 0, math.clamp(#options * 40, 40, 320))
        list.Position = UDim2.new(0, math.clamp(frame.AbsolutePosition.X, 6, workspace.CurrentCamera.ViewportSize.X - list.AbsoluteSize.X - 6), 0, frame.AbsolutePosition.Y + frame.AbsoluteSize.Y + 4)
        list.Visible = true
        isOpen = true
    end

    openBtn.Activated:Connect(function()
        if isOpen then list.Visible = false isOpen = false return end
        open()
    end)

    -- Close when clicking outside
    UserInputService.InputBegan:Connect(function(input)
        if isOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local absPos = Vector2.new(list.AbsolutePosition.X, list.AbsolutePosition.Y)
            local absSize = Vector2.new(list.AbsoluteSize.X, list.AbsoluteSize.Y)
            if not (mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y) then
                list.Visible = false
                isOpen = false
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if isOpen and list and list.Parent then
            pcall(function()
                list.Position = UDim2.new(0, frame.AbsolutePosition.X, 0, frame.AbsolutePosition.Y + frame.AbsoluteSize.Y + 4)
            end)
        end
    end)

    self:UpdateScrolling(tabName)
    return { Set = function(_, val) selected = val label.Text = tostring(labelText or "Dropdown") .. ": " .. tostring(val) if callback then pcall(callback, val) end end, Get = function() return selected end }
end

function LastOneHub:CreateKeybind(tabName, text, default, callback)
    local tab = self.Tabs[tabName]
    if not tab then return end
    local frame = create("Frame", { Parent = tab.Container, Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1 })
    local lbl = create("TextLabel", { Parent = frame, Text = tostring(text or "Keybind") .. ": " .. tostring(default or "None"), Size = UDim2.new(1, -110, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(220,220,220), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
    local btn = create("TextButton", { Parent = frame, Text = "Alterar", Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(1, -100, 0, 0), BackgroundColor3 = Color3.fromRGB(60,60,64), TextColor3 = Color3.fromRGB(240,240,240), Font = Enum.Font.GothamSemibold, TextSize = 14 })
    create("UICorner", { Parent = btn, CornerRadius = UDim.new(0,8) })

    local bind = default
    local changing = false
    if bind then
        self.Keybinds[bind] = callback
    end

    btn.Activated:Connect(function()
        btn.Text = "Pressione uma tecla..."
        changing = true
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if changing then
                bind = input.KeyCode
                lbl.Text = tostring(text or "Keybind") .. ": " .. tostring(bind.Name or tostring(bind))
                self.Keybinds = {}
                self.Keybinds[bind] = callback
                btn.Text = "Alterar"
                changing = false
            else
                local fn = self.Keybinds[input.KeyCode]
                if fn then pcall(fn) end
            end
        end
    end)

    return { Set = function(_, new) bind = new lbl.Text = tostring(text or "Keybind") .. ": " .. tostring(new.Name or tostring(new)) self.Keybinds = {} self.Keybinds[bind] = callback end, Get = function() return bind end }
end

----------------------------
-- Scrolling update utility (public)
----------------------------
function LastOneHub:UpdateScrolling(tabName)
    local tab = (type(tabName) == "table" and tabName) or self.Tabs[tabName]
    if not tab or not tab.Container then return end
    local layout = tab.Container:FindFirstChildOfClass("UIListLayout")
    if not layout then return end
    local total = 0
    local padding = layout.Padding and layout.Padding.Offset or 8
    for _, child in ipairs(tab.Container:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") or child:IsA("ScrollingFrame") then
            local ok, y = pcall(function() return child.Size.Y.Offset end)
            if ok and y then total = total + y + padding end
        end
    end
    tab.Container.CanvasSize = UDim2.new(0,0,0, math.max(0, total))
end

----------------------------
-- Notifications
----------------------------
function LastOneHub:Notify(title, text, dur)
    dur = tonumber(dur) or 3
    local function createNotificationFrame(index)
        local yOffset = -80 - ((index - 1) * 78)
        local frame = create("Frame", { Parent = self.Gui, Size = UDim2.new(0, 320, 0, 74), Position = UDim2.new(1, 24, 1, yOffset), BackgroundColor3 = Color3.fromRGB(30,30,34), ClipsDescendants = true })
        create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 10) })
        local titleLabel = create("TextLabel", { Parent = frame, Text = tostring(title or ""), Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 8), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(240,240,240), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
        local bodyLabel = create("TextLabel", { Parent = frame, Text = tostring(text or ""), Size = UDim2.new(1, -20, 0, 36), Position = UDim2.new(0, 10, 0, 30), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(200,200,200), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 13 })
        titleLabel.TextTransparency = 1
        bodyLabel.TextTransparency = 1
        frame.BackgroundTransparency = 1
        return { Frame = frame, Title = titleLabel, Body = bodyLabel }
    end

    if #self.Notifs >= self.MaxNotifs then
        local excess = (#self.Notifs + 1) - self.MaxNotifs
        for i = 1, excess do
            local old = table.remove(self.Notifs, 1)
            if old and old.Frame then
                pcall(function()
                    TweenService:Create(old.Title, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
                    TweenService:Create(old.Body, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
                    TweenService:Create(old.Frame, TweenInfo.new(0.35), { Position = UDim2.new(1, 24, old.Frame.Position.Y.Scale, old.Frame.Position.Y.Offset), BackgroundTransparency = 1 }):Play()
                end)
                task.delay(0.38, function() if old.Frame and old.Frame.Destroy then pcall(function() old.Frame:Destroy() end) end end)
            end
        end
    end

    for idx, obj in ipairs(self.Notifs) do
        local targetPos = UDim2.new(1, -24, 1, -80 - ((idx - 1) * 78))
        pcall(function() TweenService:Create(obj.Frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = targetPos }):Play() end)
    end

    local newIdx = #self.Notifs + 1
    local notif = createNotificationFrame(newIdx)
    table.insert(self.Notifs, notif)

    local finalPos = UDim2.new(1, -24, 1, -80 - ((newIdx - 1) * 78))
    pcall(function()
        TweenService:Create(notif.Frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = finalPos, BackgroundTransparency = 0 }):Play()
        TweenService:Create(notif.Title, TweenInfo.new(0.28), { TextTransparency = 0 }):Play()
        TweenService:Create(notif.Body, TweenInfo.new(0.28), { TextTransparency = 0 }):Play()
    end)

    task.delay(dur, function()
        local foundIndex = nil
        for i, o in ipairs(self.Notifs) do if o == notif then foundIndex = i break end end
        if foundIndex then
            local obj = table.remove(self.Notifs, foundIndex)
            if obj and obj.Frame then
                pcall(function()
                    TweenService:Create(obj.Title, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
                    TweenService:Create(obj.Body, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
                    TweenService:Create(obj.Frame, TweenInfo.new(0.35), { Position = UDim2.new(1, 24, obj.Frame.Position.Y.Scale, obj.Frame.Position.Y.Offset), BackgroundTransparency = 1 }):Play()
                end)
                task.delay(0.38, function() if obj.Frame and obj.Frame.Destroy then pcall(function() obj.Frame:Destroy() end) end end)
            end
        end
    end)
end
return LastOneHub
----------------------------
-- Return module
----------------------------
return LastOneHub
