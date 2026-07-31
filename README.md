# Game-Of-Life-VHDL

This repository contains a VHDL-based implementation of Conway's Game of Life and is intended to be developed using Xilinx Vivado.

The goal of this README is to provide a straightforward and repeatable workflow for editing, simulating, synthesizing, and programming the design.

## Project overview

This project is organized as a small FPGA-oriented VHDL design with:

- source files in the src directory
- simulation files in the sim directory
- board constraints in the constraints directory
- a Vivado project already scaffolded under vivado-project

## Repository structure

- src/: VHDL source files for the hardware design
- sim/: test benches and simulation-related files
- constraints/: FPGA pin assignments and timing constraints
- vivado-project/: Vivado project files and generated workspace data
- docs/: design notes and documentation
- scripts/: helper scripts for automation or local workflows

## Prerequisites

Before starting development, make sure the following are installed:

- Xilinx Vivado (recommended: 2023.x or newer)
- Git
- A compatible FPGA board support package if you plan to target hardware

Optional tools:

- GTKWave or another VHDL waveform viewer
- A text editor or VS Code with VHDL support

## Getting started

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd game-of-life-vhdl
   ```

2. Open the Vivado project:
   - Launch Vivado
   - Open the project file at vivado-project/vivado-project.xpr

3. Review the project hierarchy:
   - Add or modify source files in src/
   - Keep board-specific constraints in constraints/
   - Place simulation test benches in sim/

## Recommended development workflow

### 1. Edit the design

- Keep VHDL code modular and well-commented.
- Prefer clear entity and architecture names.
- Use consistent style for ports, signals, and indentation.
- Avoid mixing unrelated logic in a single file.

### 2. Simulate before synthesis

Before synthesizing the design, run a simulation to verify behavior:

- Create or update a test bench in sim/
- Add stimulus for the design under test
- Run behavioral simulation in Vivado
- Inspect waveforms and fix issues before moving forward

### 3. Synthesize and implement

Once simulation is passing:

- Synthesize the design
- Run implementation
- Review timing and resource reports

### 4. Program the board

If you are targeting hardware:

- Generate a bitstream
- Program the FPGA from Vivado
- Verify the behavior on the physical board

## Contribution guidelines

To keep the repository healthy and easy to work with:

- Commit small, focused changes
- Write clear commit messages
- Keep test benches updated when the design changes
- Document significant architectural decisions in docs/
- Avoid committing generated artifacts unless necessary

## Naming and organization conventions

- Use descriptive names for entities, architectures, signals, and ports
- Place reusable logic in dedicated VHDL files rather than embedding it inline
- Keep constraints board-specific and separate from source logic
- Use the Vivado project as the main entry point for builds and simulation

## Notes for this repository

This repository currently contains a basic scaffold for the VHDL project. As development progresses, the following should be maintained:

- source files in src/
- simulation benches in sim/
- constraint updates in constraints/
- project consistency in vivado-project/

## Troubleshooting

If you encounter issues:

- Confirm that the correct Vivado version is installed
- Check that the project file points to the correct source files
- Make sure the board constraint file matches the target FPGA board
- Re-run simulation before attempting synthesis if behavior changed
