using JuMP

# Load in model parameters

include("data.jl")

function bin_model(solver)

    # Create the JuMP model object

    m = Model(solver)

    # Define decision variables

    @variable(m, wind_builds[i in winds], Bin) # whether to build wind site
    @variable(m, pv_builds[i in pvs], Bin) # whether to build pv site

    @variable(m, wind_dispatch[t in timesteps]) # in MW
    @variable(m, pv_dispatch[t in timesteps]) # in MW
    @variable(m, droppedload[t in timesteps]) # in MW

    # Define some convenience expressions

    @expression(m, wind_built, sum(wind_builds[i]  * wind_capacity[i] for i in winds)) # in MW
    @expression(m, wind_generation, sum(wind_dispatch)) # MWh

    @expression(m, pv_built, sum(pv_builds[i]  * pv_capacity[i] for i in pvs)) # in MW
    @expression(m, pv_generation, sum(pv_dispatch)) # MWh

    @expression(m, unserved_energy, sum(droppedload)) # in MWh

    # Define the objective function

    @objective(m, Min,
               + wind_costpermw * wind_built # wind capital cost
               + pv_costpermw * pv_built + # pv capital cost
               + voll * unserved_energy # unserved energy cost
    )

    # Define constaints

    @constraint(m, powerbalance[t in timesteps], # balance supply and (inelastic) demand
        load[t] == wind_dispatch[t] + pv_dispatch[t] + droppedload[t])

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

    @time optimize!(m)
    printresults(m)

    return m

end
