@testset "Solving algorithm tests" begin

    @testset " Validation Test || AMP-TMC || basic solve || exampls/nlp1.jl" begin

        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                           bilinear_convexhull=false,
                           monomial_convexhull=false,
                           presolve_bt=false,
                           presolve_bp=true,
                           presolve_bt_output_tol=1e-1,
                           loglevel=10000)
        m = nlp1(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 58.38367169858795; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 7
    end

    @testset " Validation Test || AMP-TMC || basic solve || examples/nlp3.jl (3 iterations)" begin

        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
        					   mip_solver=CbcSolver(logLevel=0),
                               bilinear_convexhull=false,
                               monomial_convexhull=false,
                               presolve_bp=true,
        					   loglevel=100,
                               maxiter=3,
        					   presolve_bt_width_tol=1e-3,
        					   presolve_bt=false,
        					   disc_var_pick=0)
        m = nlp3(solver=test_solver)
        status = solve(m)

        @test status == :UserLimits

        @test isapprox(m.objVal, 7049.247897696512; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 3
    end

    @testset " Validation Test || AMP-TMC || minimum-vertex solving || examples/nlp3.jl (3 iterations)" begin

        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               bilinear_convexhull=false,
                               monomial_convexhull=false,
                               presolve_bp=true,
                               disc_var_pick=1,
                               loglevel=100,
                               maxiter=3,
                               presolve_bt_width_tol=1e-3,
                               presolve_bt=false)
        m = nlp3(solver=test_solver)
        status = solve(m)

        @test status == :UserLimits
        @test isapprox(m.objVal, 7049.247897696512; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 3
        @test isapprox(m.objBound, 3647.178; atol=1e-2)
    end

    @testset " Validation Test || PBT-AMP-TMC || basic solve || exampls/nlp1.jl" begin

        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
    							   mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                                   bilinear_convexhull=false,
                                   monomial_convexhull=false,
    							   presolve_bt=true,
    							   presolve_bt_algo=2,
                                   presolve_bp=true,
                                   presolve_bt_output_tol=1e-1,
    							   loglevel=10000)
        m = nlp1(solver=test_solver)
        status = solve(m)

        # @show m.internalModel.l_var_tight
        # @show m.internalModel.u_var_tight

        @test status == :Optimal
        @test isapprox(m.objVal, 58.38367169858795; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 2
    end

    @testset " Validation Test || BT-AMP-TMC || basic solve || examples/nlp3.jl" begin

        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
    							   mip_solver=CbcSolver(logLevel=0),
                                   bilinear_convexhull=false,
    							   loglevel=10000,
                                   maxiter=3,
    							   presolve_bt_width_tol=1e-3,
    							   presolve_bt_output_tol=1e-1,
    							   presolve_bt=true,
                                   presolve_bt_algo=1,
                                   presolve_bp=true,
    							   presolve_maxiter=2,
                                   presolve_track_time=true,
    							   disc_var_pick=max_cover_var_picker)
        m = nlp3(solver=test_solver)

        status = solve(m)

        @test status == :UserLimits
        @test m.internalModel.logs[:n_iter] == 3
        @test m.internalModel.logs[:bt_iter] == 2
    end

    @testset " Validation Test || PBT-AMP-TMC || basic solve || examples/nlp3.jl" begin

        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                                   mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                                   bilinear_convexhull=false,
                                   loglevel=10000,
                                   maxiter=2,
                                   presolve_bt=true,
                                   presolve_bt_width_tol=1e-3,
                                   presolve_bt_output_tol=1e-1,
                                   presolve_bt_algo=2,
                                   presolve_bp=true,
                                   presolve_maxiter=2,
                                   disc_var_pick=max_cover_var_picker)

        m = nlp3(solver=test_solver)
        status = solve(m)
        @test status == :UserLimits
        @test m.internalModel.logs[:n_iter] == 2
        @test m.internalModel.logs[:bt_iter] == 2
    end

    @testset " Validation Test || AMP-CONV || basic solve || examples/nlp1.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=false,
                           presolve_bp=true,
                           loglevel=10000)
        m = nlp1(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 58.38367169858795; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 7
    end

    @testset " Validation Test || PBT-AMP-CONV || basic solve || examples/nlp1.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=true,
                           presolve_bp=true,
                           presolve_bt_algo=2,
                           loglevel=10000)
        m = nlp1(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 58.38367169858795; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 1
    end

    @testset " Validation Test || AMP-CONV || basic solve || examples/nlp3.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=CbcSolver(logLevel=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=false,
                           presolve_bp=false,
                           loglevel=10000)
        m = nlp3(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 7049.247897696188; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 9
    end

    @testset " Validation Test || AMP || basic solve || examples/circle.jl" begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                               disc_abs_width_tol=1e-2,
                               disc_ratio=8,
                               maxiter=6,
                               presolve_bt = false,
                               presolve_bt_algo = 1,
                               presolve_bt_output_tol = 1e-1,
                               loglevel=10000)

        m = circle(solver=test_solver)
        solve(m)

        @test isapprox(m.objVal, 1.4142135534556992; atol=1e-3)
    end

    @testset " Validation Test || AMP || basic solve || examples/circleN.jl" begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                               disc_abs_width_tol=1e-2,
                               disc_ratio=8,
                               presolve_bt = false,
                               presolve_bt_algo = 1,
                               presolve_bt_output_tol = 1e-1,
                               loglevel=100)

        m = circleN(solver=test_solver, N=4)
        solve(m)
        @test isapprox(m.objVal, 2.0; atol=1e-3)
    end

    @testset " Validation Test || AMP-CONV-FACET || basic solve || examples/nlp3.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=CbcSolver(logLevel=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=false,
                           presolve_bp=false,
                           convhull_formulation="facet",
                           loglevel=10000)
        m = nlp3(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 7049.247897696188; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 9
    end

    @testset " Validation Test || AMP-CONV-MINIB || basic solve || examples/nlp3.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=CbcSolver(logLevel=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=false,
                           presolve_bp=false,
                           convhull_formulation="mini",
                           loglevel=10000)
        m = nlp3(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 7049.247897696188; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 9
    end

    @testset " Validation Test || AMP-CONV-FACET || basic solve || examples/nlp1.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=false,
                           presolve_bp=true,
                           convhull_formulation="facet",
                           loglevel=10000)
        m = nlp1(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 58.38367169858795; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 7
    end

    @testset " Validation Test || AMP-CONV-MINIB || basic solve || examples/nlp1.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=false,
                           presolve_bp=true,
                           convhull_formulation="mini",
                           loglevel=10000)
        m = nlp1(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 58.38367169858795; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 7
    end

    @testset " Validation Test || AMP || multi4N || N = 2 || exprmode=1:11" begin

        objBoundVec = Any[4.68059, 12.0917, 8.94604, 10.0278, 8.10006, 6.6384, 12.5674, 7.39747, 6.02928, 7.91467, 7.88307]
        objValVec = Any[2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0]
        for i in 1:11
            test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                                   mip_solver=CbcSolver(logLevel=0),
                                   disc_abs_width_tol=1e-2,
                                   maxiter=4,
                                   presolve_bp=false,
                                   loglevel=1)

            m = multi4N(solver=test_solver, N=2, exprmode=i)
            status = solve(m)

            @test status == :UserLimits
            @test isapprox(getobjectivevalue(m), objValVec[i];atol=1e-3)
            @test isapprox(getobjectivebound(m), objBoundVec[i];atol=1e-3)
        end
    end

    @testset " Validation Test || AMP || multi2 || exprmode=1:11" begin

        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               disc_abs_width_tol=1e-2,
                               maxiter=4,
                               presolve_bp=false,
                               loglevel=1)

        m = multi2(solver=test_solver)
        status = solve(m)

        @test status == :UserLimits
        @test isapprox(getobjectivevalue(m), 1.00000;atol=1e-3)
        @test isapprox(getobjectivebound(m), 1.0074;atol=1e-3)
    end

    @testset " Validation Test || AMP || multi3N || N = 2 || exprmode=1:11" begin

        objBoundVec = Any[2.97186, 3.85492, 4.23375]
        objValVec = Any[2.0, 2.0, 2.0]
        for i in 1:3
            test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                                   mip_solver=CbcSolver(logLevel=0),
                                   disc_abs_width_tol=1e-2,
                                   maxiter=4,
                                   presolve_bp=false,
                                   loglevel=1)

            m = multi3N(solver=test_solver, N=2, exprmode=i)
            status = solve(m)

            @test status == :UserLimits
            @test isapprox(getobjectivevalue(m), objValVec[i];atol=1e-3)
            @test isapprox(getobjectivebound(m), objBoundVec[i];atol=1e-3)
        end
    end

    @testset " Validation Test || AMP || multiKND || K = 3, N = 3, D = 0 " begin

        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               disc_abs_width_tol=1e-2,
                               maxiter=3,
                               presolve_bp=false,
                               loglevel=1)

        m = multiKND(solver=test_solver, randomub=50, K=3, N=3, D=0)
        status = solve(m)

        @test status == :UserLimits
        @test isapprox(getobjectivevalue(m),3.0000000824779454;atol=1e-3)
        @test isapprox(getobjectivebound(m),12.054604248046875;atol=1e-3)
    end
end

@testset "Solving Algorithm Test :: Featrue selecting delta" begin

    @testset " Validation Test || AMP || DISC-RATIO || examples/nlp3.jl " begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               disc_abs_width_tol=1e-2,
                               disc_ratio_branch=false,
                               disc_ratio=18,
                               maxiter=1,
                               presolve_bp=true,
                               loglevel=100)

        m = nlp3(solver=test_solver)
        solve(m)

        @test m.internalModel.logs[:n_iter] == 1
        @test m.internalModel.disc_ratio == 18
    end

    @testset " Validation Test || AMP || DISC-RATIO-BRANCH || examples/nlp3.jl " begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               disc_abs_width_tol=1e-2,
                               disc_ratio_branch=true,
                               maxiter=1,
                               presolve_bp=true,
                               loglevel=100)

        m = nlp3(solver=test_solver)
        solve(m)

        @test m.internalModel.logs[:n_iter] == 1
        @test m.internalModel.disc_ratio == 14
    end

    @testset " Validation Test || AMP || DISC-RATIO-BRANCH || examples/castro2m2.jl " begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               disc_abs_width_tol=1e-2,
                               disc_ratio_branch=true,
                               maxiter=1,
                               presolve_bp=true,
                               loglevel=100)

        m = castro2m2(solver=test_solver)
        solve(m)

        @test m.internalModel.logs[:n_iter] == 1
        @test m.internalModel.disc_ratio == 8
    end

    @testset " Validation Test || AMP || DISC-RATIO-BRANCH || examples/multi3N.jl exprmode=2" begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               disc_abs_width_tol=1e-2,
                               disc_ratio_branch=true,
                               maxiter=1,
                               presolve_bp=true,
                               loglevel=100)

        m = multi3N(solver=test_solver, N=3, exprmode=1)
        solve(m)

        @test m.internalModel.logs[:n_iter] == 1
        @test m.internalModel.disc_ratio == 17
    end

    @testset " Validation Test || AMP || DISC-RATIO-BRANCH || examples/multi3N.jl exprmode=2" begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               disc_abs_width_tol=1e-2,
                               disc_ratio_branch=true,
                               maxiter=1,
                               presolve_bp=false,
                               loglevel=100)

        m = multi3N(solver=test_solver, N=3, exprmode=1)
        solve(m)

        @test m.internalModel.logs[:n_iter] == 1
        @test m.internalModel.disc_ratio == 24
    end

    @testset " Validation Test || AMP || DISC-RATIO-BRANCH || examples/multi4N.jl exprmode=1" begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               disc_abs_width_tol=1e-2,
                               disc_ratio_branch=true,
                               maxiter=1,
                               presolve_bp=true,
                               loglevel=100)

        m = multi4N(solver=test_solver, N=2, exprmode=1)
        solve(m)

        @test m.internalModel.logs[:n_iter] == 1
        @test m.internalModel.disc_ratio == 13
    end

    @testset " Validation Test || AMP || DISC-RATIO-BRANCH || examples/multi4N.jl exprmode=2" begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               disc_abs_width_tol=1e-2,
                               disc_ratio_branch=true,
                               maxiter=1,
                               presolve_bp=false,
                               loglevel=100)

        m = multi4N(solver=test_solver, N=2, exprmode=1)
        solve(m)

        @test m.internalModel.logs[:n_iter] == 1
        @test m.internalModel.disc_ratio == 24
    end

    @testset " Validation Test || AMP || DISC-RATIO-BRANCH || examples/multi4N.jl exprmode=2" begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               disc_abs_width_tol=1e-2,
                               disc_ratio_branch=true,
                               maxiter=1,
                               presolve_bp=true,
                               loglevel=100)

        m = multi4N(solver=test_solver, N=2, exprmode=2)
        solve(m)

        @test m.internalModel.logs[:n_iter] == 1
        @test m.internalModel.disc_ratio == 24
    end
end

@testset "Solving algorithm tests :: Bin-Lin Solves" begin
    @testset "Operator :: bmpl && linbin && binprod solve test I" begin
        test_solver=PODSolver(minlp_local_solver=PajaritoSolver(mip_solver=CbcSolver(logLevel=0),
                                                              cont_solver=IpoptSolver(),
                                                              log_level=0),
                              nlp_local_solver=IpoptSolver(),
                              mip_solver=CbcSolver(logLevel=0),
                              loglevel=10000)

        m = bpml_lnl(test_solver)
        solve(m)
        @test isapprox(m.objVal, 0.3; atol=1e-6)
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[1]), :(x[6])])
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[2]), :(x[7])])
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[3]), :(x[8])])
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[4]), :(x[9])])
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[5]), :(x[10])])

        @test m.internalModel.nonlinear_terms[Expr[:(x[1]), :(x[6])]][:nonlinear_type] == :binlin
        @test m.internalModel.nonlinear_terms[Expr[:(x[2]), :(x[7])]][:nonlinear_type] == :binlin
        @test m.internalModel.nonlinear_terms[Expr[:(x[3]), :(x[8])]][:nonlinear_type] == :binlin
        @test m.internalModel.nonlinear_terms[Expr[:(x[4]), :(x[9])]][:nonlinear_type] == :binlin
        @test m.internalModel.nonlinear_terms[Expr[:(x[5]), :(x[10])]][:nonlinear_type] == :binlin
    end

    @testset "Operator :: bmpl && linbin && binprod solve test II" begin
        test_solver=PODSolver(minlp_local_solver=PajaritoSolver(mip_solver=CbcSolver(logLevel=0),
                                                              cont_solver=IpoptSolver(),
                                                              log_level=0),
                              nlp_local_solver=IpoptSolver(),
                              mip_solver=CbcSolver(logLevel=0),
                              loglevel=10000)

        m = bpml_binl(test_solver)
        solve(m)
        @test isapprox(m.objVal, 15422.058099086951; atol=1e-4)

        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[6]), :(x[7])])
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[7]), :(x[8])])
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[8]), :(x[9])])
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[9]), :(x[10])])
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[10]), :(x[6])])
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[11]), :(x[1])])
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[13]), :(x[2])])
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[15]), :(x[3])])
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[17]), :(x[4])])
        @test haskey(m.internalModel.nonlinear_terms, Expr[:(x[19]), :(x[5])])

        @test m.internalModel.nonlinear_terms[Expr[:(x[6]), :(x[7])]][:nonlinear_type] == :bilinear
        @test m.internalModel.nonlinear_terms[Expr[:(x[7]), :(x[8])]][:nonlinear_type] == :bilinear
        @test m.internalModel.nonlinear_terms[Expr[:(x[8]), :(x[9])]][:nonlinear_type] == :bilinear
        @test m.internalModel.nonlinear_terms[Expr[:(x[9]), :(x[10])]][:nonlinear_type] == :bilinear
        @test m.internalModel.nonlinear_terms[Expr[:(x[10]), :(x[6])]][:nonlinear_type] == :bilinear
        @test m.internalModel.nonlinear_terms[Expr[:(x[11]), :(x[1])]][:nonlinear_type] == :binlin
        @test m.internalModel.nonlinear_terms[Expr[:(x[13]), :(x[2])]][:nonlinear_type] == :binlin
        @test m.internalModel.nonlinear_terms[Expr[:(x[15]), :(x[3])]][:nonlinear_type] == :binlin
        @test m.internalModel.nonlinear_terms[Expr[:(x[17]), :(x[4])]][:nonlinear_type] == :binlin
        @test m.internalModel.nonlinear_terms[Expr[:(x[19]), :(x[5])]][:nonlinear_type] == :binlin
    end

    @testset "Operator :: bmpl && linbin && binprod solve test II" begin
        test_solver=PODSolver(minlp_local_solver=PajaritoSolver(mip_solver=CbcSolver(logLevel=0),
                                                              cont_solver=IpoptSolver(),
                                                              log_level=0),
                              nlp_local_solver=IpoptSolver(),
                              mip_solver=PajaritoSolver(mip_solver=CbcSolver(logLevel=0),
                                                        cont_solver=IpoptSolver(),
                                                        log_level=0),
                              disc_var_pick=1,
                              loglevel=10000)

        m = bpml_monl(test_solver)
        solve(m)

        @test isapprox(m.objVal, 19812.920945096557;atol=1e-4)
        @test isapprox(m.objBound, 19812.9205;atol=1e-3)

        nlk1 = Expr[:(x[9]), :(x[9])]
        nlk2 = Expr[:(x[10]), :(x[10])]
        nlk3 = Expr[:(x[8]), :(x[8])]
        nlk4 = Expr[:(x[15]), :(x[3])]
        nlk5 = Expr[:(x[6]), :(x[6])]
        nlk6 = Expr[:(x[13]), :(x[2])]
        nlk7 = Expr[:(x[17]), :(x[4])]
        nlk8 = Expr[:(x[19]), :(x[5])]
        nlk9 = Expr[:(x[7]), :(x[7])]
        nlk10 = Expr[:(x[11]), :(x[1])]

        @test m.internalModel.nonlinear_terms[nlk1][:id] == 7
        @test m.internalModel.nonlinear_terms[nlk2][:id] == 9
        @test m.internalModel.nonlinear_terms[nlk3][:id] == 5
        @test m.internalModel.nonlinear_terms[nlk4][:id] == 6
        @test m.internalModel.nonlinear_terms[nlk5][:id] == 1
        @test m.internalModel.nonlinear_terms[nlk6][:id] == 4
        @test m.internalModel.nonlinear_terms[nlk7][:id] == 8
        @test m.internalModel.nonlinear_terms[nlk8][:id] == 10
        @test m.internalModel.nonlinear_terms[nlk9][:id] == 3
        @test m.internalModel.nonlinear_terms[nlk10][:id] == 2

        @test m.internalModel.nonlinear_terms[nlk1][:y_idx] == 17
        @test m.internalModel.nonlinear_terms[nlk2][:y_idx] == 19
        @test m.internalModel.nonlinear_terms[nlk3][:y_idx] == 15
        @test m.internalModel.nonlinear_terms[nlk4][:y_idx] == 16
        @test m.internalModel.nonlinear_terms[nlk5][:y_idx] == 11
        @test m.internalModel.nonlinear_terms[nlk6][:y_idx] == 14
        @test m.internalModel.nonlinear_terms[nlk7][:y_idx] == 18
        @test m.internalModel.nonlinear_terms[nlk8][:y_idx] == 20
        @test m.internalModel.nonlinear_terms[nlk9][:y_idx] == 13
        @test m.internalModel.nonlinear_terms[nlk10][:y_idx] == 12

        @test m.internalModel.nonlinear_terms[nlk1][:nonlinear_type] == :monomial
        @test m.internalModel.nonlinear_terms[nlk2][:nonlinear_type] == :monomial
        @test m.internalModel.nonlinear_terms[nlk3][:nonlinear_type] == :monomial
        @test m.internalModel.nonlinear_terms[nlk4][:nonlinear_type] == :binlin
        @test m.internalModel.nonlinear_terms[nlk5][:nonlinear_type] == :monomial
        @test m.internalModel.nonlinear_terms[nlk6][:nonlinear_type] == :binlin
        @test m.internalModel.nonlinear_terms[nlk7][:nonlinear_type] == :binlin
        @test m.internalModel.nonlinear_terms[nlk8][:nonlinear_type] == :binlin
        @test m.internalModel.nonlinear_terms[nlk9][:nonlinear_type] == :monomial
        @test m.internalModel.nonlinear_terms[nlk10][:nonlinear_type] == :binlin
    end
end

@testset "Solving algorithm tests :: Embedding Formulation" begin
    @testset "Embedding Test || AMP-CONV || basic solve || examples/nlp1.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=false,
                           presolve_bp=true,
                           convhull_ebd=true,
                           loglevel=100)
        m = nlp1(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 58.38367169858795; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 7
    end

    @testset "Embedding Test || PBT-AMP-CONV || basic solve || examples/nlp1.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=true,
                           presolve_bp=true,
                           presolve_bt_algo=2,
                           convhull_ebd=true,
                           loglevel=100)
        m = nlp1(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 58.38367169858795; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 1
    end

    @testset "Embedding Test || AMP-CONV || basic solve || examples/nlp3.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=CbcSolver(logLevel=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=false,
                           presolve_bp=false,
                           convhull_ebd=true,
                           loglevel=100)
        m = nlp3(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 7049.247897696188; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 9
    end

    @testset "Embedding Test || AMP || special problem || ... " begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                               disc_abs_width_tol=1e-2,
                               disc_ratio=8,
                               maxiter=6,
                               presolve_bt=false,
                               presolve_bp=true,
                               presolve_bt_algo=1,
                               presolve_bt_output_tol=1e-1,
                               convhull_ebd=true,
                               loglevel=10000)

        m = circle(solver=test_solver)
        solve(m)
        @test isapprox(m.objVal, 1.4142135534556992; atol=1e-3)
    end

    @testset "Embedding IBS Test || AMP-CONV || basic solve || examples/nlp1.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=false,
                           presolve_bp=true,
                           convhull_ebd=true,
                           convhull_ebd_ibs=true,
                           loglevel=100)
        m = nlp1(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 58.38367169858795; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 7
    end

    @testset "Embedding IBS Test || AMP-CONV || basic solve || examples/nlp3.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=CbcSolver(logLevel=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=false,
                           presolve_bp=false,
                           convhull_ebd=true,
                           convhull_ebd_ibs=true,
                           loglevel=100)
        m = nlp3(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 7049.247897696188; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 9
    end

    @testset "Embedding IBS Test || AMP || special problem || ... " begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                               disc_abs_width_tol=1e-2,
                               disc_ratio=8,
                               maxiter=6,
                               presolve_bt=false,
                               presolve_bp=true,
                               presolve_bt_algo=1,
                               presolve_bt_output_tol=1e-1,
                               convhull_ebd=true,
                               convhull_ebd_ibs=true,
                               loglevel=10000)

        m = circle(solver=test_solver)
        solve(m)
        @test isapprox(m.objVal, 1.4142135534556992; atol=1e-3)
    end

    @testset "Embedding LINK Test || AMP-CONV || basic solve || examples/nlp1.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=false,
                           presolve_bp=true,
                           convhull_ebd=true,
                           convhull_ebd_link=true,
                           loglevel=100)
        m = nlp1(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 58.38367169858795; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 7
    end

    @testset "Embedding LINK Test || AMP-CONV || basic solve || examples/nlp3.jl" begin
        test_solver = PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                           mip_solver=CbcSolver(logLevel=0),
                           bilinear_convexhull=true,
                           monomial_convexhull=true,
                           presolve_bt=false,
                           presolve_bp=false,
                           convhull_ebd=true,
                           convhull_ebd_link=true,
                           loglevel=100)
        m = nlp3(solver=test_solver)
        status = solve(m)

        @test status == :Optimal
        @test isapprox(m.objVal, 7049.247897696188; atol=1e-4)
        @test m.internalModel.logs[:n_iter] == 9
    end

    @testset "Embedding LINK Test || AMP || special problem || ... " begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                               disc_abs_width_tol=1e-2,
                               disc_ratio=8,
                               maxiter=6,
                               presolve_bt=false,
                               presolve_bp=true,
                               presolve_bt_algo=1,
                               presolve_bt_output_tol=1e-1,
                               convhull_ebd=true,
                               convhull_ebd_link=true,
                               loglevel=10000)

        m = circle(solver=test_solver)
        solve(m)
        @test isapprox(m.objVal, 1.4142135534556992; atol=1e-3)
    end
end

@testset "Algorithm Logic Tests" begin
    @testset "Algorithm Logic Test || castro4m2 || 1 iteration || Error case" begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               maxiter=1,
                               colorful_pod="warmer",
                               loglevel=100)

        m = castro4m2(solver=test_solver)
        e = nothing
        try
            solve(m)
        catch e
            println("Expected error.")
        end
        @test e.msg == "NLP local solve is Error - quitting solve."
        @test m.internalModel.status[:local_solve] == :Error

    end

    @testset " Algorithm Logic Test || blend029_gl || 3 iterations || Infeasible Case" begin

        test_solver=PODSolver(minlp_local_solver=PajaritoSolver(cont_solver=IpoptSolver(print_level=0), mip_solver=CbcSolver(logLevel=0), log_level=0),
                              nlp_local_solver=IpoptSolver(print_level=0),
                              mip_solver=CbcSolver(logLevel=0),
                              presolve_bp=true,
                              disc_var_pick=1,
                              loglevel=100,
                              maxiter=3,
                              presolve_bt_width_tol=1e-3,
                              presolve_bt=false)
        m = blend029_gl(solver=test_solver)
        status = solve(m)

        @test status == :UserLimits
        @test m.internalModel.logs[:n_iter] == 3
        @test getobjbound(m) <= 14.0074
    end
end

@testset "Algorithm Special Test" begin
    @testset "Convex Model Solve" begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               maxiter=1,
                               colorful_pod="solarized",
                               loglevel=100)
        m = convex_solve(solver=test_solver)
        e = nothing
        try
            solve(m)
        catch e
            @test e.msg == "Solver does not support quadratic objectives"
        end
    end

    @testset "Uniform partitioning" begin
        test_solver=PODSolver(nlp_local_solver=IpoptSolver(print_level=0),
                               mip_solver=CbcSolver(logLevel=0),
                               disc_add_partition_method = "uniform",
                               disc_uniform_rate = 10,
                               maxiter=1,
                               colorful_pod="random",
                               timeout=100000,
                               loglevel=100)
        m = nlp3(solver=test_solver)
        solve(m)
        @test isapprox(m.objBound, 6561.7156;atol=1e-3)
    end
end
