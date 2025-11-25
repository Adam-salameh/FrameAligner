// Code your testbench here
// or browse Examples

`include "fa_test.sv"

module top_tb;
    bit clk;

    always #5 clk = ~clk;
  
  /* Waves  Remove when working with VCS*/
  initial begin
      $dumpfile("counter.vcd");
      $dumpvars;
  end

  fa_inf i_inf(clk);
    fa_test t1(i_inf);
    frame_aligner fa1(
      .clk(clk),
      .reset(i_inf.reset),
      .rx_data(i_inf.rx_data),
      .fr_byte_position(i_inf.fr_byte_position),
      .frame_detect(i_inf.frame_detect)
    );
    
endmodule