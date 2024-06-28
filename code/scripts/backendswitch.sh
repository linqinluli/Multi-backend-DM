#!/bin/bash

# Receive text parameters
backend=$1
swap_size=$2
swap_file=$3
sport=$2
farmemip=$3
clientip=$4

# Use lsmod to check currently installed modules
modules=$(lsmod)

# Unload fastswap_rdma and fastswap
if echo "$modules" | grep -q "fastswap_rdma"; then
    sudo rmmod fastswap_rdma
    sudo rmmod fastswap
fi

# Unload fastswap_dram and fastswap
if echo "$modules" | grep -q "fastswap_dram"; then
    sudo rmmod fastswap_dram
    sudo rmmod fastswap
fi

# Check if swap is enabled
swap_on=$(swapon --show)
if [ -z "$swap_on" ]; then
    if [ -z "$swap_size" ] || [ -z "$swap_file" ]; then
        echo "Please provide swap size and swap file location"
        exit 1
    fi

    # Create the specified size swap space
    sudo fallocate -l "$swap_size" "$swap_file"
    sudo chmod 600 "$swap_file"
    sudo mkswap "$swap_file"
    sudo swapon "$swap_file"
    echo "$swap_file none swap sw 0 0" | sudo tee -a /etc/fstab
fi

# Determine the input parameter and execute corresponding actions
case "$backend" in
    "rdma")
        if [ -z "$sport" ] || [ -z "$farmemip" ] || [ -z "$clientip" ]; then
            echo "Please provide sport, farmemip, and clientip"
            exit 1
        fi
        
        sudo insmod fastswap_rdma.ko sport="$sport" sip="$farmemip" cip="$clientip" nq=8
        sudo insmod fastswap.ko
        ;;
    "dram")
        cd drivers
        make BACKEND=DRAM
        sudo insmod fastswap_dram.ko $swap_size
        sudo insmod fastswap.ko
        ;;
    *)
        echo "Invalid parameter, please enter rdma or dram"
        exit 1
        ;;
esac

echo "Operation completed"
