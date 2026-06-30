module timer (
    input wire clk,
    input wire rst_n,
    input wire tick,
    input wire load_en,
    input wire [7:0] load_value,
    output reg done
);
    reg [7:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 8'h00;
            done  <= 1'b0;
        end else begin
            if (load_en) begin
                count <= load_value;
                done  <= (load_value == 0);
            end else if (tick && (count > 0)) begin
                count <= count - 1'b1;
                done  <= (count == 8'h01);
            end else if (count == 0) begin
                done  <= 1'b1;
            end
        end
    end
endmodule