module uart_tx(
    input           mclk,
    input           n_reset,
    input   [15:0]  baud_max_cnt, // set 10417-1 -> 9600 baudrate
    input   [7:0]   tr_data,
    input   [1:0]   parity_sel,
    input           stop_sel,
    input           send_en,
    output  reg     txd,
    output          done
);

// Define states
reg state;
parameter IDLE = 1'd0;
parameter SEND = 1'd1;

// State flag
wire idle_flag = (state == IDLE) ? 1'b1 : 1'b0;
wire send_flag = (state == SEND) ? 1'b1 : 1'b0;

// State transition
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        state <= 1'b0;
    else
        state <= (idle_flag & send_en) ? SEND :
                 (send_flag & (parity_sel == 2'b00) & (stop_sel == 1'b0) & (cnt2 == 4'd10)) ? IDLE :
                 (send_flag & (parity_sel == 2'b00) & (stop_sel == 1'b1) & (cnt2 == 4'd11)) ? IDLE :
                 (send_flag & (parity_sel != 2'b00) & (stop_sel == 1'b0) & (cnt2 == 4'd11)) ? IDLE :
                 (send_flag & (parity_sel != 2'b00) & (stop_sel == 1'b1) & (cnt2 == 4'd12)) ? IDLE : state;

//-----------------------------------------------------------------------------------------------------------------------------------------

// 1-bit duration counter
reg [15:0] cnt1;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        cnt1 <= 16'b0;
    else
        cnt1 <= (idle_flag) ? 16'b0 :
                (cnt1 == baud_max_cnt) ? 16'b0 : cnt1 + 1'b1;

// transmitting bit counter
reg [3:0] cnt2;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        cnt2 <= 4'b0;
    else
        cnt2 <= (idle_flag) ? 4'b0 :
                (cnt1 == baud_max_cnt) ? cnt2 + 1'b1 : cnt2;

// parity bit
wire tr_data_xor = tr_data[0]^tr_data[1]^tr_data[2]^tr_data[3]^tr_data[4]^tr_data[5]^tr_data[6]^tr_data[7];

reg parity_bit;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        parity_bit <= 1'b0;
    else
        parity_bit <= (parity_sel == 2'b01) ? tr_data_xor : (parity_sel == 2'b10) ? ~tr_data_xor : parity_bit;

// txd
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        txd <= 1'b0;
    else
        txd <= (idle_flag) ? 1'b1 : 
               ((cnt2 == 4'd0) & (cnt1 == 16'd0)) ? 1'b0 : // start bit
               ((cnt2 == 4'd1) & (cnt1 == 16'd0)) ? tr_data[0] :
               ((cnt2 == 4'd2) & (cnt1 == 16'd0)) ? tr_data[1] :
               ((cnt2 == 4'd3) & (cnt1 == 16'd0)) ? tr_data[2] :
               ((cnt2 == 4'd4) & (cnt1 == 16'd0)) ? tr_data[3] :
               ((cnt2 == 4'd5) & (cnt1 == 16'd0)) ? tr_data[4] :
               ((cnt2 == 4'd6) & (cnt1 == 16'd0)) ? tr_data[5] :
               ((cnt2 == 4'd7) & (cnt1 == 16'd0)) ? tr_data[6] :
               ((cnt2 == 4'd8) & (cnt1 == 16'd0)) ? tr_data[7] : 

               ((parity_sel == 2'b00) & (stop_sel == 1'b0) & (cnt2 == 4'd9)  & (cnt1 == 16'd0)) ? 1'b1 :

               ((parity_sel == 2'b00) & (stop_sel == 1'b1) & (cnt2 == 4'd9)  & (cnt1 == 16'd0)) ? 1'b1 :
               ((parity_sel == 2'b00) & (stop_sel == 1'b1) & (cnt2 == 4'd10) & (cnt1 == 16'd0)) ? 1'b1 :

               ((parity_sel != 2'b00) & (stop_sel == 1'b0) & (cnt2 == 4'd9)  & (cnt1 == 16'd0)) ? parity_bit :
               ((parity_sel != 2'b00) & (stop_sel == 1'b0) & (cnt2 == 4'd10) & (cnt1 == 16'd0)) ? 1'b1 :

               ((parity_sel != 2'b00) & (stop_sel == 1'b1) & (cnt2 == 4'd9)  & (cnt1 == 16'd0)) ? parity_bit :
               ((parity_sel != 2'b00) & (stop_sel == 1'b1) & (cnt2 == 4'd10) & (cnt1 == 16'd0)) ? 1'b1 :
               ((parity_sel != 2'b00) & (stop_sel == 1'b1) & (cnt2 == 4'd11) & (cnt1 == 16'd0)) ? 1'b1 : txd;

assign done = idle_flag;

endmodule
