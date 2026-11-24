`include "uvm_macros.svh"
import uvm_pkg::*;

module sys_assertion
(
    input bit clk,
    input bit rst_n,
    input bit ena,

    input bit [7:0]ui_in,
    input bit [7:0]uio_in,
    ///////////////output
    input logic [7:0]uo_out,
    input logic [7:0]uio_out,
    input logic [7:0]uio_oe
);


    // 1. Reset: While rst_n is low, BUSY=0 and DONE=0, with no clock needed for the clear.
    property a_reset_status_low;
    @(negedge rst_n)
            !rst_n |-> (uio_out[5:4] == 2'b00);
    endproperty


    // 2. Reset: While rst_n is low, uo_out = 0x00 (RD_PTR and CBUF are cleared).
    property a_reset_dataout_zero;
    @(negedge rst_n)
            !rst_n |-> (uo_out == 8'h00);
    endproperty


    // 3. Status: BUSY and DONE are never high in the same cycle.
    property a_busy_done_mutex;
        @(posedge clk)
                !(uio_out[4] && uio_out[5]);
    endproperty

    assert property(a_busy_done_mutex)
    else $error("%0t: a_busy_done_mutex FAILED (BUSY and DONE high together)", $time);

    // 4. Status: uio_out[7:6] and uio_out[3:0] are always 0.
    property a_reserved_pins_low;
        @(posedge clk)
                uio_out[7:6] == 2'b00 && uio_out[3:0] == 4'b0000;
    endproperty

    assert property(a_reserved_pins_low)
    else $error("%0t: a_reserved_pins_low FAILED", $time);

    // 5. Status: uio_oe remains 8'b1111_0000 throughout reset, loading, computation and readout.
    property a_fixed_output_enable;
        @(posedge clk)
                uio_oe == 8'b1111_0000;
    endproperty

    assert property(a_fixed_output_enable)
    else $error("%0t: a_fixed_output_enable FAILED", $time);

    // 6. Status: BUSY and DONE are never X or Z once reset is released.
    property a_status_no_x;
        @(posedge clk) disable iff(!rst_n)
                !$isunknown(uio_out[5:4]);
    endproperty

    assert property(a_status_no_x)
    else $error("%0t: a_status_no_x FAILED", $time);

    // 7. Status: uo_out is never X or Z after reset
    property a_dataout_no_x;
        @(posedge clk) disable iff(!rst_n)
                !$isunknown(uo_out);
    endproperty

    assert property(a_dataout_no_x)
    else $error("%0t: a_dataout_no_x FAILED", $time);


    // 8. Compute: When BUSY falls (outside reset), DONE is high in that same cycle.
    property a_busy_falls_to_done;
        @(posedge clk) disable iff(!rst_n)
                $fell(uio_out[4]) |-> uio_out[5];
    endproperty

    assert property(a_busy_falls_to_done)
    else $error("%0t: a_busy_falls_to_done FAILED", $time);

endmodule
