`timescale 1ns / 1ps

module baud_gen #(
    parameter int Clk_freq   = 100_000_000,
    parameter int Baud_rate  = 9_600,
    parameter int Oversample = 16
)(
    input  logic clk,
    input  logic rst_n,
    output logic rx_tick,
    output logic tx_tick
);

    localparam int Bit_time      = Clk_freq / Baud_rate;
    localparam int Sampling_time = Bit_time / Oversample;

    logic [$clog2(Bit_time)-1:0]      counter_tx;
    logic [$clog2(Sampling_time)-1:0] counter_rx;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            counter_tx <= '0;
            tx_tick    <= 1'b0;
        end
        else if (counter_tx == Bit_time-1) begin
            counter_tx <= '0;
            tx_tick    <= 1'b1;   
        end
        else begin
            counter_tx <= counter_tx + 1'b1;
            tx_tick    <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            counter_rx <= '0;
            rx_tick    <= 1'b0;
        end
        else if (counter_rx == Sampling_time-1) begin
            counter_rx <= '0;
            rx_tick    <= 1'b1;   
        end
        else begin
            counter_rx <= counter_rx + 1'b1;
            rx_tick    <= 1'b0;
        end
    end

endmodule
