-- Module: LastOneHub (com suporte a celular / touch)
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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

----------------------------
-- Construtor
----------------------------
function LastOneHub.new(title)
    local oldGui = game:GetService("CoreGui"):FindFirstChild("LastoneHub")
    if oldGui then
        pcall(function() oldGui:Destroy() end)
    end

    local self = setmetatable({}, LastOneHub)

    -- Detecta se é dispositivo touch (celular/tablet)
    local isTouch = UserInputService.TouchEnabled == true

    self.Gui = create("ScreenGui", { Parent = game:GetService("CoreGui"), ResetOnSpawn = false, Name = "LastoneHub" })

    -- tamanho padrão e reduzido para celular
    local mainSize = isTouch and UDim2.new(0, 360, 0, 260) or UDim2.new(0, 500, 0, 350)
    local mainPos = UDim2.new(0.5, -(mainSize.X.Offset/2), 0.5, -(mainSize.Y.Offset/2))

    self.Main = create("Frame", {
        Parent = self.Gui,
        Size = mainSize,
        Position = mainPos,
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        ClipsDescendants = true,
        AnchorPoint = Vector2.new(0,0)
    })

    local top = create("Frame", { Parent = self.Main, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(30, 30, 30), Name = "TopBar" })
    create("TextLabel", {
        Parent = top,
        Text = title or "LastOneHub",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamSemibold,
        TextSize = 16
    })

    local closeBtn = create("TextButton", {
        Parent = top,
        Text = "X",
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -30, 0, 0),
        BackgroundColor3 = Color3.fromRGB(170, 0, 0),
        TextColor3 = Color3.new(1, 1, 1)
    })
    create("UICorner", { Parent = closeBtn, CornerRadius = UDim.new(0, 4) })

    closeBtn.MouseButton1Click:Connect(function()
        pcall(function() self.Gui.Enabled = false end)
        if self.OnClose then pcall(self.OnClose) end
    end)

    -- Drag da janela (mouse + touch)
    local dragging, dragInput, dragStart, startPos
    local function beginDrag(input)
        dragging = true
        dragStart = input.Position
        startPos = self.Main.Position
        -- on end
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end

    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            beginDrag(input)
        elseif input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end)

    top.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and dragStart and startPos then
            local delta = input.Position - dragStart
            local sx, ox = startPos.X.Scale, startPos.X.Offset
            local sy, oy = startPos.Y.Scale, startPos.Y.Offset
            self.Main.Position = UDim2.new(sx, ox + delta.X, sy, oy + delta.Y)
        end
    end)

    -- Sidebar e container de abas
    self.Sidebar = create("Frame", { Parent = self.Main, Size = UDim2.new(0, 120, 1, -30), Position = UDim2.new(0, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(35, 35, 35) })
    create("UIListLayout", { Parent = self.Sidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) })

    self.TabHolder = create("Frame", { Parent = self.Main, Size = UDim2.new(1, -120, 1, -30), Position = UDim2.new(0, 120, 0, 30), BackgroundColor3 = Color3.fromRGB(50, 50, 50) })
    self.Tabs = {}
    self.Keybinds = {}
    self.Notifs = {}
    self.MaxNotifs = 5

    return self
end

----------------------------
-- Tabs e Scrolling
----------------------------
function LastOneHub:CreateTab(name)
    local btn = create("TextButton", { Parent = self.Sidebar, Text = name, Size = UDim2.new(1, -10, 0, 30), BackgroundColor3 = Color3.fromRGB(45, 45, 45), TextColor3 = Color3.new(1, 1, 1) })
    create("UICorner", { Parent = btn, CornerRadius = UDim.new(0,6) })
    local cont = create("ScrollingFrame", { Parent = self.TabHolder, Size = UDim2.new(1, 0, 1, 0), Visible = false, BackgroundTransparency = 1, ScrollBarThickness = 6, CanvasSize = UDim2.new(0, 0, 0, 0) })
    create("UIListLayout", { Parent = cont, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) })

    local tab = { Name = name, Button = btn, Container = cont }
    self.Tabs[name] = tab

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(self.Tabs) do
            if t.Container then t.Container.Visible = false end
        end
        cont.Visible = true
        self.CurrentTab = tab
    end)

    if not self.CurrentTab then
        cont.Visible = true
        self.CurrentTab = tab
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
        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") or child:IsA("ScrollingFrame") then
            local ok, y = pcall(function() return child.Size.Y.Offset end)
            local pad = (layout.Padding and layout.Padding.Offset) or 0
            total = total + (tonumber(y) or 0) + (tonumber(pad) or 0)
        end
    end
    tab.Container.CanvasSize = UDim2.new(0, 0, 0, total)
end

----------------------------
-- Elementos
----------------------------
-- Label
function LastOneHub:CreateLabel(tab, text)
    if not self.Tabs[tab] then return end
    local lbl = create("TextLabel", { Parent = self.Tabs[tab].Container, Text = tostring(text or ""), Size = UDim2.new(1, -10, 0, 25), BackgroundColor3 = Color3.fromRGB(60, 60, 60), TextColor3 = Color3.new(1, 1, 1) })
    self:UpdateScrolling(tab)
    return {
        Set = function(_, new) lbl.Text = tostring(new); self:UpdateScrolling(tab) end
    }
end

-- Button
function LastOneHub:CreateButton(tab, text, callback)
    if not self.Tabs[tab] then return end
    local btn = create("TextButton", { Parent = self.Tabs[tab].Container, Text = tostring(text or ""), Size = UDim2.new(1, -10, 0, 30), BackgroundColor3 = Color3.fromRGB(70, 70, 70), TextColor3 = Color3.new(1, 1, 1) })
    create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 6) })

    btn.MouseEnter:Connect(function()
        pcall(function() TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(90, 90, 90) }):Play() end)
    end)
    btn.MouseLeave:Connect(function()
        pcall(function() TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(70, 70, 70) }):Play() end)
    end)
    btn.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)

    self:UpdateScrolling(tab)
    return {
        Set = function(_, new, cb) btn.Text = tostring(new); if cb then callback = cb end end
    }
end

-- Toggle
function LastOneHub:CreateToggle(tab, text, default, callback)
    if not self.Tabs[tab] then return end
    default = (default == true)

    local frame = create("Frame", { Parent = self.Tabs[tab].Container, Size = UDim2.new(1, -10, 0, 30), BackgroundColor3 = Color3.fromRGB(60, 60, 60) })
    local lbl = create("TextLabel", { Parent = frame, Text = tostring(text or ""), Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), TextXAlignment = Enum.TextXAlignment.Left })
    local btn = create("TextButton", { Parent = frame, Text = default and "ON" or "OFF", Size = UDim2.new(0,40,1,0), Position = UDim2.new(1,-40,0,0), BackgroundColor3 = default and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0), TextColor3 = Color3.new(1,1,1) })
    create("UICorner", { Parent = btn, CornerRadius = UDim.new(0,4) })

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
        if callback then pcall(callback, state) end
    end)

    self:UpdateScrolling(tab)
    return {
        Set = function(_, val)
            state = (val == true)
            btn.Text = state and "ON" or "OFF"
            btn.BackgroundColor3 = state and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
            if callback then pcall(callback, state) end
        end,
        Get = function() return state end
    }
end

-- Slider (suporte mouse + touch)
function LastOneHub:CreateSlider(tab, text, min, max, default, callback)
    if not self.Tabs[tab] then return end
    min = tonumber(min) or 0
    max = tonumber(max) or 100
    if max == min then max = min + 1 end
    default = tonumber(default) or min
    local function safeClamp(v,a,b) v=tonumber(v) or a if v<a then return a end if v>b then return b end return v end

    local frame = create("Frame", { Parent = self.Tabs[tab].Container, Size = UDim2.new(1, -10, 0, 50), BackgroundColor3 = Color3.fromRGB(60, 60, 60) })
    local lbl = create("TextLabel", { Parent = frame, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), TextXAlignment = Enum.TextXAlignment.Left })
    local bar = create("Frame", { Parent = frame, Size = UDim2.new(1, -20, 0, 8), Position = UDim2.new(0, 10, 0, 30), BackgroundColor3 = Color3.fromRGB(90, 90, 90) })
    local knob = create("Frame", { Parent = bar, Size = UDim2.new(0, 15, 0, 15), BackgroundColor3 = Color3.fromRGB(200, 50, 50) })
    create("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })

    local dragging = false
    local touchId = nil
    local value = safeClamp(default, min, max)

    local function set(val)
        val = safeClamp(val, min, max)
        value = val
        local pct = (val - min) / (max - min)
        if pct ~= pct then pct = 0 end
        knob.Position = UDim2.new(pct, -7.5, -0.5, 0)
        lbl.Text = tostring(text or "") .. ": " .. tostring(val)
        if callback then pcall(callback, val) end
    end

    -- Input handlers (mouse + touch)
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        elseif input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            touchId = input.UserInputState == nil and nil or input -- we don't need id here; keep touch flag
        end
    end)
    knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        elseif input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            touchId = nil
        end
    end)
    -- Também permite clicar na barra para mover
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
            rel = math.clamp(rel, 0, 1)
            local computed = math.floor(min + rel * (max - min))
            set(computed)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and bar.AbsoluteSize.X > 0 then
            local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
            rel = math.clamp(rel, 0, 1)
            local computed = math.floor(min + rel * (max - min))
            set(computed)
        end
    end)

    set(value)
    self:UpdateScrolling(tab)
    return { Set = set, Get = function() return value end }
end

----------------------------
-- Input (TextBox)
----------------------------
function LastOneHub:CreateInput(tab, placeholder, callback)
    if not self.Tabs[tab] then return end
    local box = create("TextBox", {
        Parent = self.Tabs[tab].Container,
        Text = "",
        PlaceholderText = tostring(placeholder or ""),
        Size = UDim2.new(1, -10, 0, 30),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        TextColor3 = Color3.new(1, 1, 1)
    })
    box.ClearTextOnFocus = false
    box.FocusLost:Connect(function(enter)
        if enter and callback then pcall(callback, box.Text) end
    end)
    self:UpdateScrolling(tab)
    return {
        Set = function(_, txt, isText)
            if isText == true then
                box.Text = tostring(txt or "")
            else
                box.PlaceholderText = tostring(txt or "")
            end
            if callback and isText == true then pcall(callback, box.Text) end
        end,
        Get = function() return box.Text end
    }
end

----------------------------
-- Dropdown
----------------------------
function LastOneHub:CreateDropdown(tab, text, options, callback)
    if not self.Tabs[tab] then return end
    options = options or {}
    local frame = create("Frame", { Parent = self.Tabs[tab].Container, Size = UDim2.new(1, -10, 0, 30), BackgroundColor3 = Color3.fromRGB(60, 60, 60) })
    local lbl = create("TextLabel", { Parent = frame, Text = tostring(text or "") .. ": Nenhum", Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left })
    local btn = create("TextButton", { Parent = frame, Text = "▼", Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(90, 90, 90), TextColor3 = Color3.new(1, 1, 1) })
    create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 4) })

    local list = create("Frame", { Parent = self.Gui, Visible = false, BackgroundColor3 = Color3.fromRGB(70, 70, 70), Size = UDim2.new(0, 150, 0, 0), ZIndex = 50 })
    create("UIListLayout", { Parent = list, SortOrder = Enum.SortOrder.LayoutOrder })

    local selected = nil
    local isOpen = false

    local function toggleDropdown()
        if isOpen then
            list.Visible = false
            isOpen = false
            return
        end
        list:ClearAllChildren()
        create("UIListLayout", { Parent = list })
        for _, opt in ipairs(options) do
            local o = create("TextButton", { Parent = list, Text = tostring(opt), Size = UDim2.new(1, 0, 0, 25), BackgroundColor3 = Color3.fromRGB(100, 100, 100), TextColor3 = Color3.new(1, 1, 1), ZIndex = 50 })
            create("UICorner", { Parent = o, CornerRadius = UDim.new(0, 4) })
            o.MouseButton1Click:Connect(function()
                selected = opt
                lbl.Text = tostring(text or "") .. ": " .. tostring(opt)
                list.Visible = false
                isOpen = false
                if callback then pcall(callback, opt) end
            end)
            -- touch compatibility: also allow TouchEnded
            o.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    selected = opt
                    lbl.Text = tostring(text or "") .. ": " .. tostring(opt)
                    list.Visible = false
                    isOpen = false
                    if callback then pcall(callback, opt) end
                end
            end)
        end
        list.Size = UDim2.new(0, math.max(100, frame.AbsoluteSize.X), 0, #options * 25)
        list.Position = UDim2.new(0, frame.AbsolutePosition.X, 0, frame.AbsolutePosition.Y + frame.AbsoluteSize.Y)
        list.Visible = true
        isOpen = true
    end

    btn.MouseButton1Click:Connect(toggleDropdown)
    btn.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then toggleDropdown() end end)

    RunService.RenderStepped:Connect(function()
        if list.Visible and frame and frame.Parent then
            pcall(function()
                list.Position = UDim2.new(0, frame.AbsolutePosition.X, 0, frame.AbsolutePosition.Y + frame.AbsoluteSize.Y)
            end)
        end
    end)

    self:UpdateScrolling(tab)
    return {
        Set = function(_, val)
            selected = val
            lbl.Text = tostring(text or "") .. ": " .. tostring(val)
            if callback then pcall(callback, val) end
        end,
        Get = function() return selected end
    }
end

----------------------------
-- Keybind
----------------------------
function LastOneHub:CreateKeybind(tab, text, default, callback)
    if not self.Tabs[tab] then return end
    local frame = create("Frame", { Parent = self.Tabs[tab].Container, Size = UDim2.new(1, -10, 0, 30), BackgroundColor3 = Color3.fromRGB(60, 60, 60) })
    local lbl = create("TextLabel", { Parent = frame, Text = tostring(text or "") .. ": " .. tostring(default), Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left })
    local btn = create("TextButton", { Parent = frame, Text = "Mudar", Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(90, 90, 90), TextColor3 = Color3.new(1, 1, 1) })
    create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 4) })

    local bind = default
    local changing = false
    if bind ~= nil then self.Keybinds[bind] = callback end

    btn.MouseButton1Click:Connect(function()
        btn.Text = "Pressione..."
        changing = true
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if changing then
                bind = input.KeyCode
                lbl.Text = tostring(text or "") .. ": " .. tostring(bind.Name or tostring(bind))
                self.Keybinds = {}
                self.Keybinds[bind] = callback
                btn.Text = "Mudar"
                changing = false
            else
                local fn = self.Keybinds[input.KeyCode]
                if fn then pcall(fn) end
            end
        end
    end)

    self:UpdateScrolling(tab)
    return {
        Set = function(_, new)
            bind = new
            lbl.Text = tostring(text or "") .. ": " .. tostring(new.Name or tostring(new))
            self.Keybinds = {}
            self.Keybinds[bind] = callback
        end,
        Get = function() return bind end
    }
end

----------------------------
-- Notificações
----------------------------
function LastOneHub:Notify(title, text, dur)
    dur = tonumber(dur) or 3

    local function createNotificationFrame(index)
        local yOffset = -70 - ((index - 1) * 70)
        local frame = create("Frame", { Parent = self.Gui, Size = UDim2.new(0, 300, 0, 70), Position = UDim2.new(1, 320, 1, yOffset), BackgroundColor3 = Color3.fromRGB(50, 50, 50), ClipsDescendants = true })
        create("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 8) })

                local titleLabel=create("TextLabel",{ 
            Parent=frame, 
            Text=tostring(title or ""), 
            Size=UDim2.new(1,-20,0,24), 
            Position=UDim2.new(0,10,0,6), 
            BackgroundTransparency=1, 
            TextColor3=Color3.new(1,1,1), 
            TextXAlignment=Enum.TextXAlignment.Left, 
            Font=Enum.Font.SourceSansBold 
        })
        local bodyLabel=create("TextLabel",{ 
            Parent=frame, 
            Text=tostring(text or ""), 
            Size=UDim2.new(1,-20,0,36), 
            Position=UDim2.new(0,10,0,28), 
            BackgroundTransparency=1, 
            TextColor3=Color3.new(1,1,1), 
            TextWrapped=true, 
            TextXAlignment=Enum.TextXAlignment.Left 
        })

        titleLabel.TextTransparency=1
        bodyLabel.TextTransparency=1
        frame.BackgroundTransparency=1

        return { Frame=frame, Title=titleLabel, Body=bodyLabel }
    end

    if #self.Notifs>=self.MaxNotifs then
        local excess=(#self.Notifs+1)-self.MaxNotifs
        for i=1,excess do
            local old=table.remove(self.Notifs,1)
            if old and old.Frame then
                pcall(function()
                    TweenService:Create(old.Title,TweenInfo.new(0.25),{TextTransparency=1}):Play()
                    TweenService:Create(old.Body,TweenInfo.new(0.25),{TextTransparency=1}):Play()
                    TweenService:Create(old.Frame,TweenInfo.new(0.35),{
                        Position=UDim2.new(1,320,old.Frame.Position.Y.Scale,old.Frame.Position.Y.Offset), 
                        BackgroundTransparency=1
                    }):Play()
                end)
                task.delay(0.38,function()
                    if old.Frame and old.Frame.Destroy then 
                        pcall(function() old.Frame:Destroy() end) 
                    end
                end)
            end
        end
        for idx,obj in ipairs(self.Notifs) do
            local targetPos=UDim2.new(1,-320,1,-70-((idx-1)*70))
            pcall(function() 
                TweenService:Create(obj.Frame,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
                    Position=targetPos
                }):Play() 
            end)
        end
    end

    local newIdx=#self.Notifs+1
    local notif=createNotificationFrame(newIdx)
    table.insert(self.Notifs,notif)
    local finalPos=UDim2.new(1,-320,1,-70-((newIdx-1)*70))
    pcall(function()
        TweenService:Create(notif.Frame,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
            Position=finalPos,BackgroundTransparency=0
        }):Play()
        TweenService:Create(notif.Title,TweenInfo.new(0.28),{TextTransparency=0}):Play()
        TweenService:Create(notif.Body,TweenInfo.new(0.28),{TextTransparency=0}):Play()
    end)

    for idx,obj in ipairs(self.Notifs) do
        local target=UDim2.new(1,-320,1,-70-((idx-1)*70))
        pcall(function() 
            TweenService:Create(obj.Frame,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
                Position=target
            }):Play() 
        end)
    end

    task.delay(dur,function()
        local foundIndex=nil
        for i,o in ipairs(self.Notifs) do 
            if o==notif then 
                foundIndex=i 
                break 
            end 
        end
        if foundIndex then
            local obj=table.remove(self.Notifs,foundIndex)
            if obj and obj.Frame then
                pcall(function()
                    TweenService:Create(obj.Title,TweenInfo.new(0.25),{TextTransparency=1}):Play()
                    TweenService:Create(obj.Body,TweenInfo.new(0.25),{TextTransparency=1}):Play()
                    TweenService:Create(obj.Frame,TweenInfo.new(0.35),{
                        Position=UDim2.new(1,320,obj.Frame.Position.Y.Scale,obj.Frame.Position.Y.Offset),
                        BackgroundTransparency=1
                    }):Play()
                end)
                task.delay(0.38,function()
                    if obj.Frame and obj.Frame.Destroy then 
                        pcall(function() obj.Frame:Destroy() end) 
                    end
                end)
            end
        end
    end)
end

----------------------------
-- Retorno do módulo
----------------------------
return LastOneHub
