module tb_uart_tx;
reg             mclk, n_reset;
reg     [15:0]  baud_max_cnt = 16'd10416;
reg     [7:0]   tr_data      = 8'h55;
reg     [1:0]   parity_sel   = 2'b01;
reg             stop_sel     = 1'b1;
reg             send_en;
wire            txd;
wire            done;

always #5 mclk = ~mclk;

initial begin
    n_reset = 0;
    mclk = 0;

#100 n_reset = 1;
end

reg [9:0] cnt;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        cnt <= 10'b0;
    else
        cnt <= (cnt == 10'd1023) ? 10'b0 : cnt + 1'b1;

// send_en
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        send_en <= 1'b0;
    else    
        send_en <= (cnt == 10'd1000) ? 1'b1 : 1'b0;

initial begin
    $dumpfile("tb_my_uart_tx.vcd");
    $dumpvars(0, tb_my_uart_tx);
    #2000000
    $finish;
end

uart_tx t0(
    .mclk               (mclk            ),
    .n_reset            (n_reset         ),
    .baud_max_cnt       (baud_max_cnt    ),
    .tr_data            (tr_data         ),
    .parity_sel         (parity_sel      ),
    .stop_sel           (stop_sel        ),
    .send_en            (send_en         ),
    .txd                (txd             ),
    .done               (done            )
);

endmodule
