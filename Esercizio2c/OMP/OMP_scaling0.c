#include <stdio.h>
#include <stdlib.h>
#include <complex.h>
#include <time.h>
#include <mpi.h>
#include <omp.h>

// Function that writes the image xsize*ysize with a color depth depending on the value of I_max
void write_pgm_image(void *image, int maxval, int xsize, int ysize, const char *image_name){
    
    FILE* image_file = fopen(image_name, "w");
    
    int color_depth = (maxval < 256) ? sizeof(char) : sizeof(short int);
    
    fprintf(image_file, "P5\n #generated by\n #Yasmin \n%d %d\n%d\n", xsize, ysize, maxval);
    
    fwrite(image, color_depth, xsize * ysize, image_file);
    
    fclose(image_file);

    return ;
}

// Function computing the Mandelbrot set
int mandelbrot(double complex c, int max_iter){
    
    double complex z = 0 + 0 * I;
    int n = 0;

    while (n <= max_iter && cabs(z) < 2){
        
        z = z * z + c;
        n++;
    
    }
    
    return (cabs(z) >= 2) ? n : 0;
}

// Function that assigns a specific value for each pixel according to the Mandelbrot function output
void *generate_gradient(int xsize, int ysize, int start_row, int end_row, double complex c_L, double complex c_R, int max_iter){
    
    size_t image_size = (max_iter < 256) ? sizeof(char) : sizeof(short int);
    void *Image = malloc((end_row - start_row) * xsize * image_size);
    
    const double x_l = creal(c_L), x_r = creal(c_R);
    const double y_l = cimag(c_L), y_r = cimag(c_R);
    
    const double register delta_x = (x_r - x_l) / xsize;
    const double register delta_y = (y_r - y_l) / ysize;

    int yy, xx;

    #pragma omp parallel for schedule(dynamic) shared(Image) private(yy,xx)
    for (int yy = start_row; yy < end_row; yy++){

        double imag = y_l + yy * delta_y;
        
        for (int xx = 0; xx < xsize; xx++){
            
            double real = x_l + xx * delta_x;
            
            double complex c = real + imag * I;
            
            int iter = mandelbrot(c, max_iter);

            int idx = (yy - start_row)* xsize + xx;
            
            if (max_iter < 256){
                ((char*)Image)[idx] = (char)(iter);
            } else {
                ((short int*)Image)[idx] = (short int)(iter);
            }
        }       
    }
    return Image;
}

//mpicc -fopenmp OMP_scaling0.c -o OMP_scaling0 -lm -O3
//mpirun -np 1 ./OMP_scaling0 512 512 -2 -1.5 1.0 1.5 1024

int main(int argc, char **argv){
    
    // Hybrid code initialization
    int mpi_provided_thread_level; 
    MPI_Init_thread( &argc, &argv, MPI_THREAD_FUNNELED, &mpi_provided_thread_level); 
    if ( mpi_provided_thread_level < MPI_THREAD_FUNNELED ) { 
        printf("a problem arise when asking for MPI_THREAD_FUNNELED level\n"); 
        MPI_Finalize(); 
        exit( 1 ); 
    }    

    // Definition of the communicator group for MPI 
    int size, rank;
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    // Input arguments reading
    double real_xl = atof(argv[3]);
    double real_yl = atof(argv[4]);
    double real_xr = atof(argv[5]);
    double real_yr = atof(argv[6]);

    const int xsize = atoi(argv[1]);
    const int ysize = atoi(argv[2]);
    
    const int max_iter = atoi(argv[7]);

    const double complex c_L = real_xl + (real_yl * I);
    const double complex c_R = real_xr + (real_yr * I);
    
    FILE *time_results_OMP = NULL;
    if (rank == 0) time_results_OMP = fopen("OMP_scaling0.csv", "w");

    for (int threads = 1; threads <= 12; threads++) {

        clock_t start_time;
        if (rank == 0) {

            start_time = clock();
            omp_set_num_threads(threads);
        
        }

        // Each process calculates the number of rows it will handle
        const int rows_per_P = ysize / size;
        int rem = ysize % size;
        int start_row = rank * rows_per_P + ((rank < rem) ? rank : rem);
        int end_row = start_row + rows_per_P + (rank < rem ? 1 : 0);

        // Each process computes its portion of the image
        void *local_image = generate_gradient(xsize, ysize, start_row, end_row, c_L, c_R, max_iter);

        // Rank 0 will gather local images of other ranks
        void *final_image = NULL;
        if (rank == 0) {
            final_image = malloc(xsize * ysize * ((max_iter < 256) ? sizeof(char) : sizeof(short int)));
        }

        // Gather results from all processes
        MPI_Gather(local_image, (end_row - start_row) * xsize * ((max_iter < 256) ? sizeof(char) : sizeof(short int)), MPI_BYTE, 
               final_image, (end_row - start_row) * xsize * ((max_iter < 256) ? sizeof(char) : sizeof(short int)), MPI_BYTE, 
               0, MPI_COMM_WORLD);
        
        free(local_image);

        // Rank 0 process writes the final image to a file
        if (rank == 0){
        
            write_pgm_image(final_image, max_iter, xsize, ysize, "mandelbrot.pgm"); //if threads
            free(final_image); // Free final image memory

            clock_t end_time = clock();
            double elapsed_time = (double)(end_time - start_time) / CLOCKS_PER_SEC;

            fprintf(time_results_OMP, "%d, %.6f\n", threads, elapsed_time);
            
        }

    }


    if (rank == 0) fclose(time_results_OMP);

    printf("Image created...\n");

    MPI_Finalize();
    return 0;
}