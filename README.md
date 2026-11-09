## Installation

```lua
local Ssamachi = loadstring(game:HttpGet("https://raw.githubusercontent.com/yourname/ssamachi/main/Ssamachi.lua"))()
```

## Quick Start

```lua
local Ssamachi = loadstring(game:HttpGet("https://raw.githubusercontent.com/yourname/ssamachi/main/Ssamachi.lua"))()

local Window = Ssamachi:CreateWindow({
    Title = "Ssamachi",
    SubTitle = "v1.0.1",
    Icon = "settings",
    Image = "settings",
    Size = UDim2.fromOffset(600, 480),
    TabWidth = 160,
    ConfigName = "Ssamachi",
    MinimizeKey = Enum.KeyCode.LeftControl,
    Minimizer = false
})

local Tab = Window:AddTab({ Title = "Main", Icon = "home" })
local Section = Tab:AddSection("General", "list")
local SubTab = Tab:AddSubTab("Sub", "list")
```

## API Reference

### `Ssamachi:CreateWindow(Config)`

Creates the main window.

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `SubTitle` | string | `nil` | No |
| `Icon` | string / number | `nil` | No |
| `Image` | string / number | `nil` | No |
| `Size` | UDim2 | `UDim2.fromOffset(600, 480)` | No |
| `TabWidth` | number | `160` | No |
| `ConfigName` | string | `nil` | No |
| `MinimizeKey` | Enum.KeyCode | `Enum.KeyCode.LeftControl` | No |
| `Minimizer` | boolean | `false` | No |

Returns: `Window`

---

### `Window:AddTab(Config)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Icon` | string / number | `nil` | No |

Returns: `Tab`

---

### `Tab:AddSection(Title, Icon)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Icon` | string / number | `nil` | No |

Returns: `Section`

---

### `Tab:AddSubTab(Title, Icon)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Icon` | string / number | `nil` | No |

Returns: `SubTab`

---

### `SubTab:AddSection(Title, Icon)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Icon` | string / number | `nil` | No |

Returns: `Section`

---

### Elements

All elements accept `(Idx, Config)` where `Idx` is a unique identifier used for saving/loading.

#### `Section:AddButton(Idx, Config)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Icon` | string / number | `nil` | No |
| `Callback` | function | `function() end` | No |

```lua
Section:AddButton("Ssamachi", {
    Title = "Click Me",
    Description = "A button",
    Icon = "mouse",
    Callback = function()
        print("clicked")
    end
})
```

---

#### `Section:AddToggle(Idx, Config)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Default` | boolean | `false` | No |
| `Callback` | function | `function(Value) end` | No |

```lua
Section:AddToggle("Ssamachi", {
    Title = "Toggle",
    Description = "Toggles something",
    Default = false,
    Callback = function(Value)
        print(Value)
    end
})
```

---

#### `Section:AddSlider(Idx, Config)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Default` | number | `nil` | Yes |
| `Min` | number | `nil` | Yes |
| `Max` | number | `nil` | Yes |
| `Rounding` | number | `nil` | Yes |
| `Callback` | function | `function(Value) end` | No |

```lua
Section:AddSlider("Ssamachi", {
    Title = "Slider",
    Description = "Slides",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        print(Value)
    end
})
```

---

#### `Section:AddDropdown(Idx, Config)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Values` | table | `nil` | Yes |
| `Default` | string / table | `nil` | No |
| `Multi` | boolean | `false` | No |
| `AllowNull` | boolean | `false` | No |
| `KeepSearch` | boolean | `false` | No |
| `Callback` | function | `function(Value) end` | No |

```lua
Section:AddDropdown("Ssamachi", {
    Title = "Dropdown",
    Description = "Pick one",
    Values = { "One", "Two", "Three" },
    Default = "One",
    Multi = false,
    Callback = function(Value)
        print(Value)
    end
})
```

---

#### `Section:AddKeybind(Idx, Config)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Default` | string | `nil` | Yes |
| `Mode` | string | `"Toggle"` | No |
| `Callback` | function | `function(Value) end` | No |
| `ChangedCallback` | function | `function(New) end` | No |

```lua
Section:AddKeybind("Ssamachi", {
    Title = "Keybind",
    Description = "Bind a key",
    Default = "E",
    Mode = "Toggle",
    Callback = function(Value)
        print(Value)
    end
})
```

---

#### `Section:AddColorpicker(Idx, Config)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Default` | Color3 | `nil` | Yes |
| `Transparency` | number | `0` | No |
| `Callback` | function | `function(Value) end` | No |

```lua
Section:AddColorpicker("Ssamachi", {
    Title = "Color",
    Description = "Pick a color",
    Default = Color3.fromRGB(255, 0, 0),
    Transparency = 0,
    Callback = function(Value)
        print(Value)
    end
})
```

---

#### `Section:AddInput(Idx, Config)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Default` | string | `""` | No |
| `Placeholder` | string | `""` | No |
| `Numeric` | boolean | `false` | No |
| `Finished` | boolean | `false` | No |
| `MaxLength` | number | `nil` | No |
| `Callback` | function | `function(Value) end` | No |

```lua
Section:AddInput("Ssamachi", {
    Title = "Input",
    Description = "Type something",
    Default = "",
    Placeholder = "Enter text",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        print(Value)
    end
})
```

---

#### `Section:AddParagraph(Config)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Content` | string | `""` | No |
| `Icon` | string / number | `nil` | No |

```lua
Section:AddParagraph("Ssamachi", {
    Title = "Info",
    Content = "Some information here"
})
```

---

### `Window:Dialog(Config)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Content` | string | `nil` | Yes |
| `Buttons` | table | `{}` | No |

```lua
Window:Dialog({
    Title = "Confirm",
    Content = "Are you sure?",
    Buttons = {
        { Title = "Yes", Callback = function() print("yes") end },
        { Title = "No", Callback = function() print("no") end }
    }
})
```

---

### `Ssamachi:Notify(Config)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `"Title"` | No |
| `Content` | string | `"Content"` | No |
| `SubContent` | string | `""` | No |
| `Duration` | number | `nil` | No |

```lua
Ssamachi:Notify({
    Title = "Ssamachi",
    Content = "Hello",
    SubContent = "World",
    Duration = 5
})
```

---

### `Ssamachi:SaveConfiguration(Name)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Name` | string | `Window.ConfigName` | No |

Returns: `boolean`

---

### `Ssamachi:LoadConfiguration(Name)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Name` | string | `Window.ConfigName` | No |

Returns: `boolean`

---

### Element Methods

All created elements have access to the following shared methods where applicable:

- `SetTitle(string)`
- `SetDesc(string)`
- `Visible(boolean)`
- `Destroy()`

Element-specific methods:

- **Toggle**: `SetValue(boolean)`, `OnChanged(function)`
- **Slider**: `SetValue(number)`, `OnChanged(function)`
- **Dropdown**: `SetValue(string/table)`, `SetValues(table)`, `OnChanged(function)`
- **Keybind**: `SetValue(string, string)`, `OnChanged(function)`, `OnClick(function)`, `GetState()`
- **Colorpicker**: `SetValue(table, number)`, `SetValueRGB(Color3, number)`, `OnChanged(function)`
- **Input**: `SetValue(string)`, `OnChanged(function)`

---

### Element Ordering

Elements are ordered strictly by creation order. Each `Add*` call assigns an incrementing `LayoutOrder` internally, so the visual order always matches the code order. The same applies to `AddSection`, `AddSubTab`, and `AddTab`.

---

## License

MIT
