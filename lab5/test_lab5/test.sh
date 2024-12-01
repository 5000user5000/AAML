#!/bin/bash

# Compile cfu.v
echo "Compiling cfu.v..."
iverilog -o cfu cfu.v
if [ $? -ne 0 ]; then
    echo "Error: Compilation of cfu.v failed."
    exit 1
fi

# Compile cfu_tb.v
echo "Compiling cfu_tb.v..."
iverilog -o cfu_tb cfu_tb.v
if [ $? -ne 0 ]; then
    echo "Error: Compilation of cfu_tb.v failed."
    exit 1
fi

# Run the simulation
echo "Running simulation..."
vvp cfu_tb
if [ $? -ne 0 ]; then
    echo "Error: Simulation failed."
    exit 1
fi

# Open the waveform in GTKWave
echo "Opening waveform in GTKWave..."
gtkwave cfu_tb.vcd &