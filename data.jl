using CSV
using Printf

# Load in resource data from file

timeseries = CSV.read("data/load_generation.csv")

# Set up optimization parameters

voll = 10_000

n_periods = size(timeseries, 1)

wind = Array(timeseries[:, r"WIND"])
n_wind = size(wind, 2)
wind_costpermw = (1610/20 + 44) * 1000
wind_capacity = vec(maximum(wind, dims=1))

pv = Array(timeseries[:, r"PV"])
n_pv = size(pv, 2)
pv_costpermw = (1111/20 + 20) * 1000
pv_capacity = vec(maximum(pv, dims=1))

load = timeseries.load ./ 2

# Define some convenience functions

pct_str(x::Number) = (@sprintf "%0.1f" 100x) * " %"

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

    unserved_fraction = value(m[:unserved_energy]) / sum(load)
    println(pct_str(unserved_fraction), " of demand unserved at a cost of ", dollar_str(voll*value(m[:unserved_energy])))

    println("Capital investments by technology:")
    println("\t", @sprintf("%0.1f", value(m[:wind_built])), " MW wind (", dollar_str(value(m[:wind_built]) * wind_costpermw), ")")
    println("\t", @sprintf("%0.1f", value(m[:pv_built])),   " MW PV (", dollar_str(value(m[:pv_built]) * pv_costpermw), ")")

end

nothing
