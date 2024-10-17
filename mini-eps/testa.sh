#!/bin/bash

# Initialize arrays to hold the runtimes
leap_times=()
leapfrog_times=()

# Run leap 20 times
for i in {1..100}; do
  start=$(date +%s.%N)
  ./leap
  end=$(date +%s.%N)
  runtime=$(echo "$end - $start" | bc)
  leap_times+=($runtime)
done

# Run leapfrog.py 20 times
for i in {1..100}; do
  start=$(date +%s.%N)
  python3 leapfrog.py
  end=$(date +%s.%N)
  runtime=$(echo "$end - $start" | bc)
  leapfrog_times+=($runtime)
done

# Function to calculate average
calc_avg() {
  local arr=("$@")
  total=0
  for time in "${arr[@]}"; do
    total=$(echo "$total + $time" | bc)
  done
  avg=$(echo "scale=6; $total / ${#arr[@]}" | bc)
  echo $avg
}

# Function to calculate standard deviation
calc_stddev() {
  local arr=("$@")
  avg=$(calc_avg "${arr[@]}")
  sum_sq_diff=0
  for time in "${arr[@]}"; do
    diff=$(echo "$time - $avg" | bc)
    sq_diff=$(echo "$diff * $diff" | bc)
    sum_sq_diff=$(echo "$sum_sq_diff + $sq_diff" | bc)
  done
  variance=$(echo "scale=6; $sum_sq_diff / ${#arr[@]}" | bc)
  stddev=$(echo "scale=6; sqrt($variance)" | bc)
  echo $stddev
}

# Calculate average and standard deviation for leap
leap_avg=$(calc_avg "${leap_times[@]}")
leap_stddev=$(calc_stddev "${leap_times[@]}")

# Calculate average and standard deviation for leapfrog.py
leapfrog_avg=$(calc_avg "${leapfrog_times[@]}")
leapfrog_stddev=$(calc_stddev "${leapfrog_times[@]}")

# Output the results
echo "13831609
      c++, 100, $leap_avg, $leap_stddev
      python, 100, $leapfrog_avg, $leapfrog_stddev" >> analise.txt

