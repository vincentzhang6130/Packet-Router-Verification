`ifndef INC_DRIVER_BASE_SV
`define INC_DRIVER_BASE_SV

class DriverBase;
  
  virtual router_io.TB rtr_io;
  string name;
  bit[3:0] sa, da;
  logic[7:0] payload[$];
  Packet pkt2send;

  extern function new(string name = "DriverBase", virtual router_io.TB rtr_io);
  extern virtual task send();
  extern virtual task send_addrs();
  extern virtual task send_pad();
  extern virtual task send_payload();

endclass

function DriverBase::new(string name, virtual router_io.TB rtr_io);
  this.name = name;
  this.rtr_io = rtr_io;
endfunction: new

task DriverBase::send();
  send_addrs();
  send_pad();
  send_payload();
endtask: send

task DriverBase::send_addrs();
  if(TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
  this.rtr_io.cb.frame_n[this.sa] <= 1'b0;
  for(int i=0; i<4; i++) begin
    this.rtr_io.cb.din[this.sa] <= this.da[i];
    @(this.rtr_io.cb);
  end
endtask: send_addrs

task DriverBase::send_pad();
  if(TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
  this.rtr_io.cb.valid_n[this.sa] <= 1'b1;
  this.rtr_io.cb.din[this.sa] <= 1'b1;
  repeat(5) @(this.rtr_io.cb);
endtask: send_pad

task DriverBase::send_payload();
  if(TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
  this.rtr_io.cb.valid_n[this.sa] <= 1'b0;
  foreach(this.payload[index]) begin
    for(int i=0; i<8; i++) begin
      this.rtr_io.cb.din[this.sa] <= this.payload[index][i];
      this.rtr_io.cb.valid_n[this.sa] <= 1'b0;
      this.rtr_io.cb.frame_n[this.sa] <= ((index == (this.payload.size() - 1)) && (i == 7)); 
      @(this.rtr_io.cb);
    end
  end  
  this.rtr_io.cb.valid_n[this.sa] <= 1'b1;

endtask: send_payload


`endif