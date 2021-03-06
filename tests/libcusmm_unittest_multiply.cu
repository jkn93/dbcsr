/*****************************************************************************
 *  CP2K: A general program to perform molecular dynamics simulations        *
 *  Copyright (C) 2000 - 2018  CP2K developers group                         *
 *****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <vector>
#include <array>
#include "acc/libsmm_acc/libcusmm/libcusmm_benchmark.h"
#include "acc/libsmm_acc/libcusmm/libcusmm.h"
#include "acc/libsmm_acc/libcusmm/parameters.h"


/****************************************************************************\
 \brief Checks correctness of every libcusmm multiplication kernel and measures its performance.
\****************************************************************************/

int main(int argc, char** argv){

    KernelLauncher launcher_mm = libcusmm_process_d;

    char buffer[1000];
    char * kernel_descr[1] = {buffer};

    // Get all blocksizes available in libcusmm
    std::vector<Triplet> libcusmm_triplets;
    get_libcusmm_triplets(libcusmm_triplets, ht);
    int n_triplets = libcusmm_triplets.size();
    printf("# Libcusmm has %d blocksizes for multiplication\n", n_triplets);

    int max_m=0, max_n=0, max_k=0;
    for(int i=0; i<n_triplets; i++){
        max_m = max(max_n, libcusmm_triplets[i][0]);
        max_n = max(max_m, libcusmm_triplets[i][1]);
        max_k = max(max_k, libcusmm_triplets[i][2]);
    }

    libcusmm_benchmark_t* handle;
    libcusmm_benchmark_init(&handle, test, max_m, max_n, max_k);

    int errors = 0;
    for(int i=0; i<n_triplets; i++){
        int m = libcusmm_triplets[i][0];
        int n = libcusmm_triplets[i][1];
        int k = libcusmm_triplets[i][2];
        sprintf(buffer, "%d x %d x %d", m, n, k);
        errors += libcusmm_benchmark(handle, m, n, k, 1, &launcher_mm, kernel_descr);
    }
    libcusmm_benchmark_finalize(handle);

    printf("# Done, found %d matrix-matrix multiplication errors.\n", errors);
    return errors;
}

//EOF
