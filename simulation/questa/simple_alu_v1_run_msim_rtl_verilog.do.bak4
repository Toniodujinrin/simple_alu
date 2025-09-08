transcript on
if ![file isdirectory verilog_libs] {
	file mkdir verilog_libs
}

vlib verilog_libs/altera_ver
vmap altera_ver ./verilog_libs/altera_ver
vlog -vlog01compat -work altera_ver {/home/toni/intelFPGA_lite/24.1std/quartus/eda/sim_lib/altera_primitives.v}

vlib verilog_libs/lpm_ver
vmap lpm_ver ./verilog_libs/lpm_ver
vlog -vlog01compat -work lpm_ver {/home/toni/intelFPGA_lite/24.1std/quartus/eda/sim_lib/220model.v}

vlib verilog_libs/sgate_ver
vmap sgate_ver ./verilog_libs/sgate_ver
vlog -vlog01compat -work sgate_ver {/home/toni/intelFPGA_lite/24.1std/quartus/eda/sim_lib/sgate.v}

vlib verilog_libs/altera_mf_ver
vmap altera_mf_ver ./verilog_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver {/home/toni/intelFPGA_lite/24.1std/quartus/eda/sim_lib/altera_mf.v}

vlib verilog_libs/altera_lnsim_ver
vmap altera_lnsim_ver ./verilog_libs/altera_lnsim_ver
vlog -sv -work altera_lnsim_ver {/home/toni/intelFPGA_lite/24.1std/quartus/eda/sim_lib/altera_lnsim.sv}

vlib verilog_libs/cycloneive_ver
vmap cycloneive_ver ./verilog_libs/cycloneive_ver
vlog -vlog01compat -work cycloneive_ver {/home/toni/intelFPGA_lite/24.1std/quartus/eda/sim_lib/cycloneive_atoms.v}

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu/floating_point_modules {/home/toni/Desktop/simple_alu/floating_point_modules/fp_multiplier.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu/floating_point_modules {/home/toni/Desktop/simple_alu/floating_point_modules/fp_converter.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu/floating_point_modules {/home/toni/Desktop/simple_alu/floating_point_modules/fp_comparator.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu/floating_point_modules {/home/toni/Desktop/simple_alu/floating_point_modules/fp_adder.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu/integer_modules {/home/toni/Desktop/simple_alu/integer_modules/signed_adder.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu/integer_modules {/home/toni/Desktop/simple_alu/integer_modules/shift.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu/integer_modules {/home/toni/Desktop/simple_alu/integer_modules/multiplier.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu/integer_modules {/home/toni/Desktop/simple_alu/integer_modules/logic_modules.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu/integer_modules {/home/toni/Desktop/simple_alu/integer_modules/int_converter.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu/integer_modules {/home/toni/Desktop/simple_alu/integer_modules/comparator.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu {/home/toni/Desktop/simple_alu/reusable_modules.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu {/home/toni/Desktop/simple_alu/simple_alu_v1.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu {/home/toni/Desktop/simple_alu/alu_constants.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu {/home/toni/Desktop/simple_alu/alu_decoder.v}
vlog -vlog01compat -work work +incdir+/home/toni/Desktop/simple_alu {/home/toni/Desktop/simple_alu/alu_core.v}

vlog -sv -work work +incdir+/home/toni/Desktop/simple_alu/testbench/integer_modules_test {/home/toni/Desktop/simple_alu/testbench/integer_modules_test/signed_adder_test.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  signed_adder_testbench

add wave *
view structure
view signals
run -all
