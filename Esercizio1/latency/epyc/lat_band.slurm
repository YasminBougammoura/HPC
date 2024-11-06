#!/bin/bash

#SBATCH --job-name=latency
#SBATCH --time=02:00:00

#SBATCH --error=error.txt
#SBATCH --output=output.txt

#SBATCH -p EPYC
#SBATCH --nodes=1
#SBATCH --ntasks=60

echo "Running on node: $SLURMD_NODENAME"

module load openMPI/4.1.6/gnu/14.2.1

OUTPUT_DIR="epyc_benchmark"
mkdir -p $OUTPUT_DIR

run_benchmark(){
	local core1=$1
	local core2=$2
	local output_file="$OUTPUT_DIR/core_${core1}_${core2}.csv"

	echo "Message_size,Avg_latency,Bandwidth" > "$output_file"

	mpirun -np 2 --mca pml ucx --cpu-list $core1,$core2 ./osu_latency > lat.txt
	mpirun -np 2 --mca pml ucx --cpu-list $core1,$core2 ./osu_bw > bw.txt

	paste <(awk 'NR>3 {print $1, $2}' lat.txt) <(awk 'NR>3 {print $2}' bw.txt) | awk '{print $1 "," $2 "," $3}' >> "$output_file"

	rm -f lat.txt bw.txt
}

NUM_CORES=60

for ((i=1; i<$NUM_CORES; i+=10)); do
	for ((j=i+1; j<$NUM_CORES; j+=10)); do
		run_benchmark $i $j
	done
done
