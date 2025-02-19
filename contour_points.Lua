function moveTo(parsed)
    -- Очікуємо завершення попередніх команд
    Sync()

    -- Отримуємо поточну позицію робота
    local currentPos = GetPose()

    -- Створюємо об'єкт з координатами
    local x = parsed.params.X or currentPos.x
    local y = parsed.params.Y or currentPos.y
    local z = parsed.params.Z or currentPos.z
    local r = parsed.params.R or currentPos.r

    -- Виводимо параметри для перевірки
    print("MovJ parameters: X=" .. x .. ", Y=" .. y .. ", Z=" .. z .. ", R=" .. r)

    -- Виконуємо рух (змінюємо MovJ на SetPTPCmd для надійності)
    SetPTPCmd("MOVJ_XYZ", x, y, z, r)

    -- Синхронізуємо рух
    Sync()
end

-- Основний блок коду для запуску
function main()
    -- Задаємо бажані координати для руху
    local targetPos = {
        params = {
            X = 200,
            Y = 0,
            Z = 50,
            R = 0
        }
    }

    -- Викликаємо функцію переміщення
    moveTo(targetPos)
end

-- Виконуємо головну функцію
main()
