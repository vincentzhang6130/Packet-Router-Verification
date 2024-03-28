`ifndef INC_RECEIVER_BASE_SV
`define INC_RECEIVER_BASE_SV

class ReceiverBase;
  virtual router_io.TB rtr_io;
  string name;
  bit[3:0] da;
  logic[7:0] pkt2cmp_payload[$];
  Packet pkt2cmp;
  extern function new(string name = "ReceiverBase", virtual router_io.TB rtr_io);
  extern virtual task recv();
  extern virtual task get_payload();
endclass

function ReceiverBase::new(string name, virtual router_io.TB rtr_io);
  if (TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, name);
  this.name = name;
  this.rtr_io = rtr_io;
  this.pkt2cmp = new();
endfunction

task ReceiverBase::recv();
  static int pkt_cnt = 0;
  if(TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
  this.get_payload();
  // Collect the info pkt2cmp needs
  this.pkt2cmp.da = da;
  this.pkt2cmp.payload = this.pkt2cmp_payload;
  this.pkt2cmp.name = $sformatf("rcvdPkt[%0d]", pkt_cnt++);
endtask

task ReceiverBase::get_payload();
  if(TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
  this.pkt2cmp_payload.delete();

  // Watchdog for frameo_n negedge
  fork
    begin: wd_timer_fork
      fork: frameo_wd_timer
        @(negedge this.rtr_io.cb.frameo_n[da]);
        begin 
          repeat(1000) @(this.rtr_io.cb);
          $display("\n%m\n[ERROR]%t Frame[%0d] signal timed out!\n", $realtime, da);
          $finish;
        end
      join_any: frameo_wd_timer
    disable fork;
    end: wd_timer_fork
  join

  forever begin
    logic[7:0] datum;   
    for(int i=0; i<8; i=i) begin
      if(!this.rtr_io.cb.valido_n[da])
        datum[i++] = this.rtr_io.cb.dout[da];
      if(this.rtr_io.cb.frameo_n[da]) begin
        if(i==8) begin
          this.pkt2cmp_payload.push_back(datum);
          return;          
        end
        else begin
          $display("\n%m\n[ERROR]%t Packet payload not byte aligned!\n", $realtime);
          $finish;
        end    
      end  
      @(this.rtr_io.cb);
    end
    // payload size may > 1, so put 1byte to queue and continue loop
    this.pkt2cmp_payload.push_back(datum);
  end
endtask

`endif