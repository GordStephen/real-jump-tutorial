using CSV
using Printf
using Statistics

# Load in resource data from file

timeseries = CSV.read("data/load_generation.csv")

# Set up optimization parameters
# (generator economic data from 2019 NREL ATB)

voll = 10_000 # $/MWh

timesteps = 1:size(timeseries, 1)

wind = Array(timeseries[:, r"WIND"])
winds = 1:size(wind, 2)
wind_costpermw = (1610/20 + 44) * 1000 # $/MW (capital cost / lifetime + annual fixed O&M)
wind_capacity = vec(maximum(wind, dims=1)) # MW

pv = Array(timeseries[:, r"PV"])
pvs = 1:size(pv, 2)
pv_costpermw = (1111/20 + 20) * 1000 # $/MW
pv_capacity = vec(maximum(pv, dims=1)) # MW

load = timeseries.load * 0.5 # MW

thermals = ["Coal ST", "Gas CT"]
thermal_costpermw = [4036/30 + 33, 919/20 + 12] .* 1000 # $/MW
thermal_costpermw = Dict(zip(thermals, thermal_costpermw))
thermal_capacity = [400, 80] # MW
thermal_capacity = Dict(zip(thermals, thermal_capacity))
thermal_marginalcost = [18 + 5, 32 + 7] # $/MWh (fuel cost + variable O&M)
thermal_marginalcost = Dict(zip(thermals, thermal_marginalcost))

# Define some convenience functions

pct_str(x::Number) = (@sprintf "%0.3f" 100x) * "%"

dollar_str(x::Number) = "\$" *
    if x < 0
        error("Dollar input must be positive")
    elseif 0 <= x < 1e6
        @sprintf "%0.2f" x
    elseif 1e6 <= x < 1e9
        @sprintf "%0.1fM" x/1e6
    elseif 1e9  <= x <= 1e12
        @sprintf "%0.1fB" x/1e9
    else
        @sprintf "%0.1fT" x/1e12
    end


function printresults(m::Model)

    println(termination_status(m))

    println("Total annualized system cost was ", dollar_str(objective_value(m)))

    total_load = sum(load)
    unserved_fraction = value(m[:unserved_energy]) / total_load
    println(pct_str(unserved_fraction), " of demand unserved at a cost of ", dollar_str(voll*value(m[:unserved_energy])))

    println("Investments and costs by technology:")
    println("\tWind: ", @sprintf("%0.1f", value(m[:wind_built])),
            " MW (", dollar_str(value(m[:wind_built]) * wind_costpermw), " fixed)")
    println("\tPV: ", @sprintf("%0.1f", value(m[:pv_built])),
            " MW (", dollar_str(value(m[:pv_built]) * pv_costpermw), " fixed)")

    :thermal_built in keys(m.obj_dict) && for i in thermals
            n_built = round(Int, value(m[:thermal_builds][i]))
            capacity = thermal_capacity[i]
            fixed_cost = n_built * capacity * thermal_costpermw[i]
            variable_cost = thermal_marginalcost[i] * value(m[:thermal_generation][i])
            println("\t", i, ": ", n_built, " x ", capacity, " MW (",
                    dollar_str(fixed_cost), " fixed, ",
                    dollar_str(variable_cost), " variable)")
    end

    println("Energy penetration levels:")
    println("\tWind: ", pct_str(value(m[:wind_generation]) / total_load))
    println("\tPV: ", pct_str(value(m[:pv_generation]) / total_load))

    :thermal_built in keys(m.obj_dict) && for i in thermals
       println("\t", i, ": ", pct_str(value(m[:thermal_generation][i]) / total_load))
    end 
    
    if has_duals(m)
        println("Average energy price: ", dollar_str(-mean(dual.(m[:powerbalance]))), "/MWh")
    end

end

nothing
