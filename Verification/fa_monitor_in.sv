
class monitor_in;
  virtual fa_inf vinf;
  mailbox monin2scb =new(1);
  
  function new (virtual fa_inf vinf,  mailbox monin2scb);
    this.vinf = vinf;
    this.monin2scb = monin2scb;
  endfunction
  
  task main();    
    forever begin
      transactionIn transIn;
      transIn = new();
      @(posedge vinf.clk);
      transIn.rx_data = vinf.rx_data;
      monin2scb.put(transIn);
      transIn.display("[ --Monitor IN-- ]"); 
    end
  endtask
endclass