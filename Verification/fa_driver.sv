
`include "fa_inf.sv"

class driver;
  
  virtual fa_inf vinf;
  mailbox gen2drv = new(1);
  int num_frames; 
  
  // --- Coverage variables ---
  bit [15:0] header_bits_s;
  bit [7:0]  header_msb_s;
  bit [7:0]  header_lsb_s;
  header_type_t header_type_s;
  // Booleans to track payload content type
  bit contains_head1;
  bit contains_head2;
  bit contains_head1_rev;
  bit contains_head2_rev;
  
  // ================================================
  // COVERGROUP: Header Coverage
  // ================================================
  covergroup hdr_cg @(posedge vinf.clk);
    option.per_instance = 1; // Each instance stores its own coverage data

    // 1) Coverpoint on the full 16-bit header (legal and illegal headers)
    header16_cp : coverpoint header_bits_s {
      bins head1 = {16'hAFAA};
      bins head2 = {16'hBA55};
      bins other = default; // All illegal or undefined headers
    }

    // 2) Coverpoints for MSB and LSB parts separately
    msb_cp : coverpoint header_msb_s {
      bins msb1 = {8'hAF}; // MSB of HEAD1
      bins msb2 = {8'hBA}; // MSB of HEAD2
      bins MSB_other = default;
    }

    lsb_cp : coverpoint header_lsb_s {
      bins lsb1 = {8'hAA}; // LSB of HEAD1
      bins lsb2 = {8'h55}; // LSB of HEAD2
      bins LSB_other = default;
    }

    // 3) Cross coverage between MSB and LSB
    msb_lsb_cross : cross header_msb_s, header_lsb_s;
  endgroup : hdr_cg


  // ================================================
  // COVERGROUP: Payload Coverage
  // ================================================
  covergroup payload_cg @(posedge vinf.clk);
    option.per_instance = 1;

    // Coverpoints for each detected header pattern
    head1_cp      : coverpoint contains_head1     { bins yes = {1'b1}; }
    head2_cp      : coverpoint contains_head2     { bins yes = {1'b1}; }
    head1_rev_cp  : coverpoint contains_head1_rev { bins yes = {1'b1}; }
    head2_rev_cp  : coverpoint contains_head2_rev { bins yes = {1'b1}; }

    // Cross coverage (optional): correlation between all four flags
    head_cross : cross contains_head1, contains_head2,
                       contains_head1_rev, contains_head2_rev;
  endgroup : payload_cg


  // ================================================
  // Constructor
  // ================================================
  function new(virtual fa_inf vinf, mailbox gen2drv);
    this.vinf = vinf;
    this.gen2drv = gen2drv;
    num_frames = 0;
    hdr_cg = new;    
    payload_cg = new;
  endfunction 


  // ================================================
  // Reset task
  // ================================================
  task reset;
    wait(vinf.reset);
    $display("[ --DRIVER--] ----- Reset Started -----");
    vinf.rx_data <= 'h0; 
    vinf.fr_byte_position <= 'h0;
    vinf.frame_detect <= 0;
    wait(!vinf.reset);
    $display("[ --DRIVER--] ----- Reset Ended -----");
  endtask


  // ================================================
  // Main task
  // ================================================
  task main;
    bit [15:0] w16;
    forever begin
      frame frm;
      gen2drv.get(frm);

      // --- HEADER PHASE ---
      @(negedge vinf.clk);
      vinf.rx_data <= frm.header_bits[7:0]; // header LSB
      header_lsb_s = frm.header_bits[7:0];

      @(negedge vinf.clk);
      vinf.rx_data <= frm.header_bits[15:8]; // header MSB
      header_msb_s = frm.header_bits[15:8];

      // Combine for coverage
      header_bits_s = frm.header_bits;
      hdr_cg.sample();

      // --- PAYLOAD PHASE ---
      foreach (frm.payload[i]) begin
        @(negedge vinf.clk);
        vinf.rx_data <= frm.payload[i];
      end

     contains_head1     = 1'b0;
     contains_head2     = 1'b0;
     contains_head1_rev = 1'b0;
     contains_head2_rev = 1'b0;

     for (int i = 0; i < frm.payload.size()-1; i++) begin
       w16 = {frm.payload[i+1], frm.payload[i]};
       if (w16 == 16'hAFAA) contains_head1     = 1'b1;
       if (w16 == 16'hBA55) contains_head2     = 1'b1;
       if (w16 == 16'hAAAF) contains_head1_rev = 1'b1;
       if (w16 == 16'h55BA) contains_head2_rev = 1'b1;
     end

     payload_cg.sample();

      // Display frame info
      frm.display("[ --Driver-- ]");
      num_frames++;
    end
  endtask
endclass