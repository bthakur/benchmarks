// Sample code reduction.cpp
      // Example showing use of OpenMP 4.0 pragmas for offload calculation
      // Tis code was compiled with Intel(R)Composer XE 2013

#include <stdio.h>

    #define SIZE 1000
    #pragma omp declare target
    int reduce(int *inarray) 
        {
	int sum=0;
	#pragma omp target map(inarray[0:SIZE]) map(sum)
	{	
		for(int i=0;i<SIZE;i++)
		sum += inarray[i];
	}	
	return sum;
        }

	int main()
	{
	int inarray[SIZE], sum, validSum;
	validSum=0;
	for(int i=0; i<SIZE; i++){
	inarray[i]=i;
	validSum+=i;
	}

	sum=0;
	sum = reduce(inarray);
	printf("sum reduction = %d, validSum=%d\n",sum, validSum);
    }
