
class monitor_out;
  
  virtual fa_inf vinf;
  mailbox monout2scb =new(1);
  
  function new (virtual fa_inf vinf,  mailbox monout2scb);
    this.vinf = vinf;
    this.monout2scb = monout2scb;
  endfunction
  
  task main();
    forever begin
      transactionOut transOut;
      transOut = new();
      @(posedge vinf.clk);
      transOut.fr_byte_position = vinf.fr_byte_position;
      transOut.frame_detect = vinf.frame_detect; 
      monout2scb.put(transOut);
      transOut.display("[ --Monitor OUT-- ]"); 
    end
  endtask
    
endclass
    