# Uart-7n

This is a free and OpenSource UART implementation I made in my spare time.
The name - Uart-7n was supposed to mean - UART written in 7 nights (a magic and cool number).
While most basic stuff for receive and transmit state machines indeed were written in 7 nights/evenings, debugging what didn't work took much longer.
And this is nowhere near completion at this moment.

My main motivation was learning about Verilog and Digital Design.
After working a bit around Design Verification field, I decided to try my hands at creating a simple circuit of my own.

The device will be tested both in simulation (Icarus Verilog and Verilator) as well as wonderful and affordable Sipeed Tang Nano 20k FPGA board.
Additionally, I'd like to leverage Co-Simulation capabilities of Renode Framework, to develop a driver for the module.

## Repo structure

Right now there are the following directories:
* `src` - contains Verilog sources of the UART module
* `tb` - contains SystemVerilog testbenches (design verification)
* `impl` - FPGA-specific implementation details (e.g. I/O constraints I used)

## Verification

My goal is to use pure SystemVerilog testbenches for verification, without any frameworks and additional tools.
There is no need for complications as the design is very human.
Just a simple bench with asserts is my goal.

To build and run the testbenches you need [Verilator](https://veripool.org/guide/latest/index.html) (the simulator) and GNU Make.
I currently use `Verilator 5.040`.
* To run a TB, navigate to `tb` directory and execute `make targets` to see list of available tests.
* To build a specific test, execute `make test-name.tb`.
* To run a specific test, execute `make test-name.run`.

You might also want to view the waveforms.
For this, you can either use the classic [GTKWave](https://gtkwave.sourceforge.net/) or more modern [Surfer](https://surfer-project.org/).
Both are popular, free and Open Source tools for inspecting the waveforms.

### Testpoints

Table with testpoints, and what they cover will be here.

#### Receiver
- [x] Simple receive - test several back-to-back transactions
- [ ] Receive stress - send thousands of transactions, to see if there is any skew in bit count
- [x] Transmit loopback - transmit several bytes, and use rx module in "loopback" mode to verify their correctness

TODO: randomize clock skew, in case of imperfect baud (should handle it, since I deliberately reset receiver into IDLE at half the length of STOP)

## Roadmap

A very rough roadmap of features I want to introduce.
Each feature will be paired with a testbench.

- [x] Uart Receive module
- [x] Uart Transmit module
- [x] Real FPGA echo (what you write is what you get back) demo
- [ ] Transmit/Receive FIFO
- [ ] Reception and Transmission error detection
- [ ] Programmable baud rate generator
- [ ] APB/other bus integration
- [ ] Automatic flow control lines
- [ ] Zephyr driver

## Integration

You might want to integrate the RTL with your own designs.
Below is the table of top level signals, and how to connect them.

WIP

## Design

Description of the internals will be here
