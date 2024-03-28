`ifndef INC_SCOREBOARD_SV
`define INC_SCOREBOARD_SV
class Scoreboard;
  string name;
  event DONE;
  Packet refPkt[$];
  Packet pkt2cmp;
  Packet pkt2send;
  pkt_mbox driver_mbox;
  pkt_mbox receiver_mbox;

  // functional coverage properties
  bit[3:0] sa, da;
  covergroup router_cov;
    coverpoint sa;
    coverpoint da;
    cross sa, da;
  endgroup

  extern function new(string name = "Scoreboard", pkt_mbox driver_mbox = null, receiver_mbox = null);
  extern virtual task start();
  extern virtual task check();
endclass

function Scoreboard::new(string name, pkt_mbox driver_mbox, receiver_mbox);
  if (TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, name);
  this.name = name;
  if(driver_mbox==null) driver_mbox = new();
  this.driver_mbox = driver_mbox;
  if(receiver_mbox==null) receiver_mbox = new();
  this.receiver_mbox = receiver_mbox;
  router_cov = new();
endfunction: new

task Scoreboard::start();
  if(TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
  fork
    forever begin
      this.receiver_mbox.get(this.pkt2cmp);
      while(this.driver_mbox.num()) begin
        Packet pkt;
        this.driver_mbox.get(pkt);
        this.refPkt.push_back(pkt);  
      end
      this.check();     
    end
  join_none
endtask: start

task Scoreboard::check();
  int index[$];
  string message;
  static int pkts_checked = 0;
  real coverage_result;
  
  if(TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
  index = this.refPkt.find_first_index() with (item.da == this.pkt2cmp.da);
  if(index.size() <= 0) begin
    $display("\n%m\n[ERROR]%t %s not found in Reference Queue", $realtime, this.pkt2cmp.name);
    this.pkt2cmp.display("ERROR");
    $finish;
  end
  this.pkt2send = this.refPkt[index[0]];
  this.refPkt.delete(index[0]);
  if(!this.pkt2send.compare(this.pkt2cmp, message)) begin
    $display("\n%m\n[ERROR]%t Packet #%0d %s\n", $realtime, pkts_checked, message);
    this.pkt2send.display("ERROR");
    this.pkt2cmp.display("ERROR");
    $finish;
  end

  this.sa = pkt2send.sa;
  this.da = pkt2send.da; 

  // update the covergroup bins with sample()
  this.router_cov.sample();
  coverage_result = $get_coverage();

  $display("[NOTE]%t Packet #%0d %s -Coverage = %3.2f", $realtime, pkts_checked++, message, coverage_result);
  if((pkts_checked >= run_for_n_packets) || (coverage_result == 100.00)) 
    ->this.DONE;
  // $display("[NOTE]%t Packet #%0d %s", $realtime, pkts_checked++, message);
  // if(pkts_checked >= run_for_n_packets)
  //   ->this.DONE; // trigger event

endtask: check

`endif