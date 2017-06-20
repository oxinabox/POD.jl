"""
    update_var_bounds(m::PODNonlinearModel, discretization::Dict; len::Float64=length(keys(discretization)))

This function take in a dictionary-based discretization information and convert them into two bounds vectors (l_var, u_var) by picking the smallest and largest numbers. User can specify a certain length that may contains variables that is out of the scope of discretization.

Output::

    l_var::Vector{Float64}, u_var::Vector{Float64}
"""
function update_var_bounds(discretization; kwargs...)

    options = Dict(kwargs)

    haskey(options, :len) ? len = options[:len] : len = length(keys(discretization))

    l_var = fill(-Inf, len)
    u_var = fill(Inf, len)

    for var_idx in keys(discretization)
        l_var[var_idx] = discretization[var_idx][1]
        u_var[var_idx] = discretization[var_idx][end]
    end

    return l_var, u_var
end

"""
    discretization_to_bounds(d::Dict, l::Int)

Same as [`update_var_bounds`](@ref)
"""
discretization_to_bounds(d::Dict, l::Int) = update_var_bounds(d, len=l)

"""
    initialize_discretization(m::PODNonlinearModel)

This function initialize the dynamic discretization used for any bounding models. By default, it takes (.l_var_orig, .u_var_orig) as the base information. User is allowed to use alternative bounds for initializing the discretization dictionary.
The output is a dictionary with MathProgBase variable indices keys attached to the :PODNonlinearModel.discretization.
"""
function initialize_discretization(m::PODNonlinearModel; kwargs...)

    options = Dict(kwargs)

    for var in 1:m.num_var_orig
        lb = m.l_var_tight[var]
        ub = m.u_var_tight[var]
        m.discretization[var] = [lb, ub]
    end

    for var in (1+m.num_var_orig):(m.num_var_orig+m.num_var_lifted_mip)
        lb = -Inf
        ub = Inf
        m.discretization[var] = [lb, ub]
    end

    return
end

"""

    to_discretization(m::PODNonlinearModel, lbs::Vector{Float64}, ubs::Vector{Float64})

Utility functions to convert bounds vectors to Dictionary based structures that is more suitable for
partition operations.

"""
function to_discretization(m::PODNonlinearModel, lbs::Vector{Float64}, ubs::Vector{Float64}; kwargs...)

    options = Dict(kwargs)

    var_discretization = Dict()
    for var in 1:m.num_var_orig
        lb = lbs[var]
        ub = ubs[var]
        var_discretization[var] = [lb, ub]
    end

    for var in (1+m.num_var_orig):(m.num_var_orig+m.num_var_lifted_mip)
        lb = -Inf
        ub = Inf
        var_discretization[var] = [lb, ub]
    end

    return var_discretization
end

"""
    flatten_discretization(discretization::Dict)

Utility functions to eliminate all partition on discretizing variable and keep the loose bounds.

"""
function flatten_discretization(discretization::Dict; kwargs...)

    flatten_discretization = Dict()
    for var in keys(discretization)
        flatten_discretization[var] = [discretization[var][1],discretization[var][end]]
    end

    return flatten_discretization
end

"""
    add_discretization(m::PODNonlinearModel; use_discretization::Dict, use_solution::Vector)

Basic built-in method used to add a new partition on feasible domains of discretizing variables.
This method make modification in .discretization

Consider original partition [0, 3, 7, 9], where LB/any solution is 4.
Use ^ as the new partition, "|" as the original partition

A case when discretize ratio = 4
| -------- | - ^ -- * -- ^ ---- | -------- |
0          3  3.5   4   4.5     7          9

A special case when discretize ratio = 2
| -------- | ---- * ---- ^ ---- | -------- |
0          3      4      5      7          9

There are two options for this function,

    * `use_discretization(default=m.discretization)`:: to regulate which is the base to add new partitions on
    * `use_solution(default=m.best_bound_sol)`:: to regulate which solution to use when adding new partitions on

This function belongs to the hackable group, which means it can be replaced by the user to change the behvaior of the solver.
"""
function add_discretization(m::PODNonlinearModel; kwargs...)

    options = Dict(kwargs)

    haskey(options, :use_discretization) ? discretization = options[:use_discretization] : discretization = m.discretization
    haskey(options, :use_solution) ? point_vec = options[:use_solution] : point_vec = m.best_bound_sol



    # ? Perform discretization base on type of nonlinear terms

    for i in 1:m.num_var_orig
        point = point_vec[i]
        @assert point >= discretization[i][1] - m.tolerance       # Solution validation
        @assert point <= discretization[i][end] + m.tolerance
        if i in m.var_discretization_mip  # Only construct when discretized
            for j in 1:length(discretization[i])
                if point >= discretization[i][j] && point <= discretization[i][j+1]  # Locating the right location
                    @assert j < length(m.discretization[i])
                    lb_local = discretization[i][j]
                    ub_local = discretization[i][j+1]
                    distance = ub_local - lb_local
                    radius = distance / m.discretization_ratio
                    lb_new = max(point - radius, lb_local)
                    ub_new = min(point + radius, ub_local)
                    m.log_level > 99 && println("[DEBUG] VAR$(i): SOL=$(round(point,4)) RATIO=$(m.discretization_ratio)  |$(round(lb_local,4)) |$(round(lb_new,6)) <- * -> $(round(ub_new,6))| $(round(ub_local,4))|")
                    if ub_new < ub_local && !isapprox(ub_new, ub_local; atol=m.tolerance)  # Insert new UB-based partition
                        insert!(discretization[i], j+1, ub_new)
                    end
                    if lb_new > lb_local && !isapprox(lb_new, lb_local; atol=m.tolerance)  # Insert new LB-based partition
                        insert!(discretization[i], j+1, lb_new)
                    end
                    break
                end
            end
        end
    end

    return discretization
end

"""

    update_mip_time_limit(m::PODNonlinearModel)

An utility function used to dynamically regulate MILP solver time limits to fit POD solver time limits.

"""
function update_mip_time_limit(m::PODNonlinearModel; kwargs...)

    options = Dict(kwargs)
    haskey(options, :timelimit) ? timelimit = options[:timelimit] : timelimit = max(0.0, m.timeout-m.logs[:total_time])

    for i in 1:length(m.mip_solver.options)
        if fetch_timeleft_symbol(m) in collect(m.mip_solver.options[i])
            deleteat!(m.mip_solver.options, i)
            break
        end
    end

    if m.timeout != Inf
        push!(m.mip_solver.options, (fetch_timeleft_symbol(m), timelimit))
    end

    return
end

"""

    fetch_timeleft_symbol(m::PODNonlinearModel)

An utility function used to recognize differnt sub-solvers return the timelimit setup keywords.
"""
function fetch_timeleft_symbol(m::PODNonlinearModel; kwargs...)
    if string(m.mip_solver)[1:10] == "CPLEX.Cple"
        return :CPX_PARAM_TILIM
    elseif string(m.mip_solver)[1:10] == "Gurobi.Gur"
        return :TimeLimit
    elseif string(m.mip_solver)[1:10] == "Cbc.CbcMat"
        return :seconds
    else found == nothing
        error("Needs support for this MIP solver")
    end
    return
end
