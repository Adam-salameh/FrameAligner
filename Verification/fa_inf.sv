
interface fa_inf (input logic clk);

    //declare the signals
  logic [7:0] rx_data;
  logic [3:0] fr_byte_position;
  logic frame_detect,reset;
       
endinterface