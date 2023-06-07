#!/usr/bin/env lua

local common = require "build_tools.lua.common"

os.exit(common.build_rom("Main", "ROM", "", "-p=FF -z=0," .. ("kosinskiplus") .. ",Size_of_Snd_driver_guess,after", false, "https://github.com/sonicretro/s1disasm"))

-- Correct the ROM's header with a proper checksum and end-of-ROM value.
common.fix_header("ROM.bin")
