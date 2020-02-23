#using CPLEX; solver = CPLEX.Optimizer
using Gurobi; solver = Gurobi.Optimizer

include("1-LP.jl"); lp = lp_model(solver)

#include("2-binary.jl"); bin = bin_model(solver)

#include("3-SOS.jl"); sos = sos_model(solver)

#include("4-integer.jl"); int = int_model(solver)

#include("5-duals.jl"); dual = dual_model(solver)
