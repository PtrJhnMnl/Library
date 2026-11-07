# Ssamachi UI Library Documentation

**Version:** 1.0.1

A modern, animated UI library for Roblox executors (supports Fluent icons, MiniMessage rich text, acrylic-style dark theme, mobile support, config saving, etc.).

## Loading the Library

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/PtrJhnMnl/Library/refs/heads/main/Ssamachi.lua"))() -- or require the module
-- Alternatively after load: getgenv().Ssamachi or Ssamachi
```

The library returns the main `Library` table and also sets `getgenv().Ssamachi = Library` (or global `Ssamachi`).

---

## Creating a Window

```lua
local Window = Library:CreateWindow({
    Title = "My Script",              -- Required. Main window title
    SubTitle = "v1.0",                -- Optional. Shown next to title
    Icon = "home",                    -- Optional. Icon name (Fluent) or rbxassetid:// / http url
    Image = "rbxassetid://123456",    -- Optional. Large image shown above tabs (sidebar)
    Size = UDim2.fromOffset(580, 460),-- Optional. Default is reasonable size
    TabWidth = 160,                   -- Optional. Width of the left tab sidebar
    Search = true,                    -- Optional. Enable search bar in sidebar (default true)
    DropdownsOutsideWindow = false,   -- Optional. Open dropdowns to the right of the window
    MinimizeKey = Enum.KeyCode.LeftControl, -- Optional. Key to toggle minimize
    AutoConfig = "MyConfig",          -- Optional. Auto-save/load config name (uses SaveManager)
})
```

**Notes:**
- Only **one** window can be created.
- Window is automatically centered.
- Supports dragging (title bar) and resizing (bottom-right corner).
- `AutoConfig` enables automatic saving of element values on change and loading on start.

### Window Methods

| Method | Description |
|--------|-------------|
| `Window:AddTab({Title = "...", Icon = "..."})` | Creates and returns a new Tab |
| `Window:SelectTab(index)` | Selects tab by 1-based index |
| `Window:Minimize()` | Toggles window visibility |
| `Window:Destroy()` | Destroys the window |
| `Window:Dialog({Title, Content, Buttons = {{Title, Callback}, ...}})` | Shows a modal dialog |
| `Window:ToggleSearch()` | Toggles the search bar visibility |

---

## Tabs & Sections

```lua
local Tab = Window:AddTab({
    Title = "Main",
    Icon = "settings", -- Optional Fluent icon name or asset
})

-- Direct section on tab
local Section = Tab:AddSection("General", "user") -- Title, optional Icon

-- Or with SubTabs
local SubTab = Tab:AddSubTab("Combat", "sword")
local SubSection = SubTab:AddSection("Aimbot")
```

**Tab Methods:**
- `Tab:AddSection(Title, Icon?)` → returns Section
- `Tab:AddSubTab(Title, Icon?)` → returns SubTab (which also supports `:AddSection`)

**SubTab** works exactly like a Tab for adding sections/elements.

Sections are just visual headers that group elements. Elements are added to the current container (Section / Tab / SubTab).

---

## Elements

All elements are created via the metatable on Section/Tab/SubTab:

```lua
Section:AddButton(...)
Section:AddToggle(...)
Section:AddSlider(...)
-- etc.
```

Most elements accept a common set of options via the `Config` table passed to the constructor, and support:

- `Title` (required for most)
- `Description` / `Content` (optional subtitle)
- `Icon` (optional, Fluent icon name or asset URL)
- `Visible` (optional boolean)

Elements that hold state also support:
- `:SetValue(...)`
- `:OnChanged(function)`
- `:Destroy()`
- `:SetTitle(text)` / `:SetDesc(text)` / `:Visible(bool)`

### 1. Button

```lua
Section:AddButton({
    Title = "Click Me",
    Description = "Does something cool",
    Icon = "mouse-pointer", -- optional
    Callback = function()
        print("Clicked!")
    end
})
```

**Returns:** Element frame (with SetTitle, SetDesc, Visible, Destroy)

No state. Callback fires on click.

---

### 2. Toggle

```lua
local Toggle = Section:AddToggle("MyToggle", {  -- first arg is unique Index (for config saving)
    Title = "Enable Feature",
    Description = "Turns the feature on/off",
    Default = false,
    Callback = function(Value)
        print("Toggled to", Value)
    end
})
```

**Methods:**
- `Toggle:SetValue(boolean)`
- `Toggle:OnChanged(function(value))`
- `Toggle:Destroy()`
- `Toggle.Value` → current boolean

---

### 3. Slider

```lua
local Slider = Section:AddSlider("WalkSpeed", {
    Title = "Walk Speed",
    Description = "Character speed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 0,          -- decimal places
    Callback = function(Value)
        -- apply Value
    end
})
```

**Methods:**
- `Slider:SetValue(number)`
- `Slider:OnChanged(function(value))`
- `Slider:Destroy()`
- `Slider.Value`

Supports dragging the knob and typing the value (hover to reveal input).

---

### 4. Dropdown

```lua
local Dropdown = Section:AddDropdown("Mode", {
    Title = "Select Mode",
    Description = "Choose one",
    Values = {"Option A", "Option B", "Option C"},
    Default = "Option A",          -- string or number (index) or table (for Multi)
    Multi = false,                 -- allow multiple selection
    AllowNull = false,             -- allow clearing selection when Multi
    KeepSearch = false,            -- keep search text after close
    Callback = function(Value)
        -- Value is string (or table of selected when Multi)
    end
})
```

**Methods:**
- `Dropdown:SetValue(val)` / `Dropdown:SetActiveValues(table)`
- `Dropdown:SetValues(newTable)`
- `Dropdown:OnChanged(function(value))`
- `Dropdown:Open()` / `Dropdown:Close()`
- `Dropdown:Destroy()`
- `Dropdown.Value`

Supports search bar inside the dropdown list.

---

### 5. Input (TextBox)

```lua
local Input = Section:AddInput("Username", {
    Title = "Username",
    Description = "Enter your name",
    Default = "",
    Placeholder = "Type here...",
    Numeric = false,       -- only allow numbers
    Finished = false,      -- only fire callback on Enter / focus lost
    MaxLength = nil,       -- optional character limit
    Callback = function(Text)
        print(Text)
    end
})
```

**Methods:**
- `Input:SetValue(string)`
- `Input:OnChanged(function(text))`
- `Input:Destroy()`
- `Input.Value`

---

### 6. Keybind

```lua
local Keybind = Section:AddKeybind("ToggleUI", {
    Title = "Toggle UI",
    Description = "Key to show/hide",
    Default = "LeftControl",
    Mode = "Toggle",       -- "Toggle" | "Hold" | "Always"
    Callback = function(Toggled)
        -- called when activated
    end,
    ChangedCallback = function(NewKey)
        -- called when key is rebound
    end
})
```

**Methods:**
- `Keybind:SetValue(keyName, mode?)`
- `Keybind:GetState()` → boolean (current activation state)
- `Keybind:OnClick(function)` / `Keybind:OnChanged(function)`
- `Keybind:DoClick()`
- `Keybind:Destroy()`

Supports keyboard keys and MouseLeft / MouseRight / MouseMiddle.

---

### 7. Colorpicker

```lua
local Colorpicker = Section:AddColorpicker("ESPColor", {
    Title = "ESP Color",
    Description = "Color of the boxes",
    Default = Color3.fromRGB(255, 0, 0),
    Transparency = 0,              -- 0 = opaque, 1 = fully transparent
    Callback = function(Color)
        -- Color is Color3
    end
})
```

**Methods:**
- `Colorpicker:SetValue({H, S, V}, transparency?)`
- `Colorpicker:SetValueRGB(Color3, transparency?)`
- `Colorpicker:OnChanged(function(color))`
- `Colorpicker:Destroy()`
- `Colorpicker.Value` / `Colorpicker.Transparency`

Opens a full color dialog with HSV map, hue slider, RGB/Hex inputs, and optional alpha.

---

### 8. Paragraph

```lua
Section:AddParagraph({
    Title = "Information",
    Content = "This is a long description that can use <color:#FF0000>MiniMessage</color> tags.",
    Icon = "info"
})
```

Non-interactive text block. Supports rich text via MiniMessage.

---

## Notifications

```lua
Library:Notify({
    Title = "Success",
    Content = "Feature enabled",
    SubContent = "You can now use it",  -- optional smaller text
    Duration = 5                        -- seconds (nil = stays until closed)
})
```

Notifications appear in the bottom-right and can be closed manually.

---

## Minimizer Button

```lua
Library:CreateMinimizer({
    Size = UDim2.fromOffset(40, 40),
    Position = UDim2.new(0, 20, 0, 20),
    Icon = "rbxassetid://10734897102", -- or Fluent name
    Corner = 12,
    Transparency = 0.1,
    Draggable = true,
    Visible = true
})
```

Creates a floating button that toggles `Window:Minimize()`. Useful on mobile.

---

## Themes

Currently only the **Darker** theme is implemented and forced.

```lua
Library:SetTheme("Darker") -- does nothing else; always Darker
```

All colors are defined in the internal `Themes` table (Accent, AcrylicMain, Text, SubText, etc.).

---

## Icons

Uses Fluent icons by default (loaded from remote).

```lua
Library:GetIcon("home")           -- returns asset table or nil
Library:SetIcon(imageLabel, "home") -- applies to an ImageLabel
```

You can also pass raw `"rbxassetid://..."` or `"http..."` strings anywhere an Icon is accepted.

---

## Config Saving (SaveManager)

When you pass `AutoConfig = "ConfigName"` to `CreateWindow`, the library automatically:

1. Creates folder `Ssamachi/`
2. Saves/loads `Ssamachi/ConfigName.json`
3. Saves on every element change (debounced)
4. Loads values after the window is built

Supported types: Toggle, Slider, Dropdown, Colorpicker, Keybind, Input.

You can also use SaveManager manually (advanced):

```lua
-- After setting Library.AutoConfig or calling SaveManager:SetLibrary(Library)
SaveManager:SetFolder("MyFolder")
SaveManager:Save("MyConfig")
SaveManager:Load("MyConfig")
SaveManager:SetIgnoreIndexes({"SomeToggle", "Another"})
```

---

## MiniMessage / Rich Text

Any `Title`, `Description`, `Content`, or notification text supports MiniMessage-style tags that are automatically converted to Roblox RichText:

```
<red>Red text</red>
<#FF5500>Hex color</#FF5500>
<color:#00FF00>Green</color>
<bold>Bold</bold> <italic>Italic</italic>
<underline>Under</underline> <strikethrough>Strike</strikethrough>
<gradient:#FF0000:#00FF00:#0000FF>Rainbow text</gradient>
<br> for newlines
```

Supported color names: black, dark_blue, dark_green, dark_aqua, dark_red, dark_purple, gold, gray, dark_gray, blue, green, aqua, red, light_purple, yellow, white, orange, pink, lime, brown, etc.

---

## Common Patterns

```lua
local Library = loadstring(...)()

local Window = Library:CreateWindow({
    Title = "Example Hub",
    SubTitle = "by Me",
    Icon = "box",
    AutoConfig = "ExampleHub",
})

local Main = Window:AddTab({Title = "Main", Icon = "home"})
local Settings = Window:AddTab({Title = "Settings", Icon = "settings"})

local Sec = Main:AddSection("Player")

Sec:AddToggle("SpeedToggle", {
    Title = "Speed Hack",
    Default = false,
    Callback = function(v)
        -- ...
    end
})

Sec:AddSlider("SpeedValue", {
    Title = "Speed Amount",
    Default = 50,
    Min = 16,
    Max = 200,
    Rounding = 0,
    Callback = function(v) end
})

-- Minimize key is LeftControl by default
Library:CreateMinimizer({Draggable = true})
```

---

## Notes & Limitations

- Designed for exploit environments (`cloneref`, `protectgui`, `gethui`, file system functions, etc.). Studio has stubs.
- Mobile detection automatically adjusts some UI (notifications, minimizer).
- Only one window supported.
- Theme system is currently single-theme (Darker).
- Search filters elements by title, description, and visible text content.
- All animations use a custom Flipper spring/motor system.

---

*Generated for the cleaned Beta.lua / Ssamachi UI Library.*
