
class transactionOut;
  bit [3:0] fr_byte_position;
  bit       frame_detect;
  
  function void display(string name);
    $display("---------------------------------");
    $display("- %s" ,name);
    $display("---------------------------------");
    $display("- fr_byte_position = %d, frame_detect = %d ", fr_byte_position, frame_detect);
    $display("---------------------------------");
  endfunction
  
endclass