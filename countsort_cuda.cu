#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda.h>
#include "cuda_runtime.h"
#include <cuda_runtime_api.h>
#include <device_functions.h>
#include "device_launch_parameters.h"

//#define block 1
//#define threads 17

//!!!! logo provlhmatwn to programma douleuei mono me block * thread >= apo auto pou upologizei
//giati se ka8e thread dinei 1 i tou loop pou kanei parallhla

int test(int *a, int n);
int parsetable(int *a, int n);

__global__ void parallel(int elements_table, int *a, int *count,int max) {
	int index = blockIdx.x * blockDim.x + threadIdx.x;
	int stride = blockDim.x * gridDim.x;

	if (index < elements_table) {
		atomicAdd(count + a[index], 1);
	}
	__syncthreads();
}

__global__ void nestedparallel(int max, int *temp, int *count, int value) {

	int index = blockIdx.x * blockDim.x + threadIdx.x;
	int stride = blockDim.x * gridDim.x;

	int i = index;
	if (i < max + 1 && i != 0) {
		if (i < value)
			temp[i] = count[i];
		else 
			temp[i] = count[i] + count[i - value];
	}
	__syncthreads();

	if (index < max+1)
		count[index] = temp[index];
	__syncthreads();
}


int main(int argc, char *argv[]) {

	int i, counter, value, j, max = 0;
	int* a;
	int *d_a, *d_count, *d_temp;
	double delta, start, end;

	if (argc != 4) {
		printf("Noô correct number of arguments\n");
		return 1;
	}
    //4 arguments to elements table , ta blocks kai ta thread 
	int elements_table = strtol(argv[1], NULL, 10);
	int block = strtol(argv[2], NULL, 10);
    int threads = strtol(argv[2], NULL, 10);

	a = (int *)malloc(elements_table * sizeof(int));
	cudaMalloc(&d_a, elements_table * sizeof(float));

	cudaGetDeviceCount(&counter);
	printf("There are %d GPU devices in your system\n", counter);

	for (i = 0; i < elements_table; i++)
	{
		int x = rand() % elements_table;
		if (x == 0)
			x = x + (rand() % elements_table) + 1;
		a[i] = x;
		if (a[i] > max)
			max = a[i];
	}

	int *count = (int *)malloc((max + 1) * sizeof(int));
	int *temp = (int *)malloc((max + 1) * sizeof(int));
	int *output = (int *)malloc(elements_table * sizeof(int));

	cudaMalloc(&d_temp, (max + 1) * sizeof(int));
	cudaMalloc(&d_count, (max + 1) * sizeof(int));

	for (i = 0; i < max + 1; i++) {
		count[i] = 0;
		temp[i] = 0;
	}

	//parallhlopoihshmh perioxh 1h

	cudaMemcpy(d_a, a, elements_table * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_count, count, (max + 1) * sizeof(int), cudaMemcpyHostToDevice);

	parallel << <block, threads >> > (elements_table, d_a, d_count, max+1);

	cudaMemcpy(count, d_count, (max + 1) * sizeof(int), cudaMemcpyDeviceToHost);

	//to delta einai log me bash to 2 tou n
	// gia ta log kai pow prepei otan kanoume gcc na valoume k -lm 
	// gia thn math.h sto telos  
	delta = (log(elements_table) / log(2));
	int e = (int)delta;

	//2h parallel zone

	cudaMemcpy(d_temp, temp, (max + 1) * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_count, count, (max + 1) * sizeof(int), cudaMemcpyHostToDevice);

	for (j = 0; j < e + 1; j++) {
		value = pow(2, j);
		nestedparallel <<<block, threads>> > (max, d_temp, d_count, value);
	}

	cudaMemcpy(count, d_count, (max + 1) * sizeof(int), cudaMemcpyDeviceToHost);

	//telos perioxhs
	for (i = 0; i < elements_table; i++) {
		output[count[a[i]] - 1] = a[i];
		count[a[i]]--;
	}

	for (i = 0; i < elements_table; i++)
		a[i] = output[i];
	parsetable(a,elements_table);

	test(a, elements_table);

    cudaFree(d_count);
	cudaFree(d_a);
	cudaFree(d_temp);
	return 0;

}

int test(int *a, int n) {
	// if 0 == false
	int pass = 1;
	for (int i = 1; i < n; i++)
	{
		if (a[i] < a[i - 1])
			pass = 0;
	}
	if (pass)
		printf("The list is sorted\n");
	else
		printf("The list isn't sorted\n");
	return 0;
}

int parsetable(int *a, int n) {

	printf("\n");
	for (int i = 0; i < n; i++)
		printf("-%d-", a[i]);
	printf("\n");
	return 0;
}
