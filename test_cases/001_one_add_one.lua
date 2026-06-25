local env = (require "env") --[[@as test_template.Env]]

local clock = env.clock
local dut_reset = env.dut_reset
local set_input = env.set_input
local unset_input = env.unset_input

local function task_1()
    set_input(1, 1)
    clock:posedge()
end

---@type test_template.TestCase
local tc = {
    tasks = {
        dut_reset,
        task_1
    }
}

return tc
