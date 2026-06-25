local reset = require("verilua.utils.StaticQueue").reset
---@diagnostic disable: undefined-global, undefined-field

local env = (require "env") --[[@as test_template.Env]]
local tc_name = assert(os.getenv "TC_NAME", "failed to get TC_NAME")

-- ============================================================
-- 主函数（无需修改）
-- ============================================================
fork {
    main_task = function()
        if os.getenv "DUMP" then
            sim.dump_wave((os.getenv "TC" or "sim") .. ".vcd")
        end

        local tc = require(tc_name)

        env.dut_reset()
        env.launch_monitor_task()

        for _, task in ipairs(tc.tasks) do
            task()
        end
        env.test_success()
        sim.finish()
    end
}
