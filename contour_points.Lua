function moveTo(parsed)
    -- Очікуємо завершення попередніх команд
    Sync()

    -- Отримуємо поточну позицію робота
    local currentPos = GetPose()

    -- Створюємо об'єкт з координатами, додаючи значення за замовчуванням
    local p = {
        x = parsed.params.X or currentPos.x,
        y = parsed.params.Y or currentPos.y,
        z = parsed.params.Z or currentPos.z or 0,  -- Якщо Z не заданий, ставимо 0
        r = parsed.params.R or currentPos.r or 0   -- Якщо R не заданий, ставимо 0
    }

    -- Виводимо параметри для перевірки
    print("MovJ parameters: X=" .. p.x .. ", Y=" .. p.y .. ", Z=" .. p.z .. ", R=" .. p.r)

    -- Виконуємо рух, додаючи швидкість
    MovJ(p, { SpeedJ = 50 })

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
