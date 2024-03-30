class Environment;
    string name;
    rand int run_for_n_packets;
    virtual router_io.TB rtr_io;

    semaphore sem[];
    Driver drvr[];
    Receiver rcvr[];
    Generator gen;
    Scoreboard sb;

    constraint valid{ 
        this.run_for_n_packets inside {[1500:2500]};
    }

    extern function new(string name = "Env", virtual router_io.TB rtr_io);
    extern virtual function void build();
    extern virtual task reset();
    extern virtual task run();
    extern virtual function void configure();
    extern virtual task start();
    extern virtual task wait_for_end();

endclass: Environment

function Environment::new(string name = "Env", virtual router_io.TB rtr_io);
    if(TRACE_ON) $display("[TRACE]%t %s: %m", $realtime, name);
    this.name = name;
    this.rtr_io = rtr_io;
endfunction: new

task Environment::run();
    if (TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
    this.build();
    this.reset();
    this.start();
    this.wait_for_end();
endtask: run

function void Environment::configure();
    if (TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
    this.randomize();
endfunction: configure

function void Environment::build();
    if (TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
    if(this.run_for_n_packets == 0) this.run_for_n_packets = 2000;
    this.sem = new[16];
    this.drvr = new[16];
    this.rcvr = new[16];
    this.gen = new();
    this.sb = new();

    foreach(sem[i])
      this.sem[i] = new(1);

    for(int i=0; i<16; i+=1) begin   
      this.drvr[i] = new($sformatf("drvr[%0d]", i), i, sem, gen.out_box[i], sb.driver_mbox, rtr_io);
      this.rcvr[i] = new($sformatf("rcvr[%0d]", i), i, sb.receiver_mbox, rtr_io);
    end
endfunction: build

task Environment::start();
    if (TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
    this.gen.start();
    this.sb.start();
    foreach(drvr[i])
      this.drvr[i].start();
    foreach(rcvr[i])
      this.rcvr[i].start();
endtask: start

task Environment::wait_for_end();
    if (TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
    wait(this.sb.DONE.triggered); 
endtask: wait_for_end

task Environment::reset();
    if(TRACE_ON) $display("[TRACE]%t %m", $realtime);
    rtr_io.reset_n = 1'b0; //asynchronus
    rtr_io.cb.frame_n <= '1;
    rtr_io.cb.valid_n <= '1;
    ##2 rtr_io.cb.reset_n <= 1'b1;
    repeat(15) @(rtr_io.cb);
endtask: reset

