# FIFO UVM Verification Project
![UVM Version](https://img.shields.io/badge/UVM-1.2-blue)
![Simulator](https://img.shields.io/badge/Simulator-Siemens%20Questa-green)
![Project Status](https://img.shields.io/badge/Status-Completed-brightgreen)

This is a complete standard **UVM 1.2** verification platform for a 16-depth, 8-bit synchronous FIFO design.

## 📂 Project Structure

## 🧱 UVM Architecture Layer
| Layer | Module Function |
|---|---|
| Item | Transaction data packet definition + read/write constraint |
| Sequence | 3 dedicated test stimulus sequences |
| Sequencer | Transaction transmission scheduler |
| Driver | Send valid signal stimulus to FIFO pins |
| Monitor | Sample interface signals and broadcast transactions |
| Agent | Unified container for driver + monitor + sequencer |
| Scoreboard | Automatic FIFO data order & value checker |
| Coverage | Functional coverage collection for all FIFO states |
| Env | Top-level integration container |
| Test | Test entry & sequence control |

## ✅ Implemented Functions
1. Basic synchronous FIFO full/empty flag logic verification
2. First-In First-Out data order correctness check
3. Automatic data pass/mismatch report
4. Constraint: forbid simultaneous read and write
5. Full functional coverage points + cross coverage
6. Waveform dumping for debug

## 🚀 How to Run Simulation
### EDA Playground Operation
1. Simulator choice: `Siemens Questa 2025`
2. Compile options input:
3. Tick `Open EPWave after run`
4. Click `Run` to start, view waveform after finish

## 📋 Test Cases
1. Write full FIFO test
2. Read empty FIFO test
3. Long time random read/write stress test
