--[[
    LastOneHub Premium - Módulo completo
    - Remove GUIs antigas no CoreGui automaticamente (mesmo nome ou tag)
    - Sistema de notificações aprimorado (progress bar, ícone, animações)
    - Aparência melhorada (switch on/off tipo interruptor, cantos arredondados, hover tweens)
    - Proteções com pcall, limpeza de conexões e método :Destroy()

    Uso básico:
    local Hub = require(<caminho_para_arquivo>)
    local ui = Hub.new("Meu GUI")
    local tab = ui:CreateTab("Main")
    local tog = ui:CreateToggle("Main", "Ativar X", false, function(val) print(val) end)
    ui:Notify("Pronto", "GUI iniciada com sucesso", 4)

    Observação: este módulo foi escrito para ambientes onde é possível manipular CoreGui.
]]--

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LastOneHub = {}
LastOneHub.__index = LastOneHub

local function safeSet(parent, class, props)
    local ok, inst = pcall(function()
        local obj = Instance.new(class)
        if props then
            for k, v in pairs(props) do
                pcall(function() obj[k] = v end)
            end
        end
        obj.Parent = parent
        return obj
    end)
    if ok then return inst end
    return nil
end

-- Remove GUIs antigos com o mesmo nome (ou tag) no CoreGui
local function cleanupOldGuis(name)
    pcall(function()
        for _, v in ipairs(CoreGui:GetChildren()) do
            if v:IsA("ScreenGui") and (v.Name == name or v:FindFirstChild("_LastOneHubTag")) then
                pcall(function() v:Destroy() end)
            end
        end
    end)
end

-- Cria o módulo
function LastOneHub.new(title)
    title = tostring(title or "LastOneHub")

    -- cleanup
    cleanupOldGuis("LastOneHub")

    local self = setmetatable({}, LastOneHub)
    self._conns = {} -- armazenar conexões para desconectar
    self.Notifs = {}
    self.MaxNotifs = 4
    self._running = true

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "LastOneHub"
    gui.ResetOnSpawn = false
    -- tag para identificar
    local tag = Instance.new("BoolValue")
    tag.Name = "_LastOneHubTag"
    tag.Value = true
    tag.Parent = gui

    -- set parent com pcall (alguns ambientes bloqueiam)
    pcall(function() gui.Parent = CoreGui end)
    self.Gui = gui

    -- Container principal
    local main = safeSet(gui, "Frame", {
        Size = UDim2.new(0, 520, 0, 380),
        Position = UDim2.new(0.5, -260, 0.5, -190),
        BackgroundColor3 = Color3.fromRGB(28, 28, 30),
        ClipsDescendants = true,
        Name = "Main"
    })
    safeSet(main, "UICorner", { CornerRadius = UDim.new(0, 12) })
    self.Main = main

    -- Topbar
    local top = safeSet(main, "Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(22, 22, 24), Name = "Top" })
    safeSet(top, "UICorner", { CornerRadius = UDim.new(0, 12) })
    local label = safeSet(top, "TextLabel", {
        Text = title,
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(240, 240, 240),
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local closeBtn = safeSet(top, "TextButton", {
        Text = "✕",
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(1, -42, 0, 0),
        BackgroundColor3 = Color3.fromRGB(200, 55, 70),
        AutoButtonColor = false,
        TextColor3 = Color3.fromRGB(255,255,255),
        Name = "Close"
    })
    safeSet(closeBtn, "UICorner", { CornerRadius = UDim.new(0, 8) })
    table.insert(self._conns, closeBtn.MouseButton1Click:Connect(function()
        pcall(function() self:Destroy() end)
        if self.OnClose then pcall(self.OnClose) end
    end))

    -- Hover efeito no close
    closeBtn.MouseEnter:Connect(function() pcall(function() TweenService:Create(closeBtn, TweenInfo.new(0.18), { BackgroundTransparency = 0.15 }):Play() end) end)
    closeBtn.MouseLeave:Connect(function() pcall(function() TweenService:Create(closeBtn, TweenInfo.new(0.18), { BackgroundTransparency = 0 }):Play() end) end)

    -- Drag window
    do
        local dragging, dragInput, dragStart, startPos
        top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        top.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        table.insert(self._conns, UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging and dragStart and startPos then
                local delta = input.Position - dragStart
                local sx, ox = startPos.X.Scale, startPos.X.Offset
                local sy, oy = startPos.Y.Scale, startPos.Y.Offset
                main.Position = UDim2.new(sx, ox + delta.X, sy, oy + delta.Y)
            end
        end))
    end

    -- Sidebar e TabHolder
    local sidebar = safeSet(main, "Frame", { Size = UDim2.new(0, 140, 1, -36), Position = UDim2.new(0, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(24,24,26), Name = "Sidebar" })
    safeSet(sidebar, "UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
    local tabHolder = safeSet(main, "Frame", { Size = UDim2.new(1, -140, 1, -36), Position = UDim2.new(0, 140, 0, 36), BackgroundTransparency = 1, Name = "TabHolder" })

    self.Sidebar = sidebar
    self.TabHolder = tabHolder
    self.Tabs = {}
    self.CurrentTab = nil

    -- Footer (pequeno design)
    local footer = safeSet(main, "Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 1, -6), BackgroundColor3 = Color3.fromRGB(18,18,20) })
    safeSet(footer, "UICorner", { CornerRadius = UDim.new(0,6) })

    -- close old signals
    self:UpdateScrolling = function(_,...) end -- placeholder (vai substituir abaixo)

    -- salva refs
    self.Gui = gui
    self.Main = main

    return self
end

----------------------------
-- Helpers e atualização do Scrolling
----------------------------
function LastOneHub:CreateTab(name)
    if not self.TabHolder or not self.Sidebar then return end
    local btn = safeSet(self.Sidebar, "TextButton", { Text = name, Size = UDim2.new(1, -16, 0, 34), BackgroundColor3 = Color3.fromRGB(30,30,32), TextColor3 = Color3.fromRGB(230,230,230), AutoButtonColor = false })
    safeSet(btn, "UICorner", { CornerRadius = UDim.new(0, 8) })
    local cont = safeSet(self.TabHolder, "ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 6 })
    local layout = safeSet(cont, "UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })

    local tab = { Name = name, Button = btn, Container = cont }
    self.Tabs[name] = tab

    table.insert(self._conns, btn.MouseButton1Click:Connect(function()
        for _, t in pairs(self.Tabs) do if t.Container then t.Container.Visible = false end end
        cont.Visible = true
        self.CurrentTab = tab
    end))

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
-- Elementos: Label, Button, Toggle, Slider, Input, Dropdown, Keybind
----------------------------
function LastOneHub:CreateLabel(tab, text)
    if not self.Tabs[tab] then return end
    local lbl = safeSet(self.Tabs[tab].Container, "TextLabel", { Text = tostring(text or ""), Size = UDim2.new(1, -16, 0, 24), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(34,34,36), TextColor3 = Color3.fromRGB(230,230,230), TextXAlignment = Enum.TextXAlignment.Left })
    safeSet(lbl, "UICorner", { CornerRadius = UDim.new(0,6) })
    self:UpdateScrolling(tab)
    return { Set = function(_, new) lbl.Text = tostring(new); self:UpdateScrolling(tab) end }
end

function LastOneHub:CreateButton(tab, text, callback)
    if not self.Tabs[tab] then return end
    local btn = safeSet(self.Tabs[tab].Container, "TextButton", { Text = tostring(text or ""), Size = UDim2.new(1, -16, 0, 36), BackgroundColor3 = Color3.fromRGB(40,40,42), TextColor3 = Color3.fromRGB(245,245,245), AutoButtonColor = false })
    safeSet(btn, "UICorner", { CornerRadius = UDim.new(0,8) })
    btn.MouseEnter:Connect(function() pcall(function() TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(54,54,56) }):Play() end) end)
    btn.MouseLeave:Connect(function() pcall(function() TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(40,40,42) }):Play() end) end)
    table.insert(self._conns, btn.MouseButton1Click:Connect(function() if callback then pcall(callback) end end))
    self:UpdateScrolling(tab)
    return { Set = function(_, new, cb) btn.Text = tostring(new); if cb then callback = cb end end }
end

-- Toggle estilo interruptor
function LastOneHub:CreateToggle(tab, text, default, callback)
    if not self.Tabs[tab] then return end
    default = (default == true)
    local frame = safeSet(self.Tabs[tab].Container, "Frame", { Size = UDim2.new(1, -16, 0, 40), BackgroundColor3 = Color3.fromRGB(34,34,36) })
    safeSet(frame, "UICorner", { CornerRadius = UDim.new(0,8) })
    local lbl = safeSet(frame, "TextLabel", { Text = tostring(text or ""), Size = UDim2.new(0.7, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(235,235,235), TextXAlignment = Enum.TextXAlignment.Left })

    -- track e knob
    local track = safeSet(frame, "Frame", { Size = UDim2.new(0, 56, 0, 28), Position = UDim2.new(1, -66, 0.5, -14), BackgroundColor3 = default and Color3.fromRGB(72, 187, 120) or Color3.fromRGB(120, 120, 120), Name = "Track" })
    safeSet(track, "UICorner", { CornerRadius = UDim.new(1, 0) })
    local knob = safeSet(track, "Frame", { Size = UDim2.new(0, 24, 0, 24), Position = default and UDim2.new(1, -28, 0.5, -12) or UDim2.new(0, 4, 0.5, -12), BackgroundColor3 = Color3.fromRGB(255,255,255) })
    safeSet(knob, "UICorner", { CornerRadius = UDim.new(1, 0) })

    local state = default
    local function updateVisual(s)
        pcall(function()
            if s then
                TweenService:Create(track, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(72,187,120) }):Play()
                TweenService:Create(knob, TweenInfo.new(0.18), { Position = UDim2.new(1, -28, 0.5, -12) }):Play()
            else
                TweenService:Create(track, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(120,120,120) }):Play()
                TweenService:Create(knob, TweenInfo.new(0.18), { Position = UDim2.new(0, 4, 0.5, -12) }):Play()
            end
        end)
    end

    table.insert(self._conns, track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            updateVisual(state)
            if callback then pcall(callback, state) end
        end
    end))

    -- clique em qualquer parte do frame também
    table.insert(self._conns, frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            updateVisual(state)
            if callback then pcall(callback, state) end
        end
    end))

    updateVisual(state)
    self:UpdateScrolling(tab)
    return {
        Set = function(_, val) state = (val == true); updateVisual(state); if callback then pcall(callback, state) end end,
        Get = function() return state end
    }
end

-- Slider (simples)
function LastOneHub:CreateSlider(tab, text, min, max, default, callback)
    if not self.Tabs[tab] then return end
    min = tonumber(min) or 0
    max = tonumber(max) or 100
    if max == min then max = min + 1 end
    default = tonumber(default) or min

    local frame = safeSet(self.Tabs[tab].Container, "Frame", { Size = UDim2.new(1, -16, 0, 56), BackgroundColor3 = Color3.fromRGB(34,34,36) })
    safeSet(frame, "UICorner", { CornerRadius = UDim.new(0,8) })
    local lbl = safeSet(frame, "TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 6, 0, 4), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(235,235,235), TextXAlignment = Enum.TextXAlignment.Left })
    local bar = safeSet(frame, "Frame", { Size = UDim2.new(1, -20, 0, 8), Position = UDim2.new(0, 10, 0, 30), BackgroundColor3 = Color3.fromRGB(70,70,72) })
    safeSet(bar, "UICorner", { CornerRadius = UDim.new(1,0) })
    local knob = safeSet(bar, "Frame", { Size = UDim2.new(0, 16, 0, 16), BackgroundColor3 = Color3.fromRGB(220,220,220) })
    safeSet(knob, "UICorner", { CornerRadius = UDim.new(1,0) })

    local dragging = false
    local value = math.clamp(default, min, max)

    local function set(val)
        val = math.clamp(tonumber(val) or min, min, max)
        value = val
        local pct = (val - min) / (max - min)
        if pct ~= pct then pct = 0 end
        local x = pct * (bar.AbsoluteSize.X - 16)
        knob.Position = UDim2.new(0, x, 0.5, -8)
        lbl.Text = tostring(text or "") .. ": " .. tostring(val)
        if callback then pcall(callback, val) end
    end

    table.insert(self._conns, knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end))
    table.insert(self._conns, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))
    table.insert(self._conns, UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and bar.AbsoluteSize.X > 0 then
            local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
            rel = math.clamp(rel, 0, 1)
            local computed = math.floor(min + rel * (max - min))
            set(computed)
        end
    end))

    -- atualiza pos ao mudar tamanho
    table.insert(self._conns, bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        set(value)
    end))

    set(value)
    self:UpdateScrolling(tab)
    return { Set = set, Get = function() return value end }
end

-- Input (TextBox) - Set(_, val, true) define texto; sem terceiro define placeholder
function LastOneHub:CreateInput(tab, placeholder, callback)
    if not self.Tabs[tab] then return end
    local box = safeSet(self.Tabs[tab].Container, "TextBox", { Text = "", PlaceholderText = tostring(placeholder or ""), Size = UDim2.new(1, -16, 0, 34), BackgroundColor3 = Color3.fromRGB(34,34,36), TextColor3 = Color3.fromRGB(240,240,240) })
    box.ClearTextOnFocus = false
    table.insert(self._conns, box.FocusLost:Connect(function(enter)
        if enter and callback then pcall(callback, box.Text) end
    end))
    self:UpdateScrolling(tab)
    return {
        Set = function(_, txt, isText)
            if isText == true then
                box.Text = tostring(txt or "")
                if callback then pcall(callback, box.Text) end
            else
                box.PlaceholderText = tostring(txt or "")
            end
        end,
        Get = function() return box.Text end
    }
end

-- Dropdown simples
function LastOneHub:CreateDropdown(tab, text, options, callback)
    if not self.Tabs[tab] then return end
    options = options or {}
    local frame = safeSet(self.Tabs[tab].Container, "Frame", { Size = UDim2.new(1, -16, 0, 34), BackgroundColor3 = Color3.fromRGB(34,34,36) })
    safeSet(frame, "UICorner", { CornerRadius = UDim.new(0,8) })
    local lbl = safeSet(frame, "TextLabel", { Text = tostring(text or "")..": Nenhum", Size = UDim2.new(0.7,0,1,0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(235,235,235), TextXAlignment = Enum.TextXAlignment.Left })
    local btn = safeSet(frame, "TextButton", { Text = "▼", Size = UDim2.new(0.3, -8, 1, 0), Position = UDim2.new(0.7, 8, 0, 0), BackgroundColor3 = Color3.fromRGB(30,30,32), AutoButtonColor = false })
    safeSet(btn, "UICorner", { CornerRadius = UDim.new(0,6) })

    local popup = Instance.new("Frame")
    popup.Name = "_DropdownPopup"
    popup.Parent = self.Gui
    popup.BackgroundColor3 = Color3.fromRGB(36,36,38)
    popup.Visible = false
    popup.ZIndex = 60
    safeSet(popup, "UICorner", { CornerRadius = UDim.new(0,8) })

    local selected = nil
    local isOpen = false

    local function build()
        for _, c in ipairs(popup:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
        local layout = Instance.new("UIListLayout")
        layout.Parent = popup
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        for i, opt in ipairs(options) do
            local o = safeSet(popup, "TextButton", { Text = tostring(opt), Size = UDim2.new(1, -12, 0, 30), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(30,30,32), AutoButtonColor = false })
            o.Position = UDim2.new(0, 6, 0, (i-1)*32 + 6)
            safeSet(o, "UICorner", { CornerRadius = UDim.new(0,6) })
            table.insert(self._conns, o.MouseButton1Click:Connect(function()
                selected = opt
                lbl.Text = tostring(text or "") .. ": " .. tostring(opt)
                popup.Visible = false
                isOpen = false
                if callback then pcall(callback, opt) end
            end))
        end
        popup.Size = UDim2.new(0, math.max(120, frame.AbsoluteSize.X - 16), 0, #options * 32 + 12)
    end

    table.insert(self._conns, btn.MouseButton1Click:Connect(function()
        if isOpen then popup.Visible = false; isOpen = false; return end
        build()
        popup.Position = UDim2.new(0, frame.AbsolutePosition.X, 0, frame.AbsolutePosition.Y + frame.AbsoluteSize.Y + 6)
        popup.Visible = true
        isOpen = true
    end))

    table.insert(self._conns, RunService.RenderStepped:Connect(function()
        if popup.Visible and frame and frame.Parent then
            pcall(function() popup.Position = UDim2.new(0, frame.AbsolutePosition.X, 0, frame.AbsolutePosition.Y + frame.AbsoluteSize.Y + 6) end)
        end
    end))

    self:UpdateScrolling(tab)
    return { Set = function(_, val) selected = val; lbl.Text = tostring(text or "")..": "..tostring(val); if callback then pcall(callback, val) end end, Get = function() return selected end }
end

-- Keybind (simples)
function LastOneHub:CreateKeybind(tab, text, default, callback)
    if not self.Tabs[tab] then return end
    local frame = safeSet(self.Tabs[tab].Container, "Frame", { Size = UDim2.new(1, -16, 0, 34), BackgroundColor3 = Color3.fromRGB(34,34,36) })
    safeSet(frame, "UICorner", { CornerRadius = UDim.new(0,6) })
    local lbl = safeSet(frame, "TextLabel", { Text = tostring(text or "") .. ": " .. tostring(default and (tostring(default.Name or default)) or "Nenhum"), Size = UDim2.new(0.6,0,1,0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(235,235,235), TextXAlignment = Enum.TextXAlignment.Left })
    local btn = safeSet(frame, "TextButton", { Text = "Mudar", Size = UDim2.new(0.4, -8, 1, 0), Position = UDim2.new(0.6, 8, 0, 0), BackgroundColor3 = Color3.fromRGB(30,30,32), AutoButtonColor = false })
    safeSet(btn, "UICorner", { CornerRadius = UDim.new(0,6) })

    local bind = default
    local changing = false
    if bind ~= nil then self.Keybinds = self.Keybinds or {}; self.Keybinds[bind] = callback end

    table.insert(self._conns, btn.MouseButton1Click:Connect(function()
        btn.Text = "Pressione..."
        changing = true
    end))

    table.insert(self._conns, UserInputService.InputBegan:Connect(function(input, gp)
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
                local fn = self.Keybinds and self.Keybinds[input.KeyCode]
                if fn then pcall(fn) end
            end
        end
    end))

    self:UpdateScrolling(tab)
    return { Set = function(_, new) bind = new; lbl.Text = tostring(text or "") .. ": " .. tostring(new.Name or tostring(new)); self.Keybinds = {}; self.Keybinds[bind] = callback end, Get = function() return bind end }
end

----------------------------
-- Notificações aprimoradas
----------------------------
function LastOneHub:Notify(title, text, dur)
    if not self.Gui or not self._running then return end
    dur = tonumber(dur) or 3

    -- se no limite, remove o mais antigo
    if #self.Notifs >= self.MaxNotifs then
        local old = table.remove(self.Notifs, 1)
        if old and old.Frame and old.Frame.Destroy then
            pcall(function()
                TweenService:Create(old.Frame, TweenInfo.new(0.28), { Position = UDim2.new(1, 20, old.Frame.Position.Y.Scale, old.Frame.Position.Y.Offset), BackgroundTransparency = 1 }):Play()
                TweenService:Create(old.Icon, TweenInfo.new(0.18), { ImageTransparency = 1 }):Play()
                TweenService:Create(old.Title, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
                TweenService:Create(old.Body, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
            end)
            task.delay(0.34, function() pcall(function() if old.Frame and old.Frame.Destroy then old.Frame:Destroy() end end) end)
        end
    end

    -- criar notif
    local idx = #self.Notifs + 1
    local yOff = -86 - ((idx - 1) * 86)
    local f = safeSet(self.Gui, "Frame", { Size = UDim2.new(0, 340, 0, 80), Position = UDim2.new(1, 20, 1, yOff), BackgroundColor3 = Color3.fromRGB(34,34,36), ClipsDescendants = true })
    safeSet(f, "UICorner", { CornerRadius = UDim.new(0,10) })
    safeSet(f, "UIStroke", { Thickness = 1, Color = Color3.fromRGB(18,18,20), Transparency = 0.6 })

    local icon = safeSet(f, "ImageLabel", { Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0, 12, 0, 16), BackgroundTransparency = 1, Image = "rbxassetid://7051095257" })
    local titleLabel = safeSet(f, "TextLabel", { Text = tostring(title or ""), Position = UDim2.new(0, 76, 0, 12), Size = UDim2.new(1, -88, 0, 20), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(245,245,245), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left })
    local bodyLabel = safeSet(f, "TextLabel", { Text = tostring(text or ""), Position = UDim2.new(0, 76, 0, 32), Size = UDim2.new(1, -88, 0, 36), BackgroundTransparency = 1, TextWrapped = true, TextColor3 = Color3.fromRGB(210,210,210), TextXAlignment = Enum.TextXAlignment.Left })

    -- Barra de progresso
    local progBg = safeSet(f, "Frame", { Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 1, -14), BackgroundColor3 = Color3.fromRGB(24,24,26) })
    safeSet(progBg, "UICorner", { CornerRadius = UDim.new(1,0) })
    local prog = safeSet(progBg, "Frame", { Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Color3.fromRGB(72,187,120) })
    safeSet(prog, "UICorner", { CornerRadius = UDim.new(1,0) })

    -- inserir na lista e animar
    table.insert(self.Notifs, { Frame = f, Icon = icon, Title = titleLabel, Body = bodyLabel, Prog = prog })

    -- anima entrada
    pcall(function()
        local final = UDim2.new(1, -380, 1, yOff)
        TweenService:Create(f, TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = final, BackgroundTransparency = 0 }):Play()
        TweenService:Create(titleLabel, TweenInfo.new(0.28), { TextTransparency = 0 }):Play()
        TweenService:Create(bodyLabel, TweenInfo.new(0.28), { TextTransparency = 0 }):Play()
        TweenService:Create(icon, TweenInfo.new(0.28), { ImageTransparency = 0 }):Play()
    end)

    -- reposicionar todas
    for i, o in ipairs(self.Notifs) do
        local target = UDim2.new(1, -380, 1, -86 - ((i - 1) * 86))
        pcall(function() TweenService:Create(o.Frame, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = target }):Play() end)
    end

    -- progress animation (smooth)
    local elapsed = 0
    local function step(dt)
        elapsed = elapsed + dt
        local pct = math.clamp(elapsed / dur, 0, 1)
        if prog and prog.Parent then
            pcall(function()
                prog.Size = UDim2.new(pct, 0, 1, 0)
            end)
        end
        if pct >= 1 then return true end
        return false
    end

    -- conecta RenderStepped temporário
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        if step(dt) then
            if conn then conn:Disconnect() end
        end
    end)
    table.insert(self._conns, conn)

    -- remover após dur
    task.delay(dur, function()
        -- achar index
        local idx = nil
        for i, o in ipairs(self.Notifs) do if o.Frame == f then idx = i break end end
        if idx then
            local obj = table.remove(self.Notifs, idx)
            if obj and obj.Frame then
                pcall(function()
                    TweenService:Create(obj.Frame, TweenInfo.new(0.28), { Position = UDim2.new(1, 40, obj.Frame.Position.Y.Scale, obj.Frame.Position.Y.Offset), BackgroundTransparency = 1 }):Play()
                    TweenService:Create(obj.Title, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
                    TweenService:Create(obj.Body, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
                    TweenService:Create(obj.Icon, TweenInfo.new(0.18), { ImageTransparency = 1 }):Play()
                end)
                task.delay(0.34, function() pcall(function() if obj.Frame and obj.Frame.Destroy then obj.Frame:Destroy() end end) end)
            end

            -- reposicionar restante
            for i, o in ipairs(self.Notifs) do
                local target = UDim2.new(1, -380, 1, -86 - ((i - 1) * 86))
                pcall(function() TweenService:Create(o.Frame, TweenInfo.new(0.28), { Position = target }):Play() end)
            end
        end
    end)
end

----------------------------
-- Destroy: limpa tudo e desconecta
----------------------------
function LastOneHub:Destroy()
    if not self._running then return end
    self._running = false

    -- desconecta conexões
    for _, c in ipairs(self._conns) do
        pcall(function() if c and c.Disconnect then c:Disconnect() end end)
    end
    self._conns = {}

    -- destroi notificações
    for _, n in ipairs(self.Notifs) do
        pcall(function() if n.Frame and n.Frame.Destroy then n.Frame:Destroy() end end)
    end
    self.Notifs = {}

    -- destroi GUI
    pcall(function() if self.Gui and self.Gui.Destroy then self.Gui:Destroy() end end)
end
