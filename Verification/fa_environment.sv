

`include "fa_frame.sv"
`include "fa_transaction_in.sv"
`include "fa_transaction_out.sv"
`include "fa_generator.sv"
`include "fa_driver.sv"
`include "fa_monitor_in.sv"
`include "fa_monitor_out.sv"
`include "fa_scoreboard.sv"
class environment;
  generator gen;
  driver drv;
  monitor_in monin;
  monitor_out monout;
  scoreboard scb;
  
  mailbox gen2drv= new(1);
  mailbox monin2scb= new(1);
  mailbox monout2scb= new(1);
  
  virtual fa_inf vinf;
  
  function new(virtual fa_inf vinf);
    this.vinf = vinf;
    gen2drv = new();
    monin2scb = new();
    monout2scb= new();

    gen = new(gen2drv);
    drv = new(vinf,gen2drv);
    monin = new(vinf, monin2scb);
    monout = new(vinf, monout2scb);
    scb = new (monin2scb, monout2scb);
  endfunction
  
  
  task pre_test();
    vinf.reset <= 1;
    scb.reset_ref;
    scb.num_transactions = 0;
    drv.num_frames = 0;
    fork
      begin
        drv.reset();
      end
      begin
        #15;
        vinf.reset <= 0;
      end
    join
  endtask
  
  task test();
    fork 
      gen.main();
      drv.main();
      monin.main();
      monout.main();
      scb.main();
    join_any
  endtask
  
  task post_test();
    wait(gen.ended.triggered);
    wait(gen.repeat_count == drv.num_frames);
    wait(gen.repeat_count*12 == scb.num_transactions);
  endtask
  
  task run();
    pre_test();
    test();
    post_test();
  endtask  
endclass
