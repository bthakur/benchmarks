#!/bin/bash

mpif90 -openmp -C -check all -O0 -g -traceback timing.f90 data.f90 ring_exchange.f90 -o ring_exchange

rm *.mod
