#!/bin/bash

#SBATCH --job-name=scatter_algo_analysis_epyc

#SBATCH --error=error_epyc.txt

#SBATCH --time=01:00:00

#SBATCH --partition=EPYC
#SBATCH --nodes=1
# #SBATCH --nodelist=epyc001
#SBATCH --ntasks=128
#SBATCH --cpus-per-task=1

module load openMPI/4.1.6/gnu/14.2.1

analysis_results0="benchmark_0_EPYC.txt"
analysis_results1="benchmark_1_EPYC.txt"
analysis_results2="benchmark_2_EPYC.txt"

echo -e "Cores\tMessage Size\tAverage Latency (us)" > $analysis_results0
echo -e "Cores\tMessage Size\tAverage Latency (us)" > $analysis_results1
echo -e "Cores\tMessage Size\tAverage Latency (us)" > $analysis_results2

run_scatter() {
    local algorithm=$1
    local output_file=$2

    for ntasks in 2 8 16 24 32 40 48 56 64 72 80 88 96 104 112 120 128; do
	    echo "Running osu_scatter with algorithm $algorithm and ${ntasks} cores..."

	    result=$(mpirun -np ${ntasks} --map-by core --mca pml ucx --mca coll_tuned_use_dynamic_rules true --mca coll_tuned_scatter_algorithm $algorithm ./osu_scatter -x 400 -i 1000)

	    echo "$result" | awk -v cores=$ntasks 'NR > 2 {print cores "\t" $1 "\t" $2}' >> $output_file
    done
}

run_scatter 0 $analysis_results0
run_scatter 1 $analysis_results1
run_scatter 3 $analysis_results2

