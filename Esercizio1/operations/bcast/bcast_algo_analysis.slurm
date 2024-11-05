#!/bin/bash

#SBATCH --job-name=scatter_analysis

#SBATCH --error=error.txt

#SBATCH --time=01:00:00

#SBATCH --partition=THIN
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --cpus-per-task=1

module load openMPI/4.1.6/gnu/14.2.1

analysis_results1="benchmark_1_THIN.txt"
mpirun --mca coll_tuned_use_dynamic_rules true --mca coll_tuned_bcast_algorithm 2 ./osu_bcast -x 200 -i 5000 -f > $analysis_results1

analysis_results2="benchmark_2_THIN.txt"
mpirun --mca coll_tuned_use_dynamic_rules true --mca coll_tuned_bcast_algorithm 5 ./osu_bcast -x 200 -i 5000 -f > $analysis_results2

