# UART (Universal Asynchronous Receiver/Transmitter) — Verilog RTL

A synthesizable UART implementation in Verilog, featuring a configurable baud rate generator, an 8-bit transmitter, an 8-bit receiver with 16x oversampling, and a self-checking testbench.

## Overview

This project implements a standard 8-N-1 UART (8 data bits, no parity, 1 stop bit) from scratch in Verilog:

- **`baudrate_generator`** — generates enable pulses for the transmitter (1x baud rate) and receiver (16x baud rate, for oversampling) from a system clock.
- **`transmitter`** — a 4-state FSM (`IDLE → START → DATA → STOP`) that serializes an 8-bit input byte onto a `tx` line.
- **`receiver`** — a 4-state FSM that samples an incoming serial line at 16x the baud rate, detects the start bit, and reconstructs the received byte.
- **`uart_top`** — top-level module wiring the above together.
- **`uart_top_tb`** — testbench that sends bytes through the transmitter, loops them back into the receiver, and checks the received data.

## Block Diagram

<!-- Add your block diagram here. Recommended: a simple diagram showing uart_top with
     baudrate_generator, transmitter, and receiver as sub-blocks, with tx_clk_en / rx_clk_en
     and tx_temp signal connections labeled. -->

![UART Block Diagram](docs/block_diagram.png)

## FSM State Diagrams

### Transmitter

```
IDLE --(wr_en)--> START --(enb)--> DATA --(8 bits sent)--> STOP --(enb)--> IDLE
```

### Receiver

```
START --(16 samples, start bit confirmed)--> DATA --(8 bits sampled)--> STOP --(16 samples)--> START
```

## Repository Structure

```
.
├── rtl/
│   ├── baudrate_generator.v
│   ├── transmitter.v
│   ├── receiver.v
│   └── uart_top.v
├── tb/
│   └── uart_top_tb.v
├── docs/
│   └── block_diagram.png
└── README.md
```

## How to Simulate

Simulated using **Xilinx Vivado** (XSIM):

1. Open Vivado and create a new project (or use an existing one).
2. Add all files under `rtl/` as design sources.
3. Add `tb/uart_top_tb.v` as a simulation source, and set it as the top module for simulation.
4. Run **Behavioral Simulation** (Flow Navigator → SIMULATION → Run Simulation → Run Behavioral Simulation).
5. View signals in the Vivado waveform viewer, or check the Tcl Console for `$display` output.

Any other Verilog simulator (Icarus Verilog, ModelSim, Verilator, etc.) will also work — compile all files under `rtl/` along with `tb/uart_top_tb.v` and run.

## Simulation Output

<!-- Paste your console output here, e.g.:
received data is 41
received data is 55
$finish called at ... -->

```
(paste simulation console output here)
```

<!-- Add a waveform screenshot here, from Vivado's waveform viewer, showing tx/rx lines
     and the reconstructed data_out byte. In Vivado: after running Behavioral Simulation,
     right-click the waveform pane → "Save as Screenshot", or use a snipping tool. -->

![Simulation Waveform](docs/waveform.png)

## Design Notes / Debugging Log

A few real bugs were found and fixed during development — noting them here since they're common pitfalls in sequential Verilog design:

- **Multiple `always` blocks driving the same signal.** Reset logic was originally split into a separate `always` block from the main FSM, which is not correct RTL style. Fixed by folding reset into the same clocked block as the FSM (`if (rst) ... else case(state) ...`).
- **Mixed blocking (`=`) and non-blocking (`<=`) assignments** inside clocked (`always @(posedge clk)`) blocks — a common source of simulation/synthesis mismatches. Standardized on non-blocking assignments throughout all sequential logic.
- **Incorrectly chained conditionals in the receiver.** `rdy_clr` handling and the main receive FSM (`clken` + `case`) were accidentally written as an `if / else` chain, meaning clearing `rdy` would skip an entire FSM cycle. Fixed by making them independent `if` statements.
- **Incomplete reset.** FSM state registers (`state`, `bitpos`, `index`, `sample`, `temp`, `data`) were not included in the reset path, relying only on initial-value declarations — not valid for real hardware reset. Fixed by resetting all state-holding registers explicitly.

## Configuration

Baud rate and system clock frequency are set via parameters in `baudrate_generator`:

```verilog
parameter clk_freq  = 100_000_000; // system clock, Hz
parameter baud_rate = 9600;        // desired baud rate
```

Override these at instantiation for different clock/baud combinations, or to speed up simulation (e.g. smaller divisors for quick testbench runs).

## License

MIT — see [LICENSE](LICENSE).
