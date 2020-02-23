using JuMP

# Load in model parameters

include("data_ordered.jl")

function int_model(solver)

    # Create the JuMP model object

    m = Model(solver) 

    # Define decision variables

    @variable(m, wind_builds[i in 1:length(winds)], Bin) # which set of wind sites to build
    @variable(m, pv_builds[i in 1:length(pvs)], Bin) # which set of PV sites to build
    @variable(m, thermal_builds[i in thermals], Int) # number of thermal plants to build

    @variable(m, wind_dispatch[t in timesteps]) # in MW
    @variable(m, pv_dispatch[t in timesteps]) # in MW
    @variable(m, thermal_dispatch[t in timesteps, i in thermals]) # in MW

    @variable(m, droppedload[t in timesteps]) # in MW

    # Define some convenience expressions

    @expression(m, wind_built, sum(wind_builds[i]  * wind_capacity[i] for i in winds)) # MW
    @expression(m, wind_generation, sum(wind_dispatch)) # MWh

    @expression(m, pv_built, sum(pv_builds[i]  * pv_capacity[i] for i in pvs)) # MW
    @expression(m, pv_generation, sum(pv_dispatch)) # MWh

    @expression(m, thermal_built[i in thermals], thermal_builds[i] * thermal_capacity[i]) # MW
    @expression(m, thermal_generation[i in thermals],
                   sum(thermal_dispatch[t, i] for t in timesteps)) # MWh

    @expression(m, unserved_energy, sum(droppedload)) # in MWh

    # Define the objective function

    @objective(m, Min,
               + wind_costpermw * wind_built # wind fixed cost
               + pv_costpermw * pv_built # pv fixed cost
               + sum(thermal_costpermw[i] * thermal_built[i] for i in thermals) # thermal fixed cost
               + sum(thermal_marginalcost[i] * thermal_generation[i]
                     for i in thermals) # thermal fixed cost
               + voll * unserved_energy # unserved energy cost
    )

    # Define constaints

    @constraint(m, wind_builds in MOI.SOS1(collect(winds)))
    @constraint(m, pv_builds in MOI.SOS1(collect(pvs)))
    @constraint(m, thermal_builds .>= 0)

    @constraint(m, powerbalance[t in timesteps], # balance supply and (inelastic) demand
        load[t] == sum(thermal_dispatch[t,i] for i in thermals)
                   + wind_dispatch[t] + pv_dispatch[t] + droppedload[t])

    @constraint(m, minunserved[t in timesteps], # cannot have negative dropped load
        0 <= droppedload[t])

    @constraint(m, wind_mingen[t in timesteps], # cannot have negative wind generation
        0 <= wind_dispatch[t]) 

    @constraint(m, wind_maxgen[t in timesteps], # wind generation cannot exceed available capacity
        wind_dispatch[t] <= sum(wind_builds[i] * wind[t,i] for i in winds)) 

    @constraint(m, pv_mingen[t in timesteps], # cannot have negative pv generation
        0 <= pv_dispatch[t]) 

    @constraint(m, pv_maxgen[t in timesteps], # pv generation cannot exceed available capacity
        pv_dispatch[t] <= sum(pv_builds[i] * pv[t,i] for i in pvs))


    @constraint(m, thermal_mingen[t in timesteps, i in thermals], # cannot have negative thermal generation
        0 <= thermal_dispatch[t,i]) 

    @constraint(m, thermal_maxgen[t in timesteps, i in thermals], # thermal generation cannot exceed available capacity
        thermal_dispatch[t,i] <= thermal_builds[i] * thermal_capacity[i])

    @time optimize!(m)
    printresults(m)

    return m

end
