-- Функція для обрізання пробілів на початку та в кінці рядка
local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Функція для розбору рядка G-code
-- Приклад рядка: "G01 X100 Y50 Z0"
local function parseLine(line)
    local cmd = line:match("^(G%d+)")
    if not cmd then return nil end
    local params = {}
    -- Шукаємо параметри у форматі [буква][число]
    for key, value in line:gmatch("([XYZIJR])%s*([-+]?%d+%.?%d*)") do
        params[key] = tonumber(value)
    end
    return { cmd = cmd, params = params }
end

-- Функція для обчислення проміжної точки дуги
-- start: {x, y}, finish: {x, y}, center: {cx, cy}, direction: "G02" (за годинниковою) або "G03" (проти)
local function computeArcMidPoint(start, finish, center, direction)
    local angle1 = math.atan2(start[2] - center[2], start[1] - center[1])
    local angle2 = math.atan2(finish[2] - center[2], finish[1] - center[1])
    local dtheta = angle2 - angle1
    if direction == "G02" then  -- за годинниковою стрілкою: зменшуємо кут
        if dtheta > 0 then dtheta = dtheta - 2*math.pi end
    elseif direction == "G03" then -- проти годинникової стрілки: збільшуємо кут
        if dtheta < 0 then dtheta = dtheta + 2*math.pi end
    end
    local midAngle = angle1 + dtheta/2
    local radius = math.sqrt((start[1]-center[1])^2 + (start[2]-center[2])^2)
    local midX = center[1] + radius * math.cos(midAngle)
    local midY = center[2] + radius * math.sin(midAngle)
    return { midX, midY }
end

-- Глобальна змінна для поточної позиції (початково задаємо 0; у реальному застосуванні – задайте реальні значення)
local currentPos = { X = 0, Y = 0, Z = 0 }

-- Функція для обробки однієї команди G-code
local function processGCodeLine(line)
    local parsed = parseLine(line)
    if not parsed then return end

    if parsed.cmd == "G00" then
        -- Швидке переміщення – rapid move (MovJ)
        local p = {
            X = parsed.params.X or currentPos.X,
            Y = parsed.params.Y or currentPos.Y,
            Z = parsed.params.Z or currentPos.Z,
            R = parsed.params.R or 0
        }
        -- Виклик rapid move; параметри передаємо через таблицю з ключем P
        MovJ({ P = p })
        Sync()
        currentPos = p

    elseif parsed.cmd == "G01" then
        -- Лінійне переміщення – drawing move (MovL)
        local p = {
            X = parsed.params.X or currentPos.X,
            Y = parsed.params.Y or currentPos.Y,
            Z = parsed.params.Z or currentPos.Z,
            R = parsed.params.R or 0
        }
        MovL({ P = p })
        Sync()
        currentPos = p

    elseif parsed.cmd == "G02" or parsed.cmd == "G03" then
        -- Аркова інтерполяція
        -- Для дуги використовуємо I та J як зміщення від поточної позиції до центру дуги
        local center = {
            X = currentPos.X + (parsed.params.I or 0),
            Y = currentPos.Y + (parsed.params.J or 0)
        }
        local endPoint = {
            X = parsed.params.X or currentPos.X,
            Y = parsed.params.Y or currentPos.Y,
            Z = parsed.params.Z or currentPos.Z,
            R = parsed.params.R or 0
        }
        -- Обчислюємо проміжну точку дуги (тільки для XY)
        local midXY = computeArcMidPoint({currentPos.X, currentPos.Y}, {endPoint.X, endPoint.Y}, {center.X, center.Y}, parsed.cmd)
        local midPoint = { X = midXY[1], Y = midXY[2], Z = endPoint.Z, R = endPoint.R }
        -- Викликаємо функцію Arc (припускаємо, що вона доступна у вашій версії)
        Arc({ P = midPoint }, { P = endPoint }, { SpeedL = 50, AccL = 20, CP = 100, SYNC = 1 })
        Sync()
        currentPos = endPoint

    else
        print("Невідома команда: " .. parsed.cmd)
    end
end

-- Основна частина скрипту: читання файлу G-code рядок за рядком
local filename = "gcode.txt"  -- Ім'я файлу з G-code (розташуйте файл у потрібному каталозі)
local file = io.open(filename, "r")
if not file then
    print("Не вдається відкрити файл: " .. filename)
    return
end

for line in file:lines() do
    line = trim(line)
    -- Ігноруємо порожні рядки або рядки, що починаються з коментаря (наприклад, "(" або "%")
    if line ~= "" and not line:match("^%(") and not line:match("^%%") then
        processGCodeLine(line)
    end
end

file:close()
print("Обробка G-code завершена")
