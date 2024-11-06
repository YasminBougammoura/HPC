#!/bin/bash

#SBATCH --job-name=bcast_algo_analysis

#SBATCH --error=error.txt

#SBATCH --time=01:00:00

#SBATCH --partition=THIN
#SBATCH --nodes=1
#SBATCH --nodelist=thin010
#SBATCH --ntasks=24
#SBATCH --cpus-per-task=1

module load openMPI/4.1.6/gnu/14.2.1

analysis_results0="benchmark_0_THIN.txt"
analysis_results1="benchmark_1_THIN.txt"
analysis_results2="benchmark_2_THIN.txt"

echo -e "Cores\tMessage Size\tAverage Latency (us)" > $output_file0
echo -e "Cores\tMessage Size\tAverage Latency (us)" > $output_file1
echo -e "Cores\tMessage Size\tAverage Latency (us)" > $output_file2

run_bcast() {
    local algorithm=$1
    local output_file=$2

    for ntasks in 1 2 4 6 8 10 12 14 16 18 20 22 24; do
            echo "Running osu_bcast with algorithm $algorithm and ${ntasks} cores..."

            result=$(mpirun -np ${ntasks} --map-by core --mca pml ucx --mca coll_tuned_use_dynamic_rules true --mca coll_tuned_bcast_algorithm $algorithm ./osu_bcast -x 200 -i 1000)

            echo "$result" | awk -v cores=$ntasks 'NR > 2 {print cores "\t" $1 "\t" $2}' >> $output_file
    done
}

run_bcast 0 $output_file0
run_bcast 2 $output_file1
run_bcast 5 $output_file2
