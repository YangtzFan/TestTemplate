local class = require "pl.class"
local texpect = require "verilua.TypeExpect"

local f = string.format
local print = print
local assert = assert
local bit_band = bit.band

---@class (exact) test_template.TestTemplateMonitor
---@overload fun(
---		name: string,
---		input_a: verilua.handles.AliasBundle,
---		input_b: verilua.handles.AliasBundle,
---		output_sum: verilua.handles.AliasBundle,
---		options: table?): test_template.TestTemplateMonitor
---@field name string
---@field private _log_name_prefix string
---@field private cycles integer
---@field private verbose boolean
---@field private input_a verilua.handles.AliasBundle
---@field private input_b verilua.handles.AliasBundle
---@field private output_sum verilua.handles.AliasBundle
---@field private _log fun(...)
---@field sample fun(self: test_template.TestTemplateMonitor, cycles: integer)
local TestTemplateMonitor = class() --[[@as test_template.TestTemplateMonitor]]

function TestTemplateMonitor:_init(
    name,
    input_a,
    input_b,
    output_sum,
    options
)
    self.name = name
    self._log_name_prefix = "[" .. name .. "_TestTemplateMonitor]"

    texpect.expect_abdl(input_a, "INPUT_A", {
        "valid_a",
        "a"
    })
    texpect.expect_abdl(input_b, "INPUT_B", {
        "valid_b",
        "b"
    })
    texpect.expect_abdl(output_sum, "OUTPUT_SUM", {
        "valid_sum",
        "sum"
    })

    self.cycles = 0
    self.verbose = options == nil or options.verbose == nil or options.verbose
    self.sample_enable = options == nil or options.sample_enable == nil or options.sample_enable

    self.input_a = input_a
    self.input_b = input_b
    self.output_sum = output_sum
end

function TestTemplateMonitor:_log(...)
    print(f("[%d]\t%s", self.cycles, self._log_name_prefix), ...)
end

function TestTemplateMonitor:sample(cycles)
    if not self.sample_enable then
        return
    end

    self.cycles = cycles

    if self.input_a.valid_a:is(1) and self.input_b.valid_b:is(1) then
        local a = self.input_a.a:get()
        local b = self.input_b.b:get()
        local sum = self.output_sum.sum:get()
        local valid_sum = self.output_sum.valid_sum:get()

        if self.verbose then
            self:_log(f("[SAMPLE]\ta: %d\tb: %d\tsum: %d", a, b, sum))
        end

        assert(valid_sum == 1, "[CHECK FAIL] output should be valid when the two inputs are valid.")
        assert(sum == a + b, "[CHECK FAIL] output should be the sum of the two inputs.")
    end
end

return TestTemplateMonitor
