#!/bin/bash

#SBATCH --job-name=MPI_scaling_job

#SBATCH --output=output_mpi.log
#SBATCH --error=error_mpi.txt

#SBATCH --time=01:00:00

#SBATCH --nodes=1
#SBATCH --partition=THIN
##SBATCH -w fat/thinxyz

#SBATCH --ntasks=24
#SBATCH --cpus-per-task=1

module load openMPI/4.1.6/gnu/14.2.1

mpicc -fopenmp MPI_scaling1.c -o MPI_scaling -lm -march=native

export OMP_NUM_THREADS=1

for tasks in 1 2 4 6 8 10 12 14 16 18 20 22 24; do

	echo "Running with $tasks MPI tasks..."
	mpirun -np $tasks ./MPI_scaling 512 512 -2 -1.5 1 1.5 1024

done
