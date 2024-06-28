#!/bin/bash

# Get the path parameter
path=$1

# Check if the path parameter is provided
if [ -z "$path" ]; then
    echo "Please provide a log file path"
    exit 1
fi

# Run benchmarks and redirect output
for bench in "linpack" "kmeans" "stream" "quicksort"
do
    for ratio in 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1
    do
        python benchmark.py $bench $ratio >> $path
    done
done
