`timescale 1ns/100ps
program automatic test(router_io.TB rtr_io);
  `include "router_test.svh"
  `include "Packet.sv"
  `include "Driver.sv"
  `include "Receiver.sv"
  `include "Generator.sv"
  `include "Scoreboard.sv"
 
  int run_for_n_packets;
  int TRACE_ON = 0; 

  semaphore sem[];
  Driver drvr[];
  Receiver rcvr[];
  Generator gen;
  Scoreboard sb;
  
  initial begin
    $vcdpluson;
    run_for_n_packets = 2000;
    sem = new[16];
    drvr = new[16];
    rcvr = new[16];
    gen = new();
    sb = new();

    foreach(sem[i])
      sem[i] = new(1);

    for(int i=0; i<16; i+=1) begin   
      drvr[i] = new($sformatf("drvr[%0d]", i), i, sem, gen.out_box[i], sb.driver_mbox, rtr_io);
      rcvr[i] = new($sformatf("rcvr[%0d]", i), i, sb.receiver_mbox, rtr_io);
    end
  
    reset();
    gen.start();
    sb.start();
    
    foreach(drvr[i])
      drvr[i].start();
    foreach(rcvr[i])
      rcvr[i].start();
    wait(sb.DONE.triggered);  

  end

  task reset();
    if(TRACE_ON) $display("[TRACE]%t %m", $realtime);
    rtr_io.reset_n = 1'b0; //asynchronus
    rtr_io.cb.frame_n <= '1;
    rtr_io.cb.valid_n <= '1;
    ##2 rtr_io.cb.reset_n <= 1'b1;
    repeat(15) @(rtr_io.cb);
  endtask: reset

endprogram: test