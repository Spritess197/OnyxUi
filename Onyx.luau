--[[
discord: spritess197
tg: spritess197
]]
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Tokens = {
    Colors = {
        WindowBackground = Color3.fromRGB(14, 16, 21),
        TopbarBackground = Color3.fromRGB(20, 23, 30),
        Border = Color3.fromRGB(42, 48, 62),
        BorderSubtle = Color3.fromRGB(28, 32, 42),
        CardBackground = Color3.fromRGB(18, 21, 28),
        CardBorder = Color3.fromRGB(33, 38, 50),
        Elevated = Color3.fromRGB(24, 28, 38),
        ElevatedHover = Color3.fromRGB(32, 38, 52),
        TextPrimary = Color3.fromRGB(235, 238, 246),
        TextSecondary = Color3.fromRGB(180, 186, 202),
        TextMuted = Color3.fromRGB(130, 137, 153),
        CloseButton = Color3.fromRGB(255, 95, 87),
        MinimizeButton = Color3.fromRGB(254, 188, 46),
        MaximizeButton = Color3.fromRGB(40, 200, 64),
        WidgetBackground = Color3.fromRGB(20, 23, 30),
        WidgetHover = Color3.fromRGB(28, 32, 42),
        TabDefault = Color3.fromRGB(14, 16, 21),
        TabHover = Color3.fromRGB(24, 28, 37),
        TabActive = Color3.fromRGB(30, 35, 47),
        TabActiveText = Color3.fromRGB(255, 255, 255),
        TabHoverText = Color3.fromRGB(205, 212, 228),
        TabDefaultText = Color3.fromRGB(130, 137, 153),
        Accent = Color3.fromRGB(59, 130, 246),
        AccentHalf = Color3.fromRGB(147, 197, 253),
        AccentHover = Color3.fromRGB(37, 99, 235),
        AccentMuted = Color3.fromRGB(26, 44, 76),
        InputBackground = Color3.fromRGB(13, 15, 20),
        InputBorder = Color3.fromRGB(34, 40, 54),
        InputFocusBorder = Color3.fromRGB(59, 130, 246),
        TrackBackground = Color3.fromRGB(24, 28, 38),
        ToggleActive = Color3.fromRGB(59, 130, 246),
        ToggleInactive = Color3.fromRGB(28, 33, 44),
        ToggleKnob = Color3.fromRGB(235, 238, 246),
        ToggleKnobOff = Color3.fromRGB(130, 137, 153),
        PopupBackground = Color3.fromRGB(16, 19, 26),
        PopupBorder = Color3.fromRGB(42, 48, 64),
    },
    Typography = {
        FontRegular = Enum.Font.Gotham,
        FontMedium = Enum.Font.GothamMedium,
        FontBold = Enum.Font.GothamBold,
        TitleSize = 13,
        SubtitleSize = 11,
        TabSize = 14,
        SectionTitle = 13,
        ControlLabel = 12,
        Description = 11,
        ValueText = 11,
        BadgeText = 10,
    },
    Radius = {
        Window = 10,
        Card = 8,
        Section = 8,
        Toast = 8,
        Widget = 8,
        Control = 6,
        Tab = 6,
        Avatar = 6,
        Small = 4,
        Pill = 999,
    },
    Animation = {
        Duration = 0.16,
        FastDuration = 0.10,
        EasingStyle = Enum.EasingStyle.Quad,
        EasingDirection = Enum.EasingDirection.Out,
    },
}

local Maid = {}
Maid.__index = Maid

function Maid.New()
    return setmetatable({
        Tasks = {},
        IsCleaned = false,
    }, Maid)
end

function Maid:GiveTask(Task)
    if self.IsCleaned then
        if typeof(Task) == "RBXScriptConnection" then
            Task:Disconnect()
        elseif typeof(Task) == "Instance" then
            Task:Destroy()
        elseif type(Task) == "function" then
            Task()
        elseif type(Task) == "table" and Task.Destroy then
            Task:Destroy()
        end
        return Task
    end
    table.insert(self.Tasks, Task)
    return Task
end

function Maid:Cleanup()
    if self.IsCleaned then
        return
    end
    self.IsCleaned = true
    for Index = #self.Tasks, 1, -1 do
        local Task = self.Tasks[Index]
        if typeof(Task) == "RBXScriptConnection" then
            Task:Disconnect()
        elseif typeof(Task) == "Instance" then
            Task:Destroy()
        elseif type(Task) == "function" then
            Task()
        elseif type(Task) == "table" and Task.Destroy then
            Task:Destroy()
        end
        self.Tasks[Index] = nil
    end
end

Maid.Destroy = Maid.Cleanup

local Signal = {}
Signal.__index = Signal

function Signal.New()
    return setmetatable({
        Handlers = {},
        Maid = Maid.New(),
    }, Signal)
end

function Signal:Connect(Handler)
    table.insert(self.Handlers, Handler)
    local Connection = {
        Connected = true,
        Disconnect = function(Conn)
            if not Conn.Connected then
                return
            end
            Conn.Connected = false
            for Index, Item in ipairs(self.Handlers) do
                if Item == Handler then
                    table.remove(self.Handlers, Index)
                    break
                end
            end
        end
    }
    return Connection
end

function Signal:Fire(...)
    for _, Handler in ipairs(self.Handlers) do
        task.spawn(Handler, ...)
    end
end

function Signal:Destroy()
    table.clear(self.Handlers)
    self.Maid:Cleanup()
end

shared.OnyxUI_RegisteredKeybinds = shared.OnyxUI_RegisteredKeybinds or shared.MacOSWindow_RegisteredKeybinds or {}
shared.MacOSWindow_RegisteredKeybinds = shared.OnyxUI_RegisteredKeybinds

local Library = {
    CurrentWindow = nil,
    OnAccentChanged = Signal.New(),
    IsBindingKey = false,
    LastKeybindTime = 0,
    RegisteredKeybinds = shared.OnyxUI_RegisteredKeybinds,
}

function Library:ForceCloseRobloxMenu()
    pcall(function()
        GuiService:SetMenuIsOpen(false, "SettingsHub")
        GuiService:SetMenuIsOpen(false)
    end)
    local TargetCore = (get_hidden_gui or gethui) and (get_hidden_gui or gethui)() or CoreGui
    local CoreToSearch = { TargetCore, CoreGui }
    for _, RootContainer in ipairs(CoreToSearch) do
        if RootContainer then
            local RGui = RootContainer:FindFirstChild("RobloxGui") or (RootContainer.Name == "RobloxGui" and RootContainer)
            if RGui then
                local Shield = RGui:FindFirstChild("SettingsClippingShield")
                if Shield and Shield:IsA("GuiObject") then
                    Shield.Visible = false
                end
            end
        end
    end
end

function Library:SetAccentColor(NewAccent: Color3)
    Tokens.Colors.Accent = NewAccent
    local H, S, V = Color3.toHSV(NewAccent)
    Tokens.Colors.AccentHalf = Color3.fromHSV(H, math.max(0, S * 0.5), math.min(1, V * 1.2))
    Tokens.Colors.AccentHover = Color3.fromHSV(H, math.min(1, S * 1.1), math.max(0, V * 0.85))
    Tokens.Colors.AccentMuted = Color3.fromHSV(H, S * 0.4, V * 0.3)
    Tokens.Colors.ToggleActive = NewAccent
    Tokens.Colors.InputFocusBorder = NewAccent
    Library.OnAccentChanged:Fire(NewAccent)
end

local Utility = {}

function Utility.RegisterAccent(TargetInstance: Instance, PropertyName: string, ColorMapper: ((Color3) -> any)?)
    local function UpdateColor(Accent: Color3)
        if not TargetInstance or not TargetInstance.Parent then
            return
        end
        local Val = if ColorMapper then ColorMapper(Accent) else Accent
        TargetInstance[PropertyName] = Val
    end

    local Conn = Library.OnAccentChanged:Connect(UpdateColor)
    TargetInstance.Destroying:Connect(function()
        Conn:Disconnect()
    end)
    return Conn
end

function Utility.Create(ClassName: string, Properties: { [string]: any }, Children: { [number]: Instance }?)
    local InstanceObject = Instance.new(ClassName)
    for Key, Value in pairs(Properties) do
        InstanceObject[Key] = Value
    end
    if Children then
        for _, Child in ipairs(Children) do
            Child.Parent = InstanceObject
        end
    end
    return InstanceObject
end

function Utility.CreateCorner(Radius: any, Parent: Instance?)
    local CornerRadiusValue = if typeof(Radius) == "UDim" then Radius else UDim.new(0, Radius)
    return Utility.Create("UICorner", {
        CornerRadius = CornerRadiusValue,
        Parent = Parent,
    })
end

function Utility.CreateStroke(Color: Color3, Thickness: number, Transparency: number, Parent: Instance?)
    return Utility.Create("UIStroke", {
        Color = Color,
        Thickness = Thickness,
        Transparency = Transparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = Parent,
    })
end

function Utility.CreatePadding(Top: number, Bottom: number, Left: number, Right: number, Parent: Instance?)
    return Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, Top),
        PaddingBottom = UDim.new(0, Bottom),
        PaddingLeft = UDim.new(0, Left),
        PaddingRight = UDim.new(0, Right),
        Parent = Parent,
    })
end

function Utility.Tween(InstanceObject: Instance, Properties: { [string]: any }, Duration: number?)
    local TweenLength = Duration or Tokens.Animation.Duration
    local TweenInstance = TweenService:Create(
        InstanceObject,
        TweenInfo.new(TweenLength, Tokens.Animation.EasingStyle, Tokens.Animation.EasingDirection),
        Properties
    )
    TweenInstance:Play()
    return TweenInstance
end

function Utility.Snap(Value: number, Min: number, Max: number, Step: number): number
    local RawStep = math.round((Value - Min) / Step) * Step + Min
    local Stepped = math.clamp(RawStep, Min, Max)
    local DecimalPlaces = 0
    local StepString = tostring(Step)
    local DotPos = string.find(StepString, "%.")
    if DotPos then
        DecimalPlaces = #StepString - DotPos
    end
    if DecimalPlaces > 0 then
        local Multiplier = 10 ^ DecimalPlaces
        Stepped = math.round(Stepped * Multiplier) / Multiplier
    end
    return Stepped
end

local OverlayService = {}
OverlayService.__index = OverlayService

function OverlayService.New(ScreenGuiInstance: ScreenGui)
    local Self = setmetatable({
        ScreenGui = ScreenGuiInstance,
        ActivePopup = nil,
        ActiveControl = nil,
        ActiveCloseCallback = nil,
        MatchControlWidth = false,
        PositionConnection = nil,
        Maid = Maid.New(),
    }, OverlayService)

    Self.OverlayLayer = Utility.Create("Frame", {
        Name = "OverlayLayer",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 1,
        ZIndex = 500,
        Parent = ScreenGuiInstance,
    })

    Self.Maid:GiveTask(UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        if not Self.ActivePopup then
            return
        end

        if Input.KeyCode == Enum.KeyCode.Escape then
            Self:ClosePopup()
            return
        end

        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            local MousePos = Vector2.new(Input.Position.X, Input.Position.Y)
            local PopupPos = Self.ActivePopup.AbsolutePosition
            local PopupSize = Self.ActivePopup.AbsoluteSize

            local InsidePopup = (MousePos.X >= PopupPos.X and MousePos.X <= PopupPos.X + PopupSize.X and MousePos.Y >= PopupPos.Y and MousePos.Y <= PopupPos.Y + PopupSize.Y)
            local InsideControl = false
            if Self.ActiveControl and Self.ActiveControl.Parent then
                local ControlPos = Self.ActiveControl.AbsolutePosition
                local ControlSize = Self.ActiveControl.AbsoluteSize
                InsideControl = (MousePos.X >= ControlPos.X and MousePos.X <= ControlPos.X + ControlSize.X and MousePos.Y >= ControlPos.Y and MousePos.Y <= ControlPos.Y + ControlSize.Y)
            end

            if not InsidePopup and not InsideControl then
                Self:ClosePopup()
            end
        end
    end))

    return Self
end

function OverlayService:MountPopup(PopupInstance: GuiObject, SourceControl: GuiObject, CloseCallback: (() -> ())?, MatchControlWidth: boolean?)
    if self.ActivePopup then
        self:ClosePopup()
    end

    self.ActivePopup = PopupInstance
    self.ActiveControl = SourceControl
    self.ActiveCloseCallback = CloseCallback
    self.MatchControlWidth = (MatchControlWidth == true)

    PopupInstance.ZIndex = 500
    PopupInstance.Active = true
    PopupInstance.BackgroundTransparency = 0

    local function UpdatePosition()
        if not self.ActivePopup or not self.ActiveControl or not self.ActiveControl.Parent then
            self:ClosePopup()
            return
        end

        local ControlPos = self.ActiveControl.AbsolutePosition
        local ControlSize = self.ActiveControl.AbsoluteSize
        local LayerPos = self.OverlayLayer.AbsolutePosition
        local ViewportSize = self.ScreenGui.AbsoluteSize
        local PopupSize = self.ActivePopup.AbsoluteSize

        local ScrollAncestor = self.ActiveControl:FindFirstAncestorWhichIsA("ScrollingFrame")
        if ScrollAncestor then
            local ScrollTop = ScrollAncestor.AbsolutePosition.Y
            local ScrollBottom = ScrollTop + ScrollAncestor.AbsoluteSize.Y
            if ControlPos.Y + ControlSize.Y <= ScrollTop or ControlPos.Y >= ScrollBottom then
                self:ClosePopup()
                return
            end
        else
            local WindowAncestor = self.ActiveControl:FindFirstAncestor("WindowFrame")
            if WindowAncestor then
                local WinTop = WindowAncestor.AbsolutePosition.Y + 42
                local WinBottom = WindowAncestor.AbsolutePosition.Y + WindowAncestor.AbsoluteSize.Y
                if ControlPos.Y + ControlSize.Y <= WinTop or ControlPos.Y >= WinBottom then
                    self:ClosePopup()
                    return
                end
            end
        end

        if self.MatchControlWidth then
            local TargetW = ControlSize.X
            if self.ActivePopup.Size.X.Offset ~= TargetW then
                self.ActivePopup.Size = UDim2.fromOffset(TargetW, PopupSize.Y)
                PopupSize = self.ActivePopup.AbsoluteSize
            end
            local TargetX = ControlPos.X - LayerPos.X
            local TargetY = ControlPos.Y + ControlSize.Y + 2 - LayerPos.Y
            self.ActivePopup.Position = UDim2.fromOffset(TargetX, TargetY)
        else
            local TargetX = (ControlPos.X + ControlSize.X - PopupSize.X) - LayerPos.X
            if TargetX < 10 then
                TargetX = math.max(10, ControlPos.X - LayerPos.X)
            end
            local TargetY = (ControlPos.Y + ControlSize.Y + 4) - LayerPos.Y
            if TargetY + PopupSize.Y > ViewportSize.Y - 10 then
                TargetY = math.max(10, (ControlPos.Y - PopupSize.Y - 4) - LayerPos.Y)
            end
            self.ActivePopup.Position = UDim2.fromOffset(TargetX, TargetY)
        end
    end

    UpdatePosition()
    PopupInstance.Parent = self.OverlayLayer

    self.PositionConnection = RunService.RenderStepped:Connect(function()
        if not self.ActivePopup or not self.ActiveControl or not self.ActiveControl.Parent then
            self:ClosePopup()
            return
        end
        UpdatePosition()
    end)
end

function OverlayService:ClosePopup()
    if self.PositionConnection then
        self.PositionConnection:Disconnect()
        self.PositionConnection = nil
    end

    if not self.ActivePopup then
        return
    end

    local Callback = self.ActiveCloseCallback
    local Popup = self.ActivePopup

    self.ActivePopup = nil
    self.ActiveControl = nil
    self.ActiveCloseCallback = nil
    self.MatchControlWidth = false

    if Popup and Popup.Parent then
        Popup:Destroy()
    end

    if Callback then
        Callback()
    end
end

function OverlayService:IsPointerOverPopup(Position: Vector2 | Vector3): boolean
    if not self.ActivePopup or not self.ActivePopup.Parent then
        return false
    end
    local X = Position.X
    local Y = Position.Y
    local PopupPos = self.ActivePopup.AbsolutePosition
    local PopupSize = self.ActivePopup.AbsoluteSize
    return X >= PopupPos.X and X <= (PopupPos.X + PopupSize.X)
        and Y >= PopupPos.Y and Y <= (PopupPos.Y + PopupSize.Y)
end

function OverlayService:Destroy()
    self:ClosePopup()
    self.Maid:Cleanup()
    if self.OverlayLayer then
        self.OverlayLayer:Destroy()
    end
end

local function ShowColorpickerPopup(AnchorButton: GuiObject, StartColor: Color3, OnColorChanged: (Color3) -> (), Overlay: any)
    local InitialColor = StartColor
    local CurrentColor = StartColor
    local CurrentH, CurrentS, CurrentV = Color3.toHSV(CurrentColor)
    local PopupW = 280
    local PopupH = 210

    local Popup = Utility.Create("TextButton", {
        Name = "ColorpickerPopup",
        Size = UDim2.fromOffset(PopupW, PopupH),
        BackgroundColor3 = Tokens.Colors.PopupBackground,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Active = true,
        ZIndex = 500,
    }, {
        Utility.CreateCorner(Tokens.Radius.Card),
        Utility.CreateStroke(Tokens.Colors.PopupBorder, 1, 0.6),
        Utility.CreatePadding(10, 10, 10, 10),
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local TopContainer = Utility.Create("Frame", {
        Name = "TopContainer",
        Size = UDim2.new(1, 0, 0, 150),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = Popup,
    }, {
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })

    local SVBox = Utility.Create("TextButton", {
        Name = "SVBox",
        Size = UDim2.fromOffset(150, 150),
        BackgroundColor3 = Color3.fromHSV(CurrentH, 1, 1),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ClipsDescendants = true,
        LayoutOrder = 1,
        Parent = TopContainer,
    }, {
        Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.5),
    })

    local SatGrad = Utility.Create("Frame", {
        Name = "SatGrad",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = SVBox,
    }, {
        Utility.Create("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Rotation = 0,
        }),
    })

    local ValGrad = Utility.Create("Frame", {
        Name = "ValGrad",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Parent = SVBox,
    }, {
        Utility.Create("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
            Rotation = 90,
        }),
    })

    local SVMarker = Utility.Create("Frame", {
        Name = "SVMarker",
        Size = UDim2.fromOffset(12, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(CurrentS, 1 - CurrentV),
        BackgroundColor3 = CurrentColor,
        BorderSizePixel = 0,
        Parent = SVBox,
    }, {
        Utility.CreateCorner(Tokens.Radius.Pill),
        Utility.CreateStroke(Color3.new(1, 1, 1), 1.5, 0),
    })

    local HueTrack = Utility.Create("TextButton", {
        Name = "HueTrack",
        Size = UDim2.fromOffset(16, 150),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = 2,
        Parent = TopContainer,
    }, {
        Utility.CreateCorner(Tokens.Radius.Small),
        Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.5),
        Utility.Create("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            }),
        }),
    })

    local HueMarker = Utility.Create("Frame", {
        Name = "HueMarker",
        Size = UDim2.fromOffset(14, 14),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, CurrentH, 0),
        BackgroundColor3 = Color3.fromHSV(CurrentH, 1, 1),
        BorderSizePixel = 0,
        Parent = HueTrack,
    }, {
        Utility.CreateCorner(Tokens.Radius.Pill),
        Utility.CreateStroke(Color3.new(1, 1, 1), 1.5, 0),
    })

    local InputsColumn = Utility.Create("Frame", {
        Name = "InputsColumn",
        Size = UDim2.new(1, -(150 + 16 + 20), 0, 150),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Parent = TopContainer,
    }, {
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local function CreateInputRow(RowName: string, PrefixText: string, InitialVal: string, Order: number)
        local FieldFrame = Utility.Create("Frame", {
            Name = RowName .. "_Field",
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Tokens.Colors.InputBackground,
            BorderSizePixel = 0,
            LayoutOrder = Order,
            Parent = InputsColumn,
        }, {
            Utility.CreateCorner(Tokens.Radius.Small),
            Utility.CreateStroke(Tokens.Colors.InputBorder, 1, 0.5),
        })

        local PrefixLabel = Utility.Create("TextLabel", {
            Name = "Prefix",
            Size = UDim2.new(0, 24, 1, 0),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = PrefixText,
            TextColor3 = Tokens.Colors.TextMuted,
            TextSize = 10,
            Parent = FieldFrame,
        })

        local Box = Utility.Create("TextBox", {
            Name = "Input",
            Size = UDim2.new(1, -28, 1, 0),
            Position = UDim2.new(0, 26, 0, 0),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontRegular,
            Text = InitialVal,
            TextColor3 = Tokens.Colors.TextPrimary,
            TextSize = 10,
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = FieldFrame,
        })

        return Box
    end

    local HexBox = CreateInputRow("Hex", "HEX", "#" .. CurrentColor:ToHex(), 1)
    local RBox = CreateInputRow("R", "R", tostring(math.round(CurrentColor.R * 255)), 2)
    local GBox = CreateInputRow("G", "G", tostring(math.round(CurrentColor.G * 255)), 3)
    local BBox = CreateInputRow("B", "B", tostring(math.round(CurrentColor.B * 255)), 4)

    local BottomContainer = Utility.Create("Frame", {
        Name = "BottomContainer",
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        Parent = Popup,
    }, {
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })

    local ComparisonFrame = Utility.Create("Frame", {
        Name = "Comparison",
        Size = UDim2.fromOffset(54, 26),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Parent = BottomContainer,
    }, {
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })

    local OldColorBox = Utility.Create("TextButton", {
        Name = "OldColor",
        Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = InitialColor,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = 1,
        Parent = ComparisonFrame,
    }, {
        Utility.CreateCorner(Tokens.Radius.Small),
        Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.5),
    })

    local NewColorBox = Utility.Create("Frame", {
        Name = "NewColor",
        Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = CurrentColor,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        Parent = ComparisonFrame,
    }, {
        Utility.CreateCorner(Tokens.Radius.Small),
        Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.5),
    })

    local ResetBtn = Utility.Create("TextButton", {
        Name = "ResetButton",
        Size = UDim2.new(0.5, -35, 1, 0),
        BackgroundColor3 = Tokens.Colors.Elevated,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "Reset",
        TextColor3 = Tokens.Colors.TextSecondary,
        Font = Tokens.Typography.FontMedium,
        TextSize = 11,
        LayoutOrder = 2,
        Parent = BottomContainer,
    }, {
        Utility.CreateCorner(Tokens.Radius.Small),
        Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.5),
    })

    ResetBtn.MouseEnter:Connect(function()
        Utility.Tween(ResetBtn, { BackgroundColor3 = Tokens.Colors.ElevatedHover }, 0.1)
    end)
    ResetBtn.MouseLeave:Connect(function()
        Utility.Tween(ResetBtn, { BackgroundColor3 = Tokens.Colors.Elevated }, 0.1)
    end)

    local ApplyBtn = Utility.Create("TextButton", {
        Name = "ApplyButton",
        Size = UDim2.new(0.5, -35, 1, 0),
        BackgroundColor3 = Tokens.Colors.Accent,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "Apply",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Tokens.Typography.FontMedium,
        TextSize = 11,
        LayoutOrder = 3,
        Parent = BottomContainer,
    }, {
        Utility.CreateCorner(Tokens.Radius.Small),
    })

    ApplyBtn.MouseEnter:Connect(function()
        Utility.Tween(ApplyBtn, { BackgroundColor3 = Tokens.Colors.AccentHover }, 0.1)
    end)
    ApplyBtn.MouseLeave:Connect(function()
        Utility.Tween(ApplyBtn, { BackgroundColor3 = Tokens.Colors.Accent }, 0.1)
    end)
    Utility.RegisterAccent(ApplyBtn, "BackgroundColor3")

    local function RecalculateColor(SkipInputs: boolean?)
        CurrentColor = Color3.fromHSV(CurrentH, CurrentS, CurrentV)
        SVBox.BackgroundColor3 = Color3.fromHSV(CurrentH, 1, 1)
        SVMarker.Position = UDim2.fromScale(CurrentS, 1 - CurrentV)
        SVMarker.BackgroundColor3 = CurrentColor
        HueMarker.Position = UDim2.new(0.5, 0, CurrentH, 0)
        HueMarker.BackgroundColor3 = Color3.fromHSV(CurrentH, 1, 1)
        NewColorBox.BackgroundColor3 = CurrentColor

        if not SkipInputs then
            HexBox.Text = "#" .. CurrentColor:ToHex()
            RBox.Text = tostring(math.round(CurrentColor.R * 255))
            GBox.Text = tostring(math.round(CurrentColor.G * 255))
            BBox.Text = tostring(math.round(CurrentColor.B * 255))
        end

        AnchorButton.BackgroundColor3 = CurrentColor
        OnColorChanged(CurrentColor)
    end

    OldColorBox.MouseButton1Click:Connect(function()
        CurrentColor = InitialColor
        CurrentH, CurrentS, CurrentV = Color3.toHSV(CurrentColor)
        RecalculateColor()
    end)

    ResetBtn.MouseButton1Click:Connect(function()
        CurrentColor = InitialColor
        CurrentH, CurrentS, CurrentV = Color3.toHSV(CurrentColor)
        RecalculateColor()
    end)

    local HasApplied = false

    ApplyBtn.MouseButton1Click:Connect(function()
        HasApplied = true
        InitialColor = CurrentColor
        AnchorButton.BackgroundColor3 = CurrentColor
        OnColorChanged(CurrentColor)
        Overlay:ClosePopup()
    end)

    local DraggingSV = false
    local DraggingHue = false

    local function UpdateSV(InputPos: Vector3)
        local BoxPos = SVBox.AbsolutePosition
        local BoxSize = SVBox.AbsoluteSize
        CurrentS = math.clamp((InputPos.X - BoxPos.X) / BoxSize.X, 0, 1)
        CurrentV = 1 - math.clamp((InputPos.Y - BoxPos.Y) / BoxSize.Y, 0, 1)
        RecalculateColor()
    end

    local function UpdateHue(InputPos: Vector3)
        local TrackPos = HueTrack.AbsolutePosition
        local TrackSize = HueTrack.AbsoluteSize
        CurrentH = math.clamp((InputPos.Y - TrackPos.Y) / TrackSize.Y, 0, 1)
        RecalculateColor()
    end

    SVBox.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            DraggingSV = true
            UpdateSV(Input.Position)
        end
    end)

    HueTrack.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            DraggingHue = true
            UpdateHue(Input.Position)
        end
    end)

    local InputChangedConn = UserInputService.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            if DraggingSV then
                UpdateSV(Input.Position)
            elseif DraggingHue then
                UpdateHue(Input.Position)
            end
        end
    end)

    local InputEndedConn = UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            DraggingSV = false
            DraggingHue = false
        end
    end)

    HexBox.FocusLost:Connect(function()
        local CleanHex = HexBox.Text:gsub("#", ""):gsub("%s+", ""):upper()
        if #CleanHex == 6 then
            local Success, ParsedColor = pcall(function()
                return Color3.fromHex(CleanHex)
            end)
            if Success and ParsedColor then
                CurrentColor = ParsedColor
                CurrentH, CurrentS, CurrentV = Color3.toHSV(CurrentColor)
                RecalculateColor(true)
                RBox.Text = tostring(math.round(CurrentColor.R * 255))
                GBox.Text = tostring(math.round(CurrentColor.G * 255))
                BBox.Text = tostring(math.round(CurrentColor.B * 255))
                return
            end
        end
        HexBox.Text = "#" .. CurrentColor:ToHex()
    end)

    local function OnRgbFocusLost()
        local RNum = math.clamp(tonumber(RBox.Text) or math.round(CurrentColor.R * 255), 0, 255)
        local GNum = math.clamp(tonumber(GBox.Text) or math.round(CurrentColor.G * 255), 0, 255)
        local BNum = math.clamp(tonumber(BBox.Text) or math.round(CurrentColor.B * 255), 0, 255)
        CurrentColor = Color3.fromRGB(RNum, GNum, BNum)
        CurrentH, CurrentS, CurrentV = Color3.toHSV(CurrentColor)
        RecalculateColor(true)
        HexBox.Text = "#" .. CurrentColor:ToHex()
        RBox.Text = tostring(RNum)
        GBox.Text = tostring(GNum)
        BBox.Text = tostring(BNum)
    end

    RBox.FocusLost:Connect(OnRgbFocusLost)
    GBox.FocusLost:Connect(OnRgbFocusLost)
    BBox.FocusLost:Connect(OnRgbFocusLost)

    Overlay:MountPopup(Popup, AnchorButton, function()
        InputChangedConn:Disconnect()
        InputEndedConn:Disconnect()
        if not HasApplied and CurrentColor ~= InitialColor then
            CurrentColor = InitialColor
            CurrentH, CurrentS, CurrentV = Color3.toHSV(CurrentColor)
            AnchorButton.BackgroundColor3 = InitialColor
            OnColorChanged(InitialColor)
        end
    end, false)
end

local function AttachControlMethods(TargetFrame: Instance, TargetMaid: any, Overlay: any)
    local ControlHolder = {}

    function ControlHolder:AddColumns(ColumnCountNumber: number?, SpacingNumber: number?)
        local ColMaid = Maid.New()
        TargetMaid:GiveTask(ColMaid)
        local Columns = ColumnCountNumber or 2
        local Spacing = SpacingNumber or 8

        local RowFrame = Utility.Create("Frame", {
            Name = "ColumnRow",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = TargetFrame,
        }, {
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, Spacing),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Top,
            }),
        })
        ColMaid:GiveTask(RowFrame)

        local ColumnWidthScale = 1 / Columns
        local ColumnWidthOffset = -math.round(((Columns - 1) * Spacing) / Columns)

        local ColumnObjects = {}

        for Index = 1, Columns do
            local ColFrame = Utility.Create("Frame", {
                Name = "Column_" .. tostring(Index),
                Size = UDim2.new(ColumnWidthScale, ColumnWidthOffset, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = Index,
                Parent = RowFrame,
            }, {
                Utility.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    Padding = UDim.new(0, Spacing),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            })

            local ColControlMethods = AttachControlMethods(ColFrame, ColMaid, Overlay)
            ColControlMethods.Frame = ColFrame
            ColControlMethods.Maid = ColMaid
            table.insert(ColumnObjects, ColControlMethods)
        end

        return unpack(ColumnObjects)
    end

    ControlHolder.AddRow = ControlHolder.AddColumns

    function ControlHolder:AddButton(BtnConfig: { [string]: any })
        local BtnMaid = Maid.New()
        TargetMaid:GiveTask(BtnMaid)
        local Title = BtnConfig.Name or BtnConfig.Title or "Button"
        local Callback = BtnConfig.Callback or function() end
        local BtnHeight = BtnConfig.Height or 28
        local BtnBg = BtnConfig.BackgroundColor or BtnConfig.BackgroundColor3 or Tokens.Colors.Elevated
        local BtnBorder = BtnConfig.BorderColor or BtnConfig.BorderColor3 or Tokens.Colors.BorderSubtle
        local BtnTextCol = BtnConfig.CustomColor or BtnConfig.TextColor or Tokens.Colors.TextPrimary
        local BtnRadius = if BtnConfig.Radius then (if typeof(BtnConfig.Radius) == "number" then UDim.new(0, BtnConfig.Radius) else BtnConfig.Radius) else Tokens.Radius.Control

        local Button = Utility.Create("TextButton", {
            Name = Title .. "_Button",
            Size = UDim2.new(1, 0, 0, BtnHeight),
            BackgroundColor3 = BtnBg,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Parent = TargetFrame,
        }, {
            Utility.CreateCorner(BtnRadius),
            Utility.CreateStroke(BtnBorder, 1, 0.5),
        })
        BtnMaid:GiveTask(Button)

        local Label = Utility.Create("TextLabel", {
            Name = "Label",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = Title,
            TextColor3 = BtnTextCol,
            TextSize = Tokens.Typography.ControlLabel,
            Parent = Button,
        })

        Button.MouseEnter:Connect(function()
            Utility.Tween(Button, { BackgroundColor3 = Tokens.Colors.ElevatedHover }, 0.12)
        end)

        Button.MouseLeave:Connect(function()
            Utility.Tween(Button, { BackgroundColor3 = BtnBg }, 0.12)
        end)

        Button.MouseButton1Down:Connect(function()
            Utility.Tween(Button, { BackgroundColor3 = Tokens.Colors.WindowBackground }, 0.08)
        end)

        Button.MouseButton1Up:Connect(function()
            Utility.Tween(Button, { BackgroundColor3 = Tokens.Colors.ElevatedHover }, 0.08)
        end)

        Button.MouseButton1Click:Connect(function()
            if Overlay and Overlay:IsPointerOverPopup(UserInputService:GetMouseLocation()) then
                return
            end
            Callback()
        end)

        local ButtonObject = {
            Frame = Button,
            Maid = BtnMaid,
        }

        function ButtonObject:SetTitle(NewTitle: string)
            Label.Text = NewTitle
        end

        function ButtonObject:SetVisible(Visible: boolean)
            Button.Visible = Visible
        end

        function ButtonObject:SetColor(NewColor: Color3)
            Label.TextColor3 = NewColor
        end

        return ButtonObject
    end

    function ControlHolder:AddToggle(ToggleConfig: { [string]: any })
        local ToggleMaid = Maid.New()
        TargetMaid:GiveTask(ToggleMaid)
        local Title = ToggleConfig.Name or ToggleConfig.Title or "Toggle"
        local CurrentValue = if ToggleConfig.Default ~= nil then ToggleConfig.Default else false
        local Callback = ToggleConfig.Callback or function(_) end
        local SubGroupWatchers = {}

        local ActiveColor = ToggleConfig.CustomColor or Tokens.Colors.ToggleActive
        local InactiveColor = ToggleConfig.InactiveColor or Tokens.Colors.ToggleInactive
        local KnobActiveColor = ToggleConfig.KnobColor or Tokens.Colors.ToggleKnob
        local KnobInactiveColor = Tokens.Colors.ToggleKnobOff

        local RowHeight = ToggleConfig.Height or 28
        local Row = Utility.Create("Frame", {
            Name = Title .. "_ToggleRow",
            Size = UDim2.new(1, 0, 0, RowHeight),
            BackgroundTransparency = 1,
            Parent = TargetFrame,
        })
        ToggleMaid:GiveTask(Row)

        local RightSideWidth = 44
        if ToggleConfig.Keybind ~= nil then
            RightSideWidth += 62
        end
        if ToggleConfig.Color ~= nil or ToggleConfig.Colorpicker ~= nil then
            RightSideWidth += 26
        end

        local TitleLabel = Utility.Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -RightSideWidth - 8, 1, 0),
            Position = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = Title,
            TextColor3 = Tokens.Colors.TextPrimary,
            TextSize = Tokens.Typography.ControlLabel,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = Row,
        })

        local RightContainer = Utility.Create("Frame", {
            Name = "RightControls",
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundTransparency = 1,
            Parent = Row,
        }, {
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })

        local function UpdateToggleTitleBounds()
            local RightW = math.max(44, RightContainer.AbsoluteSize.X)
            TitleLabel.Size = UDim2.new(1, -(RightW + 8), 1, 0)
        end
        RightContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateToggleTitleBounds)
        task.defer(UpdateToggleTitleBounds)

        local SwitchRadius = if ToggleConfig.Radius then (if typeof(ToggleConfig.Radius) == "number" then UDim.new(0, ToggleConfig.Radius) else ToggleConfig.Radius) else Tokens.Radius.Pill
        local Switch = Utility.Create("TextButton", {
            Name = "Switch",
            Size = UDim2.fromOffset(38, 20),
            BackgroundColor3 = if CurrentValue then ActiveColor else InactiveColor,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = 10,
            Parent = RightContainer,
        }, {
            Utility.CreateCorner(SwitchRadius),
            Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.5),
        })

        if not ToggleConfig.CustomColor then
            ToggleMaid:GiveTask(Library.OnAccentChanged:Connect(function(NewAccent)
                ActiveColor = NewAccent
                if CurrentValue then
                    Switch.BackgroundColor3 = NewAccent
                end
            end))
        end

        local Knob = Utility.Create("Frame", {
            Name = "Knob",
            Size = UDim2.fromOffset(14, 14),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = if CurrentValue then UDim2.new(1, -17, 0.5, 0) else UDim2.new(0, 3, 0.5, 0),
            BackgroundColor3 = if CurrentValue then KnobActiveColor else KnobInactiveColor,
            BorderSizePixel = 0,
            Parent = Switch,
        }, {
            Utility.CreateCorner(Tokens.Radius.Pill),
        })

        local function UpdateState(NewState: boolean)
            CurrentValue = NewState
            local TargetSwitchColor = if CurrentValue then ActiveColor else InactiveColor
            local TargetKnobColor = if CurrentValue then KnobActiveColor else KnobInactiveColor
            local TargetKnobPos = if CurrentValue then UDim2.new(1, -17, 0.5, 0) else UDim2.new(0, 3, 0.5, 0)

            Utility.Tween(Switch, { BackgroundColor3 = TargetSwitchColor }, 0.14)
            Utility.Tween(Knob, { BackgroundColor3 = TargetKnobColor, Position = TargetKnobPos }, 0.14)

            for _, Watcher in ipairs(SubGroupWatchers) do
                Watcher(CurrentValue)
            end

            Callback(CurrentValue)
        end

        local CurrentBoundKey = if typeof(ToggleConfig.Keybind) == "EnumItem" then ToggleConfig.Keybind else Enum.KeyCode.None
        local KeyButton = nil
        local KeyText = nil
        local Unbindable = (ToggleConfig.Unbindable == true)
        local GuiService = game:GetService("GuiService")
        local ToggleMenuConn = nil

        local function SetupKeybind(InitialKey: any)
            CurrentBoundKey = if typeof(InitialKey) == "EnumItem" then InitialKey else Enum.KeyCode.None
            local IsListening = false

            KeyButton = Utility.Create("TextButton", {
                Name = "InlineKeybind",
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.new(0, 0, 0, 20),
                BackgroundColor3 = Tokens.Colors.Elevated,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Font = Tokens.Typography.FontMedium,
                Text = if CurrentBoundKey ~= Enum.KeyCode.None then "[" .. CurrentBoundKey.Name .. "]" else "[None]",
                TextColor3 = Tokens.Colors.TextSecondary,
                TextSize = Tokens.Typography.BadgeText,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                LayoutOrder = 1,
                Parent = RightContainer,
            }, {
                Utility.CreateCorner(Tokens.Radius.Small),
                Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.5),
                Utility.CreatePadding(2, 8, 2, 8),
                Utility.Create("UISizeConstraint", {
                    MinSize = Vector2.new(33, 20),
                }),
            })

            KeyText = KeyButton

            local ActionName = "SuppressInlineEscape_" .. HttpService:GenerateGUID(false)
            local function StopListeningToggle(WasEscape: boolean)
                IsListening = false
                pcall(function()
                    ContextActionService:UnbindAction(ActionName)
                end)
                if WasEscape then
                    pcall(function()
                        GuiService:SetMenuIsOpen(false, "SettingsHub")
                    end)
                    local SuppressEnd = tick() + 0.5
                    local SuppressConn
                    SuppressConn = RunService.RenderStepped:Connect(function()
                        if GuiService.MenuIsOpen then
                            pcall(function()
                                GuiService:SetMenuIsOpen(false, "SettingsHub")
                            end)
                        end
                        if tick() > SuppressEnd then
                            SuppressConn:Disconnect()
                        end
                    end)
                end
                if ToggleMenuConn then
                    ToggleMenuConn:Disconnect()
                    ToggleMenuConn = nil
                end
            end

            KeyButton.MouseButton1Click:Connect(function()
                if Overlay and Overlay:IsPointerOverPopup(UserInputService:GetMouseLocation()) then
                    return
                end
                if IsListening then
                    return
                end
                IsListening = true
                KeyText.Text = "[...]"
                KeyText.TextColor3 = Tokens.Colors.Accent

                pcall(function()
                    ContextActionService:BindActionAtPriority(ActionName, function(_, _, input)
                        if input.KeyCode == Enum.KeyCode.Escape then
                            return Enum.ContextActionResult.Sink
                        end
                        return Enum.ContextActionResult.Pass
                    end, false, 10000, Enum.KeyCode.Escape)
                end)

                if ToggleMenuConn then
                    ToggleMenuConn:Disconnect()
                end
                ToggleMenuConn = GuiService:GetPropertyChangedSignal("MenuIsOpen"):Connect(function()
                    if GuiService.MenuIsOpen then
                        pcall(function()
                            GuiService:SetMenuIsOpen(false, "SettingsHub")
                        end)
                    end
                end)
            end)

            local JustBoundToggleAt = 0

            ToggleMaid:GiveTask(UserInputService.InputBegan:Connect(function(Input, GameProcessed)
                if IsListening then
                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode == Enum.KeyCode.Escape then
                            StopListeningToggle(true)
                            if Unbindable then
                                CurrentBoundKey = Enum.KeyCode.None
                                KeyText.Text = "[None]"
                                KeyText.TextColor3 = Tokens.Colors.TextSecondary
                                if ToggleConfig.KeybindCallback then
                                    ToggleConfig.KeybindCallback(Enum.KeyCode.None)
                                end
                            else
                                KeyText.Text = if CurrentBoundKey ~= Enum.KeyCode.None then "[" .. CurrentBoundKey.Name .. "]" else "[None]"
                                KeyText.TextColor3 = Tokens.Colors.TextSecondary
                            end
                            return
                        end

                        if GameProcessed then
                            return
                        end

                        JustBoundToggleAt = os.clock()
                        StopListeningToggle(false)
                        CurrentBoundKey = Input.KeyCode
                        KeyText.Text = "[" .. CurrentBoundKey.Name .. "]"
                        KeyText.TextColor3 = Tokens.Colors.TextSecondary
                        if ToggleConfig.KeybindCallback then
                            ToggleConfig.KeybindCallback(CurrentBoundKey)
                        end
                    end
                    return
                end

                if GameProcessed then
                    return
                end

                if os.clock() - JustBoundToggleAt < 0.25 then
                    return
                end

                if CurrentBoundKey ~= Enum.KeyCode.None and Input.KeyCode == CurrentBoundKey then
                    UpdateState(not CurrentValue)
                end
            end))
        end

        local ColorCfg = ToggleConfig.Colorpicker or ToggleConfig.Color
        local InlineColorButton = nil
        local CurrentInlineColor: Color3? = nil
        local InlineColorCallback = nil

        if ColorCfg ~= nil then
            local StartColor = Color3.new(1, 1, 1)
            if typeof(ColorCfg) == "Color3" then
                StartColor = ColorCfg
                InlineColorCallback = ToggleConfig.ColorCallback or function(_) end
            elseif typeof(ColorCfg) == "table" then
                StartColor = ColorCfg.Default or ColorCfg.Color or Tokens.Colors.Accent
                InlineColorCallback = ColorCfg.Callback or function(_) end
            end
            CurrentInlineColor = StartColor

            InlineColorButton = Utility.Create("TextButton", {
                Name = "InlineColorSwatch",
                Size = UDim2.fromOffset(20, 20),
                BackgroundColor3 = StartColor,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = 5,
                Parent = RightContainer,
            }, {
                Utility.CreateCorner(Tokens.Radius.Small),
                Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.5),
            })

            InlineColorButton.MouseButton1Click:Connect(function()
                if Overlay and Overlay:IsPointerOverPopup(UserInputService:GetMouseLocation()) then
                    return
                end
                ShowColorpickerPopup(InlineColorButton, CurrentInlineColor or StartColor, function(NewColor)
                    CurrentInlineColor = NewColor
                    InlineColorButton.BackgroundColor3 = NewColor
                    if InlineColorCallback then
                        InlineColorCallback(NewColor)
                    end
                end, Overlay)
            end)
        end

        if ToggleConfig.Keybind ~= nil then
            SetupKeybind(ToggleConfig.Keybind)
        end

        Switch.MouseButton1Click:Connect(function()
            if Overlay and Overlay:IsPointerOverPopup(UserInputService:GetMouseLocation()) then
                return
            end
            UpdateState(not CurrentValue)
        end)

        local ToggleObject = {
            Frame = Row,
            Switch = Switch,
            Maid = ToggleMaid,
        }

        function ToggleObject:SetValue(NewState: boolean)
            UpdateState(NewState)
        end

        function ToggleObject:GetValue(): boolean
            return CurrentValue
        end

        function ToggleObject:SetVisible(Visible: boolean)
            Row.Visible = Visible
            for _, Watcher in ipairs(SubGroupWatchers) do
                Watcher(if Visible then CurrentValue else false)
            end
        end

        function ToggleObject:SetKeybind(NewKey: Enum.KeyCode)
            if not KeyButton then
                SetupKeybind(NewKey)
            else
                CurrentBoundKey = NewKey
                KeyText.Text = if CurrentBoundKey ~= Enum.KeyCode.None then "[" .. CurrentBoundKey.Name .. "]" else "[None]"
            end
        end

        function ToggleObject:GetKeybind(): Enum.KeyCode?
            return CurrentBoundKey
        end

        function ToggleObject:SetColor(NewColor: Color3)
            if InlineColorButton then
                CurrentInlineColor = NewColor
                InlineColorButton.BackgroundColor3 = NewColor
                if InlineColorCallback then
                    InlineColorCallback(NewColor)
                end
            end
        end

        function ToggleObject:GetColor(): Color3?
            return CurrentInlineColor
        end

        function ToggleObject:SetColorVisible(Visible: boolean)
            if InlineColorButton then
                InlineColorButton.Visible = Visible
            end
        end

        function ToggleObject:SetSwitchVisible(Visible: boolean)
            Switch.Visible = Visible
        end

        function ToggleObject:SetToggleVisible(Visible: boolean)
            Switch.Visible = Visible
        end

        function ToggleObject:AddSubGroup(SubGroupConfigOrBuilder: any, BuilderCallback: ((any) -> ())?)
            local SubConfig = SubGroupConfigOrBuilder
            if typeof(SubGroupConfigOrBuilder) == "function" and not BuilderCallback then
                BuilderCallback = SubGroupConfigOrBuilder
                SubConfig = {}
            elseif SubConfig == nil then
                SubConfig = {}
            end
            if typeof(SubConfig.Builder) == "function" and not BuilderCallback then
                BuilderCallback = SubConfig.Builder
            end

            local SubMaid = Maid.New()
            ToggleMaid:GiveTask(SubMaid)

            local SubFrame = Utility.Create("Frame", {
                Name = Title .. "_SubGroup",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Visible = CurrentValue,
                Parent = TargetFrame,
            }, {
                Utility.CreatePadding(0, 4, 12, 0),
                Utility.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    Padding = UDim.new(0, 6),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            })
            SubMaid:GiveTask(SubFrame)

            local SubControls = AttachControlMethods(SubFrame, SubMaid, Overlay)
            SubControls.Frame = SubFrame
            SubControls.Maid = SubMaid

            function SubControls:SetVisible(Visible: boolean)
                SubFrame.Visible = Visible
            end

            table.insert(SubGroupWatchers, function(State)
                SubFrame.Visible = State
            end)

            if BuilderCallback and typeof(BuilderCallback) == "function" then
                BuilderCallback(SubControls)
            elseif typeof(BuilderCallback) == "table" and (SubControls :: any).Build then
                (SubControls :: any):Build(BuilderCallback)
            end

            return SubControls
        end

        return ToggleObject
    end

    function ControlHolder:AddSwitcher(SwitcherConfig: { [string]: any })
        local SwitcherMaid = Maid.New()
        TargetMaid:GiveTask(SwitcherMaid)
        local Title = SwitcherConfig.Name or SwitcherConfig.Title or "Mode"
        local Options = SwitcherConfig.Options or { "Option A", "Option B" }
        local CurrentValue = SwitcherConfig.Default or Options[1]
        local Callback = SwitcherConfig.Callback or function(_) end

        local SwitcherHeight = SwitcherConfig.Height or 30
        local Container = Utility.Create("Frame", {
            Name = Title .. "_Switcher",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = TargetFrame,
        }, {
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        SwitcherMaid:GiveTask(Container)

        local TitleLabel = Utility.Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = Title,
            TextColor3 = Tokens.Colors.TextPrimary,
            TextSize = Tokens.Typography.ControlLabel,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Container,
        })

        local Track = Utility.Create("Frame", {
            Name = "Track",
            Size = UDim2.new(1, 0, 0, SwitcherHeight),
            BackgroundColor3 = Tokens.Colors.Elevated,
            BorderSizePixel = 0,
            Parent = Container,
        }, {
            Utility.CreateCorner(Tokens.Radius.Control),
            Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.5),
            Utility.CreatePadding(2, 2, 2, 2),
        })

        local OptionCount = #Options
        local OptionWidthScale = 1 / OptionCount

        local ActivePill = Utility.Create("Frame", {
            Name = "ActivePill",
            Size = UDim2.new(OptionWidthScale, 0, 1, 0),
            Position = UDim2.fromScale(0, 0),
            BackgroundColor3 = Tokens.Colors.TabActive,
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = Track,
        }, {
            Utility.CreateCorner(Tokens.Radius.Small),
            Utility.CreateStroke(Tokens.Colors.Border, 1, 0.4),
        })

        local OptionLabels = {}

        local function SelectOption(SelectedOpt: string, SkipCallback: boolean?)
            CurrentValue = SelectedOpt
            local TargetIndex = 1
            for Index, Opt in ipairs(Options) do
                if Opt == SelectedOpt then
                    TargetIndex = Index
                    break
                end
            end

            local TargetPos = UDim2.fromScale((TargetIndex - 1) * OptionWidthScale, 0)
            Utility.Tween(ActivePill, { Position = TargetPos }, 0.14)

            for Index, Opt in ipairs(Options) do
                local IsSelected = (Opt == SelectedOpt)
                local Label = OptionLabels[Index]
                if Label then
                    Utility.Tween(Label, {
                        TextColor3 = if IsSelected then Tokens.Colors.TextPrimary else Tokens.Colors.TextMuted
                    }, 0.12)
                end
            end

            if not SkipCallback then
                Callback(CurrentValue)
            end
        end

        for Index, Opt in ipairs(Options) do
            local OptBtn = Utility.Create("TextButton", {
                Name = "Option_" .. Opt,
                Size = UDim2.new(OptionWidthScale, 0, 1, 0),
                Position = UDim2.fromScale((Index - 1) * OptionWidthScale, 0),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 3,
                Parent = Track,
            })

            local Label = Utility.Create("TextLabel", {
                Name = "Label",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Font = Tokens.Typography.FontMedium,
                Text = Opt,
                TextColor3 = if Opt == CurrentValue then Tokens.Colors.TextPrimary else Tokens.Colors.TextMuted,
                TextSize = Tokens.Typography.ControlLabel,
                Parent = OptBtn,
            })

            OptBtn.MouseButton1Click:Connect(function()
                if Overlay and Overlay:IsPointerOverPopup(UserInputService:GetMouseLocation()) then
                    return
                end
                SelectOption(Opt)
            end)

            table.insert(OptionLabels, Label)
        end

        SelectOption(CurrentValue, true)

        local SwitcherObject = {
            Frame = Container,
            Maid = SwitcherMaid,
        }

        function SwitcherObject:SetValue(NewVal: string)
            SelectOption(NewVal)
        end

        function SwitcherObject:GetValue(): string
            return CurrentValue
        end

        function SwitcherObject:SetVisible(Visible: boolean)
            Container.Visible = Visible
        end

        function SwitcherObject:SetColor(NewColor: Color3)
            ActivePill.BackgroundColor3 = NewColor
        end

        return SwitcherObject
    end

    ControlHolder.AddSegmented = ControlHolder.AddSwitcher

    function ControlHolder:AddSlider(SliderConfig: { [string]: any })
        local SliderMaid = Maid.New()
        TargetMaid:GiveTask(SliderMaid)
        local Title = SliderConfig.Name or SliderConfig.Title or "Slider"
        local Min = SliderConfig.Min or 0
        local Max = SliderConfig.Max or 100
        local Step = SliderConfig.Step or 1
        local Prefix = SliderConfig.Prefix or ""
        local Suffix = SliderConfig.Suffix or ""
        local CustomColor = SliderConfig.CustomColor or SliderConfig.AccentColor or SliderConfig.Color
        local TrackColor = SliderConfig.TrackColor or Tokens.Colors.TrackBackground
        local ThumbColor = SliderConfig.ThumbColor or Tokens.Colors.TextPrimary
        local TrackHeight = SliderConfig.Height or 6
        local SliderRadius = if SliderConfig.Radius then (if typeof(SliderConfig.Radius) == "number" then UDim.new(0, SliderConfig.Radius) else SliderConfig.Radius) else Tokens.Radius.Pill
        local ShowValue = if SliderConfig.ShowValue ~= nil then SliderConfig.ShowValue else true
        local ValuePos = SliderConfig.ValuePosition or "Right"

        local CurrentValue = SliderConfig.Default or Min
        CurrentValue = Utility.Snap(CurrentValue, Min, Max, Step)
        local Callback = SliderConfig.Callback or function(_) end

        local Container = Utility.Create("Frame", {
            Name = Title .. "_Slider",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = TargetFrame,
        }, {
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        SliderMaid:GiveTask(Container)

        local TopRow = Utility.Create("Frame", {
            Name = "TopRow",
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Parent = Container,
        })

        local TitleLabel = Utility.Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -60, 1, 0),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = Title,
            TextColor3 = Tokens.Colors.TextPrimary,
            TextSize = Tokens.Typography.ControlLabel,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TopRow,
        })

        local ValueLabel = Utility.Create("TextLabel", {
            Name = "Value",
            Size = UDim2.new(0, 60, 1, 0),
            Position = UDim2.new(1, -60, 0, 0),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = Prefix .. tostring(CurrentValue) .. Suffix,
            TextColor3 = Tokens.Colors.TextMuted,
            TextSize = Tokens.Typography.ValueText,
            TextXAlignment = Enum.TextXAlignment.Right,
            Visible = ShowValue and (ValuePos == "Right"),
            Parent = TopRow,
        })

        local Track = Utility.Create("TextButton", {
            Name = "Track",
            Size = UDim2.new(1, 0, 0, TrackHeight),
            BackgroundColor3 = TrackColor,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Parent = Container,
        }, {
            Utility.CreateCorner(SliderRadius),
            Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.4),
        })

        local InitialFraction = math.clamp((CurrentValue - Min) / (Max - Min), 0, 1)
        local ThumbSize = TrackHeight + 4

        local function GetThumbPosition(Fraction: number): UDim2
            return UDim2.new(Fraction, math.round((0.5 - Fraction) * ThumbSize), 0.5, 0)
        end

        local function GetFillSize(Fraction: number): UDim2
            if Fraction <= 0 then
                return UDim2.new(0, 0, 1, 0)
            end
            local Offset = if Fraction >= 0.98 then 0 else math.round((0.5 - Fraction) * ThumbSize)
            return UDim2.new(Fraction, Offset, 1, 0)
        end

        local Fill = Utility.Create("Frame", {
            Name = "Fill",
            Size = GetFillSize(InitialFraction),
            BackgroundColor3 = CustomColor or Tokens.Colors.Accent,
            BorderSizePixel = 0,
            Visible = (InitialFraction > 0),
            Parent = Track,
        }, {
            Utility.CreateCorner(SliderRadius),
        })

        if not CustomColor then
            Utility.RegisterAccent(Fill, "BackgroundColor3")
        end

        local Thumb = Utility.Create("Frame", {
            Name = "Thumb",
            Size = UDim2.fromOffset(ThumbSize, ThumbSize),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = GetThumbPosition(InitialFraction),
            BackgroundColor3 = ThumbColor,
            BorderSizePixel = 0,
            Parent = Track,
        }, {
            Utility.CreateCorner(Tokens.Radius.Pill),
        })

        local Dragging = false

        local function UpdateValueFromInput(InputPosition: Vector3)
            local TrackPos = Track.AbsolutePosition
            local TrackSize = Track.AbsoluteSize
            local Fraction = math.clamp((InputPosition.X - TrackPos.X) / TrackSize.X, 0, 1)
            local RawValue = Min + Fraction * (Max - Min)
            CurrentValue = Utility.Snap(RawValue, Min, Max, Step)
            local CurrentFraction = math.clamp((CurrentValue - Min) / (Max - Min), 0, 1)

            ValueLabel.Text = Prefix .. tostring(CurrentValue) .. Suffix
            Fill.Visible = (CurrentFraction > 0)
            Fill.Size = GetFillSize(CurrentFraction)
            Thumb.Position = GetThumbPosition(CurrentFraction)
            Callback(CurrentValue)
        end

        Track.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                if Overlay and Overlay:IsPointerOverPopup(Input.Position) then
                    return
                end
                Dragging = true
                UpdateValueFromInput(Input.Position)
            end
        end)

        SliderMaid:GiveTask(UserInputService.InputChanged:Connect(function(Input)
            if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                if Overlay and Overlay:IsPointerOverPopup(Input.Position) then
                    Dragging = false
                    return
                end
                UpdateValueFromInput(Input.Position)
            end
        end))

        local OnReleaseCallback = SliderConfig.OnRelease or SliderConfig.ReleaseCallback
        local NotifyOnRelease = (SliderConfig.Notify == true or SliderConfig.NotifyOnRelease == true)

        SliderMaid:GiveTask(UserInputService.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                if Dragging then
                    Dragging = false
                    if OnReleaseCallback then
                        OnReleaseCallback(CurrentValue)
                    end
                    if NotifyOnRelease then
                        Library:Notify({
                            Title = Title,
                            Content = Prefix .. tostring(CurrentValue) .. Suffix,
                            Duration = 2,
                            IndicatorStyle = "Pill",
                        })
                    end
                end
            end
        end))

        local SliderObject = {
            Frame = Container,
            Maid = SliderMaid,
        }

        function SliderObject:SetValue(NewValue: number)
            CurrentValue = Utility.Snap(NewValue, Min, Max, Step)
            local CurrentFraction = math.clamp((CurrentValue - Min) / (Max - Min), 0, 1)
            ValueLabel.Text = Prefix .. tostring(CurrentValue) .. Suffix
            Fill.Visible = (CurrentFraction > 0)
            Utility.Tween(Fill, { Size = GetFillSize(CurrentFraction) }, 0.12)
            Utility.Tween(Thumb, { Position = GetThumbPosition(CurrentFraction) }, 0.12)
            Callback(CurrentValue)
        end

        function SliderObject:GetValue(): number
            return CurrentValue
        end

        function SliderObject:SetColor(NewColor: Color3)
            Fill.BackgroundColor3 = NewColor
        end

        function SliderObject:SetVisible(Visible: boolean)
            Container.Visible = Visible
        end

        function SliderObject:OnRelease(ReleaseFn: (number) -> ())
            OnReleaseCallback = ReleaseFn
        end

        return SliderObject
    end

    function ControlHolder:AddProgressBar(ProgressConfig: { [string]: any })
        local ProgressMaid = Maid.New()
        TargetMaid:GiveTask(ProgressMaid)
        local Title = ProgressConfig.Name or ProgressConfig.Title or "Progress"
        local CurrentProgress = math.clamp(ProgressConfig.Progress or 0, 0, 1)
        local ShowPercent = if ProgressConfig.ShowPercentage ~= nil then ProgressConfig.ShowPercentage else true
        local CustomColor = ProgressConfig.CustomColor or ProgressConfig.AccentColor or ProgressConfig.Color
        local TrackColor = ProgressConfig.TrackColor or Tokens.Colors.TrackBackground
        local BarHeight = ProgressConfig.Height or 6
        local BarRadius = if ProgressConfig.Radius then (if typeof(ProgressConfig.Radius) == "number" then UDim.new(0, ProgressConfig.Radius) else ProgressConfig.Radius) else Tokens.Radius.Pill

        local Row = Utility.Create("Frame", {
            Name = Title .. "_ProgressBar",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = TargetFrame,
        }, {
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        ProgressMaid:GiveTask(Row)

        local TopRow = Utility.Create("Frame", {
            Name = "TopRow",
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Parent = Row,
        })

        local TitleLabel = Utility.Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -60, 1, 0),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = Title,
            TextColor3 = Tokens.Colors.TextPrimary,
            TextSize = Tokens.Typography.ControlLabel,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TopRow,
        })

        local PercentLabel = Utility.Create("TextLabel", {
            Name = "Percent",
            Size = UDim2.new(0, 56, 1, 0),
            Position = UDim2.new(1, -56, 0, 0),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = tostring(math.round(CurrentProgress * 100)) .. "%",
            TextColor3 = Tokens.Colors.TextMuted,
            TextSize = Tokens.Typography.ValueText,
            TextXAlignment = Enum.TextXAlignment.Right,
            Visible = ShowPercent,
            Parent = TopRow,
        })

        local Track = Utility.Create("Frame", {
            Name = "Track",
            Size = UDim2.new(1, 0, 0, BarHeight),
            BackgroundColor3 = TrackColor,
            BorderSizePixel = 0,
            Parent = Row,
        }, {
            Utility.CreateCorner(BarRadius),
            Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.4),
        })

        local Fill = Utility.Create("Frame", {
            Name = "Fill",
            Size = UDim2.fromScale(CurrentProgress, 1),
            BackgroundColor3 = CustomColor or Tokens.Colors.Accent,
            BorderSizePixel = 0,
            Parent = Track,
        }, {
            Utility.CreateCorner(BarRadius),
        })

        if not CustomColor then
            Utility.RegisterAccent(Fill, "BackgroundColor3")
        end

        local ProgressObject = {
            Frame = Row,
            Maid = ProgressMaid,
        }

        function ProgressObject:SetProgress(Alpha: number)
            CurrentProgress = math.clamp(Alpha, 0, 1)
            PercentLabel.Text = tostring(math.round(CurrentProgress * 100)) .. "%"
            Utility.Tween(Fill, { Size = UDim2.fromScale(CurrentProgress, 1) }, 0.16)
        end

        function ProgressObject:SetValue(Value: number, MaxValue: number)
            local TargetMax = if MaxValue and MaxValue > 0 then MaxValue else 100
            self:SetProgress(Value / TargetMax)
        end

        function ProgressObject:GetProgress(): number
            return CurrentProgress
        end

        function ProgressObject:SetColor(NewColor: Color3)
            Fill.BackgroundColor3 = NewColor
        end

        function ProgressObject:SetVisible(Visible: boolean)
            Row.Visible = Visible
        end

        return ProgressObject
    end

    function ControlHolder:AddParagraph(ParaConfig: { [string]: any })
        local ParaMaid = Maid.New()
        TargetMaid:GiveTask(ParaMaid)
        local Title = ParaConfig.Title or "Information"
        local ContentText = ParaConfig.Content or ""

        local Card = Utility.Create("Frame", {
            Name = "ParagraphCard",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Tokens.Colors.CardBackground,
            BorderSizePixel = 0,
            Parent = TargetFrame,
        }, {
            Utility.CreateCorner(Tokens.Radius.Control),
            Utility.CreateStroke(Tokens.Colors.CardBorder, 1, 0.5),
            Utility.CreatePadding(10, 10, 12, 12),
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        ParaMaid:GiveTask(Card)

        local TitleLabel = Utility.Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = Title,
            TextColor3 = Tokens.Colors.TextPrimary,
            TextSize = Tokens.Typography.ControlLabel,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Card,
        })

        local ContentLabel = Utility.Create("TextLabel", {
            Name = "Content",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontRegular,
            Text = ContentText,
            TextColor3 = Tokens.Colors.TextMuted,
            TextSize = Tokens.Typography.Description,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = Card,
        })

        local ParaObject = {
            Frame = Card,
            Maid = ParaMaid,
        }

        function ParaObject:SetTitle(NewTitle: string)
            TitleLabel.Text = NewTitle
        end

        function ParaObject:SetContent(NewContent: string)
            ContentLabel.Text = NewContent
        end

        function ParaObject:SetVisible(Visible: boolean)
            Card.Visible = Visible
        end

        return ParaObject
    end

    function ControlHolder:AddDropdown(DropdownConfig: { [string]: any })
        local DropdownMaid = Maid.New()
        TargetMaid:GiveTask(DropdownMaid)
        local Title = DropdownConfig.Name or DropdownConfig.Title or "Dropdown"
        local Options = DropdownConfig.Options or {}
        local IsMulti = DropdownConfig.Multi or false
        local Searchable = DropdownConfig.Searchable or false
        local ReadOnly = (DropdownConfig.ReadOnly == true or DropdownConfig.OnlyView == true)
        local Callback = DropdownConfig.Callback or function(_) end

        local SelectedMap = {}
        if IsMulti then
            local Defaults = DropdownConfig.Default or {}
            for _, Item in ipairs(Defaults) do
                SelectedMap[Item] = true
            end
        else
            local Default = DropdownConfig.Default or Options[1]
            if Default then
                SelectedMap[Default] = true
            end
        end

        local DropHeight = DropdownConfig.Height or 30
        local Container = Utility.Create("Frame", {
            Name = Title .. "_Dropdown",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = TargetFrame,
        }, {
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        DropdownMaid:GiveTask(Container)

        local Label = Utility.Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = Title,
            TextColor3 = Tokens.Colors.TextPrimary,
            TextSize = Tokens.Typography.ControlLabel,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Container,
        })

        local ControlButton = Utility.Create("TextButton", {
            Name = "Control",
            Size = UDim2.new(1, 0, 0, DropHeight),
            BackgroundColor3 = Tokens.Colors.Elevated,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Parent = Container,
        }, {
            Utility.CreateCorner(Tokens.Radius.Control),
            Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.5),
            Utility.CreatePadding(0, 0, 10, 10),
        })

        local ValueLabel = Utility.Create("TextLabel", {
            Name = "ValueLabel",
            Size = UDim2.new(1, -24, 1, 0),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontRegular,
            Text = "",
            TextColor3 = Tokens.Colors.TextPrimary,
            TextSize = Tokens.Typography.ValueText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = ControlButton,
        })

        local Chevron = Utility.Create("ImageLabel", {
            Name = "Chevron",
            Size = UDim2.fromOffset(14, 14),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundTransparency = 1,
            Image = "rbxassetid://10709790948",
            ImageColor3 = Tokens.Colors.TextMuted,
            Rotation = 0,
            Visible = not ReadOnly,
            Parent = ControlButton,
        })

        local function FormatSelectionText(): string
            local SelectedList = {}
            for _, Opt in ipairs(Options) do
                if SelectedMap[Opt] then
                    table.insert(SelectedList, Opt)
                end
            end
            if #SelectedList == 0 then
                return "None selected"
            end
            return table.concat(SelectedList, ", ")
        end

        ValueLabel.Text = FormatSelectionText()

        local IsOpen = false

        local function OpenPopup()
            if ReadOnly then
                return
            end

            IsOpen = true
            Utility.Tween(Chevron, { Rotation = 180 }, 0.14)

            local SearchBarHeight = if Searchable then 28 else 0
            local ListHeight = math.clamp(#Options * 26 + 4, 28, 140)
            local TotalPopupHeight = SearchBarHeight + ListHeight + 8

            local Popup = Utility.Create("TextButton", {
                Name = "DropdownPopup",
                Size = UDim2.fromOffset(ControlButton.AbsoluteSize.X, TotalPopupHeight),
                BackgroundColor3 = Tokens.Colors.PopupBackground,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                Active = true,
                ZIndex = 500,
            }, {
                Utility.CreateCorner(Tokens.Radius.Control),
                Utility.CreateStroke(Tokens.Colors.PopupBorder, 1, 0),
                Utility.CreatePadding(4, 4, 4, 4),
                Utility.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            })

            local SearchBox = nil
            if Searchable then
                local SearchFrame = Utility.Create("Frame", {
                    Name = "SearchFrame",
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundColor3 = Tokens.Colors.InputBackground,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    Active = true,
                    LayoutOrder = 1,
                    Parent = Popup,
                }, {
                    Utility.CreateCorner(Tokens.Radius.Small),
                    Utility.CreateStroke(Tokens.Colors.InputBorder, 1, 0.5),
                    Utility.CreatePadding(0, 0, 6, 6),
                })

                SearchBox = Utility.Create("TextBox", {
                    Name = "SearchBox",
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Font = Tokens.Typography.FontRegular,
                    PlaceholderText = "Search...",
                    PlaceholderColor3 = Tokens.Colors.TextMuted,
                    Text = "",
                    TextColor3 = Tokens.Colors.TextPrimary,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    Active = true,
                    Parent = SearchFrame,
                })
            end

            local ItemScroll = Utility.Create("ScrollingFrame", {
                Name = "ItemScroll",
                Size = UDim2.new(1, 0, 0, ListHeight),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Tokens.Colors.Border,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Active = true,
                LayoutOrder = 2,
                Parent = Popup,
            }, {
                Utility.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    Padding = UDim.new(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            })

            local ItemButtons = {}

            for Index, OptionText in ipairs(Options) do
                local IsSelected = SelectedMap[OptionText] == true

                local ItemBtn = Utility.Create("TextButton", {
                    Name = "Item_" .. OptionText,
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "",
                    Active = true,
                    LayoutOrder = Index,
                    Parent = ItemScroll,
                }, {
                    Utility.CreatePadding(0, 0, 6, 6),
                })

                local ItemLabel = Utility.Create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -20, 1, 0),
                    BackgroundTransparency = 1,
                    Font = if IsSelected then Tokens.Typography.FontMedium else Tokens.Typography.FontRegular,
                    Text = OptionText,
                    TextColor3 = if IsSelected then Tokens.Colors.Accent else Tokens.Colors.TextSecondary,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ItemBtn,
                })

                local Checkmark = Utility.Create("ImageLabel", {
                    Name = "Checkmark",
                    Size = UDim2.fromOffset(12, 12),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://10709791437",
                    ImageColor3 = Tokens.Colors.Accent,
                    Visible = IsSelected,
                    Parent = ItemBtn,
                })

                ItemBtn.MouseEnter:Connect(function()
                    if not SelectedMap[OptionText] then
                        Utility.Tween(ItemLabel, { TextColor3 = Tokens.Colors.AccentHalf }, 0.1)
                    end
                end)

                ItemBtn.MouseLeave:Connect(function()
                    if not SelectedMap[OptionText] then
                        Utility.Tween(ItemLabel, { TextColor3 = Tokens.Colors.TextSecondary }, 0.1)
                    end
                end)

                ItemBtn.MouseButton1Click:Connect(function()
                    if IsMulti then
                        if SelectedMap[OptionText] then
                            SelectedMap[OptionText] = nil
                        else
                            SelectedMap[OptionText] = true
                        end
                        local NowSelected = SelectedMap[OptionText] == true
                        ItemLabel.Font = if NowSelected then Tokens.Typography.FontMedium else Tokens.Typography.FontRegular
                        ItemLabel.TextColor3 = if NowSelected then Tokens.Colors.Accent else Tokens.Colors.TextSecondary
                        Checkmark.Visible = NowSelected
                        ValueLabel.Text = FormatSelectionText()

                        local SelectedList = {}
                        for _, Opt in ipairs(Options) do
                            if SelectedMap[Opt] then
                                table.insert(SelectedList, Opt)
                            end
                        end
                        Callback(SelectedList)
                    else
                        table.clear(SelectedMap)
                        SelectedMap[OptionText] = true

                        for _, OtherItem in pairs(ItemButtons) do
                            OtherItem.Label.Font = Tokens.Typography.FontRegular
                            OtherItem.Label.TextColor3 = Tokens.Colors.TextSecondary
                            OtherItem.Checkmark.Visible = false
                        end

                        ItemLabel.Font = Tokens.Typography.FontMedium
                        ItemLabel.TextColor3 = Tokens.Colors.Accent
                        Checkmark.Visible = true
                        ValueLabel.Text = OptionText
                        Callback(OptionText)
                        Overlay:ClosePopup()
                    end
                end)

                table.insert(ItemButtons, {
                    Button = ItemBtn,
                    Label = ItemLabel,
                    Checkmark = Checkmark,
                    Text = OptionText,
                })
            end

            if SearchBox then
                SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local Query = SearchBox.Text:lower()
                    for _, Item in ipairs(ItemButtons) do
                        local Matches = Query == "" or Item.Text:lower():find(Query, 1, true) ~= nil
                        Item.Button.Visible = Matches
                    end
                end)
            end

            Overlay:MountPopup(Popup, ControlButton, function()
                IsOpen = false
                Utility.Tween(Chevron, { Rotation = 0 }, 0.14)
            end, true)
        end

        ControlButton.MouseButton1Click:Connect(function()
            if Overlay and Overlay:IsPointerOverPopup(UserInputService:GetMouseLocation()) and not IsOpen then
                return
            end
            if IsOpen then
                Overlay:ClosePopup()
            else
                OpenPopup()
            end
        end)

        local DropdownObject = {
            Frame = Container,
            Maid = DropdownMaid,
        }

        function DropdownObject:SetSelected(Target: any)
            if IsMulti and typeof(Target) == "table" then
                table.clear(SelectedMap)
                for _, Item in ipairs(Target) do
                    SelectedMap[Item] = true
                end
            elseif typeof(Target) == "string" then
                table.clear(SelectedMap)
                SelectedMap[Target] = true
            end
            ValueLabel.Text = FormatSelectionText()
        end

        function DropdownObject:GetSelected(): any
            if IsMulti then
                local Result = {}
                for _, Opt in ipairs(Options) do
                    if SelectedMap[Opt] then
                        table.insert(Result, Opt)
                    end
                end
                return Result
            end
            for _, Opt in ipairs(Options) do
                if SelectedMap[Opt] then
                    return Opt
                end
            end
            return nil
        end

        function DropdownObject:SetVisible(Visible: boolean)
            Container.Visible = Visible
        end

        return DropdownObject
    end

    function ControlHolder:AddColorpicker(ColorConfig: { [string]: any })
        local ColorMaid = Maid.New()
        TargetMaid:GiveTask(ColorMaid)
        local Title = ColorConfig.Name or ColorConfig.Title or "Colorpicker"
        local CurrentColor = ColorConfig.Default or Tokens.Colors.Accent
        local Callback = ColorConfig.Callback or function(_) end

        local RowHeight = ColorConfig.Height or 28
        local Row = Utility.Create("Frame", {
            Name = Title .. "_ColorRow",
            Size = UDim2.new(1, 0, 0, RowHeight),
            BackgroundTransparency = 1,
            Parent = TargetFrame,
        })
        ColorMaid:GiveTask(Row)

        local TitleLabel = Utility.Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -50, 1, 0),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = Title,
            TextColor3 = Tokens.Colors.TextPrimary,
            TextSize = Tokens.Typography.ControlLabel,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Row,
        })

        local Swatch = Utility.Create("TextButton", {
            Name = "Swatch",
            Size = UDim2.fromOffset(22, 22),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundColor3 = CurrentColor,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Parent = Row,
        }, {
            Utility.CreateCorner(Tokens.Radius.Small),
            Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.5),
        })

        Swatch.MouseButton1Click:Connect(function()
            if Overlay and Overlay:IsPointerOverPopup(UserInputService:GetMouseLocation()) then
                return
            end
            ShowColorpickerPopup(Swatch, CurrentColor, function(NewColor)
                CurrentColor = NewColor
                Swatch.BackgroundColor3 = NewColor
                Callback(NewColor)
            end, Overlay)
        end)

        local ColorpickerObject = {
            Frame = Row,
            Swatch = Swatch,
            Maid = ColorMaid,
        }

        function ColorpickerObject:SetColor(NewColor: Color3)
            CurrentColor = NewColor
            Swatch.BackgroundColor3 = NewColor
            Callback(NewColor)
        end

        function ColorpickerObject:GetColor(): Color3
            return CurrentColor
        end

        function ColorpickerObject:SetVisible(Visible: boolean)
            Row.Visible = Visible
        end

        return ColorpickerObject
    end

    function ControlHolder:AddTextInput(InputConfig: { [string]: any })
        local InputMaid = Maid.New()
        TargetMaid:GiveTask(InputMaid)
        local Title = InputConfig.Name or InputConfig.Title or "Input"
        local Placeholder = InputConfig.Placeholder or "Enter value..."
        local DefaultText = InputConfig.Default or ""
        local Callback = InputConfig.Callback or function(_) end

        local InputHeight = InputConfig.Height or 30
        local Container = Utility.Create("Frame", {
            Name = Title .. "_TextInput",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = TargetFrame,
        }, {
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        InputMaid:GiveTask(Container)

        local Label = Utility.Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = Title,
            TextColor3 = Tokens.Colors.TextPrimary,
            TextSize = Tokens.Typography.ControlLabel,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Container,
        })

        local BoxContainer = Utility.Create("Frame", {
            Name = "BoxContainer",
            Size = UDim2.new(1, 0, 0, InputHeight),
            BackgroundColor3 = Tokens.Colors.InputBackground,
            BorderSizePixel = 0,
            Parent = Container,
        }, {
            Utility.CreateCorner(Tokens.Radius.Control),
            Utility.CreatePadding(0, 0, 10, 10),
        })

        local BoxStroke = Utility.CreateStroke(Tokens.Colors.InputBorder, 1, 0.6, BoxContainer)

        local Box = Utility.Create("TextBox", {
            Name = "TextBox",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontRegular,
            PlaceholderText = Placeholder,
            PlaceholderColor3 = Tokens.Colors.TextMuted,
            Text = DefaultText,
            TextColor3 = Tokens.Colors.TextPrimary,
            TextSize = Tokens.Typography.ValueText,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            Parent = BoxContainer,
        })

        Box.Focused:Connect(function()
            Utility.Tween(BoxStroke, { Color = Tokens.Colors.InputFocusBorder }, 0.12)
        end)

        Box.FocusLost:Connect(function()
            Utility.Tween(BoxStroke, { Color = Tokens.Colors.InputBorder }, 0.12)
            Callback(Box.Text)
        end)

        local InputObject = {
            Frame = Container,
            Maid = InputMaid,
        }

        function InputObject:SetText(NewText: string)
            Box.Text = NewText
            Callback(NewText)
        end

        function InputObject:GetText(): string
            return Box.Text
        end

        function InputObject:SetVisible(Visible: boolean)
            Container.Visible = Visible
        end

        return InputObject
    end

    function ControlHolder:AddKeybind(KeyConfig: { [string]: any })
        local KeyMaid = Maid.New()
        TargetMaid:GiveTask(KeyMaid)
        local Title = KeyConfig.Name or KeyConfig.Title or "Keybind"
        local CurrentKey = if typeof(KeyConfig.Default) == "EnumItem" then KeyConfig.Default else Enum.KeyCode.None
        local Callback = KeyConfig.Callback or function(_) end
        local OnPressCallback = KeyConfig.OnPress or KeyConfig.PressCallback or KeyConfig.PressedCallback
        local DisallowDuplicates = (KeyConfig.DisallowDuplicates == true or KeyConfig.NoDuplicates == true or KeyConfig.Unique == true)
        local Listening = false
        local ActionName = "SuppressKeybindEscape_" .. HttpService:GenerateGUID(false)
        local KeybindId = "KB_" .. HttpService:GenerateGUID(false)

        local RowHeight = KeyConfig.Height or 28
        local Row = Utility.Create("Frame", {
            Name = Title .. "_KeybindRow",
            Size = UDim2.new(1, 0, 0, RowHeight),
            BackgroundTransparency = 1,
            Parent = TargetFrame,
        })
        KeyMaid:GiveTask(Row)

        local TitleLabel = Utility.Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -60, 1, 0),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = Title,
            TextColor3 = Tokens.Colors.TextPrimary,
            TextSize = Tokens.Typography.ControlLabel,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = Row,
        })

        local KeyBadge = Utility.Create("TextButton", {
            Name = "KeyBadge",
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 0, 22),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundColor3 = Tokens.Colors.Elevated,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Tokens.Typography.FontMedium,
            Text = if CurrentKey ~= Enum.KeyCode.None then "[" .. CurrentKey.Name .. "]" else "[None]",
            TextColor3 = Tokens.Colors.TextSecondary,
            TextSize = Tokens.Typography.BadgeText,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = Row,
        }, {
            Utility.CreateCorner(Tokens.Radius.Small),
            Utility.CreateStroke(Tokens.Colors.BorderSubtle, 1, 0.5),
            Utility.CreatePadding(2, 8, 2, 8),
            Utility.Create("UISizeConstraint", {
                MinSize = Vector2.new(33, 22),
            }),
        })

        local KeyText = KeyBadge

        local function UpdateTitleBounds()
            local BadgeW = math.max(49, KeyBadge.AbsoluteSize.X)
            TitleLabel.Size = UDim2.new(1, -(BadgeW + 10), 1, 0)
        end
        KeyBadge:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateTitleBounds)
        task.defer(UpdateTitleBounds)

        local SuppressConnections = {}
        local function ClearSuppressConnections()
            for _, Conn in ipairs(SuppressConnections) do
                pcall(function() Conn:Disconnect() end)
            end
            table.clear(SuppressConnections)
        end

        local function SuppressRobloxEscapeMenu(Duration: number)
            ClearSuppressConnections()
            Library:ForceCloseRobloxMenu()
            local SuppressUntil = tick() + Duration
            local StepConn
            StepConn = RunService.RenderStepped:Connect(function()
                if GuiService.MenuIsOpen then
                    Library:ForceCloseRobloxMenu()
                end
                if tick() > SuppressUntil then
                    StepConn:Disconnect()
                end
            end)
            table.insert(SuppressConnections, StepConn)

            local HeartConn
            HeartConn = RunService.Heartbeat:Connect(function()
                if GuiService.MenuIsOpen then
                    Library:ForceCloseRobloxMenu()
                end
                if tick() > SuppressUntil then
                    HeartConn:Disconnect()
                end
            end)
            table.insert(SuppressConnections, HeartConn)

            local MenuSigConn
            MenuSigConn = GuiService:GetPropertyChangedSignal("MenuIsOpen"):Connect(function()
                if GuiService.MenuIsOpen then
                    Library:ForceCloseRobloxMenu()
                end
                if tick() > SuppressUntil then
                    MenuSigConn:Disconnect()
                end
            end)
            table.insert(SuppressConnections, MenuSigConn)
        end

        local function ClearKeybindFromEscape()
            if not Listening then
                return
            end
            Listening = false
            Library.LastKeybindTime = os.clock()
            task.delay(0.25, function()
                Library.IsBindingKey = false
            end)

            CurrentKey = Enum.KeyCode.None
            KeyText.Text = "[None]"
            KeyText.TextColor3 = Tokens.Colors.TextSecondary
            UpdateTitleBounds()

            SuppressRobloxEscapeMenu(0.75)

            task.delay(0.35, function()
                pcall(function()
                    ContextActionService:UnbindAction(ActionName)
                end)
            end)

            task.defer(function()
                Callback(Enum.KeyCode.None)
            end)
        end

        local function StopListeningKeybind()
            Listening = false
            Library.LastKeybindTime = os.clock()
            task.delay(0.25, function()
                Library.IsBindingKey = false
            end)
            pcall(function()
                ContextActionService:UnbindAction(ActionName)
            end)
            ClearSuppressConnections()
        end

        KeyBadge.MouseButton1Click:Connect(function()
            if Overlay and Overlay:IsPointerOverPopup(UserInputService:GetMouseLocation()) then
                return
            end
            if Listening then
                return
            end
            Listening = true
            Library.IsBindingKey = true
            KeyText.Text = "[...]"
            KeyText.TextColor3 = KeyConfig.CustomColor or Tokens.Colors.Accent

            pcall(function()
                ContextActionService:BindActionAtPriority(ActionName, function(Action, State, Input)
                    if Input.KeyCode == Enum.KeyCode.Escape then
                        task.defer(ClearKeybindFromEscape)
                        return Enum.ContextActionResult.Sink
                    end
                    return Enum.ContextActionResult.Pass
                end, false, 200000, Enum.KeyCode.Escape)
            end)

            ClearSuppressConnections()
            local PreWatcher = GuiService:GetPropertyChangedSignal("MenuIsOpen"):Connect(function()
                if GuiService.MenuIsOpen and Listening then
                    Library:ForceCloseRobloxMenu()
                end
            end)
            table.insert(SuppressConnections, PreWatcher)
        end)

        KeyMaid:GiveTask(UserInputService.InputBegan:Connect(function(Input, GameProcessed)
            if Listening then
                if Input.UserInputType == Enum.UserInputType.Keyboard then
                    if Input.KeyCode == Enum.KeyCode.Escape then
                        ClearKeybindFromEscape()
                        return
                    end

                    local PressedKey = Input.KeyCode
                    if PressedKey == Enum.KeyCode.Unknown then
                        return
                    end

                    -- Check duplicate keybinds (skip self)
                    if PressedKey ~= Enum.KeyCode.None then
                        local ConflictingBind = nil
                        for OtherId, OtherBind in pairs(Library.RegisteredKeybinds) do
                            if OtherId ~= KeybindId and OtherBind.GetKey() == PressedKey then
                                if DisallowDuplicates or OtherBind.DisallowDuplicates then
                                    ConflictingBind = OtherBind
                                    break
                                end
                            end
                        end

                        if ConflictingBind then
                            StopListeningKeybind()
                            KeyText.Text = if CurrentKey ~= Enum.KeyCode.None then "[" .. CurrentKey.Name .. "]" else "[None]"
                            KeyText.TextColor3 = Tokens.Colors.TextSecondary
                            UpdateTitleBounds()
                            Library:Notify({
                                Title = "Key Conflict",
                                Content = "[" .. PressedKey.Name .. "] is already used by " .. ConflictingBind.Name .. ". Reverted.",
                                Duration = 3,
                                Color = Color3.fromRGB(239, 68, 68),
                            })
                            return
                        end
                    end

                    StopListeningKeybind()
                    CurrentKey = PressedKey
                    KeyText.Text = "[" .. CurrentKey.Name .. "]"
                    KeyText.TextColor3 = Tokens.Colors.TextSecondary
                    UpdateTitleBounds()

                    task.defer(function()
                        Callback(CurrentKey)
                    end)
                end
                return
            end

            if UserInputService:GetFocusedTextBox() ~= nil or Library.IsBindingKey or (os.clock() - (Library.LastKeybindTime or 0) < 0.35) then
                return
            end

            if CurrentKey ~= Enum.KeyCode.None and Input.KeyCode == CurrentKey then
                if OnPressCallback then
                    task.spawn(OnPressCallback, CurrentKey)
                end
            end
        end))

        Library.RegisteredKeybinds[KeybindId] = {
            Name = Title,
            DisallowDuplicates = DisallowDuplicates,
            GetKey = function()
                return CurrentKey
            end,
            SetKey = function(NewKey: Enum.KeyCode)
                CurrentKey = NewKey
                KeyText.Text = if CurrentKey ~= Enum.KeyCode.None then "[" .. CurrentKey.Name .. "]" else "[None]"
                KeyText.TextColor3 = Tokens.Colors.TextSecondary
                UpdateTitleBounds()
                task.defer(function()
                    Callback(CurrentKey)
                end)
            end,
        }

        KeyMaid:GiveTask(function()
            ClearSuppressConnections()
            Library.RegisteredKeybinds[KeybindId] = nil
        end)

        local KeyObject = {
            Frame = Row,
            Badge = KeyBadge,
            Maid = KeyMaid,
            GetValue = function(_)
                return CurrentKey
            end,
            SetValue = function(_, NewKey: Enum.KeyCode)
                CurrentKey = NewKey
                KeyText.Text = if CurrentKey ~= Enum.KeyCode.None then "[" .. CurrentKey.Name .. "]" else "[None]"
                KeyText.TextColor3 = Tokens.Colors.TextSecondary
                UpdateTitleBounds()
                task.defer(function()
                    Callback(CurrentKey)
                end)
            end,
        }
        return KeyObject
    end

    function ControlHolder:AddDivider()
        local Line = Utility.Create("Frame", {
            Name = "Divider",
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Tokens.Colors.BorderSubtle,
            BorderSizePixel = 0,
            Parent = TargetFrame,
        })
        TargetMaid:GiveTask(Line)
        return Line
    end

    function ControlHolder:AddSection(SectionConfigOrName: any, BuilderCallback: ((any) -> ())?)
        local SectionConfig = if typeof(SectionConfigOrName) == "string" then { Name = SectionConfigOrName } else (SectionConfigOrName or {})
        if typeof(SectionConfig.Builder) == "function" and not BuilderCallback then
            BuilderCallback = SectionConfig.Builder
        end
        if typeof(SectionConfig[1]) == "function" and not BuilderCallback then
            BuilderCallback = SectionConfig[1]
        end

        local SectionMaid = Maid.New()
        TargetMaid:GiveTask(SectionMaid)
        local Title = SectionConfig.Name or SectionConfig.Title or "Section"
        local IndicatorStyle = SectionConfig.IndicatorStyle or (if SectionConfig.Dot then "Dot" else "Pill")
        if SectionConfig.ShowIndicator == false or SectionConfig.Indicator == false then
            IndicatorStyle = "None"
        end

        local CardBg = SectionConfig.BackgroundColor3 or Tokens.Colors.CardBackground
        local CardStrokeColor = SectionConfig.BorderColor3 or Tokens.Colors.CardBorder
        local CardCorner = if SectionConfig.CornerRadius then (if typeof(SectionConfig.CornerRadius) == "number" then UDim.new(0, SectionConfig.CornerRadius) else SectionConfig.CornerRadius) else Tokens.Radius.Card

        local SectionCard = Utility.Create("Frame", {
            Name = Title .. "_Card",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = CardBg,
            BorderSizePixel = 0,
            Parent = TargetFrame,
        }, {
            Utility.CreateCorner(CardCorner),
            Utility.CreateStroke(CardStrokeColor, 1, 0.5),
            Utility.CreatePadding(8, 8, 12, 12),
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        SectionMaid:GiveTask(SectionCard)

        local Header = Utility.Create("Frame", {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Parent = SectionCard,
        }, {
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })

        local AccentPill = Utility.Create("Frame", {
            Name = "AccentPill",
            Size = if IndicatorStyle == "Dot" then UDim2.fromOffset(6, 6) else UDim2.fromOffset(3, 14),
            BackgroundColor3 = SectionConfig.CustomColor or Tokens.Colors.Accent,
            BorderSizePixel = 0,
            Visible = (IndicatorStyle ~= "None"),
            Parent = Header,
        }, {
            Utility.CreateCorner(if IndicatorStyle == "Dot" then UDim.new(1, 0) else Tokens.Radius.Pill),
        })

        if not SectionConfig.CustomColor and IndicatorStyle ~= "None" then
            Utility.RegisterAccent(AccentPill, "BackgroundColor3")
        end

        local TitleLabel = Utility.Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -16, 1, 0),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontBold,
            Text = Title,
            TextColor3 = Tokens.Colors.TextPrimary,
            TextSize = Tokens.Typography.SectionTitle,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Header,
        })

        local ContentContainer = Utility.Create("Frame", {
            Name = "Content",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = SectionCard,
        }, {
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })

        local SectionObject = AttachControlMethods(ContentContainer, SectionMaid, Overlay)
        SectionObject.Card = SectionCard
        SectionObject.Maid = SectionMaid
        SectionObject.Indicator = AccentPill

        function SectionObject:SetTitle(NewTitle: string)
            TitleLabel.Text = NewTitle
        end

        function SectionObject:SetVisible(Visible: boolean)
            SectionCard.Visible = Visible
        end

        function SectionObject:SetIndicatorStyle(NewStyle: string)
            if NewStyle == "Dot" then
                AccentPill.Size = UDim2.fromOffset(6, 6)
                AccentPill.Visible = true
            elseif NewStyle == "Pill" or NewStyle == "Bar" then
                AccentPill.Size = UDim2.fromOffset(3, 14)
                AccentPill.Visible = true
            elseif NewStyle == "None" then
                AccentPill.Visible = false
            end
        end

        function SectionObject:SetColor(NewColor: Color3)
            AccentPill.BackgroundColor3 = NewColor
        end

        if BuilderCallback and typeof(BuilderCallback) == "function" then
            BuilderCallback(SectionObject)
        elseif typeof(BuilderCallback) == "table" and (SectionObject :: any).Build then
            (SectionObject :: any):Build(BuilderCallback)
        end

        if typeof(SectionConfig.Elements) == "table" and (SectionObject :: any).Build then
            (SectionObject :: any):Build(SectionConfig.Elements)
        end

        return SectionObject
    end

    function ControlHolder:Build(ElementsTable: { [any]: any })
        for _, Element in ipairs(ElementsTable) do
            local ElemType = Element.Type or Element[1]
            if ElemType == "Button" then
                self:AddButton(Element)
            elseif ElemType == "Toggle" then
                self:AddToggle(Element)
            elseif ElemType == "Slider" then
                self:AddSlider(Element)
            elseif ElemType == "Dropdown" then
                self:AddDropdown(Element)
            elseif ElemType == "Colorpicker" then
                self:AddColorpicker(Element)
            elseif ElemType == "Keybind" then
                self:AddKeybind(Element)
            elseif ElemType == "Switcher" or ElemType == "Segmented" then
                self:AddSwitcher(Element)
            elseif ElemType == "ProgressBar" then
                self:AddProgressBar(Element)
            elseif ElemType == "Paragraph" then
                self:AddParagraph(Element)
            elseif ElemType == "TextInput" or ElemType == "Input" then
                self:AddTextInput(Element)
            elseif ElemType == "Divider" then
                self:AddDivider()
            elseif ElemType == "Section" then
                self:AddSection(Element)
            end
        end
        return self
    end

    ControlHolder.AddContainer = ControlHolder.AddSection

    return ControlHolder
end

-- Library is declared in lib_head.luau

function Library:CreateWindow(Config: { [string]: any })
    if Library.CurrentWindow then
        Library.CurrentWindow:Destroy()
    end

    for _, Existing in ipairs(CoreGui:GetChildren()) do
        if Existing.Name == "UILibraryRoot" then
            Existing:Destroy()
        end
    end

    local WindowMaid = Maid.New()
    local WindowSize = Config.Size or UDim2.fromOffset(880, 560)
    local DefaultSize = Vector2.new(WindowSize.X.Offset, WindowSize.Y.Offset)
    local MinWindowSize = DefaultSize
    local MaxWindowSize = Config.MaxSize or Vector2.new(1500, 1000)
    MaxWindowSize = Vector2.new(math.max(MaxWindowSize.X, MinWindowSize.X), math.max(MaxWindowSize.Y, MinWindowSize.Y))
    local SidebarWidth = Config.SidebarWidth or 225
    local TabHeight = Config.TabHeight or 36
    local TabTextSize = Config.TabSize or Tokens.Typography.TabSize
    local ToggleKey = Config.ToggleKey or Enum.KeyCode.RightControl
    local TitleText = Config.Title or "Terminal"
    local SubtitleText = Config.Subtitle or ""
    local OnCloseCallback = Config.OnClose

    local TrafficConfig = Config.TrafficLights or {}
    local CloseBtnColor = TrafficConfig.CloseColor or Tokens.Colors.CloseButton
    local MinimizeBtnColor = TrafficConfig.MinimizeColor or Tokens.Colors.MinimizeButton
    local MaximizeBtnColor = TrafficConfig.MaximizeColor or Tokens.Colors.MaximizeButton

    local ProfileConfig = Config.Profile or {}
    local ProfileEnabled = if ProfileConfig.Enabled ~= nil then ProfileConfig.Enabled else true
    local ProfileHeight = ProfileConfig.Height or 46
    local ShowAvatar = if ProfileConfig.ShowAvatar ~= nil then ProfileConfig.ShowAvatar else true
    local ShowUsername = if ProfileConfig.ShowUsername ~= nil then ProfileConfig.ShowUsername else true
    local ShowUserId = if ProfileConfig.ShowUserId ~= nil then ProfileConfig.ShowUserId else true
    local ShowFps = if ProfileConfig.ShowFps ~= nil then ProfileConfig.ShowFps else true
    local ShowPing = if ProfileConfig.ShowPing ~= nil then ProfileConfig.ShowPing else true
    local ShowDataPing = if ProfileConfig.ShowDataPing ~= nil then ProfileConfig.ShowDataPing else true

    local MinimizeConfig = Config.Minimize or {}
    local MinimizedStyle = MinimizeConfig.Style or "Auto"
    local MinimizedShowFps = if MinimizeConfig.ShowFps ~= nil then MinimizeConfig.ShowFps else true
    local MinimizedShowPing = if MinimizeConfig.ShowPing ~= nil then MinimizeConfig.ShowPing else true
    local MinimizedShowDataPing = if MinimizeConfig.ShowDataPing ~= nil then MinimizeConfig.ShowDataPing else true
    local MinimizedText = if MinimizeConfig.Text ~= nil then MinimizeConfig.Text else "N"
    local MinimizedIconAsset = if MinimizeConfig.Icon ~= nil then (if MinimizeConfig.Icon == false then "" else tostring(MinimizeConfig.Icon)) else ""
    local MinimizedIconColor = MinimizeConfig.IconColor or Color3.fromRGB(255, 255, 255)
    local MinimizedIconSize = MinimizeConfig.IconSize or UDim2.fromOffset(18, 18)
    local MinimizedAnchor = MinimizeConfig.AnchorPoint or Vector2.new(0, 0)
    local MinimizedPosition = MinimizeConfig.Position or UDim2.new(0, 14, 0, 50)
    local MinimizedCustomBuilder = MinimizeConfig.CustomBuilder or MinimizeConfig.Builder

    local IsRectangle = false
    if MinimizedStyle == "Rectangle" or MinimizedStyle == "Pill" or MinimizedStyle == "Bar" then
        IsRectangle = true
    elseif MinimizedStyle == "Compact" or MinimizedStyle == "Square" then
        IsRectangle = false
    else
        IsRectangle = MinimizedShowFps or MinimizedShowPing or (MinimizeConfig.Size ~= nil and MinimizeConfig.Size.X.Offset > 60)
    end

    local MinimizedSize = MinimizeConfig.Size or (if IsRectangle then UDim2.fromOffset(150, 42) else UDim2.fromOffset(42, 42))
    local MinimizedCorner = MinimizeConfig.CornerRadius or UDim.new(0, 8)
    local MinimizedBg = MinimizeConfig.BackgroundColor3 or Color3.fromRGB(20, 23, 30)
    local MinimizedHoverBg = MinimizeConfig.HoverColor3 or Color3.fromRGB(28, 32, 42)
    local MinimizedTransparency = MinimizeConfig.BackgroundTransparency or 0
    local MinimizedTextColor = MinimizeConfig.TextColor or Color3.fromRGB(255, 255, 255)
    local MinimizedTextSize = MinimizeConfig.TextSize or 18
    local MinimizedFont = MinimizeConfig.Font or Enum.Font.GothamBold
    local MinimizedHasStroke = if MinimizeConfig.Stroke ~= nil then MinimizeConfig.Stroke else true
    local MinimizedStrokeColor = MinimizeConfig.StrokeColor or Color3.fromRGB(80, 85, 95)
    local MinimizedStrokeThickness = MinimizeConfig.StrokeThickness or 1
    local MinimizedStrokeTransparency = MinimizeConfig.StrokeTransparency or 0

    local MinFpsLabel: TextLabel? = nil
    local MinPingLabel: TextLabel? = nil

    local WindowInstance = nil

    local RootGui = Utility.Create("ScreenGui", {
        Name = "UILibraryRoot",
        ResetOnSpawn = false,
        DisplayOrder = -1,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    WindowMaid:GiveTask(RootGui)

    local Overlay = OverlayService.New(RootGui)
    WindowMaid:GiveTask(Overlay)

    if (get_hidden_gui or gethui) then
        local Target = (get_hidden_gui or gethui)()
        RootGui.Parent = Target
    else
        RootGui.Parent = CoreGui
    end

    local WindowFrame = Utility.Create("Frame", {
        Name = "WindowFrame",
        Size = WindowSize,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = Tokens.Colors.WindowBackground,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = RootGui,
    }, {
        Utility.CreateCorner(Tokens.Radius.Window),
        Utility.CreateStroke(Tokens.Colors.Border, 1, 0),
    })
    WindowMaid:GiveTask(WindowFrame)

    local function ClampWindowPosition(TargetPosition: UDim2, OverrideSize: Vector2?): UDim2
        local ViewportSize = RootGui.AbsoluteSize
        local FrameSize = OverrideSize or WindowFrame.AbsoluteSize
        local HalfW = FrameSize.X * WindowFrame.AnchorPoint.X
        local HalfH = FrameSize.Y * WindowFrame.AnchorPoint.Y

        local CurrentPixelX = (TargetPosition.X.Scale * ViewportSize.X) + TargetPosition.X.Offset
        local CurrentPixelY = (TargetPosition.Y.Scale * ViewportSize.Y) + TargetPosition.Y.Offset

        local ClampedX = math.clamp(CurrentPixelX, HalfW, math.max(HalfW, ViewportSize.X - HalfW))
        local ClampedY = math.clamp(CurrentPixelY, HalfH, math.max(HalfH, ViewportSize.Y - HalfH))

        return UDim2.fromOffset(math.round(ClampedX), math.round(ClampedY))
    end

    WindowFrame.Position = ClampWindowPosition(WindowFrame.Position)

    local Topbar = Utility.Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 38),
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Tokens.Colors.TopbarBackground,
        BorderSizePixel = 0,
        Parent = WindowFrame,
    }, {
        Utility.CreateCorner(Tokens.Radius.Window),
    })

    local TopbarMask = Utility.Create("Frame", {
        Name = "TopbarBottomMask",
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Tokens.Colors.TopbarBackground,
        BorderSizePixel = 0,
        Parent = Topbar,
    })

    local TopbarBorder = Utility.Create("Frame", {
        Name = "TopbarBorder",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Tokens.Colors.BorderSubtle,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = Topbar,
    })

    local TrafficContainer = Utility.Create("Frame", {
        Name = "TrafficLights",
        Size = UDim2.fromOffset(72, 38),
        Position = UDim2.fromOffset(14, 0),
        BackgroundTransparency = 1,
        Parent = Topbar,
    }, {
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local function CreateTrafficButton(Name: string, Color: Color3, LayoutOrderNumber: number)
        local Button = Utility.Create("TextButton", {
            Name = Name,
            Size = UDim2.fromOffset(12, 12),
            BackgroundColor3 = Color,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = LayoutOrderNumber,
            Parent = TrafficContainer,
        }, {
            Utility.CreateCorner(UDim.new(1, 0)),
            Utility.CreateStroke(Color3.fromRGB(0, 0, 0), 1, 0.75),
        })

        Button.MouseEnter:Connect(function()
            Utility.Tween(Button, { Size = UDim2.fromOffset(13, 13) }, 0.12)
        end)

        Button.MouseLeave:Connect(function()
            Utility.Tween(Button, { Size = UDim2.fromOffset(12, 12) }, 0.12)
        end)

        return Button
    end

    local CloseBtn = CreateTrafficButton("CloseButton", CloseBtnColor, 1)
    local MinimizeBtn = CreateTrafficButton("MinimizeButton", MinimizeBtnColor, 2)
    local MaximizeBtn = CreateTrafficButton("MaximizeButton", MaximizeBtnColor, 3)

    local TitleContainer = Utility.Create("Frame", {
        Name = "TitleContainer",
        Size = UDim2.new(1, -160, 1, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = Topbar,
    }, {
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local TitleLabel = Utility.Create("TextLabel", {
        Name = "TitleLabel",
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Tokens.Typography.FontMedium,
        Text = TitleText,
        TextColor3 = Tokens.Colors.TextPrimary,
        TextSize = Tokens.Typography.TitleSize,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = TitleContainer,
    })

    if SubtitleText ~= "" then
        Utility.Create("TextLabel", {
            Name = "SubtitleLabel",
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = "-- " .. SubtitleText,
            TextColor3 = Tokens.Colors.TextMuted,
            TextSize = Tokens.Typography.SubtitleSize,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = TitleContainer,
        })
    end

    local Body = Utility.Create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -41),
        Position = UDim2.fromOffset(0, 41),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = WindowFrame,
    })

    local Sidebar = Utility.Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, SidebarWidth, 1, 0),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = Body,
    })

    local TabScrollHeightOffset = if ProfileEnabled then (-ProfileHeight - 3) else 0

    local TabScroll = Utility.Create("ScrollingFrame", {
        Name = "TabScroll",
        Size = UDim2.new(1, 0, 1, TabScrollHeightOffset),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Sidebar,
    }, {
        Utility.Create("UIPadding", {
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
        }),
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    if ProfileEnabled then
        local ProfileSeparator = Utility.Create("Frame", {
            Name = "ProfileSeparator",
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, -ProfileHeight - 1),
            BackgroundColor3 = Tokens.Colors.BorderSubtle,
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = Sidebar,
        })

        local ProfileCard = Utility.Create("Frame", {
            Name = "ProfileCard",
            Size = UDim2.new(1, 0, 0, ProfileHeight),
            Position = UDim2.new(0, 0, 1, -ProfileHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = Sidebar,
        }, {
            Utility.Create("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
            }),
        })

        local CurrentUserId = LocalPlayer and LocalPlayer.UserId or 0
        local CurrentUsername = LocalPlayer and LocalPlayer.Name or "User"

        local LeftOffset = 0

        if ShowAvatar then
            local AvatarFrame = Utility.Create("Frame", {
                Name = "AvatarFrame",
                Size = UDim2.fromOffset(30, 30),
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                BackgroundColor3 = Tokens.Colors.TabHover,
                BorderSizePixel = 0,
                Parent = ProfileCard,
            }, {
                Utility.CreateCorner(Tokens.Radius.Avatar),
            })

            Utility.Create("ImageLabel", {
                Name = "AvatarImage",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(CurrentUserId) .. "&w=48&h=48",
                Parent = AvatarFrame,
            }, {
                Utility.CreateCorner(Tokens.Radius.Avatar),
            })

            LeftOffset = 38
        end

        local UserInfoContainer = Utility.Create("Frame", {
            Name = "UserInfo",
            Size = UDim2.new(1, -LeftOffset - 78, 1, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, LeftOffset, 0.5, 0),
            BackgroundTransparency = 1,
            Parent = ProfileCard,
        }, {
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })

        if ShowUsername then
            Utility.Create("TextLabel", {
                Name = "UsernameLabel",
                Size = UDim2.new(1, 0, 0, 13),
                BackgroundTransparency = 1,
                Font = Tokens.Typography.FontMedium,
                Text = "@" .. CurrentUsername,
                TextColor3 = Tokens.Colors.TextPrimary,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                LayoutOrder = 1,
                Parent = UserInfoContainer,
            })
        end

        if ShowUserId then
            Utility.Create("TextLabel", {
                Name = "IdLabel",
                Size = UDim2.new(1, 0, 0, 11),
                BackgroundTransparency = 1,
                Font = Tokens.Typography.FontMedium,
                Text = "ID: " .. tostring(CurrentUserId),
                TextColor3 = Tokens.Colors.TextMuted,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                LayoutOrder = 2,
                Parent = UserInfoContainer,
            })
        end

        local StatsContainer = Utility.Create("Frame", {
            Name = "StatsContainer",
            Size = UDim2.new(0, 76, 1, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundTransparency = 1,
            Parent = ProfileCard,
        }, {
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })

        local FpsLabel = nil
        if ShowFps then
            FpsLabel = Utility.Create("TextLabel", {
                Name = "FpsLabel",
                Size = UDim2.new(1, 0, 0, 13),
                BackgroundTransparency = 1,
                Font = Tokens.Typography.FontMedium,
                Text = "60 FPS",
                TextColor3 = Tokens.Colors.TextMuted,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Right,
                LayoutOrder = 1,
                Parent = StatsContainer,
            })
        end

        local PingLabel = nil
        if ShowPing or ShowDataPing then
            PingLabel = Utility.Create("TextLabel", {
                Name = "PingLabel",
                Size = UDim2.new(1, 0, 0, 11),
                BackgroundTransparency = 1,
                Font = Tokens.Typography.FontMedium,
                Text = "0 / 0 ms",
                TextColor3 = Tokens.Colors.TextMuted,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Right,
                LayoutOrder = 2,
                Parent = StatsContainer,
            })
        end

        local NetworkStats = Stats:FindFirstChild("Network")
        local ServerStatsItem = NetworkStats and NetworkStats:FindFirstChild("ServerStatsItem")
        local NetworkPingStat = ServerStatsItem and ServerStatsItem:FindFirstChild("Network Ping")
        local DataPingStat = ServerStatsItem and ServerStatsItem:FindFirstChild("Data Ping")

        local FrameCounter = 0
        local LastStatsUpdate = os.clock()

        WindowMaid:GiveTask(RunService.RenderStepped:Connect(function()
            FrameCounter += 1
            local Now = os.clock()
            if Now - LastStatsUpdate >= 0.25 then
                local Elapsed = Now - LastStatsUpdate
                local CurrentFps = math.round(FrameCounter / Elapsed)
                FrameCounter = 0
                LastStatsUpdate = Now

                if FpsLabel then
                    FpsLabel.Text = tostring(CurrentFps) .. " FPS"
                end

                if MinFpsLabel then
                    MinFpsLabel.Text = tostring(CurrentFps) .. " FPS"
                end

                local NetVal = 0
                if NetworkPingStat then
                    NetVal = math.round(NetworkPingStat:GetValue())
                end

                local DataVal = 0
                if DataPingStat then
                    DataVal = math.round(DataPingStat:GetValue())
                end

                if PingLabel then
                    if ShowPing and ShowDataPing then
                        PingLabel.Text = tostring(NetVal) .. " / " .. tostring(DataVal) .. " ms"
                    elseif ShowPing then
                        PingLabel.Text = tostring(NetVal) .. " ms"
                    elseif ShowDataPing then
                        PingLabel.Text = tostring(DataVal) .. " ms"
                    end
                end

                if MinPingLabel then
                    local NetStr = tostring(NetVal)
                    local DataStr = tostring(DataVal)
                    local FullPing = NetStr .. "/" .. DataStr .. " ms"
                    if NetVal <= 9999 and DataVal <= 9999 and #FullPing <= 14 then
                        MinPingLabel.Text = FullPing
                    else
                        MinPingLabel.Text = NetStr .. " ms"
                    end
                end
            end
        end))
    end

    local SidebarBorderLine = Utility.Create("Frame", {
        Name = "SidebarBorderLine",
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.fromOffset(SidebarWidth, 0),
        BackgroundColor3 = Tokens.Colors.BorderSubtle,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = Body,
    })

    local ContentContainer = Utility.Create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -SidebarWidth - 1, 1, 0),
        Position = UDim2.fromOffset(SidebarWidth + 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = Body,
    })

    local MinimizedWidget = Utility.Create("TextButton", {
        Name = "MinimizedWidget",
        AutomaticSize = Enum.AutomaticSize.None,
        Size = UDim2.new(0, if IsRectangle then 126 else 42, 0, 42),
        AnchorPoint = MinimizedAnchor,
        Position = MinimizedPosition,
        BackgroundColor3 = MinimizedBg,
        BackgroundTransparency = MinimizedTransparency,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Visible = false,
        ZIndex = 50,
        Parent = RootGui,
    }, {
        Utility.CreateCorner(MinimizedCorner),
        Utility.CreatePadding(if IsRectangle then 4 else 0, if IsRectangle then 8 else 0, if IsRectangle then 4 else 0, if IsRectangle then 8 else 0),
        Utility.Create("UISizeConstraint", {
            MinSize = Vector2.new(42, 42),
        }),
    })
    WindowMaid:GiveTask(MinimizedWidget)

    if MinimizedHasStroke then
        Utility.CreateStroke(MinimizedStrokeColor, MinimizedStrokeThickness, MinimizedStrokeTransparency, MinimizedWidget)
    end

    local MinimizedIconInstance = nil
    local MinimizedLabelInstance = nil

    if MinimizedCustomBuilder then
        MinimizedCustomBuilder(MinimizedWidget, WindowInstance)
    elseif IsRectangle then
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = MinimizedWidget,
        })

        if MinimizedIconAsset ~= "" then
            MinimizedIconInstance = Utility.Create("ImageLabel", {
                Name = "Icon",
                Size = MinimizedIconSize,
                BackgroundTransparency = 1,
                Image = MinimizedIconAsset,
                ImageColor3 = MinimizedIconColor,
                Active = false,
                LayoutOrder = 1,
                Parent = MinimizedWidget,
            })
        end

        if MinimizedText ~= "" then
            MinimizedLabelInstance = Utility.Create("TextLabel", {
                Name = "Label",
                Size = UDim2.fromOffset(28, 32),
                BackgroundTransparency = 1,
                Font = Tokens.Typography.FontBold,
                Text = MinimizedText,
                TextColor3 = MinimizedTextColor,
                TextSize = 22,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                Active = false,
                LayoutOrder = 2,
                Parent = MinimizedWidget,
            })
        end

        if (MinimizedIconAsset ~= "" or MinimizedText ~= "") and (MinimizedShowFps or MinimizedShowPing) then
            Utility.Create("Frame", {
                Name = "Separator",
                Size = UDim2.new(0, 1, 0, 22),
                BackgroundColor3 = Tokens.Colors.BorderSubtle,
                BackgroundTransparency = 0.4,
                BorderSizePixel = 0,
                Active = false,
                LayoutOrder = 10,
                Parent = MinimizedWidget,
            })
        end

        if MinimizedShowFps or MinimizedShowPing then
            local MinStatsContainer = Utility.Create("Frame", {
                Name = "StatsContainer",
                Size = UDim2.new(0, 70, 1, 0),
                BackgroundTransparency = 1,
                Active = false,
                LayoutOrder = 20,
                Parent = MinimizedWidget,
            }, {
                Utility.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 1),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            })

            if MinimizedShowFps then
                MinFpsLabel = Utility.Create("TextLabel", {
                    Name = "FpsLabel",
                    Size = UDim2.new(1, 0, 0, 13),
                    BackgroundTransparency = 1,
                    Font = Tokens.Typography.FontMedium,
                    Text = "-- FPS",
                    TextColor3 = Color3.fromRGB(240, 240, 245),
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Active = false,
                    LayoutOrder = 1,
                    Parent = MinStatsContainer,
                })
            end

            if MinimizedShowPing then
                MinPingLabel = Utility.Create("TextLabel", {
                    Name = "PingLabel",
                    Size = UDim2.new(1, 0, 0, 11),
                    BackgroundTransparency = 1,
                    Font = Tokens.Typography.FontMedium,
                    Text = "--/-- ms",
                    TextColor3 = Color3.fromRGB(150, 155, 165),
                    TextSize = 9,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Active = false,
                    LayoutOrder = 2,
                    Parent = MinStatsContainer,
                })
            end
        end
    else
        if MinimizedIconAsset ~= "" then
            MinimizedIconInstance = Utility.Create("ImageLabel", {
                Name = "Icon",
                Size = MinimizedIconSize,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = MinimizedIconAsset,
                ImageColor3 = MinimizedIconColor,
                Active = false,
                ZIndex = 51,
                Parent = MinimizedWidget,
            })
        end

        if MinimizedText ~= "" then
            MinimizedLabelInstance = Utility.Create("TextLabel", {
                Name = "Label",
                Size = UDim2.fromScale(1, 1),
                Position = UDim2.fromScale(0, 0),
                BackgroundTransparency = 1,
                Font = MinimizedFont,
                Text = MinimizedText,
                TextColor3 = MinimizedTextColor,
                TextSize = MinimizedTextSize,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                Active = false,
                ZIndex = 51,
                Parent = MinimizedWidget,
            })
        end
    end

    MinimizedWidget.MouseEnter:Connect(function()
        Utility.Tween(MinimizedWidget, { BackgroundColor3 = MinimizedHoverBg }, 0.12)
    end)

    MinimizedWidget.MouseLeave:Connect(function()
        Utility.Tween(MinimizedWidget, { BackgroundColor3 = MinimizedBg }, 0.12)
    end)

    local function ClampWidgetPosition(TargetPosition: UDim2): UDim2
        local ViewportSize = RootGui.AbsoluteSize
        local WidgetSize = MinimizedWidget.AbsoluteSize
        local Anchor = MinimizedWidget.AnchorPoint
        local MinX = WidgetSize.X * Anchor.X
        local MaxX = math.max(MinX, ViewportSize.X - (WidgetSize.X * (1 - Anchor.X)))
        local MinY = WidgetSize.Y * Anchor.Y
        local MaxY = math.max(MinY, ViewportSize.Y - (WidgetSize.Y * (1 - Anchor.Y)))

        local CurrentPixelX = (TargetPosition.X.Scale * ViewportSize.X) + TargetPosition.X.Offset
        local CurrentPixelY = (TargetPosition.Y.Scale * ViewportSize.Y) + TargetPosition.Y.Offset

        local ClampedX = math.clamp(CurrentPixelX, MinX, MaxX)
        local ClampedY = math.clamp(CurrentPixelY, MinY, MaxY)

        return UDim2.fromOffset(math.round(ClampedX), math.round(ClampedY))
    end

    local MinimizedDragStart = nil
    local MinimizedStartPosition = nil
    local MinimizedDragging = false
    local MinimizedWasDragged = false

    WindowMaid:GiveTask(MinimizedWidget.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        MinimizedDragging = true
        MinimizedWasDragged = false
        MinimizedDragStart = Input.Position
        MinimizedStartPosition = MinimizedWidget.Position

        local StateConn
        StateConn = Input.Changed:Connect(function()
            if Input.UserInputState == Enum.UserInputState.End then
                MinimizedDragging = false
                if StateConn then
                    StateConn:Disconnect()
                end
            end
        end)
    end))

    WindowMaid:GiveTask(UserInputService.InputChanged:Connect(function(Input)
        if not MinimizedDragging or not MinimizedDragStart then
            return
        end
        if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local Delta = Input.Position - MinimizedDragStart
        if Delta.Magnitude > 3 then
            MinimizedWasDragged = true
        end

        local TargetOffset = UDim2.new(
            MinimizedStartPosition.X.Scale,
            MinimizedStartPosition.X.Offset + Delta.X,
            MinimizedStartPosition.Y.Scale,
            MinimizedStartPosition.Y.Offset + Delta.Y
        )

        MinimizedWidget.Position = ClampWidgetPosition(TargetOffset)
    end))

    local DragStart = nil
    local StartPosition = nil
    local DragInput = nil
    local Dragging = false

    WindowMaid:GiveTask(Topbar.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        if Input.Position.X < Topbar.AbsolutePosition.X + 80 then
            return
        end

        local ViewportSize = RootGui.AbsoluteSize
        local MaxW = math.clamp(ViewportSize.X - 16, MinWindowSize.X, MaxWindowSize.X)
        local MaxH = math.clamp(ViewportSize.Y - 16, MinWindowSize.Y, MaxWindowSize.Y)

        if WindowInstance and WindowInstance.IsMaximized then
            WindowInstance.IsMaximized = false
            ResizeGrip.Visible = true
            local NormW = WindowInstance.NormalWindowSize.X.Offset
            local NormH = WindowInstance.NormalWindowSize.Y.Offset
            if NormW >= MaxW - 20 or NormH >= MaxH - 20 or NormW < MinWindowSize.X or NormH < MinWindowSize.Y then
                NormW = math.clamp(math.round(ViewportSize.X * 0.65), MinWindowSize.X, math.max(MinWindowSize.X, MaxW - 40))
                NormH = math.clamp(math.round(ViewportSize.Y * 0.7), MinWindowSize.Y, math.max(MinWindowSize.Y, MaxH - 40))
                WindowInstance.NormalWindowSize = UDim2.fromOffset(NormW, NormH)
            end
            WindowFrame.Size = WindowInstance.NormalWindowSize
            local DragOffsetX = Input.Position.X - (NormW * 0.5)
            local DragOffsetY = Input.Position.Y - 20
            StartPosition = UDim2.fromOffset(DragOffsetX, DragOffsetY)
            WindowFrame.Position = ClampWindowPosition(StartPosition, Vector2.new(NormW, NormH))
            DragStart = Input.Position
            Dragging = true
        else
            Dragging = true
            DragStart = Input.Position
            StartPosition = WindowFrame.Position
        end

        local StateConn
        StateConn = Input.Changed:Connect(function()
            if Input.UserInputState == Enum.UserInputState.End then
                Dragging = false
                if StateConn then
                    StateConn:Disconnect()
                end
            end
        end)
    end))

    WindowMaid:GiveTask(Topbar.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            DragInput = Input
        end
    end))

    WindowMaid:GiveTask(UserInputService.InputChanged:Connect(function(Input)
        if Input ~= DragInput or not Dragging then
            return
        end

        local Delta = Input.Position - DragStart
        local TargetOffset = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )

        WindowFrame.Position = ClampWindowPosition(TargetOffset)
    end))

    local ResizeGrip = Utility.Create("TextButton", {
        Name = "ResizeGrip",
        Size = UDim2.fromOffset(24, 24),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 60,
        Parent = WindowFrame,
    })

    local Resizing = false
    local ResizeStartMouse = nil
    local ResizeStartSize = nil

    WindowMaid:GiveTask(ResizeGrip.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            if WindowInstance and WindowInstance.IsMaximized then
                return
            end
            Resizing = true
            ResizeStartMouse = Input.Position
            ResizeStartSize = Vector2.new(WindowFrame.AbsoluteSize.X, WindowFrame.AbsoluteSize.Y)
            local StateConn
            StateConn = Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Resizing = false
                    ResizeStartMouse = nil
                    ResizeStartSize = nil
                    if StateConn then
                        StateConn:Disconnect()
                    end
                end
            end)
        end
    end))

    WindowMaid:GiveTask(UserInputService.InputChanged:Connect(function(Input)
        if not Resizing or not ResizeStartMouse or not ResizeStartSize then
            return
        end
        if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local Delta = Input.Position - ResizeStartMouse
        local ViewportSize = RootGui.AbsoluteSize
        local MaxAllowedW = math.clamp(ViewportSize.X - 16, MinWindowSize.X, MaxWindowSize.X)
        local MaxAllowedH = math.clamp(ViewportSize.Y - 16, MinWindowSize.Y, MaxWindowSize.Y)

        local NewW = math.clamp(ResizeStartSize.X + Delta.X, MinWindowSize.X, MaxAllowedW - 20)
        local NewH = math.clamp(ResizeStartSize.Y + Delta.Y, MinWindowSize.Y, MaxAllowedH - 20)

        WindowFrame.Size = UDim2.fromOffset(NewW, NewH)
        if WindowInstance then
            WindowInstance.NormalWindowSize = WindowFrame.Size
        end
        WindowFrame.Position = ClampWindowPosition(WindowFrame.Position, Vector2.new(NewW, NewH))
        if WindowInstance then
            WindowInstance.NormalWindowPosition = WindowFrame.Position
        end
    end))

    WindowMaid:GiveTask(UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            if Dragging and WindowInstance and not WindowInstance.IsMaximized then
                WindowInstance.NormalWindowPosition = WindowFrame.Position
            end
            Dragging = false
            MinimizedDragging = false
            Resizing = false
            ResizeStartMouse = nil
            ResizeStartSize = nil
            task.delay(0.08, function()
                MinimizedWasDragged = false
            end)
        end
    end))

    WindowMaid:GiveTask(RootGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        WindowFrame.Position = ClampWindowPosition(WindowFrame.Position)
        MinimizedWidget.Position = ClampWidgetPosition(MinimizedWidget.Position)
    end))

    WindowInstance = {
        Frame = WindowFrame,
        Topbar = Topbar,
        Body = Body,
        Sidebar = Sidebar,
        ContentContainer = ContentContainer,
        MinimizedWidget = MinimizedWidget,
        Maid = WindowMaid,
        IsVisible = true,
        IsMinimized = false,
        IsMaximized = false,
        NormalWindowSize = WindowSize,
        NormalWindowPosition = WindowFrame.Position,
        Tabs = {},
        ActiveTab = nil,
        RootGui = RootGui,
    }

    function WindowInstance:SetToggleKey(NewKey: Enum.KeyCode)
        ToggleKey = NewKey
    end

    function WindowInstance:Notify(NotifConfig: { [string]: any })
        Library:Notify(NotifConfig)
    end

    function WindowInstance:SetVisible(Visible: boolean)
        self.IsVisible = Visible
        if not Visible then
            WindowFrame.Visible = false
            MinimizedWidget.Visible = false
            Overlay:ClosePopup()
        else
            if self.IsMinimized then
                MinimizedWidget.Visible = true
                WindowFrame.Visible = false
            else
                WindowFrame.Visible = true
                MinimizedWidget.Visible = false
            end
        end
    end

    local LastToggleTime = 0
    function WindowInstance:ToggleMinimize()
        local Now = os.clock()
        if Now - LastToggleTime < 0.15 then
            return
        end
        LastToggleTime = Now
        if self.IsMinimized then
            self:Restore()
        else
            self:Minimize()
        end
    end

    function WindowInstance:GetMinimizedWidget(): TextButton
        return MinimizedWidget
    end

    function WindowInstance:SetMinimizedText(NewText: string)
        if MinimizedLabelInstance then
            MinimizedLabelInstance.Text = NewText
        end
    end

    function WindowInstance:SetMinimizedIcon(NewIcon: string)
        if MinimizedIconInstance then
            MinimizedIconInstance.Image = NewIcon
        end
    end

    function WindowInstance:Toggle()
        self:ToggleMinimize()
    end

    function WindowInstance:Minimize()
        if self.IsMinimized then
            self:Restore()
            return
        end
        self.IsMinimized = true
        Overlay:ClosePopup()

        WindowFrame.Visible = false
        MinimizedWidget.Visible = true
    end

    function WindowInstance:Restore()
        if not self.IsMinimized then
            return
        end
        self.IsMinimized = false
        MinimizedWidget.Visible = false

        local ViewportSize = RootGui.AbsoluteSize
        local MaxW = math.clamp(ViewportSize.X - 16, MinWindowSize.X, MaxWindowSize.X)
        local MaxH = math.clamp(ViewportSize.Y - 16, MinWindowSize.Y, MaxWindowSize.Y)

        if self.IsMaximized then
            local TargetClamped = ClampWindowPosition(WindowFrame.Position, Vector2.new(MaxW, MaxH))
            WindowFrame.Position = TargetClamped
            WindowFrame.Size = UDim2.fromOffset(MaxW, MaxH)
            ResizeGrip.Visible = false
        else
            local NormW = self.NormalWindowSize.X.Offset
            local NormH = self.NormalWindowSize.Y.Offset
            if NormW >= MaxW - 20 or NormH >= MaxH - 20 or NormW < MinWindowSize.X or NormH < MinWindowSize.Y then
                NormW = math.clamp(math.round(ViewportSize.X * 0.65), MinWindowSize.X, math.max(MinWindowSize.X, MaxW - 40))
                NormH = math.clamp(math.round(ViewportSize.Y * 0.7), MinWindowSize.Y, math.max(MinWindowSize.Y, MaxH - 40))
                self.NormalWindowSize = UDim2.fromOffset(NormW, NormH)
            end
            WindowFrame.Position = ClampWindowPosition(self.NormalWindowPosition, Vector2.new(NormW, NormH))
            WindowFrame.Size = self.NormalWindowSize
            ResizeGrip.Visible = true
        end
        WindowFrame.Visible = true
    end

    local LastMaximizeTime = 0
    function WindowInstance:Maximize()
        local Now = os.clock()
        if Now - LastMaximizeTime < 0.15 then
            return
        end
        LastMaximizeTime = Now

        local ViewportSize = RootGui.AbsoluteSize
        local MaxW = math.clamp(ViewportSize.X - 16, MinWindowSize.X, MaxWindowSize.X)
        local MaxH = math.clamp(ViewportSize.Y - 16, MinWindowSize.Y, MaxWindowSize.Y)

        Overlay:ClosePopup()

        if self.IsMinimized then
            self.IsMinimized = false
            MinimizedWidget.Visible = false
            WindowFrame.Visible = true
            self.IsMaximized = not self.IsMaximized
        else
            self.IsMaximized = not self.IsMaximized
        end

        if self.IsMaximized then
            ResizeGrip.Visible = false
            local TargetClamped = ClampWindowPosition(WindowFrame.Position, Vector2.new(MaxW, MaxH))
            Utility.Tween(WindowFrame, {
                Size = UDim2.fromOffset(MaxW, MaxH),
                Position = TargetClamped,
            }, 0.18)
        else
            ResizeGrip.Visible = true
            local NormW = self.NormalWindowSize.X.Offset
            local NormH = self.NormalWindowSize.Y.Offset
            if NormW >= MaxW - 20 or NormH >= MaxH - 20 or NormW < MinWindowSize.X or NormH < MinWindowSize.Y then
                NormW = math.clamp(math.round(ViewportSize.X * 0.65), MinWindowSize.X, math.max(MinWindowSize.X, MaxW - 40))
                NormH = math.clamp(math.round(ViewportSize.Y * 0.7), MinWindowSize.Y, math.max(MinWindowSize.Y, MaxH - 40))
                self.NormalWindowSize = UDim2.fromOffset(NormW, NormH)
            end

            local TargetClamped = ClampWindowPosition(self.NormalWindowPosition, Vector2.new(NormW, NormH))
            self.NormalWindowPosition = TargetClamped
            Utility.Tween(WindowFrame, {
                Size = self.NormalWindowSize,
                Position = TargetClamped,
            }, 0.18)
        end
    end

    function WindowInstance:SetTitle(NewTitle: string)
        TitleLabel.Text = NewTitle
    end

    function WindowInstance:CreateTab(TabConfigOrName: any, BuilderCallback: ((any) -> ())?)
        local Config = if typeof(TabConfigOrName) == "string" then { Name = TabConfigOrName } else (TabConfigOrName or {})
        local Name = Config.Name or Config.Title or "Tab"
        if typeof(Config.Builder) == "function" and not BuilderCallback then
            BuilderCallback = Config.Builder
        end
        if typeof(Config[1]) == "function" and not BuilderCallback then
            BuilderCallback = Config[1]
        end

        local TabMaid = Maid.New()
        WindowMaid:GiveTask(TabMaid)
        local TabOrder = #self.Tabs + 1

        local TabButton = Utility.Create("TextButton", {
            Name = "Tab_" .. Name,
            Size = UDim2.new(1, 0, 0, TabHeight),
            BackgroundColor3 = Tokens.Colors.TabDefault,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = TabOrder,
            Parent = TabScroll,
        }, {
            Utility.CreateCorner(Tokens.Radius.Tab),
        })
        TabMaid:GiveTask(TabButton)

        local TabIndicator = Utility.Create("Frame", {
            Name = "Indicator",
            Size = UDim2.fromOffset(4, 4),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 8, 0.5, 0),
            BackgroundColor3 = Tokens.Colors.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = TabButton,
        }, {
            Utility.CreateCorner(UDim.new(1, 0)),
        })
        Utility.RegisterAccent(TabIndicator, "BackgroundColor3")

        local TabLabel = Utility.Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -26, 1, 0),
            Position = UDim2.fromOffset(20, 0),
            BackgroundTransparency = 1,
            Font = Tokens.Typography.FontMedium,
            Text = Name,
            TextColor3 = Tokens.Colors.TabDefaultText,
            TextSize = TabTextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = TabButton,
        })

        local TabPage = Utility.Create("ScrollingFrame", {
            Name = "Page_" .. Name,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Tokens.Colors.Border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = ContentContainer,
        }, {
            Utility.Create("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
            }),
            Utility.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        TabMaid:GiveTask(TabPage)

        local TabControlMethods = AttachControlMethods(TabPage, TabMaid, Overlay)

        local TabObject = setmetatable({
            Name = Name,
            Button = TabButton,
            Page = TabPage,
            Label = TabLabel,
            Indicator = TabIndicator,
            Maid = TabMaid,
        }, {
            __index = TabControlMethods,
        })

        TabButton.MouseEnter:Connect(function()
            if self.ActiveTab ~= TabObject then
                Utility.Tween(TabButton, { BackgroundTransparency = 0, BackgroundColor3 = Tokens.Colors.TabHover }, 0.12)
                Utility.Tween(TabLabel, { TextColor3 = Tokens.Colors.AccentHalf }, 0.12)
                Utility.Tween(TabIndicator, { Size = UDim2.fromOffset(4, 4), BackgroundTransparency = 0 }, 0.12)
            end
        end)

        TabButton.MouseLeave:Connect(function()
            if self.ActiveTab ~= TabObject then
                Utility.Tween(TabButton, { BackgroundTransparency = 1, BackgroundColor3 = Tokens.Colors.TabDefault }, 0.12)
                Utility.Tween(TabLabel, { TextColor3 = Tokens.Colors.TabDefaultText }, 0.12)
                Utility.Tween(TabIndicator, { Size = UDim2.fromOffset(4, 4), BackgroundTransparency = 1 }, 0.12)
            end
        end)

        TabButton.MouseButton1Click:Connect(function()
            self:SelectTab(TabObject)
        end)

        table.insert(self.Tabs, TabObject)

        TabMaid:GiveTask(Library.OnAccentChanged:Connect(function(NewAccent)
            if self.ActiveTab == TabObject then
                TabLabel.TextColor3 = NewAccent
            end
        end))

        if #self.Tabs == 1 then
            self:SelectTab(TabObject)
        end

        if BuilderCallback and typeof(BuilderCallback) == "function" then
            BuilderCallback(TabObject)
        elseif typeof(BuilderCallback) == "table" and (TabObject :: any).Build then
            (TabObject :: any):Build(BuilderCallback)
        end

        if typeof(Config.Elements) == "table" and (TabObject :: any).Build then
            (TabObject :: any):Build(Config.Elements)
        end

        return TabObject
    end

    function WindowInstance:SelectTab(TargetTab: any)
        Overlay:ClosePopup()
        local PreviousActiveTab = self.ActiveTab

        for _, Tab in ipairs(self.Tabs) do
            local IsSelected = (Tab == TargetTab or Tab.Name == TargetTab)
            Tab.Page.Visible = IsSelected
            if IsSelected then
                self.ActiveTab = Tab
                Utility.Tween(Tab.Button, { BackgroundTransparency = 0, BackgroundColor3 = Tokens.Colors.TabActive }, 0.14)
                Utility.Tween(Tab.Label, { TextColor3 = Tokens.Colors.Accent }, 0.14)
                Utility.Tween(Tab.Indicator, { Size = UDim2.fromOffset(3, 18), BackgroundTransparency = 0 }, 0.14)
            elseif Tab == PreviousActiveTab then
                Utility.Tween(Tab.Button, { BackgroundTransparency = 1, BackgroundColor3 = Tokens.Colors.TabDefault }, 0.14)
                Utility.Tween(Tab.Label, { TextColor3 = Tokens.Colors.TabDefaultText }, 0.14)
                Utility.Tween(Tab.Indicator, { Size = UDim2.fromOffset(4, 4), BackgroundTransparency = 1 }, 0.14)
            else
                Tab.Button.BackgroundTransparency = 1
                Tab.Button.BackgroundColor3 = Tokens.Colors.TabDefault
                Tab.Label.TextColor3 = Tokens.Colors.TabDefaultText
                Tab.Indicator.Size = UDim2.fromOffset(4, 4)
                Tab.Indicator.BackgroundTransparency = 1
            end
        end
    end

    function WindowInstance:Destroy()
        if Library.CurrentWindow == WindowInstance then
            Library.CurrentWindow = nil
        end
        WindowMaid:Cleanup()
    end

    WindowInstance.Unload = WindowInstance.Destroy
    WindowInstance.SetAccentColor = function(_, NewAccent: Color3)
        Library:SetAccentColor(NewAccent)
    end

    CloseBtn.MouseButton1Click:Connect(function()
        if OnCloseCallback then
            OnCloseCallback()
        else
            WindowInstance:Destroy()
        end
    end)

    MinimizeBtn.MouseButton1Click:Connect(function()
        WindowInstance:Minimize()
    end)

    MaximizeBtn.MouseButton1Click:Connect(function()
        WindowInstance:Maximize()
    end)

    MinimizedWidget.MouseButton1Click:Connect(function()
        if not MinimizedWasDragged then
            WindowInstance:Restore()
        end
    end)

    WindowMaid:GiveTask(UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        if UserInputService:GetFocusedTextBox() ~= nil or Library.IsBindingKey or (os.clock() - (Library.LastKeybindTime or 0) < 0.35) then
            return
        end
        if ToggleKey ~= Enum.KeyCode.None and Input.KeyCode == ToggleKey then
            WindowInstance:ToggleMinimize()
        end
    end))

    Library.CurrentWindow = WindowInstance
    return WindowInstance
end

function Library:Notify(Config: { [string]: any })
    local Title = Config.Title or "Notification"
    local Content = Config.Content or Config.Text or Config.Desc or ""
    local Duration = Config.Duration or 3.5
    local AccentColor = Config.AccentColor or Config.Color or Tokens.Colors.Accent
    local IndicatorStyle = Config.Indicator or Config.IndicatorStyle or "Pill"
    local CornerRadius = if Config.Radius then (if typeof(Config.Radius) == "number" then UDim.new(0, Config.Radius) else Config.Radius) else UDim.new(0, 8)

    local Root = if Library.CurrentWindow and Library.CurrentWindow.RootGui then Library.CurrentWindow.RootGui else nil
    if not Root or not Root.Parent then
        local Target = (get_hidden_gui or gethui) and (get_hidden_gui or gethui)() or CoreGui
        Root = Target:FindFirstChild("UILibraryRoot") or CoreGui:FindFirstChild("UILibraryRoot")
    end
    if not Root or not Root.Parent then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = Title,
                Text = Content,
                Duration = Duration,
            })
        end)
        return
    end

    local ToastContainer = Root:FindFirstChild("ToastContainer")
    if not ToastContainer then
        ToastContainer = Utility.Create("Frame", {
            Name = "ToastContainer",
            Size = UDim2.new(0, 260, 1, -40),
            Position = UDim2.new(1, -276, 0, 20),
            BackgroundTransparency = 1,
            ZIndex = 300,
            Parent = Root,
        }, {
            Utility.Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                Padding = UDim.new(0, 8),
            }),
        })
    end

    local ToastCardName = "Toast_" .. Title:gsub("%s+", "_")
    local ExistingToast = ToastContainer:FindFirstChild(ToastCardName)
    if ExistingToast then
        local Body = ExistingToast:FindFirstChild("Body", true)
        if Body and Body:IsA("TextLabel") then
            Body.Text = Content
        end
        local TimeBar = ExistingToast:FindFirstChild("TimeBar", true)
        if TimeBar then
            TimeBar.Size = UDim2.new(1, 0, 1, 0)
            local Tween = TweenService:Create(TimeBar, TweenInfo.new(Duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) })
            Tween:Play()
        end
        ExistingToast:SetAttribute("DismissTime", tick() + Duration)
        return
    end

    local ToastCard = Utility.Create("Frame", {
        Name = ToastCardName,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Tokens.Colors.CardBackground,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 301,
        Parent = ToastContainer,
    }, {
        Utility.CreateCorner(CornerRadius),
        Utility.CreateStroke(Tokens.Colors.Border, 1, 0.4),
        Utility.CreatePadding(8, 8, 10, 10),
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local HeaderRow = Utility.Create("Frame", {
        Name = "HeaderRow",
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = ToastCard,
    }, {
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    if IndicatorStyle == "Pill" then
        local Pill = Utility.Create("Frame", {
            Name = "IndicatorPill",
            Size = UDim2.fromOffset(3, 14),
            BackgroundColor3 = AccentColor,
            BorderSizePixel = 0,
            LayoutOrder = 1,
            Parent = HeaderRow,
        }, {
            Utility.CreateCorner(UDim.new(1, 0)),
        })
        if not Config.AccentColor and not Config.Color then
            Utility.RegisterAccent(Pill, "BackgroundColor3")
        end
    elseif IndicatorStyle == "Dot" then
        local Dot = Utility.Create("Frame", {
            Name = "IndicatorDot",
            Size = UDim2.fromOffset(6, 6),
            BackgroundColor3 = AccentColor,
            BorderSizePixel = 0,
            LayoutOrder = 1,
            Parent = HeaderRow,
        }, {
            Utility.CreateCorner(UDim.new(1, 0)),
        })
        if not Config.AccentColor and not Config.Color then
            Utility.RegisterAccent(Dot, "BackgroundColor3")
        end
    end

    Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -12, 1, 0),
        BackgroundTransparency = 1,
        Font = Tokens.Typography.FontBold,
        Text = Title,
        TextColor3 = Tokens.Colors.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 2,
        Parent = HeaderRow,
    })

    Utility.Create("TextLabel", {
        Name = "Body",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = Tokens.Typography.FontRegular,
        Text = Content,
        TextColor3 = Tokens.Colors.TextSecondary,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Parent = ToastCard,
    })

    local TimeTrack = Utility.Create("Frame", {
        Name = "TimeTrack",
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Tokens.Colors.BorderSubtle,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        LayoutOrder = 3,
        Parent = ToastCard,
    }, {
        Utility.CreateCorner(UDim.new(1, 0)),
    })

    local TimeBar = Utility.Create("Frame", {
        Name = "TimeBar",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = AccentColor,
        BorderSizePixel = 0,
        Parent = TimeTrack,
    }, {
        Utility.CreateCorner(UDim.new(1, 0)),
    })
    if not Config.AccentColor and not Config.Color then
        Utility.RegisterAccent(TimeBar, "BackgroundColor3")
    end

    ToastCard.Position = UDim2.new(1, 30, 0, 0)
    Utility.Tween(ToastCard, { Position = UDim2.new(0, 0, 0, 0) }, 0.2)

    local TimeTween = TweenService:Create(
        TimeBar,
        TweenInfo.new(Duration, Enum.EasingStyle.Linear),
        { Size = UDim2.new(0, 0, 1, 0) }
    )
    TimeTween:Play()

    ToastCard:SetAttribute("DismissTime", tick() + Duration)
    task.spawn(function()
        while ToastCard and ToastCard.Parent do
            local DismissTime = ToastCard:GetAttribute("DismissTime") or (tick() + 1)
            if tick() >= DismissTime then
                break
            end
            task.wait(0.1)
        end
        if ToastCard and ToastCard.Parent then
            local OutAnim = Utility.Tween(ToastCard, { Position = UDim2.new(1, 30, 0, 0) }, 0.2)
            OutAnim.Completed:Connect(function()
                ToastCard:Destroy()
            end)
        end
    end)
end

return Library
