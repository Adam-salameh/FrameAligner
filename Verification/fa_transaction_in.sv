
class transactionIn;
  rand bit [7:0] rx_data; 
  
  function void display(string name);
    $display("---------------------------------");
    $display("- %s" ,name);
    $display("---------------------------------");
    $display("- rx_data = %h ", rx_data);
    $display("---------------------------------");
  endfunction
endclass