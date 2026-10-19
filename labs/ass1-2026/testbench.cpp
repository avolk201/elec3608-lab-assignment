#include "Vtestbench.h"
#include "verilated_vcd_c.h"

int main(int argc, char **argv, char **env)
{
	printf("Built with %s %s.\n", Verilated::productName(), Verilated::productVersion());
	printf("Recommended: Verilator 4.0 or later.\n");

	Verilated::commandArgs(argc, argv);
	Vtestbench* top = new Vtestbench;

	// Tracing (vcd)
	VerilatedVcdC* tfp = NULL;
	const char* flag_vcd = Verilated::commandArgsPlusMatch("vcd");
	if (flag_vcd && 0==strcmp(flag_vcd, "+vcd")) {
		Verilated::traceEverOn(true);
		tfp = new VerilatedVcdC;
		top->trace (tfp, 99);
		tfp->open("testbench.vcd");
	}

	// Tracing (data bus, see showtrace.py)
	FILE *trace_fd = NULL;
	const char* flag_trace = Verilated::commandArgsPlusMatch("trace");
	if (flag_trace && 0==strcmp(flag_trace, "+trace")) {
		trace_fd = fopen("testbench.trace", "w");
	}

	top->clock = 0;
	top->reset = 1;
	// Watchdog: the longest test retires ~160 instructions, so 20000
	// cycles is two orders of margin.  Expiry is a failure, not an exit;
	// a program that never reaches ebreak must not print register values.
	int t = 0;
	while (!Verilated::gotFinish()) {
		if (t > 200)
			top->reset = 0;
		if (t > 200000) {
			printf("FAIL: watchdog expired at 20000 cycles without ebreak\n");
			if (tfp) tfp->close();
			delete top;
			exit(1);
		}
		top->clock = !top->clock;
		top->eval();
		if (tfp) tfp->dump (t);
		t += 5;
	}
	if (tfp) tfp->close();
	delete top;
	exit(0);
}

