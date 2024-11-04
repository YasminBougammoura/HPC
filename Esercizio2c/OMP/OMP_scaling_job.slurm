#!/bin/bash

#SBATCH --job-name=OMP_scaling_job

#SBATCH --output=output.txt
#SBATCH --error=error.txt

#SBATCH --nodes=1
#SBATCH --partition=THIN
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24

#SBATCH --time=00:30:00

module load openMPI/4.1.6/gnu/14.2.1

mpicc -fopenmp OMP_scaling2.c -o OMP_scaling -lm -march=native

for threads in $(seq 1 $SLURM_CPUS_PER_TASK); do
	
	echo "Running with $threads threads..."
	
	export OMP_NUM_THREADS=$threads

	mpirun -np 1 ./OMP_scaling 512 512 -2 -1.5 1.0 1.5 1024

done
