-- Функція для обчислення проміжної точки дуги (за алгоритмом з кола)
-- start  - початкова точка {x, y}
-- finish - кінцева точка {x, y}
-- center - координати центру дуги {cx, cy} (обчислено як поточна позиція + I, J)
-- direction - "G02" для за годинниковою стрілкою, "G03" – проти годинникової стрілки
function computeArcMidPoint(start, finish, center, direction)
    local angle1 = math.atan2(start[2] - center[2], start[1] - center[1])
    local angle2 = math.atan2(finish[2] - center[2], finish[1] - center[1])
    local dtheta = angle2 - angle1
    if direction == "G02" then  -- за годинниковою стрілкою: зменшення кута
        if dtheta > 0 then dtheta = dtheta - 2 * math.pi end
    elseif direction == "G03" then  -- проти годинникової стрілки: збільшення кута
        if dtheta < 0 then dtheta = dtheta + 2 * math.pi end
    end
    local midAngle = angle1 + dtheta / 2
    local radius = math.sqrt((start[1] - center[1])^2 + (start[2] - center[2])^2)
    local midX = center[1] + radius * math.cos(midAngle)
    local midY = center[2] + radius * math.sin(midAngle)
    return {midX, midY}
end

-- Прикладова таблиця з командами G-code
-- Для G02/G03 додатково задаємо параметри I та J (відносні зміщення для центру дуги)
local gcode_commands = {
    {cmd = "G00", X = 50,  Y = 50,  Z = 10},
    {cmd = "G00", X = 50,  Y = 50,  Z = 0},
    {cmd = "G01", X = 100, Y = 50,  Z = 0},
    {cmd = "G01", X = 100, Y = 100, Z = 0},
    -- Приклад арки за годинниковою стрілкою (G02):
    -- Поточна позиція = {100, 100}, кінцева точка = {50, 100},
    -- I = -25, J = 0 (тобто центр дуги знаходиться на 25 мм лівіше від поточної позиції)
    {cmd = "G02", X = 50, Y = 100, Z = 0, I = -25, J = 0},
    {cmd = "G00", X = 50,  Y = 100, Z = 10}
}

-- Поточна позиція робота; вона буде оновлюватись після кожного руху
local currentPos = nil

-- Обробка команд G-code
for i, command in ipairs(gcode_commands) do
    if command.cmd == "G00" then
        -- Швидке переміщення (без малювання): використання MovJ
        MovJ({command.X, command.Y, command.Z, 0})
        currentPos = {command.X, command.Y, command.Z}
    elseif command.cmd == "G01" then
        -- Лінійне переміщення: використання MovL
        MovL({command.X, command.Y, command.Z, 0})
        currentPos = {command.X, command.Y, command.Z}
    elseif command.cmd == "G02" or command.cmd == "G03" then
        if not currentPos then
            print("Помилка: поточна позиція не визначена для обчислення дуги")
        else
            -- Для арки: використання I, J як зміщення від поточної позиції
            local center = { currentPos[1] + command.I, currentPos[2] + command.J }
            -- Обчислюємо проміжну точку дуги (тільки XY; Z вважаємо однаковим)
            local midXY = computeArcMidPoint({currentPos[1], currentPos[2]}, {command.X, command.Y}, center, command.cmd)
            local midPoint = { midXY[1], midXY[2], command.Z, 0 }
            local endPoint = { command.X, command.Y, command.Z, 0 }
            -- Виклик функції Arc (припускаємо, що API Arc доступний)
            -- Параметри: проміжна точка, кінцева точка, опції руху
            Arc(midPoint, endPoint, {SpeedL = 50, AccL = 20, CP = 100, SYNC = 1})
            currentPos = {command.X, command.Y, command.Z}
        end
    else
        print("Невідома команда: " .. command.cmd)
    end
    Sync()         -- Чекаємо завершення руху
    Wait(100)      -- Невелика затримка (100 мс)
end

print("Програма завершена")
