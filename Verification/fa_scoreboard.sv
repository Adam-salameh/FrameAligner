`include "fa_refmod.sv"
class scoreboard;
  
  refmod refm;
  mailbox monin2scb;
  mailbox monout2scb;
  int num_transactions;
  bit [3:0] exp_fr_byte_position;
  bit exp_frame_detect;
  
  function new(mailbox monin2scb, mailbox monout2scb);
    this.monin2scb  = monin2scb;
    this.monout2scb = monout2scb;
    refm = new();
    num_transactions     = '0;
    exp_fr_byte_position = '0;
    exp_frame_detect     = '0;
  endfunction
  
  task main();
    transactionIn  transIn;
    transactionOut transOut;
    
    forever begin
      // Receive transaction In
      monin2scb.get(transIn);
      // Receive transaction Out
      monout2scb.get(transOut);
      
      // Run reference model
      refm.load_bytes(transIn.rx_data, exp_fr_byte_position);
      exp_frame_detect     = refm.frame_detect;
      
      // Compare results
      if (exp_fr_byte_position != transOut.fr_byte_position)
        $error("MISMATCH IN: fr_byte_position ----> exp=%0d got=%0d",
                exp_fr_byte_position, transOut.fr_byte_position);
      else
       $display("PASS: fr_byte_position ----> %0d", transOut.fr_byte_position);

      if (exp_frame_detect != transOut.frame_detect)
        $error("MISMATCH IN: frame_detect ----> exp=%0d got=%0d",
                exp_frame_detect, transOut.frame_detect);
      else
       $display("PASS: frame_detect ----> %0d", transOut.frame_detect);

      num_transactions++;
    end
    
  endtask
  task reset_ref();
    refm.reset();
endtask
endclass