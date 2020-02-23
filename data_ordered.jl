include("data.jl")

function vgavailability_cumulative(
    resource::Matrix{Float64},
    resource_capacity::Vector{Float64}
)

    cfs = vec(mean(resource, dims=1)) ./ resource_capacity
    resource_order = sortperm(cfs, rev=true)

    resource_cum = similar(resource)
    resource_capacity_cum = similar(resource_capacity)

    resource_cum[:,1] = resource[:, first(resource_order)]
    resource_capacity_cum[1] = resource_capacity[first(resource_order)]

    for i in 2:length(resource_order)
        resource_cum[:,i] = resource_cum[:,i-1] + resource[:, resource_order[i]]
        resource_capacity_cum[i] = resource_capacity_cum[i-1] + resource_capacity[resource_order[i]]
    end

    return resource_cum, resource_capacity_cum

end

wind, wind_capacity = vgavailability_cumulative(wind, wind_capacity)
pv, pv_capacity = vgavailability_cumulative(pv, pv_capacity)

nothing
