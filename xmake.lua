---@diagnostic disable: undefined-global, undefined-field

local prj_dir = os.curdir()
local build_dir = path.join(prj_dir, "build")
local rtl_dir = path.join(build_dir, "rtl")
local ChiselTemplate_dir = path.join(prj_dir, "ChiselTemplate")
local src_dir = path.join(prj_dir, "src")
local tc_dir  = path.join(prj_dir, "test_cases")

local sim = os.getenv "SIM" or "vcs" -- 默认使用 VCS 仿真器

-- ============================================================================
-- target: rtl —— 将 ChiselTemplate 中的 Chisel 源码编译为 SystemVerilog 并复制到 rtl_dir
-- ============================================================================
target("rtl", function()
    set_kind("phony")
    set_default(false)
    on_run(function()
        local ct_build_dir = path.join(ChiselTemplate_dir, "build", "rtl")
        os.cd(ChiselTemplate_dir)
        os.execv("mill", {"-i", "chiselTemplate.runMain", "template.GenerateVerilog",
            "--target", "systemverilog", "--split-verilog", "-td", ct_build_dir})

        os.tryrm(rtl_dir)
        os.mkdir(rtl_dir)
        os.cp(path.join(ct_build_dir, "*"), rtl_dir)
        cprint("${green underline}[INFO]${clear} RTL 已复制到 build/rtl/")
    end)
end)

-- ============================================================================
-- target: sim —— 主仿真入口
-- ============================================================================
target("sim", function()
    set_default(true)
    add_rules("verilua")

    if sim == "verilator" then
        add_toolchains("@verilator")
    else
        add_toolchains("@vcs")
    end

    -- TODO: 修改为实际 RTL 文件路径
    add_files(
        path.join(tc_dir, "*.lua"),
        path.join(src_dir, "*.lua"),
        path.join(src_dir, "test_template", "*.lua"),
        path.join(rtl_dir, "*.sv"),
        path.join(rtl_dir, "verification", "*.sv"),
        path.join(rtl_dir, "verification", "assert", "*.sv"),
        path.join(rtl_dir, "verification", "assume", "*.sv"),
        path.join(rtl_dir, "verification", "cover", "*.sv")
    )

    add_values("vcs.flags", "+incdir+" .. path.join(rtl_dir, "verification"))
    set_values("cfg.build_dir_name", "sim")
    set_values("cfg.top", "Top")      -- TODO: 修改为实际顶层模块名

    local TC = os.getenv("TC") -- 根据用户设置的 TC 寻找对应的用例并将名称存入 TC_NAME 环境变量
    if TC then
        TC = TC:sub(1, 3)
    else
        TC = "000" -- 指定默认用例 000
    end
    local test_cases = os.files(path.join(tc_dir, "*.lua"))
    for _, test_case in ipairs(test_cases) do
        local test_case_file = path.filename(test_case)
        if test_case_file:startswith(TC) then
            add_runenvs("TC_NAME", path.basename(test_case_file))
        end
    end

    set_values("cfg.lua_main", "tc_main.lua")
end)

-- ============================================================================
-- target: clean
-- ============================================================================
target("clean", function()
    set_kind("phony")
    set_default(false)
    on_run(function()
        os.tryrm(path.join(prj_dir, "build"))
        cprint("${green underline}[INFO]${clear} 已清空 build/")
    end)
end)
