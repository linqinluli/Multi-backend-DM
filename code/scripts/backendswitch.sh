#!/bin/bash

# Record start time
start_time=$(date +%s.%N)

backend="$1"
path="$2"
sport="$3"
farmemip="$2"
clientip="$4"

# Use lsmod to check currently installed modules
modules=$(lsmod)

# Unload fastswap_rdma and fastswap
if echo "$modules" | grep -q "fastswap_rdma"; then
    sudo rmmod fastswap
    sudo rmmod fastswap_rdma
fi

# Unload fastswap_dram and fastswap
if echo "$modules" | grep -q "fastswap_dram"; then
    sudo rmmod fastswap
    sudo rmmod fastswap_dram
fi

# Handle different backends
case "$backend" in
    ssd)
        # Turn off current system swap
        sudo swapoff -a

        # Create a 32GB swap file at the specified path
        sudo dd if=/dev/zero of="$path" bs=1M count=32768

        # Use the file to create swap
        start_time=$(date +%s.%N)
        sudo mkswap "$path"
        sudo swapon "$path"
        ;;
    dram)
        cd ~/Multi-backend-DM/code/drivers
        # Change to drivers directory and compile
        start_time=$(date +%s.%N)
        

        sudo insmod fastswap_dram.ko
        sudo insmod fastswap.ko
        ;;
    rdma)
        cd ~/Multi-backend-DM/code/drivers
        start_time=$(date +%s.%N)
        # Load rdma module with specified parameters
        sudo insmod fastswap_rdma.ko sport="$sport" sip="$farmemip" cip="$clientip"
        sudo insmod fastswap.ko
        ;;
    *)
        echo "Unknown backend parameter: $backend"
        exit 1
        ;;
esac

# Record end time
end_time=$(date +%s.%N)

# Calculate script runtime, precise to milliseconds
runtime=$(echo "scale=3; $end_time - $start_time" | bc)

echo "Script runtime: ${runtime} seconds"
