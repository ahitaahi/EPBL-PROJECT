// top.v - Top-Level Structural Integration Wrapper
module top (
    input  wire clk_50m,       // 50 MHz board clock input
    input  wire rst_btn,       // Active-high physical reset button
    input  wire veh_ns_raw,    // North-South vehicle loop sensor input
    input  wire veh_ew_raw,    // East-West vehicle loop sensor input
    input  wire ped_btn_raw,   // Pedestrian call pushbutton input
    input  wire emergency_raw, // Emergency override switch input
    input  wire night_raw,     // Night blinking mode toggle switch
    output wire NS_G, NS_Y, NS_R, // North-South light cluster pins
    output wire EW_G, EW_Y, EW_R, // East-West light cluster pins
    output wire PED_WALK,      // Pedestrian walk green indicator pin
    output wire PED_DONT       // Pedestrian don't walk red indicator pin
);

    // Deriving an active-low synchronous system reset signal
    wire rst_n = ~rst_btn; 
    wire tick; 

    // Instantiate clock enable divider (Set TICK_HZ to 10 for structured timing windows)
    clk_en #(
      .CLK_HZ(100), 
        .TICK_HZ(10)
    ) u_tick (
        .clk(clk_50m), 
        .rst_n(rst_n), 
        .tick(tick)
    );

    // Intermediate wires for conditioned signals
    wire ped_pulse, ped_level, em_pulse, em_level;
    wire night_level, vns_level, vew_level;

    // Condition and debounce the Pedestrian input
    debounce_sync #(.TICKS(3)) u_ped (
        .clk(clk_50m), .rst_n(rst_n), .tick(tick),
        .async_in(ped_btn_raw), .pulse(ped_pulse), .level(ped_level)
    );

    // Condition and debounce the Emergency input
    debounce_sync #(.TICKS(1)) u_em (
        .clk(clk_50m), .rst_n(rst_n), .tick(tick),
        .async_in(emergency_raw), .pulse(em_pulse), .level(em_level)
    );

    // Condition and debounce the Night Mode input
    debounce_sync #(.TICKS(1)) u_ng (
        .clk(clk_50m), .rst_n(rst_n), .tick(tick),
        .async_in(night_raw), .pulse(), .level(night_level)
    );

    // Condition and debounce the North-South Vehicle sensor input
    debounce_sync #(.TICKS(1)) u_vns (
        .clk(clk_50m), .rst_n(rst_n), .tick(tick),
        .async_in(veh_ns_raw), .pulse(), .level(vns_level)
    );

    // Condition and debounce the East-West Vehicle sensor input
    debounce_sync #(.TICKS(1)) u_vew (
        .clk(clk_50m), .rst_n(rst_n), .tick(tick),
        .async_in(veh_ew_raw), .pulse(), .level(vew_level)
    );

    // Instantiate the primary traffic controller FSM engine
    traffic_fsm #(
        .MAIN_IS_NS(1), 
        .TICK_HZ(10)
    ) u_fsm (
        .clk(clk_50m), .rst_n(rst_n), .tick(tick),
        .veh_ns(vns_level), .veh_ew(vew_level), .ped_pulse(ped_pulse),
        .emergency(em_level), .night_mode(night_level),
        .ns_g(NS_G), .ns_y(NS_Y), .ns_r(NS_R),
        .ew_g(EW_G), .ew_y(EW_Y), .ew_r(EW_R),
        .ped_walk(PED_WALK), .ped_dontwalk(PED_DONT)
    );

endmodule