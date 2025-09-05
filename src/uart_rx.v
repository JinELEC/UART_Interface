module uart_rx(
    input           mclk,
    input           n_reset,
    input   [15:0]  baud_max_cnt,
    input   [1:0]   parity_sel, // 0: none, 1: even, 2: odd
    input           stop_sel,   // 0: 1 stop bit, 1: 2 stop bit
    input           read_en,
    output  [7:0]   rd_data,
    output          rd_valid,
    output          full,
    output  reg     frame_err,
    output  reg     parity_err,
    input           rxd
);

// Define states
reg [1:0] state;
parameter IDLE    = 2'd0;
parameter RECEIVE = 2'd1;
parameter DONE    = 2'd2;

// State flag
wire idle_flag    = (state == IDLE)    ? 1'b1 : 1'b0;
wire receive_flag = (state == RECEIVE) ? 1'b1 : 1'b0;
wire done_flag    = (state == DONE)    ? 1'b1 : 1'b0;

// State transition
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        state <= 2'b0;
    else
        state <= (idle_flag & rxd_negedge)                                                               ? RECEIVE :
                 ((parity_sel == 2'b00) & (stop_sel == 1'b0) & (cnt2 == 4'd9)  & (cnt1 == baud_max_cnt)) ? DONE :
                 ((parity_sel == 2'b00) & (stop_sel == 1'b1) & (cnt2 == 4'd10) & (cnt1 == baud_max_cnt)) ? DONE :
                 ((parity_sel != 2'b00) & (stop_sel == 1'b0) & (cnt2 == 4'd10) & (cnt1 == baud_max_cnt)) ? DONE :
                 ((parity_sel != 2'b00) & (stop_sel == 1'b1) & (cnt2 == 4'd11) & (cnt1 == baud_max_cnt)) ? DONE :
                 (done_flag & (done_cnt == 3'd7))                                                        ? IDLE : state;

//---------------------------------------------------------------------------------------------------------------------------------------------------------
// rxd negative edge
reg rxd_1d, rxd_2d, rxd_3d;
wire rxd_negedge = ~rxd_2d & rxd_3d;
always@(negedge n_reset, posedge mclk)
    if(!n_reset) begin
        rxd_1d <= 1'b1;
        rxd_2d <= 1'b1;
        rxd_3d <= 1'b1;
    end
    else begin
        rxd_1d <= rxd;
        rxd_2d <= rxd_1d;
        rxd_3d <= rxd_2d;
    end

// 1-bit duration counter
reg [15:0] cnt1;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        cnt1 <= 16'b0;
    else
        cnt1 <= (~receive_flag) ? 4'b0 :
                (cnt1 == baud_max_cnt) ? 16'b0 : cnt1 + 1'b1;

// transmitting bit counter
reg [3:0] cnt2;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        cnt2 <= 4'b0;
    else
        cnt2 <= (~receive_flag) ? 4'b0 :
                (cnt1 == baud_max_cnt) ? cnt2 + 1'b1 : cnt2;

// read data from rxd
reg [7:0] rxd_data;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        rxd_data <= 8'b0;
    else begin
        rxd_data[0] <= ((cnt2 == 4'd1) & (cnt1 == {1'b0, baud_max_cnt[15:1]})) ? rxd_3d : rxd_data[0];
        rxd_data[1] <= ((cnt2 == 4'd2) & (cnt1 == {1'b0, baud_max_cnt[15:1]})) ? rxd_3d : rxd_data[1];
        rxd_data[2] <= ((cnt2 == 4'd3) & (cnt1 == {1'b0, baud_max_cnt[15:1]})) ? rxd_3d : rxd_data[2];
        rxd_data[3] <= ((cnt2 == 4'd4) & (cnt1 == {1'b0, baud_max_cnt[15:1]})) ? rxd_3d : rxd_data[3];
        rxd_data[4] <= ((cnt2 == 4'd5) & (cnt1 == {1'b0, baud_max_cnt[15:1]})) ? rxd_3d : rxd_data[4];
        rxd_data[5] <= ((cnt2 == 4'd6) & (cnt1 == {1'b0, baud_max_cnt[15:1]})) ? rxd_3d : rxd_data[5];
        rxd_data[6] <= ((cnt2 == 4'd7) & (cnt1 == {1'b0, baud_max_cnt[15:1]})) ? rxd_3d : rxd_data[6];
        rxd_data[7] <= ((cnt2 == 4'd8) & (cnt1 == {1'b0, baud_max_cnt[15:1]})) ? rxd_3d : rxd_data[7];
    end

// calculate partity bit & parity bit from rxd
wire cal_parity = rxd_data[0]^rxd_data[1]^rxd_data[2]^rxd_data[3]^rxd_data[4]^rxd_data[5]^rxd_data[6]^rxd_data[7];

reg cal_parity2;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        cal_parity2 <= 1'b0;
    else
        cal_parity2 <= (parity_sel == 2'b01) ? cal_parity : (parity_sel == 2'b10) ? ~cal_parity : 1'b0;

reg rxd_parity;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        rxd_parity <= 1'b0;
    else
        rxd_parity <= ((cnt2 == 4'd9) & (cnt1 == {1'b0, baud_max_cnt[15:1]})) ? rxd_3d : rxd_parity;

// stop bit 1
reg stop_bit1;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        stop_bit1 <= 1'b0;
    else
        stop_bit1 <= ((parity_sel == 2'b00) & (cnt2 == 4'd9)  & (cnt1 == {1'b0, baud_max_cnt[15:1]})) ? rxd_3d :
                     ((parity_sel != 2'b00) & (cnt2 == 4'd10) & (cnt1 == {1'b0, baud_max_cnt[15:1]})) ? rxd_3d : stop_bit1;

// stop bit 2
reg stop_bit2;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        stop_bit2 <= 1'b0;
    else
        stop_bit2 <= ((parity_sel == 2'b00) & (cnt2 == 4'd10) & (cnt1 == {1'b0, baud_max_cnt[15:1]})) ? rxd_3d :
                     ((parity_sel != 2'b00) & (cnt2 == 4'd11) & (cnt1 == {1'b0, baud_max_cnt[15:1]})) ? rxd_3d : stop_bit2;

// done state counter
reg [2:0] done_cnt;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        done_cnt <= 3'b0;
    else
        done_cnt <= (done_flag) ? done_cnt + 1'b1 : 3'b0;

// parity bit error
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        parity_err <= 1'b0;
    else
        parity_err <= (parity_sel == 2'b00) ? 1'b0 :
                      ((done_cnt == 3'd5) & (cal_parity2 == rxd_parity)) ? 1'b0 :
                      ((done_cnt == 3'd5) & (cal_parity2 != rxd_parity)) ? 1'b1 : parity_err;

// frame error
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        frame_err <= 1'b0;
    else
        frame_err <= ((done_cnt == 3'd5) & (stop_sel == 1'b0) & (stop_bit1 == 1'b0)) ? 1'b1 :
                     ((done_cnt == 3'd5) & (stop_sel == 1'b1) & (stop_bit1 == 1'b0 | stop_bit2 == 1'b0)) ? 1'b1 : frame_err;
    
// fifo ports
wire fifo_full;
assign full = fifo_full;

wire fifo_empty;
assign rd_valid = ~fifo_empty;

wire [7:0] fifo_din = rxd_data;
wire fifo_write_en = (done_cnt == 3'd2) ? 1'b1 : 1'b0;
wire fifo_read_en = read_en;
wire [7:0] fifo_dout;
assign rd_data = fifo_dout;

fifo_16x8 t0(
    .clk                (mclk           ),
    .srst               (1'b0           ),
    .din                (fifo_din       ),
    .wr_en              (fifo_write_en  ),
    .rd_en              (fifo_read_en   ),
    .dout               (fifo_dout      ),
    .full               (fifo_full      ),
    .empty              (fifo_empty     ),
    .valid              (               )
);

endmodule
