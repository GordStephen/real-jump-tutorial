using Statistics

include("data.jl")

function vgavailability_cumulative(
    resource::Matrix{Float64},
    resource_cost::Vector{Float64},
    resource_capacity::Vector{Float64}
)

    cfs = vec(mean(resource, dims=1)) ./ resource_capacity
    resource_order = sortperm(cfs, rev=true)

    resource_cum = similar(resource)
    resource_cost_cum = similar(resource_cost)
    resource_capacity_cum = similar(resource_capacity)

    resource_cum[:,1] = resource[:, first(resource_order)]
    resource_cost_cum[1] = resource_cost[first(resource_order)]
    resource_capacity_cum[1] = resource_capacity[first(resource_order)]

    for i in 2:length(resource_order)
        resource_cum[:,i] = resource_cum[:,i-1] + resource[:, resource_order[i]]
        resource_cost_cum[i] = resource_cost_cum[i-1] + resource_cost[resource_order[i]]
        resource_capacity_cum[i] = resource_capacity_cum[i-1] + resource_capacity[resource_order[i]]
    end

    return resource_cum, resource_cost_cum, resource_capacity_cum

end

wind, wind_cost, wind_capacity = vgavailability_cumulative(wind, wind_cost, wind_capacity)
pv, pv_cost, pv_capacity = vgavailability_cumulative(pv, pv_cost, pv_capacity)
