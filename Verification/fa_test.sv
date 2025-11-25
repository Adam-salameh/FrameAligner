

`include "fa_environment.sv"

program fa_test (fa_inf i_inf);
    environment env;
  
    initial begin
      env = new(i_inf);
   /*   // check RANDOM
      env.gen.mode = RANDOM_FRAMES;
      env.gen.repeat_count = 5;
      env.run();
      
      // check LOSS_OF_SYNC
      env.gen.mode = LOSS_OF_SYNC;
      env.gen.repeat_count = 4;
      env.run();
      
      // check ALIGNED
      env.gen.mode = ALIGNED;
      env.gen.repeat_count = 3;
      env.run();
   */   
      // check CUSTOM
      env.gen.mode = CUSTOM;
      env.gen.repeat_count = 8;
      env.run();
      
      $finish;
    end
endprogram

