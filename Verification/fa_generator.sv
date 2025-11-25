typedef enum { RANDOM_FRAMES, LOSS_OF_SYNC, ALIGNED, CUSTOM } gen_mode_t;

class generator;

  rand frame frm;
  int repeat_count;
  gen_mode_t mode;   
  mailbox gen2drv= new(1);
  event ended;
  
  function new(mailbox gen2drv);
  	this.gen2drv = gen2drv;
  endfunction
  
  
  task main();
    case (mode)
      RANDOM_FRAMES: generate_random();
      LOSS_OF_SYNC:  generate_loss_of_sync();
      ALIGNED:      generate_aligned();
      CUSTOM:        generate_custom();
      default: begin
        mode = RANDOM_FRAMES;
        generate_random();
      end
    endcase
  	
  	-> ended;
  endtask
  
  //------------------------------
  //  MODE: RANDOM_FRAMES
  //------------------------------
  task generate_random();
    repeat (repeat_count) begin
      frm = new();
      if (!frm.randomize())
        $fatal("Gen:: frm randomization failed");
      gen2drv.put(frm);
      frm.display("[--Generator RANDOM FRAMES--]");
    end
  endtask
 
  //------------------------------
  //  MODE: LOSS_OF_SYNC
  //  Create 4 illegal headers to force loss of sync
  //------------------------------
  task generate_loss_of_sync();
    repeat (repeat_count) begin
      frm = new();
      if (!frm.randomize() with { header_type == ILLEGAL; })
        $fatal("Gen:: Illegal frame randomization failed");
      gen2drv.put(frm);
      frm.display("[--Generator Loss Of Sync--]");
    end
  endtask
  
  //------------------------------
  //  MODE: ALIGNED
  //  Create 3 legal headers to force alignment
  //------------------------------
  task generate_aligned();
    repeat (repeat_count) begin
      frm = new();
      if (!frm.randomize() with {header_type inside {HEAD_1, HEAD_2};})
        $fatal("Gen:: legal frame randomization failed");
      gen2drv.put(frm);
      frm.display("[--Generator Aligned--]");
    end
  endtask
 
  
//------------------------------
//  MODE: CUSTOM (Extended)
//------------------------------
task generate_custom();
  int i = 1;
  repeat (repeat_count) begin
    frm = new();

    case (i)
      //------------------------------------------
      // 1) Header edge-case: LSB ok (HEAD1)
      //------------------------------------------
      1: begin
        if (!frm.randomize() with {
          header_type == ILLEGAL;
          header_bits[7:0]  == 8'hAA;
          header_bits[15:8] != 8'hAF;
        })
          $fatal("Gen:: Failed randomizing custom frame (HEAD1 LSB only)");
        frm.display("[--Generator CUSTOM Frame (HEAD1 LSB ok)--]");
      end

      //------------------------------------------
      // 2) Header edge-case: MSB ok (HEAD2)
      //------------------------------------------
      2: begin
        if (!frm.randomize() with {
          header_type == ILLEGAL;
          header_bits[15:8] == 8'hBA;
          header_bits[7:0]  != 8'h55;
        })
          $fatal("Gen:: Failed randomizing custom frame (HEAD2 MSB only)");
        frm.display("[--Generator CUSTOM Frame (HEAD2 MSB ok)--]");
      end

      //------------------------------------------
      // 3) Mixed HEAD1 LSB + HEAD2 MSB
      //------------------------------------------
      3: begin
        if (!frm.randomize() with {
          header_type == ILLEGAL;
          header_bits[7:0]  == 8'hAA;
          header_bits[15:8] == 8'hBA;
        })
          $fatal("Gen:: Failed randomizing custom frame (HEAD1 LSB + HEAD2 MSB)");
        frm.display("[--Generator CUSTOM Frame (HEAD1 LSB + HEAD2 MSB)--]");
      end

      //------------------------------------------
      // 4) Mixed HEAD2 LSB + HEAD1 MSB
      //------------------------------------------
      4: begin
        if (!frm.randomize() with {
          header_type == ILLEGAL;
          header_bits[7:0]  == 8'h55;
          header_bits[15:8] == 8'hAF;
        })
          $fatal("Gen:: Failed randomizing custom frame (HEAD2 LSB + HEAD1 MSB)");
        frm.display("[--Generator CUSTOM Frame (HEAD2 LSB + HEAD1 MSB)--]");
      end

      //------------------------------------------
      // 5) Payload contains HEAD_1 (AFAA)
      //------------------------------------------
      5: begin
        if (!frm.randomize() with { header_type == HEAD_2; })
          $fatal("Gen:: Failed randomizing frame (HEAD1 header)");

        frm.payload = new[10];
        foreach (frm.payload[j])
          frm.payload[j] = $urandom_range(0, 255);

        // Insert 16'hAFAA in payload (HEAD1)
        frm.payload[3] = 8'hAA;
        frm.payload[4] = 8'hAF;

        frm.display("[--Generator CUSTOM Frame (Payload contains HEAD1)--]");
      end

      //------------------------------------------
      // 6) Payload contains HEAD_1 reversed (AAAF)
      //------------------------------------------
      6: begin
        if (!frm.randomize() with { header_type == ILLEGAL; })
          $fatal("Gen:: Failed randomizing frame (HEAD1 header)");

        frm.payload = new[10];
        foreach (frm.payload[j])
          frm.payload[j] = $urandom_range(0, 255);

        // Insert 16'hAAAF in payload (HEAD1 reversed)
        frm.payload[3] = 8'hAF;
        frm.payload[4] = 8'hAA;

        frm.display("[--Generator CUSTOM Frame (Payload contains HEAD1 reversed)--]");
      end

      //------------------------------------------
      // 7) Payload contains HEAD_2 (BA55)
      //------------------------------------------
      7: begin
        if (!frm.randomize() with { header_type == ILLEGAL; })
          $fatal("Gen:: Failed randomizing frame (HEAD2 header)");

        frm.payload = new[10];
        foreach (frm.payload[j])
          frm.payload[j] = $urandom_range(0, 255);

        // Insert 16'hBA55 in payload (HEAD2)
        frm.payload[3] = 8'h55;
        frm.payload[4] = 8'hBA;

        frm.display("[--Generator CUSTOM Frame (Payload contains HEAD2)--]");
      end

      //------------------------------------------
      // 8) Payload contains HEAD_2 reversed (55BA)
      //------------------------------------------
      default: begin
        if (!frm.randomize() with { header_type == HEAD_1; })
          $fatal("Gen:: Failed randomizing frame (HEAD2 header)");

        frm.payload = new[10];
        foreach (frm.payload[j])
          frm.payload[j] = $urandom_range(0, 255);

        // Insert 16'h55BA in payload (HEAD2 reversed)
        frm.payload[3] = 8'hBA;
        frm.payload[4] = 8'h55;

        frm.display("[--Generator CUSTOM Frame (Payload contains HEAD2 reversed)--]");
      end
    endcase

    gen2drv.put(frm);

    i++;
    if (i > 8) i = 1; // 8 custom patterns total
  end
endtask







/*

//------------------------------
//  MODE: CUSTOM (Extended Sequence)
//------------------------------
task generate_custom();
  int i = 1;
  
  // 1) 3 random frames
  repeat (3) begin
    frm = new();
    if (!frm.randomize())
      $fatal("Gen:: random randomization failed");
    gen2drv.put(frm);
    frm.display("[--Generator CUSTOM Random Frame--]");
  end

  // 2) 3 legal frames (HEAD1 / HEAD2)
  repeat (3) begin
    frm = new();
    if (!frm.randomize() with { header_type inside {HEAD_1, HEAD_2}; })
      $fatal("Gen:: legal randomization failed");
    gen2drv.put(frm);
    frm.display("[--Generator CUSTOM Legal Frame (Random Legal)--]");
  end
  
  // 3) 4 illegal frames
  repeat (4) begin
    frm = new();
    if (!frm.randomize() with { header_type == ILLEGAL; })
      $fatal("Gen:: illegal randomization failed");
    gen2drv.put(frm);
    frm.display("[--Generator CUSTOM Illegal Frame--]");
  end

  // 4) Existing 8 custom edge/payload frames
  repeat (8) begin
    frm = new();

    case (i)
      1: begin
        if (!frm.randomize() with {
            header_type == ILLEGAL;
            header_bits[7:0] == 8'hAA;
            header_bits[15:8] != 8'hAF;
        })
          $fatal("Gen:: illegal frame randomization with correct LSB failed");
        frm.display("[--Generator CUSTOM Frame (HEAD1 LSB ok)--]");
      end
      
      2: begin
        if (!frm.randomize() with {
          header_type == ILLEGAL;
          header_bits[15:8] == 8'hBA;
          header_bits[7:0] != 8'h55;
        })
          $fatal("Gen:: illegal frame randomization with correct MSB failed");
        frm.display("[--Generator CUSTOM Frame (HEAD2 MSB ok)--]");
      end
      
      3: begin
        if (!frm.randomize() with {
          header_type == ILLEGAL;
          header_bits[7:0]  == 8'hAA;
          header_bits[15:8] == 8'hBA;
        })
          $fatal("Gen:: illegal frame randomization with HEAD1 LSB and HEAD2 MSB failed");
        frm.display("[--Generator CUSTOM Frame HEAD1 LSB and HEAD2 MSB--]");
      end
      
      4: begin
        if (!frm.randomize() with {
          header_type == ILLEGAL;
          header_bits[7:0]  == 8'h55;
          header_bits[15:8] == 8'hAF;
        })
          $fatal("Gen:: illegal frame randomization with HEAD2 LSB and HEAD1 MSB failed");
        frm.display("[--Generator CUSTOM Frame HEAD2 LSB and HEAD1 MSB--]");
      end
      
      5: begin
        if (!frm.randomize())
          $fatal("Gen:: Failed randomizing frame (Payload HEAD1)");
        frm.payload = new[10];
        foreach (frm.payload[j])
          frm.payload[j] = $urandom_range(0, 255);
        frm.payload[3] = 8'hAA;
        frm.payload[4] = 8'hAF;
        frm.display("[--Generator CUSTOM Frame (Payload contains HEAD1)--]");
      end
      
      6: begin
        if (!frm.randomize())
          $fatal("Gen:: Failed randomizing frame (Payload HEAD1 reversed)");
        frm.payload = new[10];
        foreach (frm.payload[j])
          frm.payload[j] = $urandom_range(0, 255);
        frm.payload[3] = 8'hAF;
        frm.payload[4] = 8'hAA;
        frm.display("[--Generator CUSTOM Frame (Payload contains HEAD1 reversed)--]");
      end
      
      7: begin
        if (!frm.randomize())
          $fatal("Gen:: Failed randomizing frame (Payload HEAD2)");
        frm.payload = new[10];
        foreach (frm.payload[j])
          frm.payload[j] = $urandom_range(0, 255);
        frm.payload[3] = 8'h55;
        frm.payload[4] = 8'hBA;
        frm.display("[--Generator CUSTOM Frame (Payload contains HEAD2)--]");
      end
      
      default: begin
        if (!frm.randomize())
          $fatal("Gen:: Failed randomizing frame (Payload HEAD2 reversed)");
        frm.payload = new[10];
        foreach (frm.payload[j])
          frm.payload[j] = $urandom_range(0, 255);
        frm.payload[3] = 8'hBA;
        frm.payload[4] = 8'h55;
        frm.display("[--Generator CUSTOM Frame (Payload contains HEAD2 reversed)--]");
      end
    endcase

    gen2drv.put(frm);
    i++;
    if (i > 8) i = 1;
  end
endtask
  
  */
endclass