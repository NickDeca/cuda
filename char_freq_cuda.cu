#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <cuda.h>
#include "cuda_runtime.h"
#include <cuda_runtime_api.h>
#include "device_launch_parameters.h"

#define N 128
#define base 0
//sto visual studio ta kanw define otan ta kanw compile ta dinw orismata
//#define block_count 100;
//#define thread_count 100;

//!!!! logo provlhmatwn to programma douleuei mono me block * thread >= apo auto pou upologizei
//giati se ka8e thread dinei 1 i tou loop pou kanei parallhla

__global__ void parallelf(char *buffer,int *freq, long file_size) {

	int index = blockIdx.x * blockDim.x + threadIdx.x;
	
	
    /*epeidh egrafa se visual studio kai eixe kapoio provlhma me pathing den katafera na 
	testarw to 
	for (int i = index; i < file_size;i= i + blockDim.x * gridDim.x); anti gia to if
	pou 8ewritika 8a to ekane na trexei kai se ligotera apo ton ari8mo file_size
	block kai thread dinontas ksana sto ka8e thread afou teleiwne kai allo workload
	*/
	if (index < (int)file_size ) {
		atomicAdd(freq + buffer[index], 1);
	}
	__syncthreads();

}

int main(int argc, char *argv[]) {

	FILE *pFile;
	long file_size;
	char * buffer;
	char *d_buffer;
	int	*d_freq;
	const char * filename;
	size_t result;
	int j, freq[N],counter;
	int thread_count;
	int block_count;

	if (argc != 4) {
		printf("Usage : %s <file_name>\n", argv[0]);
		return 1;
	}
	filename = argv[1];
	thread_count = strtol(argv[2], NULL, 10);
	block_count = strtol(argv[2], NULL, 10);
	pFile = fopen(filename, "rb");
	if (pFile == NULL) { perror("File error\n"); return 2; }

	cudaGetDeviceCount(&counter);
	printf("There are %d GPU devices in your system\n", counter);

	// obtain file size:
	fseek(pFile, 0, SEEK_END);
	file_size = ftell(pFile);
	rewind(pFile);
	printf("file size is %ld\n", file_size);

	// allocate memory to contain the file:
	buffer = (char*)malloc(sizeof(char)*file_size);

	cudaMalloc(&d_buffer, (sizeof(char)*file_size));
	cudaMalloc(&d_freq, N * sizeof(int));

	if (buffer == NULL) { printf("Memory error\n"); return 3; }

	// copy the file into the buffer:
	result = fread(buffer, 1, file_size, pFile);
	if (result != file_size) { printf("Reading error\n"); return 4; }
	//gemizei 128 8eseis me 0
	for (j = 0; j < N; j++) {
		freq[j] = 0;
	}
	//auto p 8eloume parallhlo , gemizei to freq 
	//parallhlopoihshmh perioxh 

	cudaMemcpy(d_buffer, buffer, (sizeof(char)*file_size), cudaMemcpyHostToDevice);
	cudaMemcpy(d_freq, freq, N * sizeof(int), cudaMemcpyHostToDevice);	

	parallelf <<< block_count , thread_count >>> (d_buffer , d_freq , file_size);

	cudaMemcpy(freq, d_freq, N * sizeof(int), cudaMemcpyDeviceToHost);

	for (j = 0; j < N; j++) {
		printf("%d = %d\n", j + base, freq[j]);
	}

	fclose(pFile);
	free(buffer);
	cudaFree(d_buffer);
	cudaFree(d_freq);

	return 0;
}
