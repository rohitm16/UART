`timescale 1ns / 1ps

module uart_top(
    input  logic       clk,
    input  logic       rst,        // active-high reset 
    input  logic       wr_enb,
    input  logic       ready_clr,
    output logic       rdy,
    output logic       busy,
    output logic [7:0] data_out
);

    // serial line between TX and RX 
    logic tx_temp;

    // clock enables , ticks from baud generator
    logic tx_clk_enb;
    logic rx_clk_enb;

    // -----------------------------------------------------------------
    // baud generator
	// -----------------------------------------------------------------
    baud_gen #(
        .Clk_freq(100_000_000),
        .Baud_rate(9_600),
        .Oversample(16)
    ) baud_inst (
        .clk    (clk),
        .rst_n  (~rst),
        .tx_tick(tx_clk_enb),
        .rx_tick(rx_clk_enb)
    );

    // -----------------------------------------------------------------
    // uart_tx
    // - enb connects to tx_clk_enb (bit-time tick)
    // - tx drives tx_temp (serial line)
    // -----------------------------------------------------------------
    uart_tx tx_inst (
        .clk     (clk),
        .reset_n (~rst),
        .wr_enb  (wr_enb),
        .enb     (tx_clk_enb),
        .data_in (data_in),
        .tx      (tx_temp),
        .busy    (busy)
    );

    // -----------------------------------------------------------------
    // uart_rx
    // - rx samples the same serial line tx_temp
    // - clk_enb connects to rx_clk_enb (oversample tick)
    // -----------------------------------------------------------------
    uart_rx rx_inst (
        .clk       (clk),
        .reset_n   (~rst),
        .ready_clr (ready_clr),
        .clk_enb   (rx_clk_enb),
        .rx        (tx_temp),
        .data_out  (data_out),
        .ready     (rdy)
    );

endmodule
