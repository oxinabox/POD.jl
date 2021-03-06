"""

    create_bounding_mip(m::PODNonlinearModel; use_disc::Dict)

Set up a JuMP MILP bounding model base on variable domain partitioning information stored in `use_disc`.
By default, if `use_disc is` not provided, it will use `m.discretizations` store in the POD model.
The basic idea of this MILP bounding model is to use Tighten McCormick to convexify the original Non-convex region.
Among all presented partitionings, the bounding model will choose one specific partition as the lower bound solution.
The more partitions there are, the better or finer bounding model relax the original MINLP while the more
efforts required to solve this MILP is required.

This function is implemented in the following manner:

    * [`amp_post_vars`](@ref): post original and lifted variables
    * [`amp_post_lifted_constraints`](@ref): post original and lifted constraints
    * [`amp_post_lifted_obj`](@ref): post original or lifted objective function
    * [`amp_post_tmc_mccormick`](@ref): post Tighen McCormick variables and constraints base on `discretization` information

More specifically, the Tightening McCormick used here can be genealized in the following mathematcial formulation. Consider a nonlinear term
```math
\\begin{subequations}
\\begin{align}
   &\\widehat{x_{ij}} \\geq (\\mathbf{x}_i^l\\cdot\\hat{\\mathbf{y}}_i) x_j + (\\mathbf{x}_j^l\\cdot\\hat{\\mathbf{y}}_j) x_i - (\\mathbf{x}_i^l\\cdot\\hat{\\mathbf{y}}_i)(\\mathbf{x}_j^l\\cdot\\hat{\\mathbf{y}}_j) \\\\
   &\\widehat{x_{ij}} \\geq (\\mathbf{x}_i^u\\cdot\\hat{\\mathbf{y}}_i) x_j + (\\mathbf{x}_j^u\\cdot\\hat{\\mathbf{y}}_j) x_i - (\\mathbf{x}_i^u\\cdot\\hat{\\mathbf{y}}_i)(\\mathbf{x}_j^u\\cdot\\hat{\\mathbf{y}}_j) \\\\
   &\\widehat{x_{ij}} \\leq (\\mathbf{x}_i^l\\cdot\\hat{\\mathbf{y}}_i) x_j + (\\mathbf{x}_j^u\\cdot\\hat{\\mathbf{y}}_j) x_i - (\\mathbf{x}_i^l\\cdot\\hat{\\mathbf{y}}_i)(\\mathbf{x}_j^u\\cdot\\hat{\\mathbf{y}}_j) \\\\
   &\\widehat{x_{ij}} \\leq (\\mathbf{x}_i^u\\cdot\\hat{\\mathbf{y}}_i) x_j + (\\mathbf{x}_j^l\\cdot\\hat{\\mathbf{y}}_j) x_i - (\\mathbf{x}_i^u\\cdot\\hat{\\mathbf{y}}_i)(\\mathbf{x}_j^l\\cdot\\hat{\\mathbf{y}}_j) \\\\
   & \\mathbf{x}_i^u\\cdot\\hat{\\mathbf{y}}_i) \\geq x_{i} \\geq \\mathbf{x}_i^l\\cdot\\hat{\\mathbf{y}}_i) \\\\
   & \\mathbf{x}_j^u\\cdot\\hat{\\mathbf{y}}_j) \\geq x_{j} \\geq \\mathbf{x}_j^l\\cdot\\hat{\\mathbf{y}}_j) \\\\
   &\\sum \\hat{\\mathbf{y}_i} = 1, \\ \\ \\sum \\hat{\\mathbf{y}_j}_k = 1 \\\\
   &\\hat{\\mathbf{y}}_i \\in \\{0,1\\}, \\hat{\\mathbf{y}}_j \\in \\{0,1\\}
\\end{align}
\\end{subequations}
```

"""
function create_bounding_mip(m::PODNonlinearModel; kwargs...)

    options = Dict(kwargs)

    haskey(options, :use_disc) ? discretization = options[:use_disc] : discretization = m.discretization

    m.model_mip = Model(solver=m.mip_solver) # Construct JuMP Model
    start_build = time()
    # ------- Model Construction ------ #
    amp_post_vars(m)                                                # Post original and lifted variables
    amp_post_lifted_constraints(m)                                  # Post lifted constraints
    amp_post_lifted_objective(m)                                    # Post objective
    amp_post_convexification(m, use_disc=discretization)  # Convexify problem
    # --------------------------------- #
    cputime_build = time() - start_build
    m.logs[:total_time] += cputime_build
    m.logs[:time_left] = max(0.0, m.timeout - m.logs[:total_time])

    return
end

"""
    amp_post_convexification(m::PODNonlinearModel; kwargs...)

warpper function to convexify the problem for a bounding model. This function talks to nonlinear_terms and convexification methods
to finish the last step required during the construction of bounding model.
"""
function amp_post_convexification(m::PODNonlinearModel; kwargs...)

    options = Dict(kwargs)

    haskey(options, :use_disc) ? discretization = options[:use_disc] : discretization = m.discretization

    for i in 1:length(m.method_convexification)                 # Additional user-defined convexification method
        eval(m.method_convexification[i])(m)
    end

    amp_post_mccormick(m, use_disc=discretization)    # handles all bi-linear and monomial convexificaitons
    amp_post_convhull(m, use_disc=discretization)         # convex hull representation

    convexification_exam(m) # Exam to see if all non-linear terms have been convexificed

    return
end

function amp_post_vars(m::PODNonlinearModel; kwargs...)

    options = Dict(kwargs)

    if haskey(options, :use_disc)
        l_var = [options[:use_disc][i][1]   for i in 1:(m.num_var_orig+m.num_var_linear_lifted_mip+m.num_var_nonlinear_lifted_mip)]
        u_var = [options[:use_disc][i][end] for i in 1:(m.num_var_orig+m.num_var_linear_lifted_mip+m.num_var_nonlinear_lifted_mip)]
    else
        l_var = m.l_var_tight
        u_var = m.u_var_tight
    end

    @variable(m.model_mip, x[i=1:(m.num_var_orig+m.num_var_linear_lifted_mip+m.num_var_nonlinear_lifted_mip)])

    for i in 1:(m.num_var_orig+m.num_var_linear_lifted_mip+m.num_var_nonlinear_lifted_mip)
        (i <= m.num_var_orig) && setcategory(x[i], m.var_type_orig[i])
        (l_var[i] > -Inf) && (setlowerbound(x[i], l_var[i]))    # Changed to tight bound, if no bound tightening is performed, will be just .l_var_orig
        (u_var[i] < Inf) && (setupperbound(x[i], u_var[i]))     # Changed to tight bound, if no bound tightening is performed, will be just .u_var_orig
    end

    return
end


function amp_post_lifted_constraints(m::PODNonlinearModel)

    for i in 1:m.num_constr_orig
        if m.structural_constr[i] == :affine
            amp_post_affine_constraint(m.model_mip, m.bounding_constr_mip[i])
        elseif m.structural_constr[i] == :convex
            amp_post_convex_constraint(m.model_mip, m.bounding_constr_mip[i])
        else
            error("Unknown structural_constr type $(m.structural_constr[i])")
        end
    end

    for i in keys(m.linear_terms)
        amp_post_linear_lift_constraints(m.model_mip, m.linear_terms[i])
    end

    return
end

function amp_post_affine_constraint(model_mip::JuMP.Model, affine::Dict)

    if affine[:sense] == :(>=)
        @constraint(model_mip,
            sum(affine[:coefs][j]*Variable(model_mip, affine[:vars][j].args[2]) for j in 1:affine[:cnt]) >= affine[:rhs])
    elseif affine[:sense] == :(<=)
        @constraint(model_mip,
            sum(affine[:coefs][j]*Variable(model_mip, affine[:vars][j].args[2]) for j in 1:affine[:cnt]) <= affine[:rhs])
    elseif affine[:sense] == :(==)
        @constraint(model_mip,
            sum(affine[:coefs][j]*Variable(model_mip, affine[:vars][j].args[2]) for j in 1:affine[:cnt]) == affine[:rhs])
    end

    return
end

function amp_post_convex_constraint(model_mip::JuMP.Model, convex::Dict)

    if convex[:sense] == :(<=)
        @constraint(model_mip,
            sum(convex[:coefs][j]*Variable(model_mip, convex[:vars][j].args[2])^2 for j in 1:convex[:cnt]) <= convex[:rhs])
    elseif convex[:sense] == :(>=)
        @constraint(model_mip,
            sum(convex[:coefs][j]*Variable(model_mip, convex[:vars][j].args[2])^2 for j in 1:convex[:cnt]) >= convex[:rhs])
    else
        error("No equality constraints should be recognized as supported convex constriants")
    end

    return
end

function amp_post_linear_lift_constraints(model_mip::JuMP.Model, l::Dict)

    @assert l[:ref][:sign] == :+
    @constraint(model_mip, Variable(model_mip, l[:y_idx]) == sum(i[1]*Variable(model_mip, i[2]) for i in l[:ref][:coef_var]) + l[:ref][:scalar])
    return
end

function amp_post_lifted_objective(m::PODNonlinearModel)

    if m.structural_obj == :affine
        @objective(m.model_mip, m.sense_orig, m.bounding_obj_mip[:rhs] + sum(m.bounding_obj_mip[:coefs][i]*Variable(m.model_mip, m.bounding_obj_mip[:vars][i].args[2]) for i in 1:m.bounding_obj_mip[:cnt]))
    elseif m.structural_obj == :convex
        @objective(m.model_mip, m.sense_orig, m.bounding_obj_mip[:rhs] + sum(m.bounding_obj_mip[:coefs][i]*Variable(m.model_mip, m.bounding_obj_mip[:vars][i].args[2])^2 for i in 1:m.bounding_obj_mip[:cnt]))
    else
        error("Unknown structural obj type $(m.structural_obj)")
    end

    return
end

function add_partition(m::PODNonlinearModel; kwargs...)

    options = Dict(kwargs)
    haskey(options, :use_disc) ? discretization = options[:use_disc] : discretization = m.discretization
    haskey(options, :use_solution) ? point_vec = options[:use_solution] : point_vec = m.best_bound_sol

    if isa(m.disc_add_partition_method, Function)
        m.discretization = eval(m.disc_add_partition_method)(m, use_disc=discretization, use_solution=point_vec)
    elseif m.disc_add_partition_method == "adaptive"
        m.discretization = add_adaptive_partition(m, use_disc=discretization, use_solution=point_vec)
    elseif m.disc_add_partition_method == "uniform"
        m.discretization = add_uniform_partition(m, use_disc=discretization)
    else
        error("Unknown input on how to add partitions.")
    end

    return
end

"""
    add_discretization(m::PODNonlinearModel; use_disc::Dict, use_solution::Vector)

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

    * `use_disc(default=m.discretization)`:: to regulate which is the base to add new partitions on
    * `use_solution(default=m.best_bound_sol)`:: to regulate which solution to use when adding new partitions on

TODO: also need to document the speical diverted cases when new partition touches both sides

This function belongs to the hackable group, which means it can be replaced by the user to change the behvaior of the solver.
"""
function add_adaptive_partition(m::PODNonlinearModel; kwargs...)

    options = Dict(kwargs)

    haskey(options, :use_disc) ? discretization = options[:use_disc] : discretization = m.discretization
    haskey(options, :use_solution) ? point_vec = copy(options[:use_solution]) : point_vec = copy(m.best_bound_sol)
    haskey(options, :use_ratio) ? ratio = options[:use_ratio] : ratio = m.disc_ratio
    haskey(options, :branching) ? branching = options[:branching] : branching = false

    (length(point_vec) < m.num_var_orig+m.num_var_linear_lifted_mip+m.num_var_nonlinear_lifted_mip) && (point_vec = resolve_lifted_var_value(m, point_vec))  # Update the solution vector for lifted variable

    branching && (discretization = deepcopy(discretization))

    # ? Perform discretization base on type of nonlinear terms ? #
    for i in m.var_disc_mip
        point = point_vec[i]                # Original Variable
        #@show i, point, discretization[i]
        if (i <= m.num_var_orig) && (m.var_type_orig[i] in [:Bin, :Int])  # DO not add partitions to discrete variables
            continue
        end
        if point < discretization[i][1] - m.tol || point > discretization[i][end] + m.tol
			warn("Soluiton VAR$(i)=$(point) out of bounds [$(discretization[i][1]),$(discretization[i][end])]. Taking middle point...")
			point = 0.5*(discretization[i][1]+discretization[i][end])
		end
        (abs(point - discretization[i][1]) <= m.tol) && (point = discretization[i][1])
        (abs(point - discretization[i][end]) <= m.tol) && (point = discretization[i][end])
        for j in 1:length(discretization[i])
            if point >= discretization[i][j] && point <= discretization[i][j+1]  # Locating the right location
                @assert j < length(m.discretization[i])
                lb_local = discretization[i][j]
                ub_local = discretization[i][j+1]
                distance = ub_local - lb_local
                if isa(ratio, Float64) || isa(ratio, Int)
                    radius = distance / ratio
                elseif isa(ratio, Function)
                    radius = distance / ratio(m)
                else
                    error("Undetermined discretization ratio")
                end
                lb_new = max(point - radius, lb_local)
                ub_new = min(point + radius, ub_local)
                ub_touch = true
                lb_touch = true
                if ub_new < ub_local && !isapprox(ub_new, ub_local; atol=m.disc_abs_width_tol) && abs(ub_new-ub_local)/(1e-8+abs(ub_local)) > m.disc_rel_width_tol    # Insert new UB-based partition
                    insert!(discretization[i], j+1, ub_new)
                    ub_touch = false
                end
                if lb_new > lb_local && !isapprox(lb_new, lb_local; atol=m.disc_abs_width_tol) && abs(lb_new-lb_local)/(1e-8+abs(lb_local)) > m.disc_rel_width_tol # Insert new LB-based partition
                    insert!(discretization[i], j+1, lb_new)
                    lb_touch = false
                end
                if (ub_touch && lb_touch) || (m.disc_consecutive_forbid>0 && check_solution_history(m, i))
                    distance = -1.0
                    pos = -1
                    for j in 2:length(discretization[i])  # it is made sure there should be at least two partitions
                        if (discretization[i][j] - discretization[i][j-1]) > distance
                            lb_local = discretization[i][j-1]
                            ub_local = discretization[i][j]
                            distance = ub_local - lb_local
                            point = lb_local + (ub_local - lb_local) / 2   # reset point
                            pos = j
                        end
                    end
                    chunk = (ub_local - lb_local)/2
                    insert!(discretization[i], pos, lb_local + chunk)
                    (m.loglevel > 99) && println("[DEBUG] !DIVERT! VAR$(i): |$(lb_local) | 2 SEGMENTS | $(ub_local)|")
                else
                    (m.loglevel > 99) && println("[DEBUG] VAR$(i): SOL=$(round(point,4)) RATIO=$(ratio), PARTITIONS=$(length(discretization[i])-1)  |$(round(lb_local,4)) |$(round(lb_new,6)) <- * -> $(round(ub_new,6))| $(round(ub_local,4))|")
                end
                break
            end
        end
    end

    return discretization
end

function add_uniform_partition(m::PODNonlinearModel; kwargs...)

    options = Dict(kwargs)
    haskey(options, :use_disc) ? discretization = options[:use_disc] : discretization = m.discretization

    for i in m.var_disc_mip  # Only construct when discretized
        lb_local = discretization[i][1]
        ub_local = discretization[i][end]
        distance = ub_local - lb_local
        chunk = distance / ((m.logs[:n_iter]+1)*m.disc_uniform_rate)
        discretization[i] = [lb_local+chunk*(j-1) for j in 1:(m.logs[:n_iter]+1)*m.disc_uniform_rate]
        push!(discretization[i], ub_local)   # Safety Scheme
        (m.loglevel > 99) && println("[DEBUG] VAR$(i): RATE=$(m.disc_uniform_rate), PARTITIONS=$(length(discretization[i]))  |$(round(lb_local,4)) | $(m.disc_uniform_rate*(1+m.logs[:n_iter])) SEGMENTS | $(round(ub_local,4))|")
    end

    return discretization
end


"""
    TODO: docstring
"""
function disc_ratio_branch(m::PODNonlinearModel, presolve=false)

    m.logs[:n_iter] > 2 && return m.disc_ratio # Stop branching after the second iterations

    ratio_pool = [3:1:24;]  # Built-in try range
    convertor = Dict(:Max=>:<, :Min=>:>)

    incumb_ratio = ratio_pool[1]
    m.sense_orig == :Min ? incumb_res = -Inf : incumb_res = Inf
    res_collector = Float64[]

    for r in ratio_pool
        st = time()
        if presolve
            branch_disc = add_adaptive_partition(m, use_disc=m.discretization,
                                                    branching=true,
                                                    use_ratio=r,
                                                    use_solution=m.best_sol)
        else
            branch_disc = add_adaptive_partition(m, use_disc=m.discretization,
                                                    branching=true,
                                                    use_ratio=r)
        end
        create_bounding_mip(m, use_disc=branch_disc)
        res = disc_branch_solve(m)
        push!(res_collector, res)
        if eval(convertor[m.sense_orig])(res, incumb_res) # && abs(abs(collector[end]-res)/collector[end]) > 1e-1  # %1 of difference
            incumb_res = res
            incumb_ratio = r
        end
        println("BRANCH RATIO = $(r), METRIC = $(res) || TIME = $(time()-st)")
    end

    if std(res_collector) >= 1e-2    # Detect if all solution are similar to each other
        println("RATIO BRANCHING OFF due to solution variance test passed.")
        m.disc_ratio_branch = false # If a ratio is selected, then stop the branching scheme
    end

    println("INCUMB_RATIO = $(incumb_ratio)")
    return incumb_ratio
end

function disc_branch_solve(m::PODNonlinearModel)

    # ================= Solve Start ================ #
    update_mip_time_limit(m)
    start_bounding_solve = time()
    status = solve(m.model_mip, suppress_warnings=true)
    cputime_branch_bounding_solve = time() - start_bounding_solve
    m.logs[:total_time] += cputime_branch_bounding_solve
    m.logs[:time_left] = max(0.0, m.timeout - m.logs[:total_time])
    # ================= Solve End ================ #

    if status in [:Optimal, :Suboptimal, :UserLimit]
        return m.model_mip.objBound
    else
        warn("Unexpected solving condition $(status) during disc branching.")
    end

    if m.sense_orig == :Min
        return -Inf
    else
        return Inf
    end
end
