#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import print_function

import json
import argparse
from os import path

from kernels.cusmm_dnt_helper import params_dict_to_kernel


def main(gpu_version, base_dir):
    # Read existing parameters
    print("GPU version:\n", gpu_version)
    param_fn = path.join(base_dir, "parameters_{}.json".format(gpu_version))
    with open(param_fn) as f:
        all_kernels = [params_dict_to_kernel(**params) for params in json.load(f)]
    print("About to process", len(all_kernels), "kernels from file", param_fn)
    parameters = dict()
    for kernel in all_kernels:
        (m, n, k), pars = kernel.as_key_value
        parameters[(m, n, k)] = pars

    # Construct output
    out, all_pars = write_parameters_file(parameters)

    # Write to c++ header-file
    file_h = "parameters.h"
    print('Found', len(parameters), 'kernels in', param_fn)
    print('Printing them to file', file_h)
    with open(file_h, 'w') as f:
        f.write(out)


#===============================================================================
def write_parameters_file(all_pars):

    # Header
    out = """\
/*****************************************************************************
 *  CP2K: A general program to perform molecular dynamics simulations        *
 *  Copyright (C) 2000 - 2018  CP2K developers group                         *
 *****************************************************************************/

/*****************************************************************************
 *  FILE GENERATED BY SCRIPT 'generate_parameters.py' DO NOT EDIT            *
 *****************************************************************************/

#ifndef PARAMETERS_H
#define PARAMETERS_H

#include "parameters_utils.h"

/*
 * Lookup table: given a triplet (m, n, k) describing a matrix-matrix multiplication, look up its optimal kernel parameters
 *
 * Keys:
 *   (m, n, k)
 *
 * Values: array of 8 integers with elements:
 *   0: mm algorithm (enum defined in libcusmm.h, possible values: 1, 2, 3, 4, 5)
 *   1: tile_m
 *   2: tile_n
 *   3: w
 *   4: v
 *   5: threads
 *   6: grouping
 *   7: minblocks
 *
 * Note: for the matrix matrix multiplication algorithms which take less than 8 parameters (i.e. "tiny", "small" and "medium"),
 * the superfluous parameters are set to 0
 */

static const std::unordered_map<Triplet, KernelParameters> ht  = {
"""
    # Initializer list body
    print("Get parameters and write to file")
    init_list_line = \
        "    {{ {{{{{m:3}, {n:3}, {k:3}}}}}, {{{{ {algo}, {tile_m}, {tile_n}, {w}, {v}, {threads}, {grouping}, {minblocks} }}}} }},\n"
    for (m, n, k), pars in sorted(all_pars.items()):
        out += init_list_line.format(algo=pars[0], tile_m=pars[1], tile_n=pars[2], w=pars[3], v=pars[4],
                                     threads=pars[5], grouping=pars[6], minblocks=pars[7], m=m, n=n, k=k)

    # Footer
    out += """\
};

#endif
//EOF
"""

    return out, all_pars


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Generator of LibCuSMM. The Library for Cuda Small Matrix Multiplications.")
    parser.add_argument("-g", "--gpu_version", metavar="GPU_VERSION", default="P100",
                        help="GPU card version, used to select the appropriate libcusmm parameters file. Default: %(default)s")
    parser.add_argument("-d", "--base_dir", metavar="BASE_DIR", default=".",
                        help="Set the base directory to look for the parameter files. Default: %(default)s")
    args = parser.parse_args()
    main(args.gpu_version, args.base_dir)
