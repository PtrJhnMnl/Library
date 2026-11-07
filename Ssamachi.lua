local CloneRef = cloneref or function(Object)
    return Object
end

local UserInputService = CloneRef(game:GetService("UserInputService"))
local TweenService = CloneRef(game:GetService("TweenService"))
local TextService = CloneRef(game:GetService("TextService"))
local HttpService = CloneRef(game:GetService("HttpService"))
local RunService = CloneRef(game:GetService("RunService"))
local Workspace = CloneRef(game:GetService("Workspace"))
local CoreGui = CloneRef(game:GetService("CoreGui"))
local Players = CloneRef(game:GetService("Players"))

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = CloneRef(LocalPlayer:GetMouse())

local Icons = loadstring(game:HttpGet("https://molto.pages.dev/source.lua"))()
Icons.SetProvider("fluent")

local Mobile = not RunService:IsStudio()
    and table.find({ Enum.Platform.IOS, Enum.Platform.Android }, UserInputService:GetPlatform()) ~= nil

local RenderStepped = RunService.RenderStepped
local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local Themes = {
    Name = "Darker",
    Accent = Color3.fromRGB(56, 109, 223),
    AcrylicMain = Color3.fromRGB(30, 30, 30),
    AcrylicBorder = Color3.fromRGB(60, 60, 60),
    TitleBarLine = Color3.fromRGB(65, 65, 65),
    Tab = Color3.fromRGB(100, 100, 100),
    Element = Color3.fromRGB(70, 70, 70),
    ElementBorder = Color3.fromRGB(25, 25, 25),
    InElementBorder = Color3.fromRGB(55, 55, 55),
    ElementTransparency = 0.82,
    ToggleSlider = Color3.fromRGB(120, 120, 120),
    ToggleToggled = Color3.fromRGB(42, 42, 42),
    SliderRail = Color3.fromRGB(120, 120, 120),
    DropdownFrame = Color3.fromRGB(120, 120, 120),
    DropdownHolder = Color3.fromRGB(35, 35, 35),
    DropdownBorder = Color3.fromRGB(25, 25, 25),
    DropdownOption = Color3.fromRGB(120, 120, 120),
    Keybind = Color3.fromRGB(120, 120, 120),
    Input = Color3.fromRGB(160, 160, 160),
    InputIndicator = Color3.fromRGB(150, 150, 150),
    InputIndicatorFocus = Color3.fromRGB(56, 109, 223),
    Dialog = Color3.fromRGB(35, 35, 35),
    DialogHolder = Color3.fromRGB(25, 25, 25),
    DialogHolderLine = Color3.fromRGB(20, 20, 20),
    DialogButton = Color3.fromRGB(35, 35, 35),
    DialogButtonBorder = Color3.fromRGB(55, 55, 55),
    DialogBorder = Color3.fromRGB(50, 50, 50),
    DialogInput = Color3.fromRGB(45, 45, 45),
    DialogInputLine = Color3.fromRGB(120, 120, 120),
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(170, 170, 170),
    Hover = Color3.fromRGB(120, 120, 120),
    HoverChange = 0.07,
}

local Library = {
    Version = "1.0.1",
    OpenFrames = {},
    Options = {},
    Themes = { "Darker" },
    Windows = {},
    Window = nil,
    Creator = nil,
    DialogOpen = false,
    MinimizeKeybind = nil,
    MinimizeKey = Enum.KeyCode.LeftControl,
    ElementsReady = false,
    LoadingConfig = false,
    SettingLoaded = false,
    Minimizer = nil,
}

local function IsMotor(Value)
    local MotorType = tostring(Value):match("^Motor%((.+)%)$")

    if MotorType then
        return true, MotorType
    end

    return false
end

local Connection = {}
Connection.__index = Connection

function Connection.New(Signal, Handler)
    return setmetatable({
        Signal = Signal,
        Connected = true,
        Handler = Handler,
    }, Connection)
end

function Connection:Disconnect()
    if self.Connected then
        self.Connected = false

        for Index, Conn in self.Signal._connections do
            if Conn == self then
                table.remove(self.Signal._connections, Index)
                return
            end
        end
    end
end

local Signal = {}
Signal.__index = Signal

function Signal.New()
    return setmetatable({
        _connections = {},
        _threads = {},
    }, Signal)
end

function Signal:Fire(...)
    for _, Conn in self._connections do
        Conn.Handler(...)
    end

    for _, Thread in self._threads do
        coroutine.resume(Thread, ...)
    end

    self._threads = {}
end

function Signal:Connect(Handler)
    local Conn = Connection.New(self, Handler)

    table.insert(self._connections, Conn)

    return Conn
end

function Signal:Wait()
    table.insert(self._threads, coroutine.running())

    return coroutine.yield()
end

local Linear = {}
Linear.__index = Linear

function Linear.New(TargetValue, Options)
    assert(TargetValue, "Missing argument #1: TargetValue")

    Options = Options or {}

    return setmetatable({
        _targetValue = TargetValue,
        _velocity = Options.velocity or 1,
    }, Linear)
end

function Linear:Step(State, Dt)
    local Position = State.value
    local Velocity = self._velocity
    local Goal = self._targetValue
    local DPos = Dt * Velocity
    local Complete = DPos >= math.abs(Goal - Position)

    Position = Position + DPos * (Goal > Position and 1 or -1)

    if Complete then
        Position = self._targetValue
        Velocity = 0
    end

    return {
        complete = Complete,
        value = Position,
        velocity = Velocity,
    }
end

local Instant = {}
Instant.__index = Instant

function Instant.New(TargetValue)
    return setmetatable({
        _targetValue = TargetValue,
    }, Instant)
end

function Instant:Step()
    return {
        complete = true,
        value = self._targetValue,
    }
end

local VELOCITY_THRESHOLD = 0.001
local POSITION_THRESHOLD = 0.001
local EPS = 0.0001

local Spring = {}
Spring.__index = Spring

function Spring.New(TargetValue, Options)
    assert(TargetValue, "Missing argument #1: TargetValue")

    Options = Options or {}

    return setmetatable({
        _targetValue = TargetValue,
        _frequency = Options.frequency or 4,
        _dampingRatio = Options.dampingRatio or 1,
    }, Spring)
end

function Spring:Step(State, Dt)
    local D = self._dampingRatio
    local F = self._frequency * 2 * math.pi
    local G = self._targetValue
    local P0 = State.value
    local V0 = State.velocity or 0
    local Offset = P0 - G
    local Decay = math.exp(-D * F * Dt)

    local P1, V1

    if D == 1 then
        P1 = (Offset * (1 + F * Dt) + V0 * Dt) * Decay + G
        V1 = (V0 * (1 - F * Dt) - Offset * (F * F * Dt)) * Decay
    elseif D < 1 then
        local C = math.sqrt(1 - D * D)
        local I = math.cos(F * C * Dt)
        local J = math.sin(F * C * Dt)

        local Z

        if C > EPS then
            Z = J / C
        else
            local A = Dt * F
            Z = A + ((A * A) * (C * C) * (C * C) / 20 - C * C) * (A * A * A) / 6
        end

        local Y

        if F * C > EPS then
            Y = J / (F * C)
        else
            local B = F * C
            Y = Dt + ((Dt * Dt) * (B * B) * (B * B) / 20 - B * B) * (Dt * Dt * Dt) / 6
        end

        P1 = (Offset * (I + D * Z) + V0 * Y) * Decay + G
        V1 = (V0 * (I - Z * D) - Offset * (Z * F)) * Decay
    else
        local C = math.sqrt(D * D - 1)
        local R1 = -F * (D - C)
        local R2 = -F * (D + C)
        local Co2 = (V0 - Offset * R1) / (2 * F * C)
        local Co1 = Offset - Co2
        local E1 = Co1 * math.exp(R1 * Dt)
        local E2 = Co2 * math.exp(R2 * Dt)

        P1 = E1 + E2 + G
        V1 = E1 * R1 + E2 * R2
    end

    local Complete = math.abs(V1) < VELOCITY_THRESHOLD and math.abs(P1 - G) < POSITION_THRESHOLD

    return {
        complete = Complete,
        value = Complete and G or P1,
        velocity = V1,
    }
end

local Noop = function() end

local BaseMotor = {}
BaseMotor.__index = BaseMotor

function BaseMotor.New()
    return setmetatable({
        _onStep = Signal.New(),
        _onStart = Signal.New(),
        _onComplete = Signal.New(),
    }, BaseMotor)
end

function BaseMotor:OnStep(Handler)
    return self._onStep:Connect(Handler)
end

function BaseMotor:OnStart(Handler)
    return self._onStart:Connect(Handler)
end

function BaseMotor:OnComplete(Handler)
    return self._onComplete:Connect(Handler)
end

function BaseMotor:Start()
    if not self._connection then
        self._connection = RunService.RenderStepped:Connect(function(DeltaTime)
            self:Step(DeltaTime)
        end)
    end
end

function BaseMotor:Stop()
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
end

BaseMotor.Destroy = BaseMotor.Stop
BaseMotor.Step = Noop
BaseMotor.GetValue = Noop
BaseMotor.SetGoal = Noop

function BaseMotor:__tostring()
    return "Motor"
end

local SingleMotor = setmetatable({}, BaseMotor)
SingleMotor.__index = SingleMotor

function SingleMotor.New(InitialValue, UseImplicitConnections)
    assert(InitialValue, "Missing argument #1: InitialValue")
    assert(typeof(InitialValue) == "number", "InitialValue must be a number!")

    local Self = setmetatable(BaseMotor.New(), SingleMotor)

    if UseImplicitConnections ~= nil then
        Self._useImplicitConnections = UseImplicitConnections
    else
        Self._useImplicitConnections = true
    end

    Self._goal = nil
    Self._state = {
        complete = true,
        value = InitialValue,
    }

    return Self
end

function SingleMotor:Step(DeltaTime)
    if self._state.complete then
        return true
    end

    local NewState = self._goal:Step(self._state, DeltaTime)

    self._state = NewState

    self._onStep:Fire(NewState.value)

    if NewState.complete then
        if self._useImplicitConnections then
            self:Stop()
        end

        self._onComplete:Fire()
    end

    return NewState.complete
end

function SingleMotor:GetValue()
    return self._state.value
end

function SingleMotor:SetGoal(Goal)
    self._state.complete = false
    self._goal = Goal

    self._onStart:Fire()

    if self._useImplicitConnections then
        self:Start()
    end
end

function SingleMotor:__tostring()
    return "Motor(Single)"
end

local GroupMotor = setmetatable({}, BaseMotor)
GroupMotor.__index = GroupMotor

local function ToMotor(Value)
    if IsMotor(Value) then
        return Value
    end

    local ValueType = typeof(Value)

    if ValueType == "number" then
        return SingleMotor.New(Value, false)
    elseif ValueType == "table" then
        return GroupMotor.New(Value, false)
    end

    error(("Unable to convert %q to motor; type %s is unsupported"):format(Value, ValueType), 2)
end

function GroupMotor.New(InitialValues, UseImplicitConnections)
    assert(InitialValues, "Missing argument #1: InitialValues")
    assert(typeof(InitialValues) == "table", "InitialValues must be a table!")
    assert(not InitialValues.step, 'InitialValues contains disallowed property "step".')

    local Self = setmetatable(BaseMotor.New(), GroupMotor)

    if UseImplicitConnections ~= nil then
        Self._useImplicitConnections = UseImplicitConnections
    else
        Self._useImplicitConnections = true
    end

    Self._complete = true
    Self._motors = {}

    for Key, Value in InitialValues do
        Self._motors[Key] = ToMotor(Value)
    end

    return Self
end

function GroupMotor:Step(DeltaTime)
    if self._complete then
        return true
    end

    local AllComplete = true

    for _, Motor in self._motors do
        local Complete = Motor:Step(DeltaTime)

        if not Complete then
            AllComplete = false
        end
    end

    self._onStep:Fire(self:GetValue())

    if AllComplete then
        if self._useImplicitConnections then
            self:Stop()
        end

        self._complete = true

        self._onComplete:Fire()
    end

    return AllComplete
end

function GroupMotor:SetGoal(Goals)
    assert(not Goals.step, 'Goals contains disallowed property "step".')

    self._complete = false

    self._onStart:Fire()

    for Key, Goal in Goals do
        local Motor = assert(self._motors[Key], ("Unknown motor for key %s"):format(Key))

        Motor:SetGoal(Goal)
    end

    if self._useImplicitConnections then
        self:Start()
    end
end

function GroupMotor:GetValue()
    local Values = {}

    for Key, Motor in self._motors do
        Values[Key] = Motor:GetValue()
    end

    return Values
end

function GroupMotor:__tostring()
    return "Motor(Group)"
end

local Flipper = {
    SingleMotor = SingleMotor,
    GroupMotor = GroupMotor,
    Instant = Instant,
    Linear = Linear,
    Spring = Spring,
    IsMotor = IsMotor,
}

local Creator = {
    Registry = {},
    Signals = {},
    TransparencyMotors = {},
    DefaultProperties = {
        ScreenGui = {
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        },
        Frame = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
        },
        ScrollingFrame = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            ScrollBarImageColor3 = Color3.new(0, 0, 0),
        },
        TextLabel = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            Font = Enum.Font.SourceSans,
            Text = "",
            TextColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            TextSize = 14,
        },
        TextButton = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            AutoButtonColor = false,
            Font = Enum.Font.SourceSans,
            Text = "",
            TextColor3 = Color3.new(0, 0, 0),
            TextSize = 14,
        },
        TextBox = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            ClearTextOnFocus = false,
            Font = Enum.Font.SourceSans,
            Text = "",
            TextColor3 = Color3.new(0, 0, 0),
            TextSize = 14,
        },
        ImageLabel = {
            BackgroundTransparency = 1,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
        },
        ImageButton = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            AutoButtonColor = false,
        },
        CanvasGroup = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
        },
    },
}

function Creator.AddSignal(SignalObj, Function)
    local Connected = SignalObj:Connect(Function)

    table.insert(Creator.Signals, Connected)

    return Connected
end

function Creator.Disconnect()
    for Idx = #Creator.Signals, 1, -1 do
        local ConnectionObj = table.remove(Creator.Signals, Idx)

        if ConnectionObj.Disconnect then
            ConnectionObj:Disconnect()
        end
    end
end

Creator.Themes = Themes
Creator.Theme = "Darker"

function Creator.GetThemeProperty(Property)
    return Themes[Property]
end

function Creator.UpdateTheme()
    Creator.Theme = "Darker"

    for Instance, Object in Creator.Registry do
        for Property, ColorIdx in Object.Properties do
            local ThemeValue = Creator.GetThemeProperty(ColorIdx)

            if ThemeValue then
                Instance[Property] = ThemeValue
            end
        end
    end

    local Transparency = Creator.GetThemeProperty("ElementTransparency")

    if Transparency then
        for _, Motor in Creator.TransparencyMotors do
            Motor:SetGoal(Flipper.Instant.New(Transparency))
        end
    end
end

function Creator.AddThemeObject(Object, Properties)
    local Idx = #Creator.Registry + 1
    local Data = {
        Object = Object,
        Properties = Properties,
        Idx = Idx,
    }

    Creator.Registry[Object] = Data

    Creator.UpdateTheme()

    return Object
end

function Creator.OverrideTag(Object, Properties)
    Creator.Registry[Object].Properties = Properties

    Creator.UpdateTheme()
end

function Creator.New(Name, Properties, Children)
    local Object = Instance.new(Name)

    for PropName, Value in Creator.DefaultProperties[Name] or {} do
        Object[PropName] = Value
    end

    for PropName, Value in Properties or {} do
        if PropName ~= "ThemeTag" then
            Object[PropName] = Value
        end
    end

    for _, Child in Children or {} do
        Child.Parent = Object
    end

    if Properties and Properties.ThemeTag then
        Creator.AddThemeObject(Object, Properties.ThemeTag)
    end

    return Object
end

function Creator.SpringMotor(Initial, Instance, Prop, IgnoreDialogCheck, ResetOnThemeChange)
    IgnoreDialogCheck = IgnoreDialogCheck or false
    ResetOnThemeChange = ResetOnThemeChange or false

    local Motor = Flipper.SingleMotor.New(Initial)

    Motor:OnStep(function(Value)
        pcall(function()
            Instance[Prop] = Value
        end)
    end)

    if ResetOnThemeChange then
        table.insert(Creator.TransparencyMotors, Motor)
    end

    local function SetValue(Value, Ignore)
        Ignore = Ignore or false

        if not IgnoreDialogCheck then
            if not Ignore then
                if Prop == "BackgroundTransparency" and Library.DialogOpen then
                    return
                end
            end
        end

        Motor:SetGoal(Flipper.Spring.New(Value, { frequency = 8 }))
    end

    return Motor, SetValue
end

Library.Creator = Creator

local New = Creator.New

local ParentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local GUI = New("ScreenGui", {
    Parent = ParentGui,
})

Library.GUI = GUI

ProtectGui(GUI)

function Library:SafeCallback(Function, ...)
    if not Function then
        return
    end

    local Success, Event = pcall(Function, ...)

    if not Success then
        local _, I = Event:find(":%d+: ")

        if not I then
            return Library:Notify({
                Title = "Interface",
                Content = "Callback error",
                SubContent = Event,
                Duration = 5,
            })
        end

        return Library:Notify({
            Title = "Interface",
            Content = "Callback error",
            SubContent = Event:sub(I + 1),
            Duration = 5,
        })
    end
end

function Library:Round(Number, Factor)
    if Factor == 0 then
        return math.floor(Number)
    end

    Number = tostring(Number)

    return Number:find("%.") and tonumber(Number:sub(1, Number:find("%.") + Factor)) or Number
end

function Library:GetIcon(Name)
    if not Name then
        return nil
    end

    if type(Name) == "number" then
        return "rbxassetid://" .. Name
    end

    if type(Name) ~= "string" or Name == "" then
        return nil
    end

    if Name:find("^rbxasset") or Name:find("^http") then
        return Name
    end

    local Success, Asset = pcall(function()
        return Icons.GetAsset(tostring(Name))
    end)

    if Success and Asset and Asset.Url then
        return Asset.Url
    end

    return nil
end

function Library:ApplyIcon(Instance, Name)
    if not Instance or not Name then
        return
    end

    if type(Name) == "number" then
        Instance.Image = "rbxassetid://" .. Name
        Instance.ImageRectSize = Vector2.zero
        Instance.ImageRectOffset = Vector2.zero
        return
    end

    if type(Name) == "string" and (Name:find("^rbxasset") or Name:find("^http")) then
        Instance.Image = Name
        Instance.ImageRectSize = Vector2.zero
        Instance.ImageRectOffset = Vector2.zero
        return
    end

    local Success, Asset = pcall(function()
        return Icons.GetAsset(tostring(Name))
    end)

    if Success and Asset and Asset.Url then
        Instance.Image = Asset.Url
        Instance.ImageRectSize = Asset.ImageRectSize or Vector2.zero
        Instance.ImageRectOffset = Asset.ImageRectOffset or Vector2.zero
    end
end

local Components = {}

Components.Element = (function()
    local Spring = Flipper.Spring.New

    return function(Title, Desc, Parent, Hover, Options)
        local Element = {}
        Options = Options or {}

        Element.TitleLabel = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
            Text = Title,
            TextColor3 = Color3.fromRGB(240, 240, 240),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            LayoutOrder = 2,
            ThemeTag = {
                TextColor3 = "Text",
            },
        })

        Element.Header = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
        }, {
            New("UIListLayout", {
                Padding = UDim.new(0, 5),
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),
        })

        if Options and Options.Icon then
            Element.IconImage = New("ImageLabel", {
                Size = UDim2.fromOffset(16, 16),
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                ThemeTag = {
                    ImageColor3 = "Text",
                },
            })

            Library:ApplyIcon(Element.IconImage, Options.Icon)

            Element.IconImage.Parent = Element.Header
        end

        Element.TitleLabel.Parent = Element.Header

        Element.DescLabel = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = Desc,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            ThemeTag = {
                TextColor3 = "SubText",
            },
        })

        Element.LabelHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -28, 0, 0),
        }, {
            New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 13),
                PaddingTop = UDim.new(0, 13),
            }),
            Element.Header,
            Element.DescLabel,
        })

        Element.Border = New("UIStroke", {
            Transparency = 0.5,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = Color3.fromRGB(0, 0, 0),
            ThemeTag = {
                Color = "ElementBorder",
            },
        })

        Element.Frame = New("TextButton", {
            Visible = Options.Visible and Options.Visible or true,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 0.89,
            BackgroundColor3 = Color3.fromRGB(130, 130, 130),
            Parent = Parent,
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            LayoutOrder = 7,
            ThemeTag = {
                BackgroundColor3 = "Element",
                BackgroundTransparency = "ElementTransparency",
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),
            Element.Border,
            Element.LabelHolder,
        })

        function Element:SetTitle(Set)
            Element.TitleLabel.Text = Set

            local HasTitle = (Set ~= nil and Set ~= "")

            Element.Header.Visible = HasTitle

            if not HasTitle then
                if Element.IconImage then
                    if not Element.DescRow then
                        Element.DescRow = New("Frame", {
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 14),
                            LayoutOrder = 2,
                        }, {
                            New("UIListLayout", {
                                Padding = UDim.new(0, 5),
                                FillDirection = Enum.FillDirection.Horizontal,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                            }),
                        })

                        Element.DescRow.Parent = Element.LabelHolder
                    end

                    if not Element.DescIconImage then
                        Element.DescIconImage = New("ImageLabel", {
                            Image = Element.IconImage.Image,
                            ImageRectSize = Element.IconImage.ImageRectSize,
                            ImageRectOffset = Element.IconImage.ImageRectOffset,
                            Size = UDim2.fromOffset(16, 16),
                            BackgroundTransparency = 1,
                            LayoutOrder = 1,
                            ThemeTag = {
                                ImageColor3 = "Text",
                            },
                        })

                        Element.DescIconImage.Parent = Element.DescRow
                    else
                        Element.DescIconImage.Image = Element.IconImage.Image
                        Element.DescIconImage.ImageRectSize = Element.IconImage.ImageRectSize
                        Element.DescIconImage.ImageRectOffset = Element.IconImage.ImageRectOffset
                        Element.DescIconImage.Parent = Element.DescRow
                    end

                    Element.DescLabel.Parent = Element.DescRow
                    Element.DescLabel.LayoutOrder = 2
                    Element.DescLabel.Size = UDim2.new(1, -24, 0, 14)
                else
                    if Element.DescRow then
                        Element.DescRow:Destroy()
                        Element.DescRow = nil
                        Element.DescIconImage = nil
                    end

                    Element.DescLabel.Parent = Element.LabelHolder
                    Element.DescLabel.LayoutOrder = 2
                    Element.DescLabel.Size = UDim2.new(1, 0, 0, 14)
                end
            else
                if Element.DescRow then
                    Element.DescRow:Destroy()
                    Element.DescRow = nil
                    Element.DescIconImage = nil
                end

                Element.DescLabel.Parent = Element.LabelHolder
                Element.DescLabel.LayoutOrder = 2
                Element.DescLabel.Size = UDim2.new(1, 0, 0, 14)
            end

            if Library.Window and Library.Window.AllElements and Library.Window.AllElements[Element.Frame] then
                Library.Window.AllElements[Element.Frame].title = Set
            end
        end

        function Element:Visible(Bool)
            Element.Frame.Visible = Bool
        end

        function Element:SetDesc(Set)
            if Set == nil then
                Set = ""
            end

            if Set == "" then
                Element.DescLabel.Visible = false
            else
                Element.DescLabel.Visible = true
            end

            Element.DescLabel.Text = Set

            if Library.Window and Library.Window.AllElements and Library.Window.AllElements[Element.Frame] then
                Library.Window.AllElements[Element.Frame].description = Set
            end
        end

        function Element:GetTitle()
            return Element.TitleLabel.Text
        end

        function Element:GetDesc()
            return Element.DescLabel.Text
        end

        function Element:Destroy()
            Element.Frame:Destroy()
        end

        Element.Header.Visible = not (Title == nil or Title == "")

        Element:SetTitle(Title or "")
        Element:SetDesc(Desc)

        if Library.Window and Library.Window.RegisterElement then
            Library.Window.RegisterElement(Element.Frame, Title, "Element", Desc)
        end

        if Hover then
            local Motor, SetTransparency = Creator.SpringMotor(
                Creator.GetThemeProperty("ElementTransparency"),
                Element.Frame,
                "BackgroundTransparency",
                false,
                true
            )

            Creator.AddSignal(Element.Frame.MouseEnter, function()
                SetTransparency(Creator.GetThemeProperty("ElementTransparency") - Creator.GetThemeProperty("HoverChange"))
            end)

            Creator.AddSignal(Element.Frame.MouseLeave, function()
                SetTransparency(Creator.GetThemeProperty("ElementTransparency"))
            end)

            Creator.AddSignal(Element.Frame.MouseButton1Down, function()
                SetTransparency(Creator.GetThemeProperty("ElementTransparency") + Creator.GetThemeProperty("HoverChange"))
            end)

            Creator.AddSignal(Element.Frame.MouseButton1Up, function()
                SetTransparency(Creator.GetThemeProperty("ElementTransparency") - Creator.GetThemeProperty("HoverChange"))
            end)
        end

        return Element
    end
end)()

Components.Section = (function()
    return function(Title, Parent, Icon)
        local Section = {}

        Section.Layout = New("UIListLayout", {
            Padding = UDim.new(0, 5),
        })

        Section.Container = New("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            Position = UDim2.fromOffset(0, 24),
            BackgroundTransparency = 1,
        }, {
            Section.Layout,
        })

        local SectionIconLabel = Icon and New("ImageLabel", {
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            ThemeTag = {
                ImageColor3 = "Text",
            },
        }) or nil

        if SectionIconLabel then
            Library:ApplyIcon(SectionIconLabel, Icon)
        end

        local SectionHeader = New("Frame", {
            Size = UDim2.new(1, -16, 0, 18),
            Position = UDim2.fromOffset(0, 2),
            BackgroundTransparency = 1,
        }, {
            New("UIListLayout", {
                Padding = UDim.new(0, 5),
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),
            SectionIconLabel,
            New("TextLabel", {
                RichText = true,
                Text = Title,
                TextTransparency = 0,
                FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                TextSize = 18,
                TextXAlignment = "Left",
                TextYAlignment = "Center",
                Size = UDim2.fromScale(0, 1),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                ThemeTag = {
                    TextColor3 = "Text",
                },
            }),
        })

        Section.Root = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 26),
            LayoutOrder = 7,
            Parent = Parent,
        }, {
            SectionHeader,
            Section.Container,
        })

        Creator.AddSignal(Section.Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Section.Container.Size = UDim2.new(1, 0, 0, Section.Layout.AbsoluteContentSize.Y)
            Section.Root.Size = UDim2.new(1, 0, 0, Section.Layout.AbsoluteContentSize.Y + 30)
        end)

        if Library.Window and Library.Window.RegisterElement then
            Library.Window.RegisterElement(Section.Root, Title, "Section")
        end

        if Library.AttachElementMethods then
            Library.AttachElementMethods(Section)
        end

        return Section
    end
end)()

Components.Tab = (function()
    local Spring = Flipper.Spring.New
    local Instant = Flipper.Instant.New

    local TabModule = {
        Window = nil,
        Tabs = {},
        Containers = {},
        SelectedTab = 0,
        TabCount = 0,
        AnimationTask = nil,
        CurrentAnimationTab = 0,
    }

    function TabModule:Init(Window)
        TabModule.Window = Window

        return TabModule
    end

    function TabModule:GetCurrentTabPos()
        local TabHolderPos = TabModule.Window.TabHolder.AbsolutePosition.Y
        local TabPos = TabModule.Tabs[TabModule.SelectedTab].Frame.AbsolutePosition.Y

        return TabPos - TabHolderPos
    end

    function TabModule:New(Title, Icon, Parent)
        local Window = TabModule.Window

        TabModule.TabCount = TabModule.TabCount + 1

        local TabIndex = TabModule.TabCount

        local Tab = {
            Selected = false,
            Name = Title,
            Type = "Tab",
        }

        local HasIcon = Icon ~= nil and Icon ~= ""

        local TabIconLabel = HasIcon and New("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(0, 8, 0.5, 0),
            BackgroundTransparency = 1,
            ZIndex = 11,
            ThemeTag = {
                ImageColor3 = "Text",
            },
        }) or nil

        if TabIconLabel then
            Library:ApplyIcon(TabIconLabel, Icon)
        end

        Tab.Frame = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 0.92,
            Parent = Parent,
            ZIndex = 10,
            ThemeTag = {
                BackgroundColor3 = "Tab",
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 6),
            }),
            New("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = HasIcon and UDim2.new(0, 30, 0.5, 0) or UDim2.new(0, 12, 0.5, 0),
                Text = Title,
                RichText = true,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextTransparency = 0,
                FontFace = Font.new(
                    "rbxasset://fonts/families/GothamSSm.json",
                    Enum.FontWeight.Regular,
                    Enum.FontStyle.Normal
                ),
                TextSize = 12,
                TextXAlignment = "Left",
                TextYAlignment = "Center",
                Size = UDim2.new(1, -12, 1, 0),
                BackgroundTransparency = 1,
                ZIndex = 11,
                ThemeTag = {
                    TextColor3 = "Text",
                },
            }),
            TabIconLabel,
        })

        local ContainerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        Tab.ContainerAnim = New("CanvasGroup", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            GroupTransparency = 0,
            Parent = Window.ContainerHolder,
            Visible = false,
            Position = UDim2.fromOffset(0, 0),
        })

        Tab.ContainerFrame = New("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Parent = Tab.ContainerAnim,
            Visible = true,
            BottomImage = "",
            MidImage = "",
            TopImage = "",
            ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
            ScrollBarImageTransparency = 0.95,
            ScrollBarThickness = 3,
            BorderSizePixel = 0,
            CanvasSize = UDim2.fromScale(0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollingEnabled = true,
        }, {
            ContainerLayout,
            New("UIPadding", {
                PaddingRight = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 1),
                PaddingTop = UDim.new(0, 1),
                PaddingBottom = UDim.new(0, 1),
            }),
        })

        Tab.ContainerXMotor = Flipper.SingleMotor.New(0)
        Tab.ContainerTransparencyMotor = Flipper.SingleMotor.New(0)

        Tab.ContainerXMotor:OnStep(function(Value)
            if Tab.ContainerAnim and Tab.ContainerAnim.Parent then
                Tab.ContainerAnim.Position = UDim2.fromOffset(Value, 0)
            end
        end)

        Tab.ContainerTransparencyMotor:OnStep(function(Value)
            if Tab.ContainerAnim and Tab.ContainerAnim.Parent then
                Tab.ContainerAnim.GroupTransparency = Value
            end
        end)

        Creator.AddSignal(ContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Tab.ContainerFrame.CanvasSize = UDim2.new(0, 0, 0, ContainerLayout.AbsoluteContentSize.Y + 2)
        end)

        Tab.Motor, Tab.SetTransparency = Creator.SpringMotor(0.92, Tab.Frame, "BackgroundTransparency")

        Creator.AddSignal(Tab.Frame.MouseEnter, function()
            Tab.SetTransparency(Tab.Selected and 0.85 or 0.87)
        end)

        Creator.AddSignal(Tab.Frame.MouseLeave, function()
            Tab.SetTransparency(Tab.Selected and 0.89 or 0.92)
        end)

        Creator.AddSignal(Tab.Frame.MouseButton1Down, function()
            Tab.SetTransparency(0.92)
        end)

        Creator.AddSignal(Tab.Frame.MouseButton1Up, function()
            Tab.SetTransparency(Tab.Selected and 0.85 or 0.89)
        end)

        Creator.AddSignal(Tab.Frame.MouseButton1Click, function()
            TabModule:SelectTab(TabIndex)
        end)

        TabModule.Containers[TabIndex] = Tab.ContainerAnim
        TabModule.Tabs[TabIndex] = Tab

        Tab.Container = Tab.ContainerFrame
        Tab.ScrollFrame = Tab.Container

        Tab.SubTabs = {}
        Tab.SubTabContainers = {}
        Tab.SelectedSubTab = 0
        Tab.SubTabCount = 0
        Tab.SubTabHolder = nil

        function Tab:AddSubTab(SubTitle, SubIcon)
            self.SubTabCount = self.SubTabCount + 1

            local SubTabIndex = self.SubTabCount

            if not self.SubTabHolder then
                local SubTabListLayout = New("UIListLayout", {
                    Padding = UDim.new(0, 6),
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                })

                self.SubTabHolder = New("ScrollingFrame", {
                    Size = UDim2.new(1, -20, 0, 40),
                    Position = UDim2.fromOffset(1, 8),
                    BackgroundTransparency = 1,
                    Parent = self.ContainerFrame,
                    ScrollingDirection = Enum.ScrollingDirection.X,
                    ScrollBarThickness = 0,
                    ScrollBarImageTransparency = 1,
                    ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
                    CanvasSize = UDim2.fromScale(0, 1),
                    BorderSizePixel = 0,
                }, {
                    SubTabListLayout,
                    New("UIPadding", {
                        PaddingLeft = UDim.new(0, 0),
                        PaddingRight = UDim.new(0, 0),
                        PaddingTop = UDim.new(0, 0),
                        PaddingBottom = UDim.new(0, 0),
                    }),
                })

                Creator.AddSignal(SubTabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                    self.SubTabHolder.CanvasSize = UDim2.new(0, SubTabListLayout.AbsoluteContentSize.X, 0, 40)
                end)

                local SubTabContainerHolder = New("Frame", {
                    Size = UDim2.new(1, -11, 1, -56),
                    Position = UDim2.fromOffset(1, 48),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true,
                    Parent = self.ContainerFrame,
                })

                self.SubTabContainerHolder = SubTabContainerHolder
            end

            local HasSubIcon = SubIcon ~= nil and SubIcon ~= ""

            local SubTabIconLabel = HasSubIcon and New("ImageLabel", {
                Size = UDim2.fromOffset(16, 16),
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                ThemeTag = {
                    ImageColor3 = "Text",
                },
            }) or nil

            if SubTabIconLabel then
                Library:ApplyIcon(SubTabIconLabel, SubIcon)
            end

            local SubTabButton = New("TextButton", {
                Size = UDim2.new(0, 0, 0, 32),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 0.92,
                Parent = self.SubTabHolder,
                Text = "",
                ThemeTag = {
                    BackgroundColor3 = "Tab",
                },
            }, {
                New("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                }),
                New("UIStroke", {
                    Transparency = 1,
                    Thickness = 1,
                    ThemeTag = {
                        Color = "Accent",
                    },
                }),
                New("UIListLayout", {
                    Padding = UDim.new(0, 6),
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                }),
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                    PaddingTop = UDim.new(0, 6),
                    PaddingBottom = UDim.new(0, 6),
                }),
                SubTabIconLabel,
                New("TextLabel", {
                    Text = SubTitle,
                    RichText = true,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextTransparency = 0,
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    TextSize = 12,
                    TextXAlignment = "Left",
                    TextYAlignment = "Center",
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    LayoutOrder = 2,
                    ThemeTag = {
                        TextColor3 = "Text",
                    },
                }),
            })

            local SubTabContainerAnim = New("CanvasGroup", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                GroupTransparency = 0,
                Parent = self.SubTabContainerHolder,
                Visible = false,
                Position = UDim2.fromOffset(0, 0),
            })

            local SubTabContainer = New("ScrollingFrame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Parent = SubTabContainerAnim,
                Visible = true,
                BottomImage = "",
                MidImage = "",
                TopImage = "",
                ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
                ScrollBarImageTransparency = 0.95,
                ScrollBarThickness = 3,
                BorderSizePixel = 0,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ScrollingEnabled = true,
            }, {
                New("UIListLayout", {
                    Padding = UDim.new(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
                New("UIPadding", {
                    PaddingRight = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 1),
                    PaddingTop = UDim.new(0, 1),
                    PaddingBottom = UDim.new(0, 1),
                }),
            })

            local SubTabLayout = SubTabContainer:FindFirstChild("UIListLayout")

            Creator.AddSignal(SubTabLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                SubTabContainer.CanvasSize = UDim2.new(0, 0, 0, SubTabLayout.AbsoluteContentSize.Y + 2)
            end)

            local SubTabXMotor = Flipper.SingleMotor.New(0)
            local SubTabTransparencyMotor = Flipper.SingleMotor.New(0)

            SubTabXMotor:OnStep(function(Value)
                if SubTabContainerAnim and SubTabContainerAnim.Parent then
                    SubTabContainerAnim.Position = UDim2.fromOffset(Value, 0)
                end
            end)

            SubTabTransparencyMotor:OnStep(function(Value)
                if SubTabContainerAnim and SubTabContainerAnim.Parent then
                    SubTabContainerAnim.GroupTransparency = Value
                end
            end)

            local SubTabMotor, SubTabSetTransparency = Creator.SpringMotor(0.92, SubTabButton, "BackgroundTransparency")
            local SubTabStroke = SubTabButton:FindFirstChild("UIStroke")

            local function UpdateSubTabAppearance()
                if self.SelectedSubTab == SubTabIndex then
                    SubTabSetTransparency(0.75)

                    if SubTabStroke then
                        SubTabStroke.Transparency = 0
                    end
                else
                    SubTabSetTransparency(0.92)

                    if SubTabStroke then
                        SubTabStroke.Transparency = 1
                    end
                end
            end

            Creator.AddSignal(SubTabButton.MouseEnter, function()
                if self.SelectedSubTab ~= SubTabIndex then
                    SubTabSetTransparency(0.87)
                end
            end)

            Creator.AddSignal(SubTabButton.MouseLeave, function()
                UpdateSubTabAppearance()
            end)

            Creator.AddSignal(SubTabButton.MouseButton1Down, function()
                SubTabSetTransparency(0.92)
            end)

            Creator.AddSignal(SubTabButton.MouseButton1Up, function()
                UpdateSubTabAppearance()
            end)

            UpdateSubTabAppearance()

            Creator.AddSignal(SubTabButton.MouseButton1Click, function()
                self:SelectSubTab(SubTabIndex)
            end)

            local SubTab = {
                Type = "SubTab",
                Name = SubTitle,
                Button = SubTabButton,
                Container = SubTabContainer,
                ContainerAnim = SubTabContainerAnim,
                XMotor = SubTabXMotor,
                TransparencyMotor = SubTabTransparencyMotor,
                SetTransparency = SubTabSetTransparency,
                Selected = false,
            }

            self.SubTabs[SubTabIndex] = SubTab
            self.SubTabContainers[SubTabIndex] = SubTabContainerAnim

            if self.SubTabCount == 1 then
                self:SelectSubTab(SubTabIndex)
            end

            function SubTab:AddSection(SectionTitle, SectionIcon)
                local Section = { Type = "Section" }
                local SectionFrame = Components.Section(SectionTitle, SubTab.Container, SectionIcon)

                Section.Container = SectionFrame.Container
                Section.ScrollFrame = SubTab.Container

                if Library.AttachElementMethods then
                    Library.AttachElementMethods(Section)
                end

                return Section
            end

            if Library.AttachElementMethods then
                Library.AttachElementMethods(SubTab)
            end

            return SubTab
        end

        function Tab:SelectSubTab(SubTabIndex)
            if self.SelectedSubTab == SubTabIndex then
                return
            end

            local PreviousSubTab = self.SelectedSubTab
            local Direction = (PreviousSubTab > 0 and SubTabIndex > PreviousSubTab) and 1 or -1

            if PreviousSubTab == 0 then
                Direction = 0
            end

            local ContainerSize = self.SubTabContainerHolder and self.SubTabContainerHolder.AbsoluteSize.X or 500
            local SlideDistance = math.min(ContainerSize * 0.15, 60)

            self.SelectedSubTab = SubTabIndex

            for Idx, SubTabObj in self.SubTabs do
                SubTabObj.Selected = (Idx == SubTabIndex)

                local SubTabStroke = SubTabObj.Button:FindFirstChild("UIStroke")

                if Idx == SubTabIndex then
                    SubTabObj.SetTransparency(0.75)

                    if SubTabStroke then
                        SubTabStroke.Transparency = 0
                    end
                else
                    SubTabObj.SetTransparency(0.92)

                    if SubTabStroke then
                        SubTabStroke.Transparency = 1
                    end
                end
            end

            if PreviousSubTab > 0 and PreviousSubTab ~= SubTabIndex and self.SubTabs[PreviousSubTab] and self.SubTabs[SubTabIndex] then
                local OldContainer = self.SubTabs[PreviousSubTab].ContainerAnim
                local NewContainer = self.SubTabs[SubTabIndex].ContainerAnim
                local OldSubTab = self.SubTabs[PreviousSubTab]
                local NewSubTab = self.SubTabs[SubTabIndex]

                for Idx, Container in self.SubTabContainers do
                    if Container and Idx ~= PreviousSubTab and Idx ~= SubTabIndex then
                        Container.Visible = false
                        Container.Position = UDim2.fromOffset(0, 0)
                        Container.GroupTransparency = 0

                        if self.SubTabs[Idx] and self.SubTabs[Idx].XMotor and self.SubTabs[Idx].TransparencyMotor then
                            self.SubTabs[Idx].XMotor:SetGoal(Instant(0))
                            self.SubTabs[Idx].TransparencyMotor:SetGoal(Instant(0))
                        end
                    end
                end

                OldContainer.Visible = true
                OldContainer.Position = UDim2.fromOffset(0, 0)
                OldContainer.GroupTransparency = 0

                OldSubTab.XMotor:SetGoal(Instant(0))
                OldSubTab.TransparencyMotor:SetGoal(Instant(0))

                NewContainer.Visible = true
                NewContainer.Position = UDim2.fromOffset(Direction * SlideDistance, 0)
                NewContainer.GroupTransparency = 1

                NewSubTab.XMotor:SetGoal(Instant(Direction * SlideDistance))
                NewSubTab.TransparencyMotor:SetGoal(Instant(1))

                OldSubTab.XMotor:SetGoal(Spring(-Direction * SlideDistance, { frequency = 4, dampingRatio = 0.7 }))
                OldSubTab.TransparencyMotor:SetGoal(Spring(1, { frequency = 4, dampingRatio = 0.7 }))

                NewSubTab.XMotor:SetGoal(Spring(0, { frequency = 4, dampingRatio = 0.7 }))
                NewSubTab.TransparencyMotor:SetGoal(Spring(0, { frequency = 4, dampingRatio = 0.7 }))

                task.spawn(function()
                    if self.SelectedSubTab == SubTabIndex and self.SubTabs[PreviousSubTab] then
                        local OldContainer2 = self.SubTabs[PreviousSubTab].ContainerAnim
                        local OldSubTab2 = self.SubTabs[PreviousSubTab]

                        if OldContainer2 and OldContainer2.Parent then
                            OldContainer2.Visible = false
                            OldContainer2.Position = UDim2.fromOffset(0, 0)
                            OldContainer2.GroupTransparency = 0
                        end

                        if OldSubTab2 and OldSubTab2.XMotor and OldSubTab2.TransparencyMotor then
                            OldSubTab2.XMotor:SetGoal(Instant(0))
                            OldSubTab2.TransparencyMotor:SetGoal(Instant(0))
                        end
                    end
                end)
            else
                for Idx, Container in self.SubTabContainers do
                    if Container then
                        Container.Visible = (Idx == SubTabIndex)
                        Container.Position = UDim2.fromOffset(0, 0)
                        Container.GroupTransparency = 0

                        if self.SubTabs[Idx] and self.SubTabs[Idx].XMotor and self.SubTabs[Idx].TransparencyMotor then
                            self.SubTabs[Idx].XMotor:SetGoal(Instant(0))
                            self.SubTabs[Idx].TransparencyMotor:SetGoal(Instant(0))
                        end
                    end
                end
            end
        end

        function Tab:AddSection(SectionTitle, SectionIcon)
            if self.SelectedSubTab > 0 and self.SubTabs[self.SelectedSubTab] then
                return self.SubTabs[self.SelectedSubTab]:AddSection(SectionTitle, SectionIcon)
            end

            local Section = { Type = "Section" }
            local SectionFrame = Components.Section(SectionTitle, Tab.Container, SectionIcon)

            Section.Container = SectionFrame.Container
            Section.ScrollFrame = Tab.Container

            if Library.AttachElementMethods then
                Library.AttachElementMethods(Section)
            end

            return Section
        end

        if Library.AttachElementMethods then
            Library.AttachElementMethods(Tab)
        end

        return Tab
    end

    function TabModule:SelectTab(Tab)
        if TabModule.SelectedTab == Tab then
            return
        end

        if TabModule.AnimationTask then
            task.cancel(TabModule.AnimationTask)
            TabModule.AnimationTask = nil
        end

        local Window = TabModule.Window
        local PreviousTab = TabModule.SelectedTab
        local Direction = (PreviousTab > 0 and Tab > PreviousTab) and 1 or -1

        if PreviousTab == 0 then
            Direction = 0
        end

        local ContainerSize = Window.ContainerHolder and Window.ContainerHolder.AbsoluteSize.X or 500
        local SlideDistance = math.min(ContainerSize * 0.15, 60)

        TabModule.SelectedTab = Tab
        TabModule.CurrentAnimationTab = Tab

        for _, TabObject in TabModule.Tabs do
            TabObject.SetTransparency(0.92)
            TabObject.Selected = false
        end

        TabModule.Tabs[Tab].SetTransparency(0.89)
        TabModule.Tabs[Tab].Selected = true

        Window.SelectorPosMotor:SetGoal(Spring(TabModule:GetCurrentTabPos(), { frequency = 6 }))

        if PreviousTab > 0 and PreviousTab ~= Tab and TabModule.Tabs[PreviousTab] and TabModule.Tabs[Tab] then
            local OldContainer = TabModule.Tabs[PreviousTab].ContainerAnim
            local NewContainer = TabModule.Tabs[Tab].ContainerAnim
            local OldTab = TabModule.Tabs[PreviousTab]
            local NewTab = TabModule.Tabs[Tab]

            if not OldContainer
                or not NewContainer
                or not OldTab.ContainerXMotor
                or not OldTab.ContainerTransparencyMotor
                or not NewTab.ContainerXMotor
                or not NewTab.ContainerTransparencyMotor
            then
                for Idx, Container in TabModule.Containers do
                    if Container then
                        Container.Visible = (Idx == Tab)
                        Container.Position = UDim2.fromOffset(0, 0)
                        Container.GroupTransparency = 0
                    end
                end

                return
            end

            for Idx, Container in TabModule.Containers do
                if Container and Idx ~= PreviousTab and Idx ~= Tab then
                    Container.Visible = false
                    Container.Position = UDim2.fromOffset(0, 0)
                    Container.GroupTransparency = 0

                    if TabModule.Tabs[Idx] and TabModule.Tabs[Idx].ContainerXMotor and TabModule.Tabs[Idx].ContainerTransparencyMotor then
                        TabModule.Tabs[Idx].ContainerXMotor:SetGoal(Instant(0))
                        TabModule.Tabs[Idx].ContainerTransparencyMotor:SetGoal(Instant(0))
                    end
                end
            end

            OldContainer.Visible = true
            OldContainer.Position = UDim2.fromOffset(0, 0)
            OldContainer.GroupTransparency = 0

            OldTab.ContainerXMotor:SetGoal(Instant(0))
            OldTab.ContainerTransparencyMotor:SetGoal(Instant(0))

            NewContainer.Visible = true
            NewContainer.Position = UDim2.fromOffset(Direction * SlideDistance, 0)
            NewContainer.GroupTransparency = 1

            NewTab.ContainerXMotor:SetGoal(Instant(Direction * SlideDistance))
            NewTab.ContainerTransparencyMotor:SetGoal(Instant(1))

            OldTab.ContainerXMotor:SetGoal(Spring(-Direction * SlideDistance, { frequency = 4, dampingRatio = 0.7 }))
            OldTab.ContainerTransparencyMotor:SetGoal(Spring(1, { frequency = 4, dampingRatio = 0.7 }))

            NewTab.ContainerXMotor:SetGoal(Spring(0, { frequency = 4, dampingRatio = 0.7 }))
            NewTab.ContainerTransparencyMotor:SetGoal(Spring(0, { frequency = 4, dampingRatio = 0.7 }))

            TabModule.AnimationTask = task.spawn(function()
                if TabModule.CurrentAnimationTab == Tab and TabModule.Tabs[PreviousTab] then
                    local OldContainer2 = TabModule.Tabs[PreviousTab].ContainerAnim
                    local OldTab2 = TabModule.Tabs[PreviousTab]

                    if OldContainer2 and OldContainer2.Parent then
                        OldContainer2.Visible = false
                        OldContainer2.Position = UDim2.fromOffset(0, 0)
                        OldContainer2.GroupTransparency = 0
                    end

                    if OldTab2 and OldTab2.ContainerXMotor and OldTab2.ContainerTransparencyMotor then
                        OldTab2.ContainerXMotor:SetGoal(Instant(0))
                        OldTab2.ContainerTransparencyMotor:SetGoal(Instant(0))
                    end

                    TabModule.AnimationTask = nil
                end
            end)
        else
            for Idx, Container in TabModule.Containers do
                if Container then
                    Container.Visible = (Idx == Tab)
                    Container.Position = UDim2.fromOffset(0, 0)
                    Container.GroupTransparency = 0

                    if TabModule.Tabs[Idx] and TabModule.Tabs[Idx].ContainerXMotor and TabModule.Tabs[Idx].ContainerTransparencyMotor then
                        TabModule.Tabs[Idx].ContainerXMotor:SetGoal(Instant(0))
                        TabModule.Tabs[Idx].ContainerTransparencyMotor:SetGoal(Instant(0))
                    end
                end
            end
        end
    end

    return TabModule
end)()

Components.Button = (function()
    local Spring = Flipper.Spring.New

    return function(Theme, Parent, DialogCheck)
        DialogCheck = DialogCheck or false

        local Button = {}

        Button.Title = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 14,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ThemeTag = {
                TextColor3 = "Text",
            },
        })

        Button.HoverFrame = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ThemeTag = {
                BackgroundColor3 = "Hover",
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),
        })

        Button.Frame = New("TextButton", {
            Size = UDim2.new(0, 0, 0, 32),
            Parent = Parent,
            ThemeTag = {
                BackgroundColor3 = "DialogButton",
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),
            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Transparency = 0.65,
                ThemeTag = {
                    Color = "DialogButtonBorder",
                },
            }),
            Button.HoverFrame,
            Button.Title,
        })

        local Motor, SetTransparency = Creator.SpringMotor(1, Button.HoverFrame, "BackgroundTransparency", DialogCheck)

        Creator.AddSignal(Button.Frame.MouseEnter, function()
            SetTransparency(0.97)
        end)

        Creator.AddSignal(Button.Frame.MouseLeave, function()
            SetTransparency(1)
        end)

        Creator.AddSignal(Button.Frame.MouseButton1Down, function()
            SetTransparency(1)
        end)

        Creator.AddSignal(Button.Frame.MouseButton1Up, function()
            SetTransparency(0.97)
        end)

        return Button
    end
end)()

Components.Dialog = (function()
    local Spring = Flipper.Spring.New

    local Dialog = {
        Window = nil,
    }

    function Dialog:Init(Window)
        Dialog.Window = Window

        return Dialog
    end

    function Dialog:Create()
        local NewDialog = {
            Buttons = 0,
        }

        NewDialog.TintFrame = New("TextButton", {
            Text = "",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            Parent = Dialog.Window.Root,
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 8),
            }),
        })

        local TintMotor, TintTransparency = Creator.SpringMotor(1, NewDialog.TintFrame, "BackgroundTransparency", true)

        NewDialog.ButtonHolder = New("Frame", {
            Size = UDim2.new(1, -40, 1, -40),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundTransparency = 1,
        }, {
            New("UIListLayout", {
                Padding = UDim.new(0, 10),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })

        NewDialog.ButtonHolderFrame = New("Frame", {
            Size = UDim2.new(1, 0, 0, 70),
            Position = UDim2.new(0, 0, 1, -70),
            ThemeTag = {
                BackgroundColor3 = "DialogHolder",
            },
        }, {
            New("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                ThemeTag = {
                    BackgroundColor3 = "DialogHolderLine",
                },
            }),
            NewDialog.ButtonHolder,
        })

        NewDialog.Title = New("TextLabel", {
            FontFace = Font.new(
                "rbxasset://fonts/families/GothamSSm.json",
                Enum.FontWeight.SemiBold,
                Enum.FontStyle.Normal
            ),
            Text = "Dialog",
            TextColor3 = Color3.fromRGB(240, 240, 240),
            TextSize = 22,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 22),
            Position = UDim2.fromOffset(20, 25),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            ThemeTag = {
                TextColor3 = "Text",
            },
        })

        NewDialog.Scale = New("UIScale", {
            Scale = 1,
        })

        local ScaleMotor, Scale = Creator.SpringMotor(1.1, NewDialog.Scale, "Scale")

        NewDialog.Root = New("CanvasGroup", {
            Size = UDim2.fromOffset(300, 165),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            GroupTransparency = 1,
            Parent = NewDialog.TintFrame,
            ThemeTag = {
                BackgroundColor3 = "Dialog",
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 8),
            }),
            New("UIStroke", {
                Transparency = 0.5,
                ThemeTag = {
                    Color = "DialogBorder",
                },
            }),
            NewDialog.Scale,
            NewDialog.Title,
            NewDialog.ButtonHolderFrame,
        })

        local RootMotor, RootTransparency = Creator.SpringMotor(1, NewDialog.Root, "GroupTransparency")

        function NewDialog:Open()
            Library.DialogOpen = true

            NewDialog.Scale.Scale = 1.1

            TintTransparency(0.75)
            RootTransparency(0)
            Scale(1)
        end

        function NewDialog:Close()
            Library.DialogOpen = false

            TintTransparency(1)
            RootTransparency(1)
            Scale(1.1)

            NewDialog.Root.UIStroke:Destroy()
            NewDialog.TintFrame:Destroy()
        end

        function NewDialog:Button(Title, Callback)
            NewDialog.Buttons = NewDialog.Buttons + 1

            Title = Title or "Button"
            Callback = Callback or function() end

            local Button = Components.Button("", NewDialog.ButtonHolder, true)

            Button.Title.Text = Title

            for _, Btn in NewDialog.ButtonHolder:GetChildren() do
                if Btn:IsA("TextButton") then
                    Btn.Size =
                        UDim2.new(1 / NewDialog.Buttons, -(((NewDialog.Buttons - 1) * 10) / NewDialog.Buttons), 0, 32)
                end
            end

            Creator.AddSignal(Button.Frame.MouseButton1Click, function()
                Library:SafeCallback(Callback)

                NewDialog:Close()
            end)

            return Button
        end

        return NewDialog
    end

    return Dialog
end)()

Components.Notification = (function()
    local Spring = Flipper.Spring.New

    local Notification = {}

    function Notification:Init(Gui)
        Library.ActiveNotifications = Library.ActiveNotifications or {}

        Notification.Holder = New("Frame", {
            Position = UDim2.new(1, -30, 1, -30),
            Size = UDim2.new(0, 310, 1, -30),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            Parent = Gui,
        }, {
            New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                Padding = UDim.new(0, 20),
            }),
        })
    end

    function Notification:New(Config)
        Config.Title = Config.Title or "Title"
        Config.Content = Config.Content or "Content"
        Config.SubContent = Config.SubContent or ""
        Config.Duration = Config.Duration or nil

        local NewNotification = { Closed = false }

        NewNotification.Title = New("TextLabel", {
            Position = UDim2.new(0, 14, 0, 17),
            Text = Config.Title,
            RichText = true,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextTransparency = 0,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 13,
            TextXAlignment = "Left",
            TextYAlignment = "Center",
            Size = UDim2.new(1, -12, 0, 12),
            TextWrapped = true,
            BackgroundTransparency = 1,
            ThemeTag = { TextColor3 = "Text" },
        })

        NewNotification.ContentLabel = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = Config.Content,
            RichText = true,
            TextColor3 = Color3.fromRGB(240, 240, 240),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            TextWrapped = true,
            ThemeTag = { TextColor3 = "Text" },
        })

        NewNotification.SubContentLabel = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = Config.SubContent,
            RichText = true,
            TextColor3 = Color3.fromRGB(240, 240, 240),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            TextWrapped = true,
            ThemeTag = { TextColor3 = "SubText" },
        })

        NewNotification.LabelHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(14, 40),
            Size = UDim2.new(1, -28, 0, 0),
        }, {
            New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 3),
            }),
            NewNotification.ContentLabel,
            NewNotification.SubContentLabel,
        })

        NewNotification.CloseButton = New("TextButton", {
            Text = "",
            Position = UDim2.new(1, -14, 0, 13),
            Size = UDim2.fromOffset(20, 20),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
        })

        local CloseIcon = New("ImageLabel", {
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Parent = NewNotification.CloseButton,
            ThemeTag = { ImageColor3 = "Text" },
        })

        Library:ApplyIcon(CloseIcon, "dismiss-20-filled")

        NewNotification.Root = New("Frame", {
            BackgroundTransparency = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.fromScale(1, 0),
            ThemeTag = { BackgroundColor3 = "Dialog" },
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 8) }),
            New("UIStroke", {
                Transparency = 0.5,
                Thickness = 1,
                ThemeTag = { Color = "DialogBorder" },
            }),
            NewNotification.Title,
            NewNotification.CloseButton,
            NewNotification.LabelHolder,
        })

        if Config.Content == "" then
            NewNotification.ContentLabel.Visible = false
        end

        if Config.SubContent == "" then
            NewNotification.SubContentLabel.Visible = false
        end

        NewNotification.Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 200),
            Parent = Notification.Holder,
        }, {
            NewNotification.Root,
        })

        local RootMotor = Flipper.GroupMotor.New({ Scale = 1, Offset = 60 })

        RootMotor:OnStep(function(Values)
            NewNotification.Root.Position = UDim2.new(Values.Scale, Values.Offset, 0, 0)
        end)

        Creator.AddSignal(NewNotification.CloseButton.MouseButton1Click, function()
            NewNotification:Close()
        end)

        function NewNotification:Open()
            local ContentSize = NewNotification.LabelHolder.AbsoluteSize.Y

            NewNotification.Holder.Size = UDim2.new(1, 0, 0, 58 + ContentSize)

            RootMotor:SetGoal({
                Scale = Spring(0, { frequency = 5 }),
                Offset = Spring(0, { frequency = 5 }),
            })
        end

        function NewNotification:Close()
            if not NewNotification.Closed then
                NewNotification.Closed = true

                for I, Notif in Library.ActiveNotifications or {} do
                    if Notif == NewNotification then
                        table.remove(Library.ActiveNotifications, I)
                        break
                    end
                end

                task.spawn(function()
                    RootMotor:SetGoal({
                        Scale = Spring(1, { frequency = 5 }),
                        Offset = Spring(60, { frequency = 5 }),
                    })

                    NewNotification.Holder:Destroy()
                end)
            end
        end

        table.insert(Library.ActiveNotifications, NewNotification)

        NewNotification:Open()

        if Config.Duration then
            task.delay(Config.Duration, function()
                NewNotification:Close()
            end)
        end

        return NewNotification
    end

    return Notification
end)()

Components.Textbox = (function()
    return function(Parent)
        local Textbox = {}

        Textbox.Input = New("TextBox", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromOffset(10, 0),
            ThemeTag = {
                TextColor3 = "Text",
                PlaceholderColor3 = "SubText",
            },
        })

        Textbox.Container = New("Frame", {
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Position = UDim2.new(0, 6, 0, 0),
            Size = UDim2.new(1, -12, 1, 0),
        }, {
            Textbox.Input,
        })

        Textbox.Indicator = New("Frame", {
            Size = UDim2.new(1, -4, 0, 1),
            Position = UDim2.new(0, 2, 1, 0),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 0,
            ThemeTag = { BackgroundColor3 = "DialogInputLine" },
        })

        Textbox.Frame = New("Frame", {
            Size = UDim2.new(0, 0, 0, 30),
            BackgroundTransparency = 0,
            Parent = Parent,
            ThemeTag = { BackgroundColor3 = "DialogInput" },
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 4) }),
            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Transparency = 0.65,
                ThemeTag = { Color = "DialogButtonBorder" },
            }),
            Textbox.Indicator,
            Textbox.Container,
        })

        local function Update()
            local PADDING = 2
            local Reveal = Textbox.Container.AbsoluteSize.X

            if not Textbox.Input:IsFocused() or Textbox.Input.TextBounds.X <= Reveal - 2 * PADDING then
                Textbox.Input.Position = UDim2.new(0, PADDING, 0, 0)
            else
                local Cursor = Textbox.Input.CursorPosition

                if Cursor ~= -1 then
                    local Subtext = string.sub(Textbox.Input.Text, 1, Cursor - 1)
                    local Width = TextService:GetTextSize(
                        Subtext,
                        Textbox.Input.TextSize,
                        Textbox.Input.Font,
                        Vector2.new(math.huge, math.huge)
                    ).X

                    local CurrentCursorPos = Textbox.Input.Position.X.Offset + Width

                    if CurrentCursorPos < PADDING then
                        Textbox.Input.Position = UDim2.fromOffset(PADDING - Width, 0)
                    elseif CurrentCursorPos > Reveal - PADDING - 1 then
                        Textbox.Input.Position = UDim2.fromOffset(Reveal - Width - PADDING - 1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Creator.AddSignal(Textbox.Input:GetPropertyChangedSignal("Text"), Update)
        Creator.AddSignal(Textbox.Input:GetPropertyChangedSignal("CursorPosition"), Update)

        Creator.AddSignal(Textbox.Input.Focused, function()
            Textbox.Input.Text = ""

            Update()

            Textbox.Indicator.Size = UDim2.new(1, -2, 0, 2)
            Textbox.Indicator.Position = UDim2.new(0, 1, 1, 0)
            Textbox.Indicator.BackgroundTransparency = 0

            Creator.OverrideTag(Textbox.Frame, { BackgroundColor3 = "DialogHolder" })
            Creator.OverrideTag(Textbox.Indicator, { BackgroundColor3 = "InputIndicatorFocus" })
        end)

        Creator.AddSignal(Textbox.Input.FocusLost, function()
            Update()

            Textbox.Indicator.Size = UDim2.new(1, -4, 0, 1)
            Textbox.Indicator.Position = UDim2.new(0, 2, 1, 0)
            Textbox.Indicator.BackgroundTransparency = 0.5

            Creator.OverrideTag(Textbox.Frame, { BackgroundColor3 = "DialogInput" })
            Creator.OverrideTag(Textbox.Indicator, { BackgroundColor3 = "DialogInputLine" })
        end)

        return Textbox
    end
end)()

Components.TitleBar = (function()
    return function(Config)
        local TitleBar = {}

        local TitleBarIconLabel = Config.Icon and New("ImageLabel", {
            Size = UDim2.fromOffset(20, 20),
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            ThemeTag = { ImageColor3 = "Text" },
        }) or nil

        if TitleBarIconLabel then
            Library:ApplyIcon(TitleBarIconLabel, Config.Icon)
        end

        local TitleText = New("TextLabel", {
            RichText = true,
            Text = Config.Title,
            FontFace = Font.new(
                "rbxasset://fonts/families/GothamSSm.json",
                Enum.FontWeight.Regular,
                Enum.FontStyle.Normal
            ),
            TextSize = 12,
            TextXAlignment = "Left",
            TextYAlignment = "Center",
            Size = UDim2.fromScale(0, 1),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            LayoutOrder = Config.Icon and 2 or 1,
            ThemeTag = { TextColor3 = "Text" },
        })

        local SubTitleText = Config.SubTitle and New("TextLabel", {
            RichText = true,
            Text = Config.SubTitle,
            TextTransparency = 0.4,
            FontFace = Font.new(
                "rbxasset://fonts/families/GothamSSm.json",
                Enum.FontWeight.Regular,
                Enum.FontStyle.Normal
            ),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextYAlignment = Enum.TextYAlignment.Center,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -16, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            ThemeTag = { TextColor3 = "Text" },
        }) or nil

        TitleBar.Frame = New("Frame", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundTransparency = 1,
            Parent = Config.Parent,
        }, {
            New("Frame", {
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
            }, {
                New("UIListLayout", {
                    Padding = UDim.new(0, 5),
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),
                TitleBarIconLabel,
                TitleText,
            }),
            SubTitleText,
            New("Frame", {
                BackgroundTransparency = 0.5,
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 1, 0),
                ThemeTag = { BackgroundColor3 = "TitleBarLine" },
            }),
        })

        return TitleBar
    end
end)()

Components.Window = (function()
    local Spring = Flipper.Spring.New
    local Instant = Flipper.Instant.New

    return function(Config)
        local Window = {
            Minimized = false,
            Maximized = false,
            Size = Config.Size,
            CurrentPos = 0,
            TabWidth = 0,
            Position = UDim2.fromOffset(0, 0),
        }

        Library.Window = Window

        local Dragging, DragInput, MousePos, StartPos = false, nil, nil, nil
        local Resizing, ResizePos = false, nil
        local MinimizeNotif = false

        Window.AcrylicPaint = {
            Frame = New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                ThemeTag = { BackgroundColor3 = "AcrylicMain" },
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 8) }),
                New("UIStroke", {
                    Transparency = 0.5,
                    Thickness = 1,
                    ThemeTag = { Color = "AcrylicBorder" },
                }),
            }),
            AddParent = function() end,
            SetVisibility = function() end,
        }

        local function CenterWindow()
            local Vp = Camera.ViewportSize
            local X = math.max(0, (Vp.X - Window.Size.X.Offset) / 2)
            local Y = math.max(0, (Vp.Y - Window.Size.Y.Offset) / 2)

            Window.Position = UDim2.fromOffset(math.floor(X), math.floor(Y))

            if Window.Root then
                Window.Root.Position = Window.Position
            end
        end

        Window.TabWidth = Config.TabWidth

        local Selector = New("Frame", {
            Size = UDim2.fromOffset(4, 0),
            BackgroundColor3 = Color3.fromRGB(76, 194, 255),
            Position = UDim2.fromOffset(0, 45),
            AnchorPoint = Vector2.new(0, 0.5),
            ZIndex = 1,
            ThemeTag = { BackgroundColor3 = "Accent" },
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 9) }),
        })

        local ResizeStartFrame = New("Frame", {
            Size = UDim2.fromOffset(20, 20),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -20, 1, -2),
        })

        local SearchElements = {}
        local AllElements = {}

        local function NormalizeText(Text)
            if not Text then
                return ""
            end

            Text = tostring(Text)
            Text = string.gsub(Text, "^%s+", "")
            Text = string.gsub(Text, "%s+$", "")
            Text = string.gsub(Text, "%s+", " ")

            return string.lower(Text)
        end

        local function GetElementValues(ElementFrame)
            local Values = {}

            local function AddText(Text)
                if Text and Text ~= "" then
                    table.insert(Values, tostring(Text))
                end
            end

            local function FindTextInDescendants(Obj)
                if Obj:IsA("TextLabel") or Obj:IsA("TextButton") or Obj:IsA("TextBox") then
                    AddText(Obj.Text)
                end

                for _, Child in Obj:GetChildren() do
                    FindTextInDescendants(Child)
                end
            end

            FindTextInDescendants(ElementFrame)

            return Values
        end

        local function CheckMatch(Text, Query)
            if Query == "" then
                return true
            end

            local NormalizedText = NormalizeText(Text)

            if NormalizedText == "" then
                return false
            end

            local QueryLower = NormalizeText(Query)

            if QueryLower == "" then
                return true
            end

            if string.find(QueryLower, "%s", 1) then
                local Words = {}

                for Word in string.gmatch(QueryLower, "%S+") do
                    if #Word > 0 then
                        table.insert(Words, Word)
                    end
                end

                if #Words == 0 then
                    return true
                end

                for _, Word in Words do
                    if not string.find(NormalizedText, Word, 1, true) then
                        return false
                    end
                end

                return true
            else
                return string.find(NormalizedText, QueryLower, 1, true) ~= nil
            end
        end

        local function UpdateElementVisibility(SearchTerm)
            if not SearchTerm then
                SearchTerm = ""
            end

            local NormalizedQuery = NormalizeText(SearchTerm)
            local MatchedSectionFrames = {}
            local ElementsInMatchedSections = {}

            for Element, Data in AllElements do
                if Element and Element.Parent then
                    if Data.type == "Section" then
                        local Title = tostring(Data.title or "")

                        if NormalizedQuery ~= "" and CheckMatch(Title, NormalizedQuery) then
                            MatchedSectionFrames[Element] = true

                            if Element:FindFirstChild("Container") then
                                local Container = Element:FindFirstChild("Container")

                                for _, Child in Container:GetChildren() do
                                    if not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
                                        ElementsInMatchedSections[Child] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end

            for Element, Data in AllElements do
                if Element and Element.Parent then
                    if NormalizedQuery == "" then
                        Element.Visible = true
                    else
                        local Title = tostring(Data.title or "")
                        local Desc = tostring(Data.description or "")
                        local MatchesTitle = CheckMatch(Title, NormalizedQuery)
                        local MatchesDesc = CheckMatch(Desc, NormalizedQuery)
                        local MatchesValues = false
                        local ElementValues = GetElementValues(Element)

                        for _, Value in ElementValues do
                            if CheckMatch(Value, NormalizedQuery) then
                                MatchesValues = true
                                break
                            end
                        end

                        local MatchesSection = ElementsInMatchedSections[Element] == true

                        if not MatchesSection and Data.section then
                            for SectionFrame in MatchedSectionFrames do
                                if Data.section == SectionFrame then
                                    MatchesSection = true
                                    break
                                end
                            end
                        end

                        Element.Visible = MatchesTitle or MatchesDesc or MatchesValues or MatchesSection
                    end
                end
            end

            task.spawn(function()
                if not Window or not Window.ContainerHolder then
                    return
                end

                for _, TabContainer in Window.ContainerHolder:GetChildren() do
                    if TabContainer:IsA("ScrollingFrame") then
                        local ContainerLayout = TabContainer:FindFirstChild("UIListLayout")

                        if ContainerLayout then
                            local ContainerPadding = TabContainer:FindFirstChild("UIPadding")
                            local PaddingTop = ContainerPadding and ContainerPadding.PaddingTop.Offset or 1
                            local PaddingBottom = ContainerPadding and ContainerPadding.PaddingBottom.Offset or 1
                            local ContentSize = ContainerLayout.AbsoluteContentSize.Y + PaddingTop + PaddingBottom

                            TabContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(0, ContentSize))
                        end

                        for _, Section in TabContainer:GetChildren() do
                            if Section:IsA("Frame") and Section.Name ~= "UIPadding" then
                                local SectionContainer = Section:FindFirstChild("Container")

                                if SectionContainer and SectionContainer:IsA("Frame") then
                                    local ContainerLayout = SectionContainer:FindFirstChild("UIListLayout")

                                    if ContainerLayout then
                                        local HasVisibleChild = false

                                        for _, Element in SectionContainer:GetChildren() do
                                            if not Element:IsA("UIListLayout") and Element.Visible then
                                                HasVisibleChild = true
                                                break
                                            end
                                        end

                                        if SearchTerm == "" or HasVisibleChild then
                                            Section.Visible = true

                                            local ContainerPadding = SectionContainer:FindFirstChild("UIPadding")
                                            local ContainerPaddingTop = ContainerPadding and ContainerPadding.PaddingTop.Offset or 0
                                            local ContainerPaddingBottom = ContainerPadding and ContainerPadding.PaddingBottom.Offset or 0
                                            local ContainerContentSize = ContainerLayout.AbsoluteContentSize.Y
                                                + ContainerPaddingTop
                                                + ContainerPaddingBottom

                                            SectionContainer.Size = UDim2.new(1, 0, 0, math.max(0, ContainerContentSize))
                                        else
                                            Section.Visible = false
                                            SectionContainer.Size = UDim2.new(1, 0, 0, 0)
                                        end
                                    end
                                end

                                local SectionLayout = Section:FindFirstChild("UIListLayout")

                                if SectionLayout then
                                    local SectionPadding = Section:FindFirstChild("UIPadding")
                                    local SectionPaddingTop = SectionPadding and SectionPadding.PaddingTop.Offset or 0
                                    local SectionPaddingBottom = SectionPadding and SectionPadding.PaddingBottom.Offset or 0
                                    local SectionContentSize = SectionLayout.AbsoluteContentSize.Y
                                        + SectionPaddingTop
                                        + SectionPaddingBottom

                                    Section.Size = UDim2.new(1, 0, 0, math.max(0, SectionContentSize + 30))
                                end
                            end
                        end
                    end
                end
            end)
        end

        local function RegisterElement(ElementFrame, Title, ElementType, Description)
            if ElementFrame then
                local SectionFrame = nil
                local Parent = ElementFrame.Parent

                while Parent do
                    if Parent:FindFirstChild("Container") then
                        local SectionContainer = Parent:FindFirstChild("Container")

                        if SectionContainer and ElementFrame.Parent == SectionContainer then
                            SectionFrame = Parent
                            break
                        end
                    end

                    Parent = Parent.Parent
                end

                AllElements[ElementFrame] = {
                    title = tostring(Title or ""),
                    type = ElementType or "Element",
                    description = tostring(Description or ""),
                    section = SectionFrame,
                }
            end
        end

        local ImageAsset = Config.Image
        local HasImage = ImageAsset and ImageAsset ~= nil
        local ImageSize = Window.TabWidth - 24
        local TopOffset = 0

        local ImageFrame = HasImage and New("ImageLabel", {
            Size = UDim2.new(0, ImageSize, 0, ImageSize),
            Position = UDim2.new(0.5, 0, 0, TopOffset),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Image = "",
            ZIndex = 5,
            Visible = true,
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        }) or nil

        if HasImage then
            Library:ApplyIcon(ImageFrame, ImageAsset)
        end

        Window.HasImage = HasImage
        Window.ImageFrame = ImageFrame
        Window.ImageSize = ImageSize
        Window.TopOffset = TopOffset

        local SearchOffset = HasImage and (ImageSize + 10 + TopOffset) or TopOffset
        local SearchHeight = 28

        local TabHolderTop

        if HasImage then
            TabHolderTop = ImageSize + 10 + TopOffset + SearchHeight + 6
        else
            TabHolderTop = TopOffset + SearchHeight + 6
        end

        Window.TabHolderTop = TabHolderTop

        Window.TabHolder = New("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, -(TabHolderTop + 6)),
            Position = UDim2.new(0, 0, 0, TabHolderTop),
            BackgroundTransparency = 1,
            ScrollBarImageTransparency = 1,
            ScrollBarThickness = 0,
            BorderSizePixel = 0,
            CanvasSize = UDim2.fromScale(0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, {
            New("UIListLayout", {
                Padding = UDim.new(0, 4),
            }),
        })

        local SearchFrame = New("Frame", {
            Size = UDim2.new(1, 0, 0, 28),
            Position = UDim2.new(0, 0, 0, SearchOffset),
            BackgroundTransparency = 0.7,
            ZIndex = 10,
            Visible = true,
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            ThemeTag = { BackgroundColor3 = "Element" },
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 4) }),
        })

        local SearchInput = New("TextBox", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -36, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            PlaceholderText = "Search",
            PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
            ClearTextOnFocus = false,
            Text = "",
            Parent = SearchFrame,
            ThemeTag = { TextColor3 = "Text", PlaceholderColor3 = "SubText" },
        })

        local SearchIconLabel = New("ImageLabel", {
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(1, -13, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Parent = SearchFrame,
            ImageTransparency = 0.3,
            ThemeTag = { ImageColor3 = "SubText" },
        })

        Library:ApplyIcon(SearchIconLabel, "search-20-filled")

        Creator.AddSignal(SearchInput:GetPropertyChangedSignal("Text"), function()
            UpdateElementVisibility(SearchInput.Text or "")
        end)

        Creator.AddSignal(SearchInput.Focused, function()
            SearchInput.Text = ""
        end)

        Creator.AddSignal(UserInputService.InputBegan, function(Input, GameProcessed)
            if GameProcessed then
                return
            end

            if Input.KeyCode == Enum.KeyCode.Escape and SearchInput:IsFocused() then
                SearchInput.Text = ""
                SearchInput:ReleaseFocus()
            end
        end)

        Window.SearchElements = SearchElements
        Window.AllElements = AllElements
        Window.RegisterElement = RegisterElement
        Window.UpdateElementVisibility = UpdateElementVisibility

        local ImageOffset = HasImage and (ImageSize + 10 + TopOffset) or TopOffset
        local TotalOffset = SearchHeight + ImageOffset

        local TabFrame = New("Frame", {
            Size = UDim2.new(0, Window.TabWidth, 1, -62),
            Position = UDim2.new(0, 12, 0, 54),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
        }, {
            ImageFrame,
            SearchFrame,
            Window.TabHolder,
            Selector,
        })

        Window.TabFrame = TabFrame

        Window.ContainerHolder = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
        })

        Window.ContainerAnim = New("CanvasGroup", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
        })

        Window.ContainerCanvas = New("Frame", {
            Size = UDim2.new(1, -Window.TabWidth - 32, 1, -56),
            Position = UDim2.fromOffset(Window.TabWidth + 26, 48),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
        }, {
            Window.ContainerAnim,
            Window.ContainerHolder,
        })

        local RootChildren = {}

        table.insert(RootChildren, Window.AcrylicPaint.Frame)
        table.insert(RootChildren, Window.ContainerCanvas)
        table.insert(RootChildren, TabFrame)
        table.insert(RootChildren, ResizeStartFrame)

        Window.Root = New("Frame", {
            BackgroundTransparency = 1,
            Size = Window.Size,
            Position = Window.Position,
            Parent = Config.Parent,
        }, RootChildren)

        CenterWindow()

        Creator.AddSignal(Camera:GetPropertyChangedSignal("ViewportSize"), CenterWindow)

        Window.TitleBar = Components.TitleBar({
            Title = Config.Title,
            SubTitle = Config.SubTitle,
            Icon = Config.Icon,
            Parent = Window.Root,
        })

        do
            local UserInfoHeight = 56

            Window.UserInfoHeight = UserInfoHeight

            local UserInfoSection = New("Frame", {
                Name = "UserInfoSection",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, UserInfoHeight),
                Position = UDim2.new(0, 0, 1, -(UserInfoHeight + 2)),
                ZIndex = 15,
                Parent = TabFrame,
            })

            New("Frame", {
                Name = "UserInfoSeparator",
                BackgroundTransparency = 0.5,
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 1, -(UserInfoHeight + 4)),
                ZIndex = 15,
                Parent = TabFrame,
                ThemeTag = { BackgroundColor3 = "TitleBarLine" },
            })

            local AvatarSize = 28
            local Avatar = New("ImageLabel", {
                Name = "Avatar",
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(AvatarSize, AvatarSize),
                Position = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Image = "",
                Parent = UserInfoSection,
            }, {
                New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                New("UIStroke", { Transparency = 0.7, Thickness = 1, ThemeTag = { Color = "ElementBorder" } }),
            })

            pcall(function()
                local Content, IsReady = Players:GetUserThumbnailAsync(
                    Players.LocalPlayer.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size100x100
                )

                if IsReady and Content then
                    Avatar.Image = Content
                end
            end)

            local TitleText = tostring(LocalPlayer.DisplayName or LocalPlayer.Name)
            local SubtitleText = "@" .. tostring(LocalPlayer.Name)

            New("TextLabel", {
                Name = "UserName",
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                TextSize = 13,
                Text = TitleText,
                Size = UDim2.new(1, -AvatarSize - 12, 0.5, 0),
                Position = UDim2.new(0, AvatarSize + 12, 0, -2),
                Parent = UserInfoSection,
                ThemeTag = { TextColor3 = "Text" },
            })

            New("TextLabel", {
                Name = "UserSubtitle",
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                TextSize = 12,
                TextTransparency = 0.4,
                Text = SubtitleText,
                Size = UDim2.new(1, -AvatarSize - 12, 0.5, 0),
                Position = UDim2.new(0, AvatarSize + 12, 0.5, 2),
                Parent = UserInfoSection,
                ThemeTag = { TextColor3 = "Text" },
            })

            Window.TabHolder.Size = UDim2.new(1, 0, 1, -(TabHolderTop + 6 + UserInfoHeight))
        end

        local SizeMotor = Flipper.GroupMotor.New({
            X = Window.Size.X.Offset,
            Y = Window.Size.Y.Offset,
        })

        local PosMotor = Flipper.GroupMotor.New({
            X = Window.Position.X.Offset,
            Y = Window.Position.Y.Offset,
        })

        Window.SelectorPosMotor = Flipper.SingleMotor.New(17)
        Window.SelectorSizeMotor = Flipper.SingleMotor.New(0)
        Window.ContainerBackMotor = Flipper.SingleMotor.New(0)
        Window.ContainerPosMotor = Flipper.SingleMotor.New(94)
        Window.ContainerXMotor = Flipper.SingleMotor.New(0)

        SizeMotor:OnStep(function(Values)
            Window.Root.Size = UDim2.new(0, Values.X, 0, Values.Y)
        end)

        PosMotor:OnStep(function(Values)
            Window.Root.Position = UDim2.new(0, Values.X, 0, Values.Y)
        end)

        local LastValue = 0
        local LastTime = 0

        Window.SelectorPosMotor:OnStep(function(Value)
            local Base = Window.TabHolderTop or 45
            local VerticalInset = 16
            local SelectorY = Base + Value + VerticalInset

            local SearchOffset = Window.HasImage and (Window.ImageSize + Window.TopOffset + 10) or Window.TopOffset
            local SearchTop = SearchOffset
            local SearchBottom = SearchTop + 28

            if Window.HasImage and Window.ImageSize then
                local ImageBottom = Window.ImageSize + Window.TopOffset + 10

                if SelectorY < ImageBottom then
                    Selector.Visible = false
                    return
                end
            end

            if SelectorY >= SearchTop and SelectorY <= SearchBottom then
                Selector.Visible = false
                return
            end

            if Window.UserInfoHeight and Window.TabFrame then
                local TabFrameSize = Window.TabFrame.AbsoluteSize.Y
                local UserInfoTop = TabFrameSize - Window.UserInfoHeight - 2
                local UserInfoBottom = UserInfoTop + Window.UserInfoHeight

                if SelectorY >= UserInfoTop and SelectorY <= UserInfoBottom then
                    Selector.Visible = false
                    return
                end
            end

            Selector.Visible = true
            Selector.Position = UDim2.new(0, 0, 0, SelectorY)

            local Now = tick()
            local DeltaTime = Now - LastTime

            if LastValue ~= nil then
                Window.SelectorSizeMotor:SetGoal(Spring((math.abs(Value - LastValue) / (DeltaTime * 60)) + 16))
                LastValue = Value
            end

            LastTime = Now
        end)

        Window.SelectorSizeMotor:OnStep(function(Value)
            Selector.Size = UDim2.new(0, 4, 0, Value)
        end)

        Window.ContainerBackMotor:OnStep(function(Value)
            Window.ContainerAnim.GroupTransparency = Value
        end)

        local ContainerXValue = 0
        local ContainerYValue = 94

        local function UpdateContainerPosition()
            if Window.ContainerAnim then
                Window.ContainerAnim.Position = UDim2.fromOffset(ContainerXValue, ContainerYValue)
            end
        end

        Window.ContainerPosMotor:OnStep(function(Value)
            ContainerYValue = Value
            UpdateContainerPosition()
        end)

        Window.ContainerXMotor:OnStep(function(Value)
            ContainerXValue = Value
            UpdateContainerPosition()
        end)

        local OldSizeX
        local OldSizeY

        Window.Maximize = function(Value, NoPos, NoSpring)
            Window.Maximized = Value

            if Value then
                OldSizeX = Window.Size.X.Offset
                OldSizeY = Window.Size.Y.Offset
            end

            local SizeX = Value and Camera.ViewportSize.X or OldSizeX
            local SizeY = Value and Camera.ViewportSize.Y or OldSizeY

            SizeMotor:SetGoal({
                X = Flipper[NoSpring and "Instant" or "Spring"].New(SizeX, { frequency = 6 }),
                Y = Flipper[NoSpring and "Instant" or "Spring"].New(SizeY, { frequency = 6 }),
            })

            Window.Size = UDim2.fromOffset(SizeX, SizeY)

            if not NoPos then
                PosMotor:SetGoal({
                    X = Spring(Value and 0 or Window.Position.X.Offset, { frequency = 6 }),
                    Y = Spring(Value and 0 or Window.Position.Y.Offset, { frequency = 6 }),
                })
            end
        end

        Creator.AddSignal(Window.TitleBar.Frame.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                MousePos = Input.Position
                StartPos = Window.Root.Position

                if Window.Maximized then
                    StartPos = UDim2.fromOffset(
                        Mouse.X - (Mouse.X * ((OldSizeX - 100) / Window.Root.AbsoluteSize.X)),
                        Mouse.Y - (Mouse.Y * (OldSizeY / Window.Root.AbsoluteSize.Y))
                    )
                end

                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)

        Creator.AddSignal(Window.TitleBar.Frame.InputChanged, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                DragInput = Input
            end
        end)

        Creator.AddSignal(ResizeStartFrame.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Resizing = true
                ResizePos = Input.Position
            end
        end)

        Creator.AddSignal(UserInputService.InputChanged, function(Input)
            if Input == DragInput and Dragging then
                local Delta = Input.Position - MousePos

                Window.Position = UDim2.fromOffset(StartPos.X.Offset + Delta.X, StartPos.Y.Offset + Delta.Y)

                PosMotor:SetGoal({
                    X = Instant(Window.Position.X.Offset),
                    Y = Instant(Window.Position.Y.Offset),
                })

                if Window.Maximized then
                    Window.Maximize(false, true, true)
                end
            end

            if (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
                and Resizing
            then
                local Delta = Input.Position - ResizePos
                local StartSize = Window.Size
                local TargetSize = Vector3.new(StartSize.X.Offset, StartSize.Y.Offset, 0)
                    + Vector3.new(1, 1, 0) * Delta

                local TargetSizeClamped =
                    Vector2.new(math.clamp(TargetSize.X, 470, 2048), math.clamp(TargetSize.Y, 380, 2048))

                SizeMotor:SetGoal({
                    X = Flipper.Instant.New(TargetSizeClamped.X),
                    Y = Flipper.Instant.New(TargetSizeClamped.Y),
                })
            end
        end)

        Creator.AddSignal(UserInputService.InputEnded, function(Input)
            if Resizing == true or Input.UserInputType == Enum.UserInputType.Touch then
                Resizing = false

                Window.Size = UDim2.fromOffset(SizeMotor:GetValue().X, SizeMotor:GetValue().Y)
            end
        end)

        Creator.AddSignal(Window.TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            if Window.TabHolder and Window.TabHolder.UIListLayout then
                local Padding = Window.TabHolder:FindFirstChild("UIPadding")
                local PaddingTop = Padding and Padding.PaddingTop.Offset or 6
                local PaddingBottom = Padding and Padding.PaddingBottom.Offset or 6
                local ContentSize = Window.TabHolder.UIListLayout.AbsoluteContentSize.Y + PaddingTop + PaddingBottom

                if ContentSize > 0 then
                    Window.TabHolder.CanvasSize = UDim2.new(0, 0, 0, ContentSize)
                end
            end
        end)

        Creator.AddSignal(UserInputService.InputBegan, function(Input)
            if type(Library.MinimizeKeybind) == "table"
                and Library.MinimizeKeybind.Type == "Keybind"
                and not UserInputService:GetFocusedTextBox()
            then
                if Input.KeyCode.Name == Library.MinimizeKeybind.Value then
                    Window:Minimize()
                end
            elseif Input.KeyCode == Library.MinimizeKey and not UserInputService:GetFocusedTextBox() then
                Window:Minimize()
            end
        end)

        function Window:Minimize()
            Window.Minimized = not Window.Minimized
            Window.Root.Visible = not Window.Minimized

            for _, Option in Library.Options do
                if Option and Option.Type == "Dropdown" and Option.Opened then
                    Option:Close()
                end
            end

            if not MinimizeNotif then
                MinimizeNotif = true

                local Key = Library.MinimizeKeybind and Library.MinimizeKeybind.Value or Library.MinimizeKey.Name

                if not Mobile then
                    Library:Notify({
                        Title = "Interface",
                        Content = "Press " .. Key .. " to Toggle UI",
                        Duration = 5,
                    })
                end
            end
        end

        function Window:Destroy()
            Window.Root:Destroy()
        end

        local DialogModule = Components.Dialog:Init(Window)

        function Window:Dialog(DialogConfig)
            local Dialog = DialogModule:Create()

            Dialog.Title.Text = DialogConfig.Title

            local ContentHolder = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                ScrollBarImageTransparency = 0.7,
                ScrollBarThickness = 4,
                BottomImage = "",
                MidImage = "",
                TopImage = "",
                Position = UDim2.fromOffset(20, 60),
                Size = UDim2.new(1, -40, 1, -110),
                CanvasSize = UDim2.fromOffset(0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Parent = Dialog.Root,
            })

            local Content = New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                Text = DialogConfig.Content,
                RichText = true,
                TextColor3 = Color3.fromRGB(240, 240, 240),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped = true,
                Size = UDim2.new(1, -8, 0, 0),
                BackgroundTransparency = 1,
                Parent = ContentHolder,
                ThemeTag = { TextColor3 = "Text" },
            })

            New("UISizeConstraint", {
                MinSize = Vector2.new(300, 165),
                MaxSize = Vector2.new(620, math.huge),
                Parent = Dialog.Root,
            })

            local MaxWidth = math.min(620, Window.Size.X.Offset - 120)
            local BaseWidth = math.max(300, math.min(MaxWidth, Content.TextBounds.X + 40))

            Dialog.Root.Size = UDim2.fromOffset(BaseWidth, 165)
            ContentHolder.Size = UDim2.new(1, -40, 1, -110)

            task.defer(function()
                local ContentHeight = Content.TextBounds.Y
                local Desired = math.clamp(ContentHeight + 110, 165, 420)

                Dialog.Root.Size = UDim2.fromOffset(BaseWidth, Desired)
                ContentHolder.CanvasSize = UDim2.fromOffset(0, ContentHeight)
            end)

            for _, ButtonConfig in DialogConfig.Buttons do
                Dialog:Button(ButtonConfig.Title, ButtonConfig.Callback)
            end

            Dialog:Open()
        end

        local TabModule = Components.Tab:Init(Window)

        Window.TabModule = TabModule
        Window.Tabs = TabModule.Tabs

        function Window:AddTab(TabConfig)
            return TabModule:New(TabConfig.Title, TabConfig.Icon, Window.TabHolder)
        end

        function Window:SelectTab(Tab)
            TabModule:SelectTab(Tab)
        end

        Creator.AddSignal(Window.TabHolder:GetPropertyChangedSignal("CanvasPosition"), function()
            LastValue = TabModule:GetCurrentTabPos() + 16
            LastTime = 0

            Window.SelectorPosMotor:SetGoal(Instant(TabModule:GetCurrentTabPos()))
        end)

        return Window
    end
end)()

local ElementsTable = {}
local AddSignal = Creator.AddSignal

ElementsTable.Button = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Button"

    function Element:New(Config)
        assert(Config.Title, "Button - Missing Title")

        Config.Callback = Config.Callback or function() end

        local ButtonFrame = Components.Element(Config.Title, Config.Description, self.Container, true, Config)

        local ButtonIconLabel = New("ImageLabel", {
            Size = UDim2.fromOffset(16, 16),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            BackgroundTransparency = 1,
            Parent = ButtonFrame.Frame,
            ThemeTag = { ImageColor3 = "Text" },
        })

        Library:ApplyIcon(ButtonIconLabel, "cursor-click-20-filled")

        Creator.AddSignal(ButtonFrame.Frame.MouseButton1Click, function()
            Library:SafeCallback(Config.Callback)
        end)

        return ButtonFrame
    end

    return Element
end)()

ElementsTable.Toggle = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Toggle"

    function Element:New(Idx, Config)
        assert(Config.Title, "Toggle - Missing Title")

        local Toggle = {
            Value = Config.Default or false,
            Callback = Config.Callback or function(Value) end,
            Type = "Toggle",
        }

        local ToggleFrame = Components.Element(Config.Title, Config.Description, self.Container, true, Config)

        ToggleFrame.DescLabel.Size = UDim2.new(1, -54, 0, 14)

        Toggle.SetTitle = ToggleFrame.SetTitle
        Toggle.SetDesc = ToggleFrame.SetDesc
        Toggle.Visible = ToggleFrame.Visible
        Toggle.Elements = ToggleFrame

        local ToggleCircle = New("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.new(0, 2, 0.5, 0),
            ImageTransparency = 0.5,
            ThemeTag = { ImageColor3 = "ToggleSlider" },
        })

        Library:ApplyIcon(ToggleCircle, "circle-20-filled")

        local ToggleBorder = New("UIStroke", {
            Transparency = 0.5,
            ThemeTag = { Color = "ToggleSlider" },
        })

        local ToggleSlider = New("Frame", {
            Size = UDim2.fromOffset(36, 18),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Parent = ToggleFrame.Frame,
            BackgroundTransparency = 1,
            ThemeTag = { BackgroundColor3 = "Accent" },
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 9) }),
            ToggleBorder,
            ToggleCircle,
        })

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func

            Func(Toggle.Value)
        end

        function Toggle:SetValue(Value)
            Value = not not Value
            Toggle.Value = Value

            Creator.OverrideTag(ToggleBorder, { Color = Toggle.Value and "Accent" or "ToggleSlider" })
            Creator.OverrideTag(ToggleCircle, { ImageColor3 = Toggle.Value and "ToggleToggled" or "ToggleSlider" })

            TweenService:Create(
                ToggleCircle,
                TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                { Position = UDim2.new(0, Toggle.Value and 19 or 2, 0.5, 0) }
            ):Play()

            TweenService:Create(
                ToggleSlider,
                TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                { BackgroundTransparency = Toggle.Value and 0.45 or 1 }
            ):Play()

            ToggleCircle.ImageTransparency = Toggle.Value and 0 or 0.5
            Library:SafeCallback(Toggle.Changed, Toggle.Value)

            task.spawn(function()
                Library:SafeCallback(Toggle.Callback, Toggle.Value)
            end)
        end

        function Toggle:Destroy()
            ToggleFrame:Destroy()

            Library.Options[Idx] = nil
        end

        Creator.AddSignal(ToggleFrame.Frame.MouseButton1Click, function()
            Toggle:SetValue(not Toggle.Value)
        end)

        Toggle:SetValue(Toggle.Value)

        Library.Options[Idx] = Toggle

        return Toggle
    end

    return Element
end)()

ElementsTable.Dropdown = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Dropdown"

    function Element:New(Idx, Config)
        local Dropdown = {
            Values = Config.Values,
            Value = Config.Default,
            Multi = Config.Multi,
            Buttons = {},
            Opened = false,
            Type = "Dropdown",
            Callback = Config.Callback or function() end,
            Search = true,
            KeepSearch = Config.KeepSearch == true,
        }

        if Dropdown.Multi and (Config.AllowNull or type(Config.Value) ~= "table") then
            Dropdown.Value = {}
        end

        local DropdownFrame = Components.Element(Config.Title, Config.Description, self.Container, false, Config)

        DropdownFrame.DescLabel.Size = UDim2.new(1, -170, 0, 14)

        Dropdown.SetTitle = DropdownFrame.SetTitle
        Dropdown.SetDesc = DropdownFrame.SetDesc
        Dropdown.Visible = DropdownFrame.Visible
        Dropdown.Elements = DropdownFrame

        local Container = self.Container

        local DropdownDisplay = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            Text = "",
            TextColor3 = Color3.fromRGB(240, 240, 240),
            TextSize = 14,
            AutomaticSize = Enum.AutomaticSize.Y,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -40, 0.5, 0),
            Position = UDim2.new(0, 8, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ThemeTag = { TextColor3 = "Text" },
        })

        local DropdownIco = New("ImageLabel", {
            Size = UDim2.fromOffset(16, 16),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            BackgroundTransparency = 1,
            Rotation = 180,
            ThemeTag = { ImageColor3 = "SubText" },
        })

        Library:ApplyIcon(DropdownIco, "chevron-down-20-filled")

        local DropdownInner = New("TextButton", {
            Size = UDim2.fromOffset(160, 30),
            Position = UDim2.new(1, -10, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 0.9,
            Parent = DropdownFrame.Frame,
            ThemeTag = { BackgroundColor3 = "DropdownFrame" },
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 5) }),
            New("UIStroke", {
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = { Color = "InElementBorder" },
            }),
            DropdownIco,
            DropdownDisplay,
        })

        local DropdownListLayout = New("UIListLayout", {
            Padding = UDim.new(0, 3),
        })

        local DropdownScrollFrame = New("ScrollingFrame", {
            Size = UDim2.new(1, -5, 1, -10),
            Position = UDim2.fromOffset(5, 5),
            BackgroundTransparency = 1,
            BottomImage = "",
            MidImage = "",
            TopImage = "",
            ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
            ScrollBarImageTransparency = 0.75,
            ScrollBarThickness = 5,
            BorderSizePixel = 0,
            CanvasSize = UDim2.fromScale(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, {
            DropdownListLayout,
        })

        local SearchBar = New("Frame", {
            Size = UDim2.new(1, -10, 0, 28),
            Position = UDim2.fromOffset(5, 5),
            BackgroundTransparency = 0.7,
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            ThemeTag = { BackgroundColor3 = "Element" },
            ZIndex = 24,
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 4) }),
        })

        local SearchBox = New("TextBox", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -36, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            PlaceholderText = "Search",
            PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
            ClearTextOnFocus = false,
            Text = "",
            Parent = SearchBar,
            ThemeTag = { TextColor3 = "Text", PlaceholderColor3 = "SubText" },
            ZIndex = 24,
        })

        local DropdownSearchIconLabel = New("ImageLabel", {
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(1, -13, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Parent = SearchBar,
            ImageTransparency = 0.3,
            ZIndex = 25,
            ThemeTag = { ImageColor3 = "SubText" },
        })

        Library:ApplyIcon(DropdownSearchIconLabel, "search-20-filled")

        DropdownScrollFrame.Position = UDim2.fromOffset(5, 38)
        DropdownScrollFrame.Size = UDim2.new(1, -5, 1, -43)

        local RecalculateCanvasSize, RecalculateListSize, RecalculateListPosition
        local FilterToken = 0

        local function ApplyFilter()
            FilterToken = FilterToken + 1

            local MyToken = FilterToken

            task.spawn(function()
                if MyToken ~= FilterToken then
                    return
                end

                local Text = (SearchBox.Text or ""):lower()

                for _, Element in DropdownScrollFrame:GetChildren() do
                    if not Element:IsA("UIListLayout") then
                        local Value = Element:FindFirstChild("ButtonLabel") and Element.ButtonLabel.Text or ""

                        Element.Visible = Text == "" or Value:lower():find(Text, 1, true) ~= nil
                    end
                end

                RecalculateCanvasSize()
                RecalculateListSize()
                RecalculateListPosition()
            end)
        end

        Creator.AddSignal(SearchBox:GetPropertyChangedSignal("Text"), ApplyFilter)

        local DropdownHolderFrame = New("Frame", {
            Size = UDim2.fromScale(1, 0.6),
            ThemeTag = { BackgroundColor3 = "DropdownHolder" },
        }, {
            SearchBar,
            DropdownScrollFrame,
            New("UICorner", { CornerRadius = UDim.new(0, 7) }),
            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = { Color = "DropdownBorder" },
            }),
            New("ImageLabel", {
                BackgroundTransparency = 1,
                Image = "",
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(23, 23, 277, 277),
                Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(30, 30),
                Position = UDim2.fromOffset(-15, -15),
                ImageColor3 = Color3.fromRGB(0, 0, 0),
                ImageTransparency = 0.1,
            }),
        })

        local DropdownHolderCanvas = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(170, 300),
            Parent = Library.GUI,
            Visible = false,
        }, {
            DropdownHolderFrame,
            New("UISizeConstraint", { MinSize = Vector2.new(170, 0) }),
        })

        table.insert(Library.OpenFrames, DropdownHolderCanvas)

        local WindowRoot = Library.Window and Library.Window.Root or nil

        function RecalculateListPosition()
            if not DropdownHolderCanvas or not DropdownInner then
                return
            end

            local DropdownX = DropdownInner.AbsolutePosition.X
            local DropdownY = DropdownInner.AbsolutePosition.Y
            local DropdownHeight = DropdownInner.AbsoluteSize.Y
            local CanvasWidth = DropdownHolderCanvas.AbsoluteSize.X
            local CanvasHeight = DropdownHolderCanvas.AbsoluteSize.Y
            local ViewportHeight = Camera.ViewportSize.Y
            local ViewportWidth = Camera.ViewportSize.X

            if not WindowRoot then
                WindowRoot = Library.Window and Library.Window.Root

                if not WindowRoot and Container then
                    local Parent = Container.Parent

                    while Parent do
                        if Parent:IsA("Frame") then
                            if Parent:FindFirstChild("ContainerCanvas") or Parent:FindFirstChild("TitleBar") then
                                WindowRoot = Parent
                                break
                            end
                        end

                        if Parent:IsA("ScreenGui") then
                            break
                        end

                        Parent = Parent.Parent
                    end
                end
            end

            local TargetX = DropdownX - 1

            if WindowRoot then
                local WindowX = WindowRoot.AbsolutePosition.X
                local WindowWidth = WindowRoot.AbsoluteSize.X
                local WindowRight = WindowX + WindowWidth
                local CanvasRight = DropdownX + CanvasWidth - 1

                if CanvasRight > WindowRight then
                    TargetX = math.max(WindowX + 5, WindowRight - CanvasWidth - 5)
                end
            else
                local CanvasRight = DropdownX + CanvasWidth - 1

                if CanvasRight > ViewportWidth then
                    TargetX = math.max(5, ViewportWidth - CanvasWidth - 5)
                end
            end

            local TargetY
            local SpaceBelow = ViewportHeight - (DropdownY + DropdownHeight)
            local SpaceAbove = DropdownY

            if CanvasHeight <= SpaceBelow then
                TargetY = DropdownY + DropdownHeight + 5
            elseif CanvasHeight <= SpaceAbove then
                TargetY = DropdownY - CanvasHeight - 5
            else
                if SpaceBelow > SpaceAbove then
                    TargetY = DropdownY + DropdownHeight + 5
                else
                    TargetY = math.max(5, DropdownY - CanvasHeight - 5)
                end
            end

            DropdownHolderCanvas.Position = UDim2.fromOffset(TargetX, TargetY)
        end

        local ListSizeX = 0

        function RecalculateListSize()
            if not DropdownHolderCanvas or not DropdownHolderFrame then
                return
            end

            local VisibleCount = 0

            for _, Element in DropdownScrollFrame:GetChildren() do
                if not Element:IsA("UIListLayout") and Element.Visible then
                    VisibleCount = VisibleCount + 1
                end
            end

            local ItemHeight = 32
            local Padding = 3
            local SearchHeight = 38
            local InnerMargins = 10

            local EstimatedContent = (VisibleCount > 0)
                    and (VisibleCount * ItemHeight + (VisibleCount - 1) * Padding + InnerMargins + SearchHeight)
                or (InnerMargins + SearchHeight)

            local MaxHeight = 392
            local TargetHeight = math.min(EstimatedContent, MaxHeight)
            local CanvasWidth = math.max(170, ListSizeX > 0 and (ListSizeX + 20) or 170)

            DropdownHolderCanvas.Size = UDim2.fromOffset(CanvasWidth, TargetHeight)
            DropdownHolderFrame.Size = UDim2.fromScale(1, 1)
        end

        function RecalculateCanvasSize()
            DropdownScrollFrame.CanvasSize = UDim2.fromOffset(0, DropdownListLayout.AbsoluteContentSize.Y)
        end

        RecalculateListPosition()
        RecalculateListSize()
        RecalculateCanvasSize()

        Creator.AddSignal(DropdownInner:GetPropertyChangedSignal("AbsolutePosition"), RecalculateListPosition)

        if WindowRoot then
            Creator.AddSignal(WindowRoot:GetPropertyChangedSignal("AbsolutePosition"), function()
                if Dropdown.Opened then
                    RecalculateListPosition()
                end
            end)

            Creator.AddSignal(WindowRoot:GetPropertyChangedSignal("AbsoluteSize"), function()
                if Dropdown.Opened then
                    RecalculateListPosition()
                end
            end)
        end

        Creator.AddSignal(DropdownListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            RecalculateCanvasSize()
            RecalculateListSize()
            RecalculateListPosition()
        end)

        Creator.AddSignal(DropdownInner.MouseButton1Click, function()
            if Dropdown.Opened then
                Dropdown:Close()
            else
                Dropdown:Open()
            end
        end)

        Creator.AddSignal(DropdownInner.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.Touch then
                if Dropdown.Opened then
                    Dropdown:Close()
                else
                    Dropdown:Open()
                end
            end
        end)

        Creator.AddSignal(UserInputService.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch
            then
                local MousePos = Input.UserInputType == Enum.UserInputType.MouseButton1
                        and Vector2.new(Mouse.X, Mouse.Y)
                    or Input.Position

                local AbsPos, AbsSize = DropdownHolderFrame.AbsolutePosition, DropdownHolderFrame.AbsoluteSize
                local InnerAbsPos, InnerAbsSize = DropdownInner.AbsolutePosition, DropdownInner.AbsoluteSize

                local ClickedInsideDropdown = MousePos.X >= AbsPos.X
                    and MousePos.X <= AbsPos.X + AbsSize.X
                    and MousePos.Y >= AbsPos.Y
                    and MousePos.Y <= AbsPos.Y + AbsSize.Y

                local ClickedInsideInner = MousePos.X >= InnerAbsPos.X
                    and MousePos.X <= InnerAbsPos.X + InnerAbsSize.X
                    and MousePos.Y >= InnerAbsPos.Y
                    and MousePos.Y <= InnerAbsPos.Y + InnerAbsSize.Y

                if not ClickedInsideDropdown and not ClickedInsideInner then
                    Dropdown:Close()
                end
            end
        end)

        function Dropdown:Open()
            if Dropdown.Opened then
                return
            end

            Dropdown.Opened = true

            for _, Frame in Library.OpenFrames do
                if Frame ~= DropdownHolderCanvas and Frame.Visible then
                    Frame.Visible = false
                end
            end

            if SearchBox and not Dropdown.KeepSearch then
                SearchBox.Text = ""
            end

            DropdownHolderCanvas.Visible = true

            RecalculateListPosition()
            RecalculateListSize()
            RecalculateCanvasSize()

            TweenService:Create(
                DropdownHolderFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                { Size = UDim2.fromScale(1, 1) }
            ):Play()

            TweenService:Create(
                DropdownIco,
                TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                { Rotation = 0 }
            ):Play()
        end

        function Dropdown:Close()
            Dropdown.Opened = false

            DropdownHolderFrame.Size = UDim2.fromScale(1, 1)
            DropdownHolderCanvas.Visible = false

            TweenService:Create(
                DropdownIco,
                TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                { Rotation = 180 }
            ):Play()

            Dropdown:Display()

            for _, Element in DropdownScrollFrame:GetChildren() do
                if not Element:IsA("UIListLayout") then
                    Element.Visible = true
                end
            end
        end

        function Dropdown:Display()
            local Values = Dropdown.Values
            local Str = ""

            if Config.Multi then
                for Idx, Value in Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ", "
                    end
                end

                Str = Str:sub(1, #Str - 2)
            else
                Str = Dropdown.Value or ""
            end

            DropdownDisplay.Text = (Str == "" and "--" or Str)
        end

        function Dropdown:GetActiveValues()
            if Config.Multi then
                local T = {}

                for Value in Dropdown.Value do
                    table.insert(T, Value)
                end

                return T
            else
                return Dropdown.Value and 1 or 0
            end
        end

        function Dropdown:SetActiveValues(Value)
            Dropdown.Value = Value

            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            task.spawn(function()
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            end)

            Dropdown:BuildDropdownList()
        end

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local Buttons = {}

            for _, Element in DropdownScrollFrame:GetChildren() do
                if not Element:IsA("UIListLayout") then
                    Element:Destroy()
                end
            end

            for _, Value in Values do
                local Table = {}

                local ButtonSelector = New("Frame", {
                    Size = UDim2.fromOffset(4, 14),
                    BackgroundColor3 = Color3.fromRGB(76, 194, 255),
                    Position = UDim2.fromOffset(-1, 16),
                    AnchorPoint = Vector2.new(0, 0.5),
                    ThemeTag = { BackgroundColor3 = "Accent" },
                }, {
                    New("UICorner", { CornerRadius = UDim.new(0, 2) }),
                })

                local ButtonLabel = New("TextLabel", {
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    Text = Value,
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Position = UDim2.fromOffset(10, 0),
                    Name = "ButtonLabel",
                    ThemeTag = { TextColor3 = "Text" },
                })

                local Button = New("TextButton", {
                    Size = UDim2.new(1, -5, 0, 32),
                    BackgroundTransparency = 1,
                    ZIndex = 23,
                    Text = "",
                    Parent = DropdownScrollFrame,
                    ThemeTag = { BackgroundColor3 = "DropdownOption" },
                }, {
                    ButtonSelector,
                    ButtonLabel,
                    New("UICorner", { CornerRadius = UDim.new(0, 6) }),
                })

                local Selected

                if Config.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end

                local BackMotor, SetBackTransparency = Creator.SpringMotor(1, Button, "BackgroundTransparency")
                local SelMotor, SetSelTransparency = Creator.SpringMotor(1, ButtonSelector, "BackgroundTransparency")
                local SelectorSizeMotor = Flipper.SingleMotor.New(6)

                SelectorSizeMotor:OnStep(function(Value2)
                    ButtonSelector.Size = UDim2.new(0, 4, 0, Value2)
                end)

                Creator.AddSignal(Button.MouseEnter, function()
                    SetBackTransparency(Selected and 0.85 or 0.89)
                end)

                Creator.AddSignal(Button.MouseLeave, function()
                    SetBackTransparency(Selected and 0.89 or 1)
                end)

                Creator.AddSignal(Button.MouseButton1Down, function()
                    SetBackTransparency(0.92)
                end)

                Creator.AddSignal(Button.MouseButton1Up, function()
                    SetBackTransparency(Selected and 0.85 or 0.89)
                end)

                function Table:UpdateButton()
                    if Config.Multi then
                        Selected = Dropdown.Value[Value]

                        if Selected then
                            SetBackTransparency(0.89)
                        end
                    else
                        Selected = Dropdown.Value == Value

                        SetBackTransparency(Selected and 0.89 or 1)
                    end

                    SelectorSizeMotor:SetGoal(Flipper.Spring.New(Selected and 14 or 6, { frequency = 6 }))
                    SetSelTransparency(Selected and 0 or 1)
                end

                AddSignal(Button.Activated, function()
                    local Try = not Selected

                    if Dropdown:GetActiveValues() == 1 and not Try and not Config.AllowNull then
                    else
                        if Config.Multi then
                            Selected = Try
                            Dropdown.Value[Value] = Selected and true or nil
                        else
                            Selected = Try
                            Dropdown.Value = Selected and Value or nil

                            for _, OtherButton in Buttons do
                                OtherButton:UpdateButton()
                            end
                        end

                        Table:UpdateButton()

                        Dropdown:Display()

                        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                        task.spawn(function()
                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                        end)
                    end
                end)

                Table:UpdateButton()
                Dropdown:Display()

                Buttons[Button] = Table
            end

            ListSizeX = 0

            for Button in Buttons do
                if Button.ButtonLabel then
                    local TextSize = Button.ButtonLabel.TextBounds.X

                    if TextSize > ListSizeX then
                        ListSizeX = TextSize
                    end
                end
            end

            ListSizeX = math.max(150, ListSizeX + 40)

            RecalculateCanvasSize()
            RecalculateListSize()
        end

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func

            Func(Dropdown.Value)
        end

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local NTable = {}

                for Value in Val do
                    if table.find(Dropdown.Values, Value) then
                        NTable[Value] = true
                    end
                end

                Dropdown.Value = NTable
            else
                if not Val then
                    Dropdown.Value = nil
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val
                end
            end

            Dropdown:BuildDropdownList()

            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            task.spawn(function()
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            end)
        end

        function Dropdown:Destroy()
            DropdownFrame:Destroy()

            Library.Options[Idx] = nil
        end

        Dropdown:BuildDropdownList()
        Dropdown:Display()

        local Defaults = {}

        if type(Config.Default) == "string" then
            local Idx = table.find(Dropdown.Values, Config.Default)

            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Config.Default) == "table" then
            for _, Value in Config.Default do
                local Idx = table.find(Dropdown.Values, Value)

                if Idx then
                    table.insert(Defaults, Idx)
                end
            end
        elseif type(Config.Default) == "number" and Dropdown.Values[Config.Default] ~= nil then
            table.insert(Defaults, Config.Default)
        end

        if next(Defaults) then
            for I = 1, #Defaults do
                local Index = Defaults[I]

                if Config.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end

                if not Config.Multi then
                    break
                end
            end

            Dropdown:BuildDropdownList()
            Dropdown:Display()
        end

        Library.Options[Idx] = Dropdown

        return Dropdown
    end

    return Element
end)()

ElementsTable.Paragraph = (function()
    local Paragraph = {}
    Paragraph.__index = Paragraph
    Paragraph.__type = "Paragraph"

    function Paragraph:New(Config)
        Config.Content = Config.Content or ""

        local P = Components.Element(Config.Title, Config.Content, Paragraph.Container, false, Config)

        P.Frame.BackgroundTransparency = 0.92
        P.Border.Transparency = 0.6
        P.SetTitle = P.SetTitle
        P.SetDesc = P.SetDesc
        P.Visible = P.Visible
        P.Elements = P

        return P
    end

    return Paragraph
end)()

ElementsTable.Slider = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Slider"

    function Element:New(Idx, Config)
        assert(Config.Title, "Slider - Missing Title.")
        assert(Config.Default, "Slider - Missing default value.")
        assert(Config.Min, "Slider - Missing minimum value.")
        assert(Config.Max, "Slider - Missing maximum value.")
        assert(Config.Rounding, "Slider - Missing rounding value.")

        local Slider = {
            Value = nil,
            Min = Config.Min,
            Max = Config.Max,
            Rounding = Config.Rounding,
            Callback = Config.Callback or function(Value) end,
            Type = "Slider",
        }

        local Dragging = false

        local SliderFrame = Components.Element(Config.Title, Config.Description, self.Container, false, Config)

        SliderFrame.DescLabel.Size = UDim2.new(1, -170, 0, 14)

        Slider.Elements = SliderFrame
        Slider.SetTitle = SliderFrame.SetTitle
        Slider.SetDesc = SliderFrame.SetDesc
        Slider.Visible = SliderFrame.Visible

        local SliderDot = New("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, -7, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            ThemeTag = { ImageColor3 = "Accent" },
        })

        Library:ApplyIcon(SliderDot, "circle-20-filled")

        local SliderRail = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(7, 0),
            Size = UDim2.new(1, -14, 1, 0),
        }, {
            SliderDot,
        })

        local SliderFill = New("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            ThemeTag = { BackgroundColor3 = "Accent" },
        }, {
            New("UICorner", { CornerRadius = UDim.new(1, 0) }),
        })

        local SliderDisplay = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = "",
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Right,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 100, 0, 14),
            Position = UDim2.new(0, -4, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            ThemeTag = { TextColor3 = "SubText" },
        })

        local SliderInput = New("TextBox", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = "",
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 14),
            Position = UDim2.new(0, -4, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            PlaceholderText = "",
            ClearTextOnFocus = false,
            Visible = true,
            TextWrapped = false,
            TextTransparency = 1,
            BorderSizePixel = 0,
            ThemeTag = { TextColor3 = "SubText" },
        })

        New("Frame", {
            Size = UDim2.new(1, 0, 0, 4),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            BackgroundTransparency = 0.4,
            Parent = SliderFrame.Frame,
            ThemeTag = { BackgroundColor3 = "SliderRail" },
        }, {
            New("UICorner", { CornerRadius = UDim.new(1, 0) }),
            New("UISizeConstraint", { MaxSize = Vector2.new(150, math.huge) }),
            SliderDisplay,
            SliderInput,
            SliderFill,
            SliderRail,
        })

        local IsHovering = false
        local InputVisible = false
        local CurrentWidthTween = nil

        local function CalculateInputWidth(Text)
            local TextSize = TextService:GetTextSize(Text or "0", 12, Enum.Font.SourceSans, Vector2.new(1000, 14))

            return math.max(25, math.min(80, TextSize.X + 8))
        end

        local function UpdateInputWidth(Text, Animate)
            if CurrentWidthTween then
                CurrentWidthTween:Cancel()
                CurrentWidthTween = nil
            end

            local TargetWidth = CalculateInputWidth(Text)
            local CurrentWidth = SliderInput.Size.X.Offset

            if Animate and math.abs(TargetWidth - CurrentWidth) > 0.5 then
                CurrentWidthTween = TweenService:Create(
                    SliderInput,
                    TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    { Size = UDim2.new(0, TargetWidth, 0, 14) }
                )

                CurrentWidthTween:Play()

                CurrentWidthTween.Completed:Connect(function()
                    CurrentWidthTween = nil
                end)
            else
                SliderInput.Size = UDim2.new(0, TargetWidth, 0, 14)
            end
        end

        Creator.AddSignal(SliderFrame.Frame.MouseEnter, function()
            IsHovering = true

            if not SliderInput:IsFocused() then
                SliderDisplay.Visible = false
                SliderInput.Text = tostring(Slider.Value)

                UpdateInputWidth(tostring(Slider.Value), false)

                InputVisible = true

                TweenService:Create(
                    SliderInput,
                    TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    { TextTransparency = 0, BackgroundTransparency = 1 }
                ):Play()
            end
        end)

        Creator.AddSignal(SliderFrame.Frame.MouseLeave, function()
            IsHovering = false

            if not SliderInput:IsFocused() and InputVisible then
                TweenService:Create(
                    SliderInput,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
                    { TextTransparency = 1, BackgroundTransparency = 1 }
                ):Play()

                SliderDisplay.Visible = true
                InputVisible = false
            end
        end)

        Creator.AddSignal(SliderInput.Changed, function(Property)
            if Property == "Text" then
                local Text = SliderInput.Text
                local CleanText = Text:gsub("[^%d%.%-]", "")

                if CleanText:find("%-") and CleanText:find("%-") ~= 1 then
                    CleanText = CleanText:gsub("%-", "")
                end

                local DotCount = 0

                CleanText = CleanText:gsub("%.", function()
                    DotCount = DotCount + 1

                    return DotCount == 1 and "." or ""
                end)

                if CleanText ~= Text then
                    SliderInput.Text = CleanText
                    return
                end

                if InputVisible or SliderInput:IsFocused() then
                    UpdateInputWidth(CleanText, true)
                end
            end
        end)

        Creator.AddSignal(SliderInput.FocusLost, function()
            local InputValue = tonumber(SliderInput.Text)

            if InputValue then
                Slider:SetValue(InputValue)
            else
                SliderInput.Text = tostring(Slider.Value)

                UpdateInputWidth(tostring(Slider.Value), true)
            end

            if not IsHovering then
                TweenService:Create(
                    SliderInput,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
                    { TextTransparency = 1, BackgroundTransparency = 1 }
                ):Play()

                SliderDisplay.Visible = true
                InputVisible = false
            end
        end)

        Creator.AddSignal(SliderInput.Focused, function()
            SliderInput.Text = ""

            UpdateInputWidth("", false)
        end)

        Creator.AddSignal(SliderInput.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Dragging = false
            end
        end)

        Creator.AddSignal(SliderDot.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch
            then
                Dragging = true
            end
        end)

        Creator.AddSignal(SliderDot.InputEnded, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch
            then
                Dragging = false
            end
        end)

        Creator.AddSignal(UserInputService.InputChanged, function(Input)
            if Dragging then
                local Position = nil

                if Input.UserInputType == Enum.UserInputType.MouseMovement then
                    Position = Input.Position
                elseif Input.UserInputType == Enum.UserInputType.Touch then
                    Position = Input.Position
                end

                if Position then
                    local SizeScale =
                        math.clamp((Position.X - SliderRail.AbsolutePosition.X) / SliderRail.AbsoluteSize.X, 0, 1)

                    Slider:SetValue(Slider.Min + ((Slider.Max - Slider.Min) * SizeScale))
                end
            end
        end)

        Creator.AddSignal(SliderRail.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true

                local SizeScale =
                    math.clamp((Input.Position.X - SliderRail.AbsolutePosition.X) / SliderRail.AbsoluteSize.X, 0, 1)

                Slider:SetValue(Slider.Min + ((Slider.Max - Slider.Min) * SizeScale))
            end
        end)

        Creator.AddSignal(SliderRail.InputEnded, function(Input)
            if Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end)

        function Slider:OnChanged(Func)
            Slider.Changed = Func

            Func(Slider.Value)
        end

        function Slider:SetValue(Value)
            self.Value = Library:Round(math.clamp(Value, Slider.Min, Slider.Max), Slider.Rounding)

            SliderDot.Position = UDim2.new((self.Value - Slider.Min) / (Slider.Max - Slider.Min), -7, 0.5, 0)
            SliderFill.Size = UDim2.fromScale((self.Value - Slider.Min) / (Slider.Max - Slider.Min), 1)
            SliderDisplay.Text = tostring(self.Value)

            if InputVisible or SliderInput:IsFocused() then
                SliderInput.Text = tostring(self.Value)

                UpdateInputWidth(tostring(self.Value), not SliderInput:IsFocused())
            end

            if not InputVisible and not SliderInput:IsFocused() then
                SliderInput.Text = tostring(self.Value)
            end

            Library:SafeCallback(Slider.Changed, self.Value)
            task.spawn(function()
                Library:SafeCallback(Slider.Callback, self.Value)
            end)
        end

        function Slider:Destroy()
            SliderFrame:Destroy()

            Library.Options[Idx] = nil
        end

        Slider:SetValue(Config.Default)

        Library.Options[Idx] = Slider

        return Slider
    end

    return Element
end)()

ElementsTable.Keybind = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Keybind"

    function Element:New(Idx, Config)
        assert(Config.Title, "KeyBind - Missing Title")
        assert(Config.Default, "KeyBind - Missing default value.")

        local Keybind = {
            Value = Config.Default,
            Toggled = false,
            Mode = Config.Mode or "Toggle",
            Type = "Keybind",
            Callback = Config.Callback or function(Value) end,
            ChangedCallback = Config.ChangedCallback or function(New) end,
        }

        local Picking = false

        local KeybindFrame = Components.Element(Config.Title, Config.Description, self.Container, true)

        Keybind.SetTitle = KeybindFrame.SetTitle
        Keybind.SetDesc = KeybindFrame.SetDesc
        Keybind.Visible = KeybindFrame.Visible
        Keybind.Elements = KeybindFrame

        local KeybindDisplayLabel = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            Text = Config.Default,
            TextColor3 = Color3.fromRGB(240, 240, 240),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.new(0, 0, 0, 14),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            ThemeTag = { TextColor3 = "Text" },
        })

        local KeybindDisplayFrame = New("TextButton", {
            Size = UDim2.fromOffset(0, 30),
            Position = UDim2.new(1, -10, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 0.9,
            Parent = KeybindFrame.Frame,
            AutomaticSize = Enum.AutomaticSize.X,
            ThemeTag = { BackgroundColor3 = "Keybind" },
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 5) }),
            New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
            New("UIStroke", {
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = { Color = "InElementBorder" },
            }),
            KeybindDisplayLabel,
        })

        function Keybind:GetState()
            if UserInputService:GetFocusedTextBox() and Keybind.Mode ~= "Always" then
                return false
            end

            if Keybind.Mode == "Always" then
                return true
            elseif Keybind.Mode == "Hold" then
                if Keybind.Value == "None" then
                    return false
                end

                local Key = Keybind.Value

                if Key == "MouseLeft" or Key == "MouseRight" then
                    return Key == "MouseLeft" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == "MouseRight"
                            and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[Keybind.Value])
                end
            else
                return Keybind.Toggled
            end
        end

        function Keybind:SetValue(Key, Mode)
            Key = Key or Keybind.Key
            Mode = Mode or Keybind.Mode

            KeybindDisplayLabel.Text = Key
            Keybind.Value = Key
            Keybind.Mode = Mode
        end

        function Keybind:OnClick(Callback)
            Keybind.Clicked = Callback
        end

        function Keybind:OnChanged(Callback)
            Keybind.Changed = Callback

            Callback(Keybind.Value)
        end

        function Keybind:DoClick()
            Library:SafeCallback(Keybind.Changed, Keybind.Value)
            task.spawn(function()
                Library:SafeCallback(Keybind.Callback, Keybind.Toggled)
                Library:SafeCallback(Keybind.Clicked, Keybind.Toggled)
            end)
        end

        function Keybind:Destroy()
            KeybindFrame:Destroy()

            Library.Options[Idx] = nil
        end

        Creator.AddSignal(KeybindDisplayFrame.MouseButton1Click, function()
            if Picking then
                return
            end

            Picking = true
            KeybindDisplayLabel.Text = ". . ."

            task.defer(function()
                local Event

                Event = UserInputService.InputBegan:Connect(function(Input)
                    local Key

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = "MouseRight"
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton3 then
                        Key = "MouseMiddle"
                    end

                    if Key then
                        Picking = false
                        KeybindDisplayLabel.Text = Key
                        Keybind.Value = Key

                        Library:SafeCallback(Keybind.ChangedCallback, Input.KeyCode or Input.UserInputType)
                        Library:SafeCallback(Keybind.Changed, Input.KeyCode or Input.UserInputType)

                        Event:Disconnect()
                    end
                end)
            end)
        end)

        Creator.AddSignal(UserInputService.InputBegan, function(Input)
            if not Picking and not UserInputService:GetFocusedTextBox() then
                if Keybind.Mode == "Toggle" then
                    local Key = Keybind.Value

                    if Key == "MouseLeft" or Key == "MouseRight" then
                        if Key == "MouseLeft" and Input.UserInputType == Enum.UserInputType.MouseButton1
                            or Key == "MouseRight" and Input.UserInputType == Enum.UserInputType.MouseButton2
                        then
                            Keybind.Toggled = not Keybind.Toggled

                            Keybind:DoClick()
                        end
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            Keybind.Toggled = not Keybind.Toggled

                            Keybind:DoClick()
                        end
                    end
                end
            end
        end)

        Library.Options[Idx] = Keybind

        return Keybind
    end

    return Element
end)()

ElementsTable.Colorpicker = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Colorpicker"

    function Element:New(Idx, Config)
        assert(Config.Title, "Colorpicker - Missing Title")
        assert(Config.Default, "AddColorPicker: Missing default value.")

        local Colorpicker = {
            Value = Config.Default,
            Transparency = Config.Transparency or 0,
            Type = "Colorpicker",
            Title = type(Config.Title) == "string" and Config.Title or "Colorpicker",
            Callback = Config.Callback or function(Color) end,
        }

        function Colorpicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color)

            Colorpicker.Hue = H
            Colorpicker.Sat = S
            Colorpicker.Vib = V
        end

        Colorpicker:SetHSVFromRGB(Colorpicker.Value)

        local ColorpickerFrame = Components.Element(Config.Title, Config.Description, self.Container, true)

        Colorpicker.SetTitle = ColorpickerFrame.SetTitle
        Colorpicker.SetDesc = ColorpickerFrame.SetDesc
        Colorpicker.Visible = ColorpickerFrame.Visible
        Colorpicker.Elements = ColorpickerFrame

        local DisplayFrameColor = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Colorpicker.Value,
            Parent = ColorpickerFrame.Frame,
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 4) }),
        })

        New("ImageLabel", {
            Size = UDim2.fromOffset(26, 26),
            Position = UDim2.new(1, -10, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Parent = ColorpickerFrame.Frame,
            Image = "",
            ImageTransparency = 0.45,
            ScaleType = Enum.ScaleType.Tile,
            TileSize = UDim2.fromOffset(40, 40),
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 4) }),
            DisplayFrameColor,
        })

        local function CreateColorDialog()
            local Dialog = Components.Dialog:Create()

            Dialog.Title.Text = Colorpicker.Title
            Dialog.Root.Size = UDim2.fromOffset(430, 330)

            local Hue, Sat, Vib = Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib
            local Transparency = Colorpicker.Transparency

            local function CreateInput()
                local Box = Components.Textbox()

                Box.Frame.Parent = Dialog.Root
                Box.Frame.Size = UDim2.new(0, 90, 0, 32)

                return Box
            end

            local function CreateInputLabel(Text, Pos)
                return New("TextLabel", {
                    FontFace = Font.new(
                        "rbxasset://fonts/families/GothamSSm.json",
                        Enum.FontWeight.Medium,
                        Enum.FontStyle.Normal
                    ),
                    Text = Text,
                    TextColor3 = Color3.fromRGB(240, 240, 240),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 0, 32),
                    Position = Pos,
                    BackgroundTransparency = 1,
                    Parent = Dialog.Root,
                    ThemeTag = { TextColor3 = "Text" },
                })
            end

            local function GetRGB()
                local Value = Color3.fromHSV(Hue, Sat, Vib)

                return {
                    R = math.floor(Value.r * 255),
                    G = math.floor(Value.g * 255),
                    B = math.floor(Value.b * 255),
                }
            end

            local SatCursor = New("ImageLabel", {
                Size = UDim2.new(0, 18, 0, 18),
                ScaleType = Enum.ScaleType.Fit,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
            })

            Library:ApplyIcon(SatCursor, "circle-20-regular")

            local SatVibMap = New("ImageLabel", {
                Size = UDim2.fromOffset(180, 160),
                Position = UDim2.fromOffset(20, 55),
                Image = "",
                BackgroundColor3 = Colorpicker.Value,
                BackgroundTransparency = 0,
                Parent = Dialog.Root,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 4) }),
                SatCursor,
            })

            local OldColorFrame = New("Frame", {
                BackgroundColor3 = Colorpicker.Value,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = Colorpicker.Transparency,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 4) }),
            })

            New("ImageLabel", {
                Image = "",
                ImageTransparency = 0.45,
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.fromOffset(40, 40),
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(112, 220),
                Size = UDim2.fromOffset(88, 24),
                Parent = Dialog.Root,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 4) }),
                New("UIStroke", { Thickness = 2, Transparency = 0.75 }),
                OldColorFrame,
            })

            local DialogDisplayFrame = New("Frame", {
                BackgroundColor3 = Colorpicker.Value,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 0,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 4) }),
            })

            New("ImageLabel", {
                Image = "",
                ImageTransparency = 0.45,
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.fromOffset(40, 40),
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(20, 220),
                Size = UDim2.fromOffset(88, 24),
                Parent = Dialog.Root,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 4) }),
                New("UIStroke", { Thickness = 2, Transparency = 0.75 }),
                DialogDisplayFrame,
            })

            local SequenceTable = {}

            for Color = 0, 1, 0.1 do
                table.insert(SequenceTable, ColorSequenceKeypoint.new(Color, Color3.fromHSV(Color, 1, 1)))
            end

            local HueDragHolder = New("Frame", {
                Size = UDim2.new(1, 0, 1, -10),
                Position = UDim2.fromOffset(0, 5),
                BackgroundTransparency = 1,
            })

            local HueDrag = New("ImageLabel", {
                Size = UDim2.fromOffset(14, 14),
                Parent = HueDragHolder,
                ThemeTag = { ImageColor3 = "DialogInput" },
            })

            Library:ApplyIcon(HueDrag, "circle-20-filled")

            local HueSlider = New("Frame", {
                Size = UDim2.fromOffset(12, 190),
                Position = UDim2.fromOffset(210, 55),
                Parent = Dialog.Root,
            }, {
                New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                New("UIGradient", {
                    Color = ColorSequence.new(SequenceTable),
                    Rotation = 90,
                }),
                HueDragHolder,
            })

            local HexInput = CreateInput()

            HexInput.Frame.Position = UDim2.fromOffset(Config.Transparency and 260 or 240, 55)
            CreateInputLabel("Hex", UDim2.fromOffset(Config.Transparency and 360 or 340, 55))

            local RedInput = CreateInput()

            RedInput.Frame.Position = UDim2.fromOffset(Config.Transparency and 260 or 240, 95)
            CreateInputLabel("Red", UDim2.fromOffset(Config.Transparency and 360 or 340, 95))

            local GreenInput = CreateInput()

            GreenInput.Frame.Position = UDim2.fromOffset(Config.Transparency and 260 or 240, 135)
            CreateInputLabel("Green", UDim2.fromOffset(Config.Transparency and 360 or 340, 135))

            local BlueInput = CreateInput()

            BlueInput.Frame.Position = UDim2.fromOffset(Config.Transparency and 260 or 240, 175)
            CreateInputLabel("Blue", UDim2.fromOffset(Config.Transparency and 360 or 340, 175))

            local AlphaInput

            if Config.Transparency then
                AlphaInput = CreateInput()

                AlphaInput.Frame.Position = UDim2.fromOffset(260, 215)
                CreateInputLabel("Alpha", UDim2.fromOffset(360, 215))
            end

            local TransparencySlider, TransparencyDrag, TransparencyColor

            if Config.Transparency then
                local TransparencyDragHolder = New("Frame", {
                    Size = UDim2.new(1, 0, 1, -10),
                    Position = UDim2.fromOffset(0, 5),
                    BackgroundTransparency = 1,
                })

                TransparencyDrag = New("ImageLabel", {
                    Size = UDim2.fromOffset(14, 14),
                    Parent = TransparencyDragHolder,
                    ThemeTag = { ImageColor3 = "DialogInput" },
                })

                Library:ApplyIcon(TransparencyDrag, "circle-20-filled")

                TransparencyColor = New("Frame", {
                    Size = UDim2.fromScale(1, 1),
                }, {
                    New("UIGradient", {
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1),
                        }),
                        Rotation = 270,
                    }),
                    New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })

                TransparencySlider = New("Frame", {
                    Size = UDim2.fromOffset(12, 190),
                    Position = UDim2.fromOffset(230, 55),
                    Parent = Dialog.Root,
                    BackgroundTransparency = 1,
                }, {
                    New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    New("ImageLabel", {
                        Image = "",
                        ImageTransparency = 0.45,
                        ScaleType = Enum.ScaleType.Tile,
                        TileSize = UDim2.fromOffset(40, 40),
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        Parent = Dialog.Root,
                    }, {
                        New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    }),
                    TransparencyColor,
                    TransparencyDragHolder,
                })
            end

            local function Display()
                SatVibMap.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)

                HueDrag.Position = UDim2.new(0, -1, Hue, -6)
                SatCursor.Position = UDim2.new(Sat, 0, 1 - Vib, 0)
                DialogDisplayFrame.BackgroundColor3 = Color3.fromHSV(Hue, Sat, Vib)
                HexInput.Input.Text = "#" .. Color3.fromHSV(Hue, Sat, Vib):ToHex()
                RedInput.Input.Text = GetRGB()["R"]
                GreenInput.Input.Text = GetRGB()["G"]
                BlueInput.Input.Text = GetRGB()["B"]

                if Config.Transparency then
                    TransparencyColor.BackgroundColor3 = Color3.fromHSV(Hue, Sat, Vib)
                    DialogDisplayFrame.BackgroundTransparency = Transparency
                    TransparencyDrag.Position = UDim2.new(0, -1, 1 - Transparency, -6)
                    AlphaInput.Input.Text = Library:Round((1 - Transparency) * 100, 0) .. "%"
                end
            end

            Creator.AddSignal(HexInput.Input.FocusLost, function(Enter)
                if Enter then
                    local Success, Result = pcall(Color3.fromHex, HexInput.Input.Text)

                    if Success and typeof(Result) == "Color3" then
                        Hue, Sat, Vib = Color3.toHSV(Result)
                    end
                end

                Display()
            end)

            Creator.AddSignal(RedInput.Input.FocusLost, function(Enter)
                if Enter then
                    local CurrentColor = GetRGB()

                    local Success, Result =
                        pcall(Color3.fromRGB, RedInput.Input.Text, CurrentColor["G"], CurrentColor["B"])

                    if Success and typeof(Result) == "Color3" then
                        if tonumber(RedInput.Input.Text) <= 255 then
                            Hue, Sat, Vib = Color3.toHSV(Result)
                        end
                    end
                end

                Display()
            end)

            Creator.AddSignal(GreenInput.Input.FocusLost, function(Enter)
                if Enter then
                    local CurrentColor = GetRGB()

                    local Success, Result =
                        pcall(Color3.fromRGB, CurrentColor["R"], GreenInput.Input.Text, CurrentColor["B"])

                    if Success and typeof(Result) == "Color3" then
                        if tonumber(GreenInput.Input.Text) <= 255 then
                            Hue, Sat, Vib = Color3.toHSV(Result)
                        end
                    end
                end

                Display()
            end)

            Creator.AddSignal(BlueInput.Input.FocusLost, function(Enter)
                if Enter then
                    local CurrentColor = GetRGB()

                    local Success, Result =
                        pcall(Color3.fromRGB, CurrentColor["R"], CurrentColor["G"], BlueInput.Input.Text)

                    if Success and typeof(Result) == "Color3" then
                        if tonumber(BlueInput.Input.Text) <= 255 then
                            Hue, Sat, Vib = Color3.toHSV(Result)
                        end
                    end
                end

                Display()
            end)

            if Config.Transparency then
                Creator.AddSignal(AlphaInput.Input.FocusLost, function(Enter)
                    if Enter then
                        local Value = tonumber(AlphaInput.Input.Text)

                        if Value and Value >= 0 and Value <= 100 then
                            Transparency = 1 - Value * 0.01
                        end
                    end

                    Display()
                end)
            end

            Creator.AddSignal(SatVibMap.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1
                    or Input.UserInputType == Enum.UserInputType.Touch
                then
                    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local MinX = SatVibMap.AbsolutePosition.X
                        local MaxX = MinX + SatVibMap.AbsoluteSize.X
                        local MouseX = math.clamp(Mouse.X, MinX, MaxX)

                        local MinY = SatVibMap.AbsolutePosition.Y
                        local MaxY = MinY + SatVibMap.AbsoluteSize.Y
                        local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

                        Sat = (MouseX - MinX) / (MaxX - MinX)
                        Vib = 1 - ((MouseY - MinY) / (MaxY - MinY))

                        Display()

                        RenderStepped:Wait()
                    end
                end
            end)

            Creator.AddSignal(HueSlider.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1
                    or Input.UserInputType == Enum.UserInputType.Touch
                then
                    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local MinY = HueSlider.AbsolutePosition.Y
                        local MaxY = MinY + HueSlider.AbsoluteSize.Y
                        local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

                        Hue = (MouseY - MinY) / (MaxY - MinY)

                        Display()

                        RenderStepped:Wait()
                    end
                end
            end)

            if Config.Transparency then
                Creator.AddSignal(TransparencySlider.InputBegan, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            local MinY = TransparencySlider.AbsolutePosition.Y
                            local MaxY = MinY + TransparencySlider.AbsoluteSize.Y
                            local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

                            Transparency = 1 - ((MouseY - MinY) / (MaxY - MinY))

                            Display()

                            RenderStepped:Wait()
                        end
                    end
                end)
            end

            Display()

            Dialog:Button("Done", function()
                Colorpicker:SetValue({ Hue, Sat, Vib }, Transparency)
            end)

            Dialog:Button("Cancel")
            Dialog:Open()
        end

        function Colorpicker:Display()
            Colorpicker.Value = Color3.fromHSV(Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib)

            DisplayFrameColor.BackgroundColor3 = Colorpicker.Value
            DisplayFrameColor.BackgroundTransparency = Colorpicker.Transparency

            Library:SafeCallback(Colorpicker.Changed, Colorpicker.Value)
            task.spawn(function()
                Library:SafeCallback(Colorpicker.Callback, Colorpicker.Value)
            end)
        end

        function Colorpicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])

            Colorpicker.Transparency = Transparency or 0

            Colorpicker:SetHSVFromRGB(Color)
            Colorpicker:Display()
        end

        function Colorpicker:SetValueRGB(Color, Transparency)
            Colorpicker.Transparency = Transparency or 0

            Colorpicker:SetHSVFromRGB(Color)
            Colorpicker:Display()
        end

        function Colorpicker:OnChanged(Func)
            Colorpicker.Changed = Func

            Func(Colorpicker.Value)
        end

        function Colorpicker:Destroy()
            ColorpickerFrame:Destroy()

            Library.Options[Idx] = nil
        end

        Creator.AddSignal(ColorpickerFrame.Frame.MouseButton1Click, function()
            CreateColorDialog()
        end)

        Creator.AddSignal(ColorpickerFrame.Frame.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.Touch then
                CreateColorDialog()
            end
        end)

        Colorpicker:Display()

        Library.Options[Idx] = Colorpicker

        return Colorpicker
    end

    return Element
end)()

ElementsTable.Input = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Input"

    function Element:New(Idx, Config)
        assert(Config.Title, "Input - Missing Title")

        Config.Callback = Config.Callback or function() end

        local Input = {
            Value = Config.Default or "",
            Numeric = Config.Numeric or false,
            Finished = Config.Finished or false,
            Callback = Config.Callback or function(Value) end,
            Type = "Input",
        }

        local InputFrame = Components.Element(Config.Title, Config.Description, self.Container, false)

        Input.SetTitle = InputFrame.SetTitle
        Input.SetDesc = InputFrame.SetDesc
        Input.Visible = InputFrame.Visible
        Input.Elements = InputFrame

        local Textbox = Components.Textbox(InputFrame.Frame)

        Textbox.Frame.Position = UDim2.new(1, -10, 0.5, 0)
        Textbox.Frame.AnchorPoint = Vector2.new(1, 0.5)
        Textbox.Frame.Size = UDim2.fromOffset(160, 30)
        Textbox.Input.Text = Config.Default or ""
        Textbox.Input.PlaceholderText = Config.Placeholder or ""

        local Box = Textbox.Input

        function Input:SetValue(Text)
            if Config.MaxLength and #Text > Config.MaxLength then
                Text = Text:sub(1, Config.MaxLength)
            end

            if Input.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Input.Value
                end
            end

            Input.Value = Text
            Box.Text = Text

            Library:SafeCallback(Input.Changed, Input.Value)
            task.spawn(function()
                Library:SafeCallback(Input.Callback, Input.Value)
            end)
        end

        AddSignal(Box.Focused, function()
            Box.Text = ""
        end)

        if Input.Finished then
            AddSignal(Box.FocusLost, function(Enter)
                if not Enter then
                    return
                end

                Input:SetValue(Box.Text)
            end)
        else
            AddSignal(Box:GetPropertyChangedSignal("Text"), function()
                Input:SetValue(Box.Text)
            end)
        end

        function Input:OnChanged(Func)
            Input.Changed = Func

            Func(Input.Value)
        end

        function Input:Destroy()
            InputFrame:Destroy()

            Library.Options[Idx] = nil
        end

        Library.Options[Idx] = Input

        return Input
    end

    return Element
end)()

local NotificationModule = Components.Notification

NotificationModule:Init(GUI)

local SaveManager = {}
local Elements = {}

Elements.__index = Elements

local function AttachElementMethods(Target)
    for _, ElementComponent in ElementsTable do
        local MethodName = "Add" .. ElementComponent.__type

        if Target[MethodName] == nil then
            Target[MethodName] = function(self, Idx, Config)
                ElementComponent.Container = self.Container
                ElementComponent.Type = self.Type
                ElementComponent.ScrollFrame = self.ScrollFrame
                ElementComponent.Library = Library

                local CreatedElement = ElementComponent:New(Idx, Config)

                if CreatedElement and CreatedElement.OnChanged and Library.AutoConfig then
                    CreatedElement:OnChanged(function()
                        task.defer(function()
                            if Library.ElementsReady and not Library.LoadingConfig and Library.SettingLoaded then
                                SaveManager:Save(Library.AutoConfig)
                            end
                        end)
                    end)
                end

                return CreatedElement
            end
        end
    end
end

Library.AttachElementMethods = AttachElementMethods

do
    SaveManager.Folder = "Ssamachi"
    SaveManager.Ignore = {}

    local function Pick(Data, ...)
        for _, Key in { ... } do
            local V = Data[Key]

            if V ~= nil then
                return V
            end
        end

        return nil
    end

    SaveManager.Parser = {
        Toggle = {
            Save = function(Idx, Object)
                return { Type = "Toggle", Idx = Idx, Value = Object.Value == true }
            end,
            Load = function(Idx, Data)
                local Option = SaveManager.Options and SaveManager.Options[Idx]
                if not Option then
                    Option = Library.Options and Library.Options[Idx]
                end
                if Option and Option.SetValue then
                    local V = Pick(Data, "Value", "value")
                    if V ~= nil then
                        Option:SetValue(V == true or V == "true" or V == 1)
                    end
                end
            end,
        },
        Slider = {
            Save = function(Idx, Object)
                return { Type = "Slider", Idx = Idx, Value = tonumber(Object.Value) or Object.Value }
            end,
            Load = function(Idx, Data)
                local Option = SaveManager.Options and SaveManager.Options[Idx]
                if not Option then
                    Option = Library.Options and Library.Options[Idx]
                end
                if Option and Option.SetValue then
                    local V = Pick(Data, "Value", "value")
                    if V ~= nil then
                        Option:SetValue(tonumber(V) or V)
                    end
                end
            end,
        },
        Dropdown = {
            Save = function(Idx, Object)
                return { Type = "Dropdown", Idx = Idx, Value = Object.Value, Multi = Object.Multi }
            end,
            Load = function(Idx, Data)
                local Option = SaveManager.Options and SaveManager.Options[Idx]
                if not Option then
                    Option = Library.Options and Library.Options[Idx]
                end
                if Option and Option.SetValue then
                    local V = Pick(Data, "Value", "value")
                    if V ~= nil then
                        Option:SetValue(V)
                    end
                end
            end,
        },
        Colorpicker = {
            Save = function(Idx, Object)
                return {
                    Type = "Colorpicker",
                    Idx = Idx,
                    Value = Object.Value:ToHex(),
                    Transparency = Object.Transparency,
                }
            end,
            Load = function(Idx, Data)
                local Option = SaveManager.Options and SaveManager.Options[Idx]
                if not Option then
                    Option = Library.Options and Library.Options[Idx]
                end
                if Option and Option.SetValueRGB then
                    local Hex = Pick(Data, "Value", "value")
                    local Trans = Pick(Data, "Transparency", "transparency") or 0
                    if Hex then
                        local Ok, Color = pcall(Color3.fromHex, Hex)
                        if Ok and Color then
                            Option:SetValueRGB(Color, Trans)
                        end
                    end
                end
            end,
        },
        Keybind = {
            Save = function(Idx, Object)
                return { Type = "Keybind", Idx = Idx, Mode = Object.Mode, Key = Object.Value }
            end,
            Load = function(Idx, Data)
                local Option = SaveManager.Options and SaveManager.Options[Idx]
                if not Option then
                    Option = Library.Options and Library.Options[Idx]
                end
                if Option and Option.SetValue then
                    local Key = Pick(Data, "Key", "key")
                    local Mode = Pick(Data, "Mode", "mode")
                    if Key then
                        Option:SetValue(Key, Mode)
                    end
                end
            end,
        },
        Input = {
            Save = function(Idx, Object)
                return { Type = "Input", Idx = Idx, Text = tostring(Object.Value or "") }
            end,
            Load = function(Idx, Data)
                local Option = SaveManager.Options and SaveManager.Options[Idx]
                if not Option then
                    Option = Library.Options and Library.Options[Idx]
                end
                local Text = Pick(Data, "Text", "text")
                if Option and Option.SetValue and type(Text) == "string" then
                    Option:SetValue(Text)
                end
            end,
        },
    }

    function SaveManager:SetIgnoreIndexes(List)
        for _, Key in List do
            self.Ignore[Key] = true
        end
    end

    function SaveManager:SetFolder(Folder)
        self.Folder = Folder

        self:BuildFolderTree()
    end

    function SaveManager:Save(Name)
        if not Name then
            return false, "no config file is selected"
        end

        if Library.LoadingConfig then
            return false, "loading in progress"
        end

        self:BuildFolderTree()

        local FullPath = self.Folder .. "/" .. Name .. ".json"
        local Data = { Objects = {} }
        local Options = self.Options or Library.Options or {}

        for Idx, Option in Options do
            if Option and Option.Type and self.Parser[Option.Type] and not self.Ignore[Idx] then
                local Ok, Saved = pcall(self.Parser[Option.Type].Save, Idx, Option)

                if Ok and Saved then
                    table.insert(Data.Objects, Saved)
                end
            end
        end

        local Success, Encoded = pcall(HttpService.JSONEncode, HttpService, Data)
        if not Success then
            return false, "failed to encode data"
        end

        local WriteOk, WriteErr = pcall(writefile, FullPath, Encoded)
        if not WriteOk then
            return false, tostring(WriteErr)
        end

        return true
    end

    function SaveManager:Load(Name)
        if not Name then
            return false, "no config file is selected"
        end

        self.Options = Library.Options

        if not Library.ElementsReady then
            task.defer(function()
                SaveManager:Load(Name)
            end)

            return false, "elements not ready"
        end

        local File = self.Folder .. "/" .. Name .. ".json"

        if not isfile(File) then
            Library.SettingLoaded = true

            if Ssamachi then
                Ssamachi.SettingLoaded = true
            end

            return false, "Create Config Save File"
        end

        local Success, Decoded = pcall(HttpService.JSONDecode, HttpService, readfile(File))
        if not Success or type(Decoded) ~= "table" then
            Library.SettingLoaded = true
            return false, "decode error"
        end

        local Objects = Decoded.Objects or Decoded.objects or {}
        local OptionCount = 0

        for _ in Library.Options or {} do
            OptionCount = OptionCount + 1
        end

        if #Objects > 0 and OptionCount == 0 then
            if not self._EmptyRetry then
                self._EmptyRetry = 0
            end

            self._EmptyRetry = self._EmptyRetry + 1

            if self._EmptyRetry <= 15 then
                task.defer(function()
                    SaveManager:Load(Name)
                end)

                return false, "options not registered yet"
            end

            Library.SettingLoaded = true
            self._EmptyRetry = 0

            return false, "no options registered"
        end

        self._EmptyRetry = 0

        Library.LoadingConfig = true
        self.Options = Library.Options

        local Applied = 0
        local Missing = 0

        for _, OptionData in Objects do
            local OptionType = OptionData.Type or OptionData.type
            local OptionIdx = OptionData.Idx or OptionData.idx

            if OptionType and OptionIdx and self.Parser[OptionType] and not self.Ignore[OptionIdx] then
                local Exists = Library.Options and Library.Options[OptionIdx]

                if Exists then
                    local Ok, Err = pcall(function()
                        self.Parser[OptionType].Load(OptionIdx, OptionData)
                    end)
                    if Ok then
                        Applied = Applied + 1
                    end
                else
                    Missing = Missing + 1
                end
            end
        end

        if Missing > 0 and not self._RetriedLoad then
            self._RetriedLoad = true

            task.defer(function()
                Library.LoadingConfig = false
                SaveManager:Load(Name)
                self._RetriedLoad = false
            end)

            return false, "retrying for late options"
        end

        self._RetriedLoad = false

        task.delay(0.25, function()
            Library.LoadingConfig = false
            Library.SettingLoaded = true

            if Ssamachi then
                Ssamachi.SettingLoaded = true
            end
        end)

        return true, Decoded, Applied
    end

    function SaveManager:BuildFolderTree()
        local Paths = { self.Folder, self.Folder .. "/" }

        for _, Str in Paths do
            if not isfolder(Str) then
                makefolder(Str)
            end
        end
    end

    function SaveManager:SetLibrary(Lib)
        self.Library = Lib
        self.Options = Lib.Options
    end

    SaveManager:BuildFolderTree()
end

Library.SaveManager = SaveManager
Library.Elements = Elements

function Library:CreateWindow(Config)
    assert(Config.Title, "Window - Missing Title")

    if Library.Window then
        print("You cannot create more than one window.")
        return
    end

    Library.MinimizeKey = Config.MinimizeKey or Enum.KeyCode.LeftControl
    Library.Theme = "Darker"

    Config.BackgroundTransparency = 0

    local Window = Components.Window({
        Parent = GUI,
        Size = Config.Size,
        Title = Config.Title,
        Icon = Config.Icon,
        Image = Config.Image,
        BackgroundTransparency = 0,
        SubTitle = Config.SubTitle,
        TabWidth = Config.TabWidth,
    })

    Library.Window = Window

    table.insert(Library.Windows, Window)

    Library:SetTheme("Darker")

    if Config.AutoConfig then
        Library.AutoConfig = tostring(Config.AutoConfig)

        SaveManager:SetLibrary(Library)
    end

    task.defer(function()
        if
            Window.TabModule
            and #Window.TabModule.Tabs > 0
            and (Window.TabModule.SelectedTab == 0 or Window.TabModule.SelectedTab == nil)
        then
            Window:SelectTab(1)
        end

        Library.ElementsReady = true

        if Library.AutoConfig then
            Library.SettingLoaded = false
            Library.LoadingConfig = true

            SaveManager:BuildFolderTree()
            SaveManager:SetLibrary(Library)

            task.spawn(function()
                local Deadline = tick() + 5
                local LastCount = 0
                local Stable = 0

                while tick() < Deadline do
                    local Count = 0

                    for _ in Library.Options do
                        Count = Count + 1
                    end

                    if Count > 0 and Count == LastCount then
                        Stable = Stable + 1
                        if Stable >= 5 then
                            break
                        end
                    else
                        Stable = 0
                    end

                    LastCount = Count
                    task.wait()
                end

                SaveManager:SetLibrary(Library)

                local Ok, Result, Applied = SaveManager:Load(Library.AutoConfig)

                task.delay(0.5, function()
                    if not Library.SettingLoaded then
                        Library.LoadingConfig = false
                        Library.SettingLoaded = true

                        if Ssamachi then
                            Ssamachi.SettingLoaded = true
                        end
                    end
                end)
            end)
        end
    end)

    local ShowMinimizer = true

    if not Mobile then
        if Config.Minimizer ~= nil then
            ShowMinimizer = Config.Minimizer
        end
    end

    if ShowMinimizer and not Library.Minimizer then
        local ParentGui = Library.GUI or GUI

        if ParentGui then
            ParentGui.DisplayOrder = 1000
        end

        local Holder = New("Frame", {
            Name = "SsamachiMinimizer",
            Parent = ParentGui,
            Size = UDim2.fromOffset(50, 50),
            Position = UDim2.new(1, -50, 0, 50),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            ZIndex = 999999999,
            Visible = true,
        })

        local BtnInstance = New("TextButton", {
            Name = "MinimizeButton",
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            BackgroundTransparency = 0,
            AutoButtonColor = true,
            Parent = Holder,
            ZIndex = 1000000000,
            ThemeTag = { BackgroundColor3 = "Element" },
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 10) }),
            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Transparency = 0.6,
                Thickness = 2,
                ThemeTag = { Color = "ElementBorder" },
            }),
        })

        if Config.Image then
            local IconLabel = New("ImageLabel", {
                Name = "Icon",
                Size = UDim2.new(0.8, 0, 0.8, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Parent = BtnInstance,
                ThemeTag = { ImageColor3 = "Text" },
            }, {
                New("UIAspectRatioConstraint", { AspectRatio = 1, AspectType = Enum.AspectType.FitWithinMaxSize }),
                New("UICorner", { CornerRadius = UDim.new(0, 0) }),
            })
            Library:ApplyIcon(IconLabel, Config.Image)
        end

        local Dragging = false
        local DragMoved = false
        local DragStartPos = nil
        local HolderStartAbs = nil

        local function ClampHolderPosition(X, Y)
            local Viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            local Size = Holder.AbsoluteSize
            local MaxX = math.max(0, Viewport.X - Size.X)
            local MaxY = math.max(0, Viewport.Y - Size.Y)
            return math.clamp(X, 0, MaxX), math.clamp(Y, 0, MaxY)
        end

        Creator.AddSignal(BtnInstance.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch
            then
                Dragging = true
                DragMoved = false
                DragStartPos = Vector2.new(Input.Position.X, Input.Position.Y)
                HolderStartAbs = Holder.AbsolutePosition

                local Conn
                Conn = Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        local WasClick = not DragMoved
                        Dragging = false
                        DragStartPos = nil
                        HolderStartAbs = nil
                        Conn:Disconnect()

                        if WasClick and Library.Window then
                            Library.Window:Minimize()
                        end
                    end
                end)
            end
        end)

        Creator.AddSignal(UserInputService.InputChanged, function(Input)
            if not Dragging or not DragStartPos or not HolderStartAbs then
                return
            end

            if Input.UserInputType ~= Enum.UserInputType.MouseMovement
                and Input.UserInputType ~= Enum.UserInputType.Touch
            then
                return
            end

            local Current = Vector2.new(Input.Position.X, Input.Position.Y)
            local Delta = Current - DragStartPos

            if not DragMoved and Delta.Magnitude < 4 then
                return
            end

            DragMoved = true

            local NewX, NewY = ClampHolderPosition(
                HolderStartAbs.X + Delta.X,
                HolderStartAbs.Y + Delta.Y
            )

            Holder.AnchorPoint = Vector2.new(0, 0)
            Holder.Position = UDim2.fromOffset(NewX, NewY)
        end)

        Library.Minimizer = Holder
    end

    return Window
end

function Library:SetTheme(Value)
    Library.Theme = "Darker"
    Creator.Theme = "Darker"

    Creator.UpdateTheme()
end

function Library:Notify(Config)
    return NotificationModule:New(Config)
end

if getgenv then
    getgenv().Ssamachi = Library
else
    Ssamachi = Library
end

return Library
