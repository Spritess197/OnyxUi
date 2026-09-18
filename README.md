# Onyx

Simple, dark and fast UI library for Luau / Roblox. Built with clean geometry, low memory footprint, responsive drag/resize and custom micro-interactions.

## Installation

```luau
local Onyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/Spritess197/OnyxUi/refs/heads/main/Onyx.luau"))()
```

## Basic Example

```luau
local Onyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/Spritess197/OnyxUi/refs/heads/main/Onyx.luau"))()

local Window = Onyx:CreateWindow({
    Title = "Onyx Interface",
    Subtitle = "v1.0",
    Size = UDim2.fromOffset(880, 560),
    MaxSize = Vector2.new(1400, 900),
    SidebarWidth = 210,
    TabHeight = 36,
    ToggleKey = Enum.KeyCode.RightShift,
    Minimize = {
        Position = UDim2.new(0, 14, 0, 50),
        Style = "Rectangle",
        Text = "O",
        ShowFps = true,
        ShowPing = true,
    },
})

Window:CreateTab("Main", function(Tab)
    local Left, Right = Tab:AddColumns(2, 8)

    Left:AddSection("Combat", function(Card)
        Card:SetIndicatorStyle("Dot")

        Card:AddToggle({
            Name = "Aimbot",
            Default = false,
            Keybind = Enum.KeyCode.E,
            Color = Color3.fromRGB(59, 130, 246),
            Callback = function(state)
                print("Aimbot state:", state)
            end,
        })

        Card:AddSlider({
            Name = "Smoothness",
            Min = 1,
            Max = 20,
            Default = 8,
            Suffix = "x",
            Callback = function(value)
                print("Smoothness:", value)
            end,
        })
    end)

    Right:AddSection("Settings", function(Card)
        Card:AddKeybind({
            Name = "Windowed / Maximize",
            Default = Enum.KeyCode.K,
            DisallowDuplicates = true,
            OnPress = function()
                Window:Maximize()
            end,
        })

        Card:AddDropdown({
            Name = "Target Part",
            Items = {"Head", "Torso", "HumanoidRootPart"},
            Default = "Head",
            Callback = function(selected)
                print("Target:", selected)
            end,
        })
    end)
end)
```

## API Reference

### CreateWindow

```luau
local Window = Onyx:CreateWindow({
    Title = "Window Title",
    Subtitle = "Optional subtitle",
    Size = UDim2.fromOffset(880, 560),       -- Default size and resize floor
    MaxSize = Vector2.new(1400, 900),        -- Max bounds
    SidebarWidth = 210,
    TabHeight = 36,
    ToggleKey = Enum.KeyCode.RightShift,
    OnClose = function() end,                -- Fires when close button is pressed
    Minimize = {
        Position = UDim2.new(0, 14, 0, 50),
        Style = "Rectangle",                 -- "Rectangle" or "Circle"
        Text = "N",                          -- Widget logo text
        ShowFps = true,
        ShowPing = true,
        ShowDataPing = false,
    },
})
```

Window methods:
- `Window:Maximize()` - toggles windowed / maximized state.
- `Window:Minimize()` - minimizes to floating widget.
- `Window:Restore()` - restores from widget.
- `Window:Toggle()` - toggles minimize / restore.
- `Window:SetTitle(title)` - updates window title.
- `Window:Destroy()` - cleans up maids, instances and connections.

### Tabs and Columns

```luau
Window:CreateTab("Visuals", function(Tab)
    -- Creates responsive columns (count, gapOffset)
    local Col1, Col2 = Tab:AddColumns(2, 8)
end)
```

### Sections (Cards)

```luau
Col1:AddSection("Section Name", function(Card)
    -- Indicator style for row elements: "Dot", "Pill", "Bar"
    Card:SetIndicatorStyle("Dot")
end)
```

### Toggle

Supports standalone toggles, or inline colorpickers and keybinds on the same row.

```luau
Card:AddToggle({
    Name = "Player ESP",
    Default = true,
    -- Optional inline colorpicker
    Color = Color3.fromRGB(255, 60, 60),
    ColorCallback = function(color) end,
    -- Optional inline keybind
    Keybind = Enum.KeyCode.X,
    KeybindCallback = function(key) end,
    Callback = function(state) end,
})
```

### Slider

```luau
Card:AddSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 150,
    Default = 24,
    Step = 1,
    Suffix = " spd",
    Callback = function(val) end,
})
```

### Keybind

Single-key badge with automatic centering and minimum width floor matching `[None]`. Automatically avoids duplicate binds and suppresses the Roblox Escape menu when clearing.

```luau
Card:AddKeybind({
    Name = "Toggle Menu",
    Default = Enum.KeyCode.RightShift,
    DisallowDuplicates = true,
    OnPress = function() end,
    Callback = function(key) end,
})
```

### Dropdown

```luau
Card:AddDropdown({
    Name = "Priority",
    Items = {"Closest", "Lowest HP", "Crosshair"},
    Default = "Closest",
    MultiSelect = false,
    Callback = function(selected) end,
})
```

### Switcher (Segmented Control)

```luau
Card:AddSwitcher({
    Name = "Mode",
    Options = {"Legit", "Rage", "Disabled"},
    Default = "Legit",
    Callback = function(option) end,
})
```

### Colorpicker

```luau
Card:AddColorpicker({
    Name = "Accent Color",
    Default = Color3.fromRGB(59, 130, 246),
    Callback = function(color)
        Onyx:SetAccentColor(color)
    end,
})
```

### Notifications

```luau
Onyx:Notify({
    Title = "Saved",
    Content = "Configuration applied",
    Duration = 3,
    IndicatorStyle = "Pill",
    AccentColor = Color3.fromRGB(40, 200, 64),
})
```

## License

MIT
