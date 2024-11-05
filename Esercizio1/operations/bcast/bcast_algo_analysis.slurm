#!/bin/bash

#SBATCH --job-name=scatter_analysis

#SBATCH --error=error.txt

#SBATCH --time=01:00:00

#SBATCH --partition=EPYC
#SBATCH --nodes=1
#SBATCH --ntasks=128
#SBATCH --cpus-per-task=1

module load openMPI/4.1.6/gnu/14.2.1

for warmup in 200 400; do

        for iter in 1000 5000; do

                analysis_results1="benchmark_1_${warmup}w_${iter}i.txt"
                mpirun --mca coll_tuned_use_dynamic_rules true --mca coll_tuned_bcast_algorithm 2 ./osu_bcast -x $warmup -i $iter -f > $analysis_results1

		analysis_results2="benchmark_2_${warmup}w_${iter}i.txt"
		mpirun --mca coll_tuned_use_dynamic_rules true --mca coll_tuned_bcast_algorithm 5 ./osu_bcast -x $warmup -i $iter -f > $analysis_results2

        done
done
