// traffic_tb.v - High-Speed System Testbench
`timescale 1ns/1ps

module traffic_tb;
    reg clk_50m = 0;
    reg rst_btn = 1;
    reg veh_ns_raw = 0;
    reg veh_ew_raw = 0;
    reg ped_btn_raw = 0;
    reg emergency_raw = 0;
    reg night_raw = 0;

    wire NS_G, NS_Y, NS_R;
    wire EW_G, EW_Y, EW_R;
    wire PED_WALK, PED_DONT;

    // Instantiate Device Under Test
    top DUT (
        .clk_50m(clk_50m), .rst_btn(rst_btn),
        .veh_ns_raw(veh_ns_raw), .veh_ew_raw(veh_ew_raw),
        .ped_btn_raw(ped_btn_raw), .emergency_raw(emergency_raw), .night_raw(night_raw),
        .NS_G(NS_G), .NS_Y(NS_Y), .NS_R(NS_R),
        .EW_G(EW_G), .EW_Y(EW_Y), .EW_R(EW_R),
        .PED_WALK(PED_WALK), .PED_DONT(PED_DONT)
    );

    // Clock generator: 20ns period
    always #10 clk_50m = ~clk_50m;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, traffic_tb);

        // System Reset
        #40 rst_btn = 0;

        // Sequence 1: Fast East-West Vehicle Trigger
        #100 veh_ew_raw = 1;
        #40  veh_ew_raw = 0;

        // Sequence 2: Fast Pedestrian Trigger
        #600 ped_btn_raw = 1;
        #40  ped_btn_raw = 0;

        // Sequence 3: Fast Emergency Override Trigger
        #600 emergency_raw = 1;
        #200 emergency_raw = 0;

        // End Simulation gracefully
        #400 $finish;
    end
endmodule