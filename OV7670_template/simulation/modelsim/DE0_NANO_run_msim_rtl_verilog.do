transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/labuser/Desktop/jd794/CV-with-FPGA/OV7670_template {C:/Users/labuser/Desktop/jd794/CV-with-FPGA/OV7670_template/VGA_DRIVER.v}
vlog -vlog01compat -work work +incdir+C:/Users/labuser/Desktop/jd794/CV-with-FPGA/OV7670_template {C:/Users/labuser/Desktop/jd794/CV-with-FPGA/OV7670_template/DE0_NANO.v}
vlog -vlog01compat -work work +incdir+C:/Users/labuser/Desktop/jd794/CV-with-FPGA/OV7670_template {C:/Users/labuser/Desktop/jd794/CV-with-FPGA/OV7670_template/Dual_Port_RAM_M9K.v}

