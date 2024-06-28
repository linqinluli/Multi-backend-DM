#!/bin/bash

cd ~/Multi-backend-DM/code/eval/quicksort
make

pip install scikit-learn

cd ~/Multi-backend-DM/code/eval/stream
make