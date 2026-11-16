# Run from the repository root in Questa/ModelSim.
vlib work
vlog -sv rtl/baud_gen.v rtl/transmitter.v rtl/receiver.v rtl/top_uart.v tb/tb_dut.sv
vsim -c tb_top
run -all
quit -f
