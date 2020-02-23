include("4-integer.jl")

function dual_model(solver)

    m = int_model(solver)
    resolve_fix_discrete!(m, solver)

end

function resolve_fix_discrete!(m::Model, solver)

    # Go through all variables and fix binaries / integers
    # such that the problem is convex and has duals
    vars = all_variables(m)
    vals = value.(vars)
    for (var, val) in zip(vars, vals)
        if is_binary(var) || is_integer(var)
            is_binary(var) ? unset_binary(var) : unset_integer(var)
            fix(var, val, force=true)
        end
    end

    # Remove SOS1 constraints
    for con in all_constraints(m, Array{VariableRef,1}, MOI.SOS1{Float64})
        delete(m, con)
    end

    set_optimizer(m, solver)
    @time optimize!(m)
    printresults(m)

    return m

end


