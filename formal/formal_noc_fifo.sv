// ============================================================================
// File: formal_noc_fifo.sv
// Project: Ara_MultiCore_WSE_HBM3
// Description:
//   Formal Property Verification (SVA) for Synchronous NoC FIFO.
//   Target: SymbiYosys (sby) with Z3 SMT/SAT Solver.
// ============================================================================

`timescale 1ps/1fs

module formal_noc_fifo #(
    parameter int unsigned DATA_W = 32,
    parameter int unsigned DEPTH  = 4
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic [DATA_W-1:0] push_data_i,
    input  logic              push_valid_i,
    output logic              push_ready_o,
    output logic [DATA_W-1:0] pop_data_o,
    output logic              pop_valid_o,
    input  logic              pop_ready_i
);

    // Instantiate Design Under Test (DUT)
    ara_noc_fifo #(
        .DATA_W(DATA_W),
        .DEPTH (DEPTH)
    ) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .push_data_i (push_data_i),
        .push_valid_i(push_valid_i),
        .push_ready_o(push_ready_o),
        .pop_data_o  (pop_data_o),
        .pop_valid_o (pop_valid_o),
        .pop_ready_i (pop_ready_i)
    );

`ifdef FORMAL
    // Formal Reset Setup (Reset low in cycle 0, then high)
    reg [2:0] reset_cnt = 0;
    always @(posedge clk) begin
        if (reset_cnt < 3'd4)
            reset_cnt <= reset_cnt + 1'b1;
    end

    always_comb begin
        if (reset_cnt < 3'd2)
            assume (!rst_n);
        else
            assume (rst_n);
    end

    // ------------------------------------------------------------------------
    // MATHEMATICAL INVARIANTS (SVA ASSERTIONS)
    // ------------------------------------------------------------------------

    // Invariant 1: Queue occupancy can NEVER exceed DEPTH
    always @(posedge clk) begin
        if (rst_n) begin
            assert (dut.count_q <= DEPTH);
        end
    end

    // Invariant 2: Ready and Valid flags must strictly match internal counter
    always @(posedge clk) begin
        if (rst_n) begin
            assert (push_ready_o == (dut.count_q < DEPTH));
            assert (pop_valid_o  == (dut.count_q > 0));
        end
    end

    // Invariant 3: Pointers must stay within [0, DEPTH-1]
    always @(posedge clk) begin
        if (rst_n) begin
            assert (dut.wr_ptr_q < DEPTH);
            assert (dut.rd_ptr_q < DEPTH);
        end
    end

    // Invariant 4: No pop fire when count is 0 (Underflow Immunity)
    always @(posedge clk) begin
        if (rst_n && dut.count_q == 0) begin
            assert (!pop_valid_o);
            assert (!dut.pop_fire);
        end
    end

    // Invariant 5: No push fire when count is DEPTH (Overflow Immunity)
    always @(posedge clk) begin
        if (rst_n && dut.count_q == DEPTH) begin
            assert (!push_ready_o);
            assert (!dut.push_fire);
        end
    end

    // Invariant 6: Single-step Counter Delta Conservation
    // At every cycle: count[t+1] = count[t] + push_fire - pop_fire
    localparam int unsigned PTR_W = $clog2(DEPTH);
    logic [PTR_W:0] past_count;
    logic past_push_fire, past_pop_fire, past_rst_n;
    always @(posedge clk) begin
        past_count     <= dut.count_q;
        past_push_fire <= dut.push_fire;
        past_pop_fire  <= dut.pop_fire;
        past_rst_n     <= rst_n;

        if (rst_n && past_rst_n) begin
            case ({past_push_fire, past_pop_fire})
                2'b10: assert (dut.count_q == past_count + 1'b1);
                2'b01: assert (dut.count_q == past_count - 1'b1);
                2'b11: assert (dut.count_q == past_count);
                2'b00: assert (dut.count_q == past_count);
            endcase
        end
    end

`endif

endmodule
