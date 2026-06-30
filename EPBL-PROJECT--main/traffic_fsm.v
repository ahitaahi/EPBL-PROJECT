module traffic_fsm #(
    parameter integer MAIN_IS_NS = 1,
    parameter integer TICK_HZ = 10
)(
    input wire clk,
    input wire rst_n,
    input wire tick,
    input wire veh_ns,
    input wire veh_ew,
    input wire ped_pulse,
    input wire emergency,
    input wire night_mode,
    output reg ns_g, ns_y, ns_r,
    output reg ew_g, ew_y, ew_r,
    output reg ped_walk,
    output reg ped_dontwalk
);
    // 10 State Encoding Configuration Matrix
    localparam [3:0]
        S_NS_G      = 4'b0000, S_NS_Y      = 4'b0001,
        S_ALL_RED1  = 4'b0010, S_EW_G      = 4'b0011,
        S_EW_Y      = 4'b0100, S_ALL_RED2  = 4'b0101,
        S_PED_WALK  = 4'b0110, S_PED_FLASH = 4'b0111,
        S_EMERGENCY = 4'b1000, S_NIGHT     = 4'b1001;

    reg [3:0] current_state, next_state;
    reg ped_latch;
    
    // Timer Interface Wires
    reg timer_load;
    reg [7:0] timer_val;
    wire timer_done;

    // Local timing configurations calculated based on Tick frequency
    wire [7:0] t_green_min = 8'd12 * TICK_HZ;
    wire [7:0] t_yellow    = 8'd3  * TICK_HZ;
    wire [7:0] t_allred    = 8'd1  * TICK_HZ;
    wire [7:0] t_walk      = 8'd8  * TICK_HZ;
    wire [7:0] t_flash     = 8'd4  * TICK_HZ;

    // Instantiate Internal Timer
    timer u_fsm_timer (
        .clk(clk), .rst_n(rst_n), .tick(tick),
        .load_en(timer_load), .load_value(timer_val), .done(timer_done)
    );

    // Pedestrian Request Capture Latch
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            ped_latch <= 1'b0;
        else if (ped_pulse) 
            ped_latch <= 1'b1;
        else if (current_state == S_PED_WALK) 
            ped_latch <= 1'b0;
    end

    // FSM State Transition Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= S_NS_G;
        else        current_state <= next_state;
    end

    // Next State Combinational Logic
    always @(*) begin
        next_state = current_state;
        timer_load = 1'b0;
        timer_val  = 8'h00;

        if (emergency) begin
            next_state = S_EMERGENCY;
        end else if (night_mode && current_state != S_EMERGENCY) begin
            next_state = S_NIGHT;
        end else begin
            case (current_state)
                S_NS_G: begin
                    if (timer_done && (veh_ew || ped_latch)) begin
                        next_state = S_NS_Y;
                        timer_load = 1'b1;
                        timer_val  = t_yellow;
                    end
                end
                S_NS_Y: begin
                    if (timer_done) begin
                        next_state = S_ALL_RED1;
                        timer_load = 1'b1;
                        timer_val  = t_allred;
                    end
                end
                S_ALL_RED1: begin
                    if (timer_done) begin
                        if (ped_latch) begin
                            next_state = S_PED_WALK;
                            timer_load = 1'b1;
                            timer_val  = t_walk;
                        end else begin
                            next_state = S_EW_G;
                            timer_load = 1'b1;
                            timer_val  = t_green_min;
                        end
                    end
                end
                S_EW_G: begin
                    if (timer_done && (veh_ns || ped_latch)) begin
                        next_state = S_EW_Y;
                        timer_load = 1'b1;
                        timer_val  = t_yellow;
                    end
                end
                S_EW_Y: begin
                    if (timer_done) begin
                        next_state = S_ALL_RED2;
                        timer_load = 1'b1;
                        timer_val  = t_allred;
                    end
                end
                S_ALL_RED2: begin
                    if (timer_done) begin
                        next_state = S_NS_G;
                        timer_load = 1'b1;
                        timer_val  = t_green_min;
                    end
                end
                S_PED_WALK: begin
                    if (timer_done) begin
                        next_state = S_PED_FLASH;
                        timer_load = 1'b1;
                        timer_val  = t_flash;
                    end
                end
                S_PED_FLASH: begin
                    if (timer_done) begin
                        next_state = S_EW_G;
                        timer_load = 1'b1;
                        timer_val  = t_green_min;
                    end
                end
                S_EMERGENCY: begin
                    if (!emergency) begin
                        next_state = S_ALL_RED1;
                        timer_load = 1'b1;
                        timer_val  = t_allred;
                    end
                end
                S_NIGHT: begin
                    if (!night_mode) begin
                        next_state = S_ALL_RED1;
                        timer_load = 1'b1;
                        timer_val  = t_allred;
                    end
                end
                default: next_state = S_NS_G;
            endcase
        end
    end

    // Clock-driven Output Logic
    reg flash_reg = 0;
    always @(posedge clk) begin
        if (tick) flash_reg <= ~flash_reg;
    end

    always @(*) begin
        // Safe Default Assertions
        ns_g = 0; ns_y = 0; ns_r = 1;
        ew_g = 0; ew_y = 0; ew_r = 1;
        ped_walk = 0; ped_dontwalk = 1;

        case (current_state)
            S_NS_G: begin ns_g = 1; ns_r = 0; end
            S_NS_Y: begin ns_y = 1; ns_r = 0; end
            S_ALL_RED1, S_ALL_RED2: begin /* All Red Lights Active */ end
            S_EW_G: begin ew_g = 1; ew_r = 0; end
            S_EW_Y: begin ew_y = 1; ew_r = 0; end
            S_PED_WALK: begin ped_walk = 1; ped_dontwalk = 0; end
            S_PED_FLASH: begin ped_walk = flash_reg; ped_dontwalk = !flash_reg; end
            S_EMERGENCY: begin /* All Red Lights Active */ end
            S_NIGHT: begin
                ns_y = flash_reg; ns_r = 0;
                ew_r = flash_reg;
            end
        endcase
    end
endmodule