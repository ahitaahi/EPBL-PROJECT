module debounce_sync #(
    parameter integer TICKS = 3  // Filter window size 
)(
    input wire clk,
    input wire rst_n,
    input wire tick,
    input wire async_in,
    output reg pulse,
    output reg level
);
    // Two-stage synchronizer chain to neutralize metastability
    reg sync_0, sync_1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= async_in;
            sync_1 <= sync_0;
        end
    end

    // Counter-based filter logic
    reg [2:0] debounce_cnt;
    reg prev_level;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_cnt <= 0;
            level        <= 1'b0;
            prev_level   <= 1'b0;
            pulse        <= 1'b0;
        end else begin
            pulse <= 1'b0;
            if (tick) begin
                if (sync_1 == level) begin
                    debounce_cnt <= 0;
                end else begin
                    if (debounce_cnt == TICKS - 1) begin
                        debounce_cnt <= 0;
                        level        <= sync_1;
                        prev_level   <= level;
                        if (sync_1 && !level) begin
                            pulse <= 1'b1; // Edge trigger indicator pulse
                        end
                    end else begin
                        debounce_cnt <= debounce_cnt + 1'b1;
                    end
                end
            end
        end
    end
endmodule