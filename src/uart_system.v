module uart_system(
    input           clock,
    input           n_reset, 
    input   [3:0]   btn,
    input           sw,
    output          uart_txd,
    output  [7:0]   led
);

wire [3:0] btn_out_clear;

btn_in t0(
    .clock          (clock              ),
    .n_reset        (n_reset            ),
    .btn_in         (btn[0]             ),
    .btn_out        (btn_out_clear[0]   )
);

btn_in t1(
    .clock          (clock              ),
    .n_reset        (n_reset            ),
    .btn_in         (btn[1]             ),
    .btn_out        (btn_out_clear[1]   )
);

btn_in t2(
    .clock          (clock              ),
    .n_reset        (n_reset            ),
    .btn_in         (btn[2]             ),
    .btn_out        (btn_out_clear[2]   )
);

btn_in t3(
    .clock          (clock              ),
    .n_reset        (n_reset            ),
    .btn_in         (btn[3]             ),
    .btn_out        (btn_out_clear[3]   )
);

reg [7:0] tr_data;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        tr_data <= 8'b0;
    else
        tr_data <= (btn_out_clear[0]) ? 8'h41 :
                   (btn_out_clear[1]) ? 8'h42 :
                   (btn_out_clear[2]) ? 8'h43 :
                   (btn_out_clear[3]) ? 8'h44 : tr_data;

wire send_en = (btn_out_clear[0] | btn_out_clear[1] | btn_out_clear[2] | btn_out_clear[3]);

wire done;
wire [15:0] baud_max_cnt = 16'd10416;
wire [1:0]  pairty_sel   = 2'b01;
wire        stop_sel     = 1'b1;
wire txd;

wire rxd;
wire read_en = sw;
wire rd_valid;
wire full;
wire frame_err;
wire parity_err;

assign rxd = txd;

wire [7:0] rd_data;
assign led = rd_data;

uart_tx t4(
    .mclk               (clock              ),
    .n_reset            (n_reset            ),
    .baud_max_cnt       (baud_max_cnt       ),
    .parity_sel         (parity_sel         ),
    .stop_sel           (stop_sel           ),
    .tr_data            (tr_data            ),
    .send_en            (send_en            ),
    .txd                (txd                ),
    .done               (done               )
);

uart_rx t5(
    .mclk               (clock              ),
    .n_reset            (n_reset            ),
    .baud_max_cnt       (baud_max_cnt       ),
    .parity_sel         (parity_sel         ),
    .stop_sel           (stop_sel           ),
    .read_en            (read_en            ),
    .rd_data            (rd_data            ),
    .rd_valid           (rd_valid           ),
    .full               (full               ),
    .frame_err          (frame_err          ),
    .parity_err         (parity_err         ),
    .rxd                (rxd                )
);

ila_0 t6(
    .clk                (clock              ),
    .probe0             (read_en            ),
    .probe1             (rd_data            )
    );
    

endmodule
