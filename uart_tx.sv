`timescale 1ns / 1ps

module uart_tx(
    input  logic       clk,
    input  logic       reset_n,
    input  logic       wr_enb,
    input  logic       enb, // baud tick
    input  logic [7:0] data_in,
    output logic       tx,
    output logic       busy
);


    logic [7:0] data_reg,  data_next;
    logic [3:0] index_reg, index_next;
    logic       tx_reg,    tx_next;

    typedef enum logic [1:0] {Idle, Start, Data, Stop} state_type;
    state_type state_reg, state_next;

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            state_reg <= Idle;
            data_reg  <= '0;
            index_reg <= '0;
            tx_reg    <= 1'b1;   // UART idle  high
        end
        else begin
            state_reg <= state_next;
            data_reg  <= data_next;
            index_reg <= index_next;
            tx_reg    <= tx_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        data_next  = data_reg;
        index_next = index_reg;
        tx_next    = tx_reg;

        case (state_reg)

            Idle: begin
                tx_next = 1'b1;
                if (wr_enb) begin
                    data_next  = data_in;  
                    state_next = Start;
                end
            end

            Start: begin
                tx_next = 1'b0; // Start bit            
                if (enb) begin
                    index_next = 0;        
                    state_next = Data;
                end
            end

            Data: begin
                tx_next = data_reg[index_reg];
                if (enb) begin
                    if (index_reg == 7) begin
                        state_next = Stop;  
                    end
                    else begin
                        index_next = index_reg + 1;
                    end
                end
            end

            Stop: begin
                tx_next = 1'b1; // Stop bit
                if (enb) begin
                    state_next = Idle;
                end
            end

            default: state_next = Idle;
        endcase
    end

    assign tx   = tx_reg;
    assign busy = (state_reg != Idle);

endmodule
