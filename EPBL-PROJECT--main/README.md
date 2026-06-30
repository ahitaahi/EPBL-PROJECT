# FPGA-Based Parameterizable Traffic Light Controller

## 📌 Project Overview
This repository contains an industry-oriented, fully synthesizable **FPGA-Based Traffic Light Controller (TLC)** project implemented in Verilog HDL. The system is designed using a robust synchronous architecture to regulate a 4-way intersection while processing real-world inputs: vehicle presence loop sensors, pedestrian crosswalk requests, emergency vehicle overrides, and low-visibility night blinking modes.

To prevent clock skew and domain crossing hazards, the entire design operates within a **single global clock domain** driven by an energy-efficient clock-enable tick structure.

---

## 🛠️ Key Hardware Features
* **Synchronous Clock-Enable Distribution**: Eliminates internal sub-derived clock networks by driving all system registers directly via the global 50 MHz line using structural 10 Hz enable strobes.
* **Metastability Mitigation**: External asynchronous inputs pass through a dual-stage register pipeline to decouple system logic from setup/hold timing violations.
* **Digital Counter Debouncing**: Integrates a structural filtering counter window to neutralize noise glitches from external push-buttons.
* **Emergency Vehicle Preemption**: Real-time asynchronous override immediately forces an all-red safety isolation phase across both traffic vectors until the override clears.
* **Low-Visibility Night Mode**: System safely drops into a low-power degraded state featuring blinking yellow indicators for the main arterial road and blinking red for cross streets.

---

## 📐 Hardware Architecture Block Diagram

```text
Clock Input (50MHz) ──► [ clk_en ] ──► 10Hz Tick Strobe ──┐
                                                           ▼
Asynchronous Inputs ──► [ debounce_sync ] ──► [ Core traffic_fsm Module ] ──► System Output Status
  - Vehicle Loop Sensors                                  │                      - Intersection Signal Clusters
  - Pedestrian Pushbuttons                                └──► [ timer ]         - Crosswalk Pedestrian Indicators
  - Emergency Override Switches
```

---

## 🚦 Moore Finite State Machine Diagram
The system uses a strictly deterministic **10-state Moore FSM Architecture** where outputs are safely derived directly from registered state definitions to completely avoid combinational output glitches:

```text
       ┌───────────► [ S_NS_G ] ────────────┐
       │               │ (Side road demand) │
       │               ▼                    │
       │             [ S_NS_Y ]             │
       │               │                    │
       │               ▼                    │
       │            [ S_ALL_RED1 ]          │
       │               │                    │
       │       ┌───────┴───────┐            │  (Emergency Switch Triggered)
       │       ▼ (Ped Latch)   ▼ (No Ped)   ├───► [ S_EMERGENCY ] ──► Forces All-Red Safe Mode
       │  [ S_PED_WALK ]     [ S_EW_G ]     │
       │       │               │            │  (Night Mode Switch Triggered)
       │       ▼               ▼ (NS Demand)├───► [ S_NIGHT ] ──► Blinking Yellow/Red Mode
       │  [ S_PED_FLASH ]    [ S_EW_Y ]     │
       │       │               │            │
       │       └───────┬───────┘            │
       │               ▼                    │
       │            [ S_ALL_RED2 ] ─────────┘
       └───────────────┘
```

---

## 💻 Simulation & Verification Proof

### 1. Clean Compilation & Runtime Logs
The complete system compiles with zero errors or warnings under the `Icarus Verilog 12.0` simulation engine environment:

![Simulation Run Log](images/simulation_run_log.png)

### 2. Time-Domain Waveform Trace
Functional behavioral verification confirming safe timing loops, pedestrian crosswalk latch sequencing, and priority emergency overrides:

![Verification Waveforms](images/waveform_proof.png)

---

## 📂 System Directory Structure
This repository perfectly aligns with industrial structural layouts for RTL design projects:
```text
FPGA-Traffic-Light-Controller/
├── rtl/
│   ├── params.vh          # System configuration timing macros
│   ├── clk_en.v           # Global synchronous clock enable scaler
│   ├── debounce_sync.v    # 2-stage synchronizer + digital logic filter
│   ├── timer.v            # Programmable down-counter tracker
│   ├── traffic_fsm.v      # Core Moore FSM sequencing engine
│   └── top.v              # Unified top-level layout wrapper mesh
├── tb/
│   └── traffic_tb.v       # Self-checking design testbench vector suite
├── constraints/
│   └── nexys_a7_pins.xdc  # Physical Xilinx Artix-7 target FPGA mapping
└── images/
    ├── simulation_run_log.png
    └── waveform_proof.png
```

---

## 🚀 Step-by-Step Local Simulation Guide
To execute behavioral simulations locally using open-source tools:

1. Clone this repository structure:
   ```bash
   git clone https://github.com
   cd fpga-traffic-light-controller
   ```
2. Compile design modules and testbench source blocks:
   ```bash
   iverilog -g2012 -o traffic_netlist.out rtl/*.v tb/traffic_tb.v
   ```
3. Run the compiled test program:
   ```bash
   vvp traffic_netlist.out
   ```
4. Open the generated file in GTKWave to view the timing waveforms:
   ```bash
   gtkwave dump.vcd
   ```
