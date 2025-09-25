// ==================================================
// Part 3: Testbench
// ==================================================
`timescale 1ns/1ps
module tb_axi;
  logic clk, rst_n;

  // Interface
  axi_if axi(clk, rst_n);

  // DUT
  axi_master m0(.clk(clk), .rst_n(rst_n), .axi(axi));
  axi_slave  s0(.clk(clk), .rst_n(rst_n), .axi(axi));

  // Clock
  initial clk=0;
  always #5 clk = ~clk;

  // Reset
  initial begin
    rst_n=0;
    #20 rst_n=1;
  end

  // Transaction class for constrained random
  class axi_txn;
    rand bit [31:0] addr;
    rand int        len;
    rand bit [31:0] data[];
    constraint c_len { len inside {[1:4]}; }
    function string sprint(); return $sformatf(\"AXI TXN addr=%h len=%0d\", addr, len); endfunction
  endclass

  // Scoreboard
  bit [31:0] golden_mem [256];

  initial begin
    wait(rst_n);
    axi_txn t;
    repeat (5) begin
      t = new();
      assert(t.randomize() with { addr inside {[32'h0:32'hFF]}; });
      t.data = new[t.len];
      foreach(t.data[i]) t.data[i] = $random;

      // WRITE
      m0.write_burst(t.addr, t.len, t.data);
      for (int i=0;i<t.len;i++) golden_mem[(t.addr>>2)+i] = t.data[i];

      // READ
      bit [31:0] rdata[];
      m0.read_burst(t.addr, t.len, rdata);
      for (int i=0;i<t.len;i++) begin
        if (rdata[i] !== golden_mem[(t.addr>>2)+i]) begin
          $error(\"Mismatch at %0d: expected %h got %h\", i, golden_mem[(t.addr>>2)+i], rdata[i]);
        end
      end
    end

    #100;
    $display(\"AXI Testbench completed successfully\");
    $finish;
  end
endmodule
