function moveTo(parsed)
    -- Очікуємо завершення попередніх команд
    Sync()

    -- Отримуємо поточну позицію робота
    local currentPos = GetPose()

    -- Перевіряємо, чи всі необхідні параметри передані
    if not parsed.params.X or not parsed.params.Y or not parsed.params.Z or not parsed.params.R then
        print("Error: Missing motion point parameters for MovJ instruction")
        return
    end

    -- Зчитуємо параметри
    local x = parsed.params.X
    local y = parsed.params.Y
    local z = parsed.params.Z
    local r = parsed.params.R

    -- Виводимо параметри для налагодження
    print("Executing MovJ with parameters: X=" .. x .. ", Y=" .. y .. ", Z=" .. z .. ", R=" .. r)

    -- Виконуємо рух за допомогою MovJ
    MovJ(x, y, z, r)

    -- Синхронізуємо рух
    Sync()
end

-- Основний блок коду
function main()
    -- Встановлюємо бажані координати
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
