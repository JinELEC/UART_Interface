module tb_uart_rx;

reg              mclk, n_reset;
    wire     [15:0]  baud_max_cnt = 16'd10416; // baudrate = 9600
wire     [1:0]   parity_sel   = 2'b01;
wire             stop_sel     = 1'b1;
reg              read_en;
wire    [7:0]    tr_data      = 8'h55;
wire    [7:0]    rd_data;
wire             rd_valid;
wire             full;
wire             frame_err;
wire             parity_err;
wire             txd;
wire             rxd;
wire             done;

always #5 mclk = ~mclk;

initial begin
    n_reset = 0;
    mclk = 0;

#100 n_reset = 1;
end

reg [19:0] cnt;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        cnt <= 20'b0;
    else
        cnt <= cnt + 1'b1;

reg send_en;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        send_en <= 1'b0;
    else
        send_en <= (cnt == 20'd1000) ? 1'b1 : 1'b0;

always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        read_en <= 1'b0;
    else
        read_en <= (cnt == 20'd140000) ? 1'b1 : 1'b0;

assign rxd = txd;

uart_tx t0(
    .mclk               (mclk            ),
    .n_reset            (n_reset         ),
    .baud_max_cnt       (baud_max_cnt    ),
    .parity_sel         (parity_sel      ),
    .stop_sel           (stop_sel        ),
    .tr_data            (tr_data         ),
    .send_en            (send_en         ),
    .txd                (txd             ),
    .done               (done            )
);

uart_rx t1(
    .mclk               (mclk            ),
    .n_reset            (n_reset         ),
    .baud_max_cnt       (baud_max_cnt    ),
    .parity_sel         (parity_sel      ),
    .stop_sel           (stop_sel        ),
    .rd_data            (rd_data         ),
    .read_en            (read_en         ),
    .rd_valid           (rd_valid        ),
    .full               (full            ),
    .frame_err          (frame_err       ),
    .parity_err         (parity_err      ),
    .rxd                (rxd             )
);

endmodule
