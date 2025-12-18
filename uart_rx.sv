`timescale 1ns / 1ps

module uart_rx(
    input  logic       clk,
    input  logic       reset_n,
    input  logic       ready_clr,
    input  logic       clk_enb,    // sampling tick i.e. 16x
    input  logic       rx,
    output reg  [7:0]  data_out,   
    output logic       ready
);

    localparam int OVERSAMPLE = 16;         
    localparam int HALF       = OVERSAMPLE/2;

    logic [3:0] sample_reg, sample_next;    // for sampling
    logic [2:0] index_reg,  index_next;     // for index of bits 
    logic [7:0] temp_reg,   temp_next;
    logic       ready_reg,  ready_next;

    typedef enum logic [1:0] {Idle, Start, Data, Stop} state_type; 
    state_type state_reg, state_next;

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            state_reg  <= Idle;
            sample_reg <= '0;
            index_reg  <= '0;
            temp_reg   <= '0;
            data_out   <= '0;
            ready_reg  <= 1'b0;
        end
        else begin
            state_reg  <= state_next;
            sample_reg <= sample_next;
            index_reg  <= index_next;
            temp_reg   <= temp_next;
            data_out   <= data_out;   
            ready_reg  <= ready_next;

            // WHEN byte complete we update data_out in this sequential block
            if (state_reg == Stop && state_next == Idle) begin        
                data_out <= temp_reg;
            end
        end
    end
    
    always_comb begin
        state_next  = state_reg;
        sample_next = sample_reg;
        index_next  = index_reg;
        temp_next   = temp_reg;
        ready_next  = ready_reg;

        // clear ready when external clear asserted, synchronous behavior chosen
        if (ready_clr)
            ready_next = 1'b0;

        case (state_reg)

            Idle: begin
                // wait for start bit (rx falling edge)
                sample_next = '0;
                index_next  = '0;
                if (rx == 1'b0) begin
                    // detected potential start, go to Start and begin counting on clk_enb
                    state_next = Start;
                end
            end

            Start: begin
                // On each sampling tick, increment sample counter until half-bit center
                if (clk_enb) begin
                    if (sample_reg == HALF-1) begin
                        // on reached center of start bit go to Data and prepare to sample first data bit
                        sample_next = '0;
                        index_next  = '0;
                        state_next  = Data;
                    end
                    else begin
                        sample_next = sample_reg + 1'b1;
                    end
                end
            end

            Data: begin
                // Sampling each data bit at the center of bit period
                if (clk_enb) begin
                    if (sample_reg == OVERSAMPLE-1) begin
                        // end of a bit period: capture bit at center moment (we captured at sample==OVERSAMPLE-1)
                        sample_next = '0;
                        // capture current rx into temp at current index
                        temp_next = temp_reg;
                        temp_next[index_reg] = rx;
                        if (index_reg == 3'd7) begin
                            // last data bit captured 
                            state_next = Stop;
                        end
                        else begin
                            index_next = index_reg + 1'b1;
                        end
                    end
                    else begin
                        sample_next = sample_reg + 1'b1;
                    end
                end
            end

            Stop: begin
                // wait one bit-time (stop bit). After full bit-time, mark ready and go Idle.
                if (clk_enb) begin
                    if (sample_reg == OVERSAMPLE-1) begin
                        sample_next = '0;
                        state_next  = Idle;
                        ready_next  = 1'b1;    // byte ready — latched into data_out in sequential block
                    end
                    else begin
                        sample_next = sample_reg + 1'b1;
                    end
                end
            end

            default: begin
                state_next  = Idle;
                sample_next = '0;
                index_next  = '0;
                temp_next   = '0;
                ready_next  = 1'b0;
            end
        endcase
    end

    assign ready = ready_reg;

endmodule
