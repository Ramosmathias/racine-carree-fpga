onerror {quit -code 1}
onbreak {quit -code 1}

set root [pwd]
if {![file isfile [file join $root src sqrt_core.vhd]]} {
    puts stderr "Launch from the repository root: vsim -c -do sim/run.do"
    quit -code 1
}
set output [file join $root build modelsim]
file mkdir $output
cd $output
file delete -force pipeline.csv
if {![file isdirectory work]} {
    vlib work
}

vcom -2008 [file join $root src sqrt_core.vhd] [file join $root sim pipeline_tb.vhd]
vsim -t ps work.pipeline_tb
vcd file pipeline.vcd
vcd add /*
run 1 us
vcd flush

if {[string trim [examine -radix binary sim:/pipeline_tb/passed] "'"] ne "1"} {
    puts stderr "Pipeline test did not finish successfully."
    quit -code 1
}
quit -code 0
