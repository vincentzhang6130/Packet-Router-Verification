interface router_io (input bit clock);
    
  logic reset_n;
  logic [15:0]	din;
  logic [15:0]	frame_n;
  logic [15:0]	valid_n;
  logic [15:0]	dout;
  logic [15:0]	valido_n;
  logic [15:0]	busy_n;
  logic [15:0]	frameo_n;

  clocking cb @(posedge clock);
    default input #1ns output #1ns;
    output reset_n;
    input dout, valido_n, busy_n, frameo_n; 
    output din, frame_n, valid_n;
  endclocking: cb
  
  // design this for asynchronous  reset
  modport TB(clocking cb, output reset_n);

endinterface: router_io