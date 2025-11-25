typedef enum bit[1:0] {HEAD_1, HEAD_2, ILLEGAL}header_type_t;

class frame;

  rand header_type_t header_type; 
  rand bit [15:0] header_bits;
  rand byte payload[];
  
  constraint payload_size_c {
    payload.size() == 10;
  }
  
  constraint header_map_c {
    if (header_type == HEAD_1)
      header_bits == 16'hAFAA;
    else if (header_type == HEAD_2)
      header_bits == 16'hBA55;
    else
      // ILLEGAL: must not be any of the legal headers
      !(header_bits inside {16'hAFAA, 16'hBA55});
  }
  
  constraint header_type_dist_c {
  header_type dist { HEAD_1 := 3, HEAD_2 := 3, ILLEGAL := 1 };
  }
  
  function void display(string name);
    $display("---------------------------------");
    $display("- %s" ,name);
    $display("---------------------------------");
    $display("type = %s, header_bits = %04h, payload_size = %0d",header_type.name(), header_bits, payload.size());
    $write("payload: ");
    foreach (payload[i]) $write("%02h ", payload[i]);
    $display("---------------------------------");
  endfunction
  
endclass