#!/bin/bash

#SBATCH --job-name=scatter_analysis

#SBATCH --error=error.txt

#SBATCH --time=01:00:00

#SBATCH --partition=THIN
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --cpus-per-task=1

module load openMPI/4.1.6/gnu/14.2.1

for warmup in 200 400; do

        for iter in 1000 5000; do

                analysis_results="benchmark_THIN_${warmup}w_${iter}i.txt"
                mpirun ./osu_scatter -x $warmup -i $iter -f > $analysis_results

        done
done
