--[[
    Muscle Legends - Auto Farm GUI (إصدار مصحح)
    المكان: Muscle Legends (Place ID: 3623096087)
--]]

-- إعدادات الخدمات
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- التحقق من اللعبة الصحيحة
if game.PlaceId ~= 3623096087 then
    warn("⚠️ هذا السكريبت مصمم للعبة Muscle Legends فقط!")
    return
end

-- إعدادات السكريبت
local Settings = {
    AutoTrain = {
        Enabled = false,
        TrainSpeed = 50,
    },
    AutoCollect = {
        Enabled = false,
        CollectRange = 50,
    },
    AutoRebirth = {
        Enabled = false,
        RebirthAt = 10000,
    },
    Teleport = {
        SelectedGym = "Tiny Island",
    },
    AntiAFK = {
        Enabled = true,
    },
}

-- قائمة الصالات الرياضية
local Gyms = {
    "Tiny Island",
    "Frost Gym",
    "Mythical Gym",
    "Eternal Gym",
    "Legends Gym",
}

-- متغيرات التحكم (حلقات التشغيل)
local TrainLoop = nil
local CollectLoop = nil
local RebirthLoop = nil
local AntiAFKLoop = nil

-- ==================== الدوال الأساسية (يجب تعريفها قبل استخدامها) ====================

-- دالة التدريب التلقائي
local function startAutoTrain()
    if TrainLoop then TrainLoop:Disconnect() end
    if not Settings.AutoTrain.Enabled then return end

    TrainLoop = RunService.Heartbeat:Connect(function()
        if not Settings.AutoTrain.Enabled or not LocalPlayer.Character then return end
        
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        -- محاكاة النقر للتدريب
        pcall(function()
            VirtualUser:Button1Down(Vector2.new(0, 0))
            wait(0.1 / (Settings.AutoTrain.TrainSpeed / 10))
            VirtualUser:Button1Up(Vector2.new(0, 0))
        end)
    end)
end

-- دالة جمع العملات التلقائي
local function startAutoCollect()
    if CollectLoop then CollectLoop:Disconnect() end
    if not Settings.AutoCollect.Enabled then return end

    CollectLoop = RunService.Heartbeat:Connect(function()
        if not Settings.AutoCollect.Enabled or not LocalPlayer.Character then return end
        
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        -- البحث عن العملات القريبة
        local coins = workspace:FindPartsInRegion3(
            Region3.new(
                rootPart.Position - Vector3.new(Settings.AutoCollect.CollectRange, 10, Settings.AutoCollect.CollectRange),
                rootPart.Position + Vector3.new(Settings.AutoCollect.CollectRange, 10, Settings.AutoCollect.CollectRange)
            ),
            LocalPlayer.Character,
            100
        )
        
        for _, part in ipairs(coins) do
            if part:GetAttribute("IsCoin") or part.Name:lower():find("coin") or part.Name:lower():find("gem") then
                firetouchinterest(rootPart, part, 0)
                task.wait(0.05)
                firetouchinterest(rootPart, part, 1)
            end
        end
    end)
end

-- دالة التحقق من إعادة الميلاد
local function startRebirthCheck()
    if RebirthLoop then RebirthLoop:Disconnect() end
    if not Settings.AutoRebirth.Enabled then return end

    RebirthLoop = RunService.Heartbeat:Connect(function()
        if not Settings.AutoRebirth.Enabled then return end
        
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            local strength = leaderstats:FindFirstChild("Strength") or leaderstats:FindFirstChild("Power")
            if strength and strength.Value >= Settings.AutoRebirth.RebirthAt then
                -- محاولة إعادة الميلاد
                local rebirthRemote = game.ReplicatedStorage:FindFirstChild("Rebirth") 
                    or (game.ReplicatedStorage:FindFirstChild("RemoteEvent") and game.ReplicatedStorage.RemoteEvent:FindFirstChild("Rebirth"))
                
                if rebirthRemote then
                    rebirthRemote:FireServer()
                end
            end
        end
    end)
end

-- دالة الانتقال إلى الصالة
local function teleportToGym(gymName)
    if not LocalPlayer.Character then return end
    
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local gymLocation = workspace:FindFirstChild(gymName) 
        or (workspace:FindFirstChild("Gyms") and workspace.Gyms:FindFirstChild(gymName))
    
    if gymLocation and gymLocation:FindFirstChild("SpawnLocation") then
        local spawn = gymLocation:FindFirstChild("SpawnLocation")
        rootPart.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
        notify("✅ تم الانتقال إلى " .. gymName)
    else
        notify("❌ لم يتم العثور على الصالة", 3)
    end
end

-- دالة الإشعارات
local function notify(message, duration)
    duration = duration or 3
    local screenGui = ScreenGui  -- متغير عام معرف لاحقاً، لكننا سنمرره كمعامل أو نستخدم متغير عام
    
    -- تأكد من وجود ScreenGui
    if not ScreenGui then return end
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 250, 0, 40)
    notification.Position = UDim2.new(0.5, -125, 0, 50)
    notification.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    notification.BackgroundTransparency = 0.2
    notification.BorderSizePixel = 0
    notification.ZIndex = 200
    notification.Parent = ScreenGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notification
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -20, 1, 0)
    notifText.Position = UDim2.new(0, 10, 0, 0)
    notifText.BackgroundTransparency = 1
    notifText.TextColor3 = Color3.new(1, 1, 1)
    notifText.Text = message
    notifText.Font = Enum.Font.Gotham
    notifText.TextSize = 14
    notifText.ZIndex = 201
    notifText.Parent = notification
    
    task.delay(duration, function()
        notification:Destroy()
    end)
end

-- ==================== بناء واجهة المستخدم ====================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MuscleLegendsGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 1000
ScreenGui.ResetOnSpawn = false

-- الإطار الرئيسي
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 100
MainFrame.Parent = ScreenGui

-- زوايا دائرية للإطار الرئيسي
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- شريط العنوان
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 101
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0, 250, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.Text = "⚡ Muscle Legends - Auto Farm"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 102
TitleLabel.Parent = TitleBar

-- زر الإغلاق
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(1, -30, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 18
CloseButton.ZIndex = 102
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    if TrainLoop then TrainLoop:Disconnect() end
    if CollectLoop then CollectLoop:Disconnect() end
    if RebirthLoop then RebirthLoop:Disconnect() end
    if AntiAFKLoop then AntiAFKLoop:Disconnect() end
end)

-- إطار المحتوى القابل للتمرير
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -20, 1, -55)
ContentFrame.Position = UDim2.new(0, 10, 0, 45)
ContentFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ContentFrame.BorderSizePixel = 0
ContentFrame.ZIndex = 101
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
ContentFrame.ScrollBarThickness = 6
ContentFrame.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = ContentFrame

-- دالة إنشاء عنوان قسم
local function CreateSection(parent, text, yPos)
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, -20, 0, 30)
    section.Position = UDim2.new(0, 10, 0, yPos)
    section.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    section.TextColor3 = Color3.fromRGB(255, 200, 100)
    section.Text = "📌 " .. text
    section.Font = Enum.Font.GothamBold
    section.TextSize = 16
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.ZIndex = 102
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 5)
    sectionCorner.Parent = section
    
    return yPos + 40
end

-- دالة إنشاء زر تبديل (Toggle)
local function CreateToggle(parent, text, getFunc, setFunc, yPos, description)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 45)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    frame.BorderSizePixel = 0
    frame.ZIndex = 101
    frame.Parent = parent
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 102
    label.Parent = frame
    
    if description then
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -20, 0, 15)
        descLabel.Position = UDim2.new(0, 10, 0, 25)
        descLabel.BackgroundTransparency = 1
        descLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        descLabel.Text = description
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 11
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.ZIndex = 102
        descLabel.Parent = frame
    end
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 22, 0, 22)
    indicator.Position = UDim2.new(1, -35, 0, description and 12 or 11)
    indicator.BackgroundColor3 = getFunc() and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 102
    indicator.Parent = frame
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 4)
    indicatorCorner.Parent = indicator
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = 103
    button.Parent = frame
    
    button.MouseButton1Click:Connect(function()
        local newState = not getFunc()
        setFunc(newState)
        indicator.BackgroundColor3 = newState and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        
        -- تشغيل الوظائف المناسبة حسب التبديل
        if text == "تفعيل التدريب التلقائي" then
            if newState then startAutoTrain() else if TrainLoop then TrainLoop:Disconnect() end end
        elseif text == "تفعيل جمع العملات" then
            if newState then startAutoCollect() else if CollectLoop then CollectLoop:Disconnect() end end
        elseif text == "تفعيل إعادة الميلاد" then
            if newState then startRebirthCheck() else if RebirthLoop then RebirthLoop:Disconnect() end end
        end
    end)
    
    return yPos + 55
end

-- دالة إنشاء شريط تمرير (Slider) مع إصلاح مشكلة السحب
local function CreateSlider(parent, text, getFunc, setFunc, minVal, maxVal, yPos, description)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 55)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    frame.BorderSizePixel = 0
    frame.ZIndex = 101
    frame.Parent = parent
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = text .. ": " .. getFunc()
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 102
    label.Parent = frame
    
    if description then
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -20, 0, 15)
        descLabel.Position = UDim2.new(0, 10, 0, 38)
        descLabel.BackgroundTransparency = 1
        descLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        descLabel.Text = description
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 10
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.ZIndex = 102
        descLabel.Parent = frame
    end
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -80, 0, 6)
    sliderBg.Position = UDim2.new(0, 10, 0, 30)
    sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    sliderBg.BorderSizePixel = 0
    sliderBg.ZIndex = 102
    sliderBg.Parent = frame
    
    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(0, 3)
    sliderBgCorner.Parent = sliderBg
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 14, 0, 14)
    local percent = (getFunc() - minVal) / (maxVal - minVal)
    sliderButton.Position = UDim2.new(percent, -7, 0, -4)
    sliderButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    sliderButton.Text = ""
    sliderButton.ZIndex = 103
    sliderButton.Parent = sliderBg
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 7)
    sliderCorner.Parent = sliderButton
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 40, 0, 20)
    valueLabel.Position = UDim2.new(1, -50, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    valueLabel.Text = tostring(getFunc())
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 14
    valueLabel.ZIndex = 102
    valueLabel.Parent = frame
    
    -- متغير السحب
    local dragging = false
    
    sliderButton.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- استخدام RenderStepped للتحديث أثناء السحب
    RunService.RenderStepped:Connect(function()
        if dragging then
            local mousePos = UserInputService:GetMouseLocation()
            local absPos = sliderBg.AbsolutePosition.X
            local size = sliderBg.AbsoluteSize.X
            local relativeX = math.clamp(mousePos - absPos, 0, size)
            local newValue = math.floor(minVal + (relativeX / size) * (maxVal - minVal))
            setFunc(newValue)
            sliderButton.Position = UDim2.new((newValue - minVal) / (maxVal - minVal), -7, 0, -4)
            label.Text = text .. ": " .. newValue
            valueLabel.Text = tostring(newValue)
        end
    end)
    
    return yPos + 65
end

-- دالة إنشاء قائمة منسدلة (Dropdown)
local function CreateDropdown(parent, text, getFunc, setFunc, options, yPos)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 45)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    frame.BorderSizePixel = 0
    frame.ZIndex = 101
    frame.Parent = parent
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 150, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 102
    label.Parent = frame
    
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(0, 120, 0, 30)
    dropdownBtn.Position = UDim2.new(1, -130, 0, 7)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    dropdownBtn.TextColor3 = Color3.new(1, 1, 1)
    dropdownBtn.Text = getFunc()
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextSize = 13
    dropdownBtn.ZIndex = 102
    dropdownBtn.Parent = frame
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 5)
    dropdownCorner.Parent = dropdownBtn
    
    local currentIndex = 1
    for i, opt in ipairs(options) do
        if opt == getFunc() then
            currentIndex = i
            break
        end
    end
    
    dropdownBtn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex % #options + 1
        local newValue = options[currentIndex]
        setFunc(newValue)
        dropdownBtn.Text = newValue
    end)
    
    return yPos + 55
end

-- بناء المحتوى
local yPos = 10

-- قسم التدريب التلقائي
yPos = CreateSection(ContentFrame, "التدريب التلقائي (Auto Train)", yPos)
yPos = CreateToggle(ContentFrame, "تفعيل التدريب التلقائي", 
    function() return Settings.AutoTrain.Enabled end,
    function(v) Settings.AutoTrain.Enabled = v end,
    yPos, "يقوم بتدريب القوة والسرعة والتحمل تلقائياً")

yPos = CreateSlider(ContentFrame, "سرعة التدريب", 
    function() return Settings.AutoTrain.TrainSpeed end,
    function(v) Settings.AutoTrain.TrainSpeed = v end,
    1, 100, yPos, "كلما زاد الرقم كان التدريب أسرع")

-- قسم الجمع التلقائي
yPos = CreateSection(ContentFrame, "الجمع التلقائي (Auto Collect)", yPos + 10)
yPos = CreateToggle(ContentFrame, "تفعيل جمع العملات", 
    function() return Settings.AutoCollect.Enabled end,
    function(v) Settings.AutoCollect.Enabled = v end,
    yPos, "يجمع العملات والجواهر من الأرض تلقائياً")

yPos = CreateSlider(ContentFrame, "نطاق الجمع", 
    function() return Settings.AutoCollect.CollectRange end,
    function(v) Settings.AutoCollect.CollectRange = v end,
    10, 100, yPos, "نطاق الجمع بالستوديوت")

-- قسم إعادة الميلاد التلقائي
yPos = CreateSection(ContentFrame, "إعادة الميلاد (Auto Rebirth)", yPos + 10)
yPos = CreateToggle(ContentFrame, "تفعيل إعادة الميلاد", 
    function() return Settings.AutoRebirth.Enabled end,
    function(v) Settings.AutoRebirth.Enabled = v end,
    yPos, "يعيد الميلاد تلقائياً عند الوصول للقوة المطلوبة")

yPos = CreateSlider(ContentFrame, "القوة المطلوبة", 
    function() return Settings.AutoRebirth.RebirthAt end,
    function(v) Settings.AutoRebirth.RebirthAt = v end,
    1000, 100000, yPos, "الحد الأدنى من القوة لإعادة الميلاد")

-- قسم الانتقال السريع
yPos = CreateSection(ContentFrame, "الانتقال السريع (Teleport)", yPos + 10)
yPos = CreateDropdown(ContentFrame, "اختر الصالة", 
    function() return Settings.Teleport.SelectedGym end,
    function(v) Settings.Teleport.SelectedGym = v end,
    Gyms, yPos)

-- زر الانتقال
local teleportBtn = Instance.new("TextButton")
teleportBtn.Size = UDim2.new(1, -20, 0, 40)
teleportBtn.Position = UDim2.new(0, 10, 0, yPos)
teleportBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
teleportBtn.TextColor3 = Color3.new(1, 1, 1)
teleportBtn.Text = "🚀 انتقل الآن"
teleportBtn.Font = Enum.Font.GothamBold
teleportBtn.TextSize = 16
teleportBtn.ZIndex = 102
teleportBtn.Parent = ContentFrame

local teleportCorner = Instance.new("UICorner")
teleportCorner.CornerRadius = UDim.new(0, 8)
teleportCorner.Parent = teleportBtn

teleportBtn.MouseButton1Click:Connect(function()
    teleportToGym(Settings.Teleport.SelectedGym)
end)

yPos = yPos + 50

-- تحديث حجم المحتوى
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)

-- تشغيل Anti-AFK تلقائياً
AntiAFKLoop = RunService.Heartbeat:Connect(function()
    if Settings.AntiAFK.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), true)
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- إشعار عند التحميل
notify("✅ تم تحميل Auto Farm GUI بنجاح!", 5)
