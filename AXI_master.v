interface axi_if #(parameter ADDR_W=32, DATA_W=32)(input bit clk, input bit rst_n);
  // Write address channel
  logic [ADDR_W-1:0] AWADDR;
  logic [7:0]        AWLEN;    // burst length
  logic              AWVALID;
  logic              AWREADY;

  // Write data channel
  logic [DATA_W-1:0] WDATA;
  logic              WLAST;
  logic              WVALID;
  logic              WREADY;
  // Write response channel
  logic [1:0]        BRESP;
  logic              BVALID;
  logic              BREADY;

  // Read address channel
  logic [ADDR_W-1:0] ARADDR;
  logic [7:0]        ARLEN;
  logic              ARVALID;
  logic              ARREADY;

  // Read data channel
  logic [DATA_W-1:0] RDATA;
  logic              RLAST;
  logic [1:0]        RRESP;
  logic              RVALID;
  logic              RREADY;
endinterface

module axi_master #(parameter ADDR_W=32, DATA_W=32)(
  input  logic clk, rst_n,
  inout  axi_if #(ADDR_W, DATA_W) axi
);
  // Simple programmable transfer task
  task automatic write_burst(input [ADDR_W-1:0] addr, input int len, input bit [DATA_W-1:0] data[]);
    // address phase
    axi.AWADDR  <= addr;
    axi.AWLEN   <= len-1;
    axi.AWVALID <= 1;
    wait (axi.AWREADY);
    axi.AWVALID <= 0;

    // data phase
    for (int i=0; i<len; i++) begin
      axi.WDATA  <= data[i];
      axi.WLAST  <= (i == len-1);
      axi.WVALID <= 1;
      wait (axi.WREADY);
      axi.WVALID <= 0;
    end

    // response
    axi.BREADY <= 1;
    wait (axi.BVALID);
    axi.BREADY <= 0;
  endtask

  task automatic read_burst(input [ADDR_W-1:0] addr, input int len, output bit [DATA_W-1:0] data[]);
    axi.ARADDR  <= addr;
    axi.ARLEN   <= len-1;
    axi.ARVALID <= 1;
    wait (axi.ARREADY);
    axi.ARVALID <= 0;

    data = new[len];
    for (int i=0; i<len; i++) begin
      axi.RREADY <= 1;
      wait (axi.RVALID);
      data[i] = axi.RDATA;
      if (axi.RLAST) axi.RREADY <= 0;
    end
  endtask
endmodule
