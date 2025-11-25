class refmod;
  bit [7:0] header_lsb, header_msb;
  bit [3:0] na_byte_cnt;         // byte counter inside frame
  bit [3:0] fr_byte_position;    // byte position in frame
  bit       header_ok;           // current frame header validity
  bit       frame_detect;        // 1 when 3 consecutive legal headers are seen
  int       good_count;          // count consecutive valid headers (when searching)
  int       bad_count;           // count consecutive Invalid headers (when aligned)
  bit       pending_deassert;    // Flag to delay deassertion until frame end

  // constructor
  function new();
    reset();
  endfunction
  
  function void reset();
    header_lsb       = '0;
    header_msb       = '0;
    na_byte_cnt      = '0;
    fr_byte_position = '0;
    header_ok        = '0;
    frame_detect     = '0;
    good_count       = '0;
    bad_count        = '0;
    pending_deassert  = 0;
  endfunction

  // Load incoming bytes and detect headers
  task load_bytes(input bit [7:0] rx_data,output [3:0] result);
    // Byte count within frame
    case (na_byte_cnt)
      
      0: header_lsb = rx_data;
      
      1: begin
        header_msb = rx_data;
        // Evaluate header validity
        header_ok = is_valid_header(header_lsb, header_msb);

        // Update sync logic on header boundaries
        detect();
      end
      
      11: begin
        // Frame end: check if we should deassert now
        if (pending_deassert) begin
          frame_detect = 0;
          pending_deassert = 0;
        end
        
        // Prepare next frame
        na_byte_cnt = 0;
        if (header_ok)
          fr_byte_position++;
        result = fr_byte_position;
        return;
      end
    endcase
    
    // If legal header → count byte positions for this frame
    if (header_ok)begin
      fr_byte_position = na_byte_cnt;
    end
    
    na_byte_cnt++;
    result = fr_byte_position;
    return;
  endtask
  
  function bit is_valid_header(bit [7:0] lsb, bit [7:0] msb);
    return ( (lsb == 8'hAA && msb == 8'hAF) || (lsb == 8'h55 && msb == 8'hBA) );
  endfunction

task detect();
  if (!frame_detect) begin
    // Searching for sync: 3 consecutive good headers
	good_count = header_ok ? good_count + 1 : 0;
    bad_count = 0;

    if (good_count == 3) begin
      frame_detect <= 1;
      good_count = 0;
      bad_count = 0;
    end
  end
  else begin
    // Tracking: lose sync after 4 bad headers
	bad_count = header_ok ? 0 : bad_count + 1;
    good_count = 0;
    
    if (bad_count == 4) begin
      pending_deassert = 1; // Don't drop immediately — wait until frame end
      frame_detect = 0;
      bad_count = 0;
      good_count = 0;
    end
  end
endtask
endclass