module axi_slave #(parameter ADDR_W=32, DATA_W=32, DEPTH=256)(
  input  logic clk, rst_n,
  inout  axi_if #(ADDR_W, DATA_W) axi
);
  logic [DATA_W-1:0] mem [0:DEPTH-1];

  // Write logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      axi.AWREADY <= 0;
      axi.WREADY  <= 0;
      axi.BVALID  <= 0;
    end else begin
      // address handshake
      if (axi.AWVALID && !axi.AWREADY) axi.AWREADY <= 1;
      else axi.AWREADY <= 0;

      // data handshake
      if (axi.WVALID) begin
        mem[axi.AWADDR[7:0] >> 2] <= axi.WDATA;
        axi.WREADY <= 1;
        if (axi.WLAST) begin
          axi.BVALID <= 1;
          axi.BRESP  <= 2'b00; // OKAY
        end
      end else axi.WREADY <= 0;

      // response
      if (axi.BVALID && axi.BREADY) axi.BVALID <= 0;
    end
  end

  // Read logic
  int rcount;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      axi.ARREADY <= 0;
      axi.RVALID  <= 0;
    end else begin
      if (axi.ARVALID && !axi.ARREADY) begin
        axi.ARREADY <= 1;
        rcount = axi.ARLEN+1;
      end else axi.ARREADY <= 0;

      if (rcount > 0) begin
        axi.RDATA <= mem[axi.ARADDR[7:0] >> 2];
        axi.RLAST <= (rcount == 1);
        axi.RVALID <= 1;
        axi.RRESP  <= 2'b00;
        if (axi.RVALID && axi.RREADY) rcount -= 1;
      end else axi.RVALID <= 0;
    end
  end
endmodule
