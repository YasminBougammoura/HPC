for warmup in 100 200 300; do
	for iter in 500 1000 1500 2000; do
		analysis_results="benchmark_${warmup}w_${iter}i.txt"
		mpirun osu_scatter -x $warmup -i $iter -f > $analysis_results
	done
done
