# OnyxUI 🪨

> **OnyxUI** is a modern, senior-engineered, macOS-inspired UI library for Luau / Roblox. Crafted with strict minimalism, pixel-perfect geometry, responsive controls, and high-performance micro-interactions.

---

## ✨ Features

- **macOS Sequoia Window Frame**:
  - Interactive traffic lights (Close, Minimize, Maximize/Windowed).
  - Native window dragging with drag un-maximize (standard macOS behavior).
  - Bottom-right corner resize handle (`ResizeGrip`) with configurable constraints.
  - Floor size clamped to default window dimensions (`DefaultSize`).
  - Minimized floating widget with live FPS and Network/Data ping statistics.
- **Rich Control Suite**:
  - **Toggles**: Smooth animations, supporting inline Colorpickers and inline Keybind badges.
  - **Sliders**: Drag & manual numeric text entry, custom formatting & suffix support.
  - **Dropdowns**: Popups with automated z-index management, single and multi-selection.
  - **Keybinds**: Single-key badges with `[None]` minimum floor sizing, dead-center text alignment, automatic key conflict prevention (`DisallowDuplicates`), and Roblox Escape menu suppression.
  - **Colorpickers**: Inline and standalone HSV palette, RGB text inputs, and real-time accent binding.
  - **Switchers (Segmented Controls)**: iOS/macOS-styled segmented buttons with sliding selector.
  - **Buttons & Input Boxes**: Modern styled text inputs and action buttons with responsive hover tweens.
  - **Notifications (Toasts)**: Non-intrusive floating toasts with progress duration bar, custom accent colors, and multiple indicator styles (`Pill`, `Dot`, `Bar`).

---

## 🚀 Quick Start

### Direct Loadstring (from GitHub)
```luau
local OnyxUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/<YourUsername>/OnyxUI/main/OnyxUI.luau"))()

local Window = OnyxUI:CreateWindow({
    Title = "OnyxUI Application",
    Subtitle = "macOS Sequoia Edition",
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
```

---

## 📖 API Documentation

### 1. Window Creation
```luau
local Window = OnyxUI:CreateWindow({
    Title = string,
    Subtitle = string?,
    Size = UDim2?,              -- Default: UDim2.fromOffset(880, 560)
    MaxSize = Vector2?,         -- Default: Vector2.new(1500, 1000)
    SidebarWidth = number?,     -- Default: 210
    TabHeight = number?,        -- Default: 36
    ToggleKey = Enum.KeyCode?,  -- Default: Enum.KeyCode.RightShift
    OnClose = (() -> ())?,      -- Callback when close traffic light button is clicked
    Minimize = {
        Position = UDim2?,
        Style = "Rectangle" | "Circle",
        Text = string?,
        ShowFps = boolean?,
        ShowPing = boolean?,
    }
})
```

### 2. Creating Tabs & Columns
```luau
Window:CreateTab("Combat", function(CombatTab)
    -- Dual column layout (2 columns with 8px gap)
    local LeftColumn, RightColumn = CombatTab:AddColumns(2, 8)

    LeftColumn:AddSection("Aimbot Settings", function(Card)
        Card:SetIndicatorStyle("Dot") -- "Dot", "Pill", "Bar"

        Card:AddToggle({
            Name = "Enable Aimbot",
            Default = false,
            Callback = function(Value: boolean)
                print("Aimbot:", Value)
            end,
        })
    end)
end)
```

### 3. Controls Reference

#### Toggle with Inline Keybind & Colorpicker
```luau
Card:AddToggle({
    Name = "Visual ESP",
    Default = true,
    Color = Color3.fromRGB(59, 130, 246),
    ColorCallback = function(NewColor: Color3)
        print("ESP Color:", NewColor)
    end,
    Keybind = Enum.KeyCode.V,
    KeybindCallback = function(Key: Enum.KeyCode)
        print("ESP Keybind:", Key)
    end,
    Callback = function(State: boolean)
        print("ESP Toggled:", State)
    end,
})
```

#### Slider
```luau
Card:AddSlider({
    Name = "Field of View",
    Min = 30,
    Max = 120,
    Default = 90,
    Step = 1,
    Suffix = "°",
    Callback = function(Value: number)
        print("FOV:", Value)
    end,
})
```

#### Keybind
```luau
Card:AddKeybind({
    Name = "Maximize / Windowed",
    Default = Enum.KeyCode.K,
    DisallowDuplicates = true,
    OnPress = function()
        Window:Maximize()
    end,
})
```

#### Dropdown
```luau
Card:AddDropdown({
    Name = "Target Hitbox",
    Items = { "Head", "Torso", "HumanoidRootPart" },
    Default = "Head",
    MultiSelect = false,
    Callback = function(Selected: string)
        print("Hitbox:", Selected)
    end,
})
```

#### Switcher (Segmented)
```luau
Card:AddSwitcher({
    Name = "ESP Mode",
    Options = { "Smart ESP", "Manual ESP", "Off" },
    Default = "Smart ESP",
    Callback = function(Selected: string)
        print("Selected mode:", Selected)
    end,
})
```

#### Notifications (Toast)
```luau
OnyxUI:Notify({
    Title = "Configuration Loaded",
    Content = "Settings synchronized successfully.",
    Duration = 3.5,
    IndicatorStyle = "Pill",
    AccentColor = Color3.fromRGB(40, 200, 64),
})
```

---

## 🛠️ Repository Structure

```
├── OnyxUI.luau          # Standalone compiled library
├── Showcase.luau        # Full demo showcasing all features & controls
└── README.md            # Documentation & usage guide
```

---

## 📄 License
MIT License. Free for open-source and personal use.
