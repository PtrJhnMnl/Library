## Installation

```lua
local Ssamachi = loadstring(game:HttpGet("https://raw.githubusercontent.com/PtrJhnMnl/Library/refs/heads/main/Ssamachi.lua"))()
```

## API Reference

### `Ssamachi:CreateWindow(Config)`

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

```lua
local Window = Ssamachi:CreateWindow({ Title = "Ssamachi" })
```

---

### `Window:AddTab(Config)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Icon` | string / number | `nil` | No |

Returns: `Tab`

```lua
local Tab = Window:AddTab({ Title = "Main" })
```

---

### `Tab:AddSection(Title, Icon)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Icon` | string / number | `nil` | No |

Returns: `Section`

```lua
local Section = Tab:AddSection("General")
```

---

### `Tab:AddSubTab(Title, Icon)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Icon` | string / number | `nil` | No |

Returns: `SubTab`

```lua
local SubTab = Tab:AddSubTab("Sub")
```

---

### `SubTab:AddSection(Title, Icon)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Icon` | string / number | `nil` | No |

Returns: `Section`

```lua
local SubSection = SubTab:AddSection("Sub General")
```

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
Section:AddButton("Ssamachi", { Title = "Click Me" })
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
Section:AddToggle("Ssamachi", { Title = "Toggle" })
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
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 1
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
    Values = { "One", "Two", "Three" }
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
    Default = "E"
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
    Default = Color3.fromRGB(255, 0, 0)
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
Section:AddInput("Ssamachi", { Title = "Input" })
```

---

#### `Section:AddParagraph(Config)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Content` | string | `""` | No |
| `Icon` | string / number | `nil` | No |

```lua
Section:AddParagraph("Ssamachi", { Title = "Info" })
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
Ssamachi:Notify({ Title = "Ssamachi" })
```

---

### `Ssamachi:SaveConfiguration(Name)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Name` | string | `Window.ConfigName` | No |

Returns: `boolean`

```lua
Ssamachi:SaveConfiguration()
```

---

### `Ssamachi:LoadConfiguration(Name)`

| Arg | Type | Default | Required |
|---|---|---|---|
| `Name` | string | `Window.ConfigName` | No |

Returns: `boolean`

```lua
Ssamachi:LoadConfiguration()
```

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
