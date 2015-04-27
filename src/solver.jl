abstract Solver

immutable NRSolver <: Solver
    tol::Float64
    max_iters::Int
end

function solve(solver::NRSolver, fp::FEProblem, exporter::AbstractDataExporter)
    println("Starting Newton-Raphson solver..")
    load = extload(fp)
    tstep = 0
    n_print = 0

    gu1 = Array(Int, 0)
    gv1 = Array(Int, 0)
    gu2 = Array(Int, 0)
    gv2 = Array(Int, 0)
    du = Array(Int, 0)
    dv = Array(Int, 0)
    for node in fp.nodes
        for dof in node.dofs
            if dof.active
                if dof.dof_type == Du
                    push!(du, dof.eq_n)
                elseif dof.dof_type == Dv
                    push!(dv, dof.eq_n)
                elseif dof.dof_type == Gu1
                    push!(gu1, dof.eq_n)
                elseif dof.dof_type == Gv1
                    push!(gv1, dof.eq_n)
                elseif dof.dof_type == Gu2
                    push!(gu2, dof.eq_n)
                elseif dof.dof_type == Gv2
                    push!(gv2, dof.eq_n)
                end
            end
        end
    end

    dofferinos = [(Du, du), (Dv, dv), (Gu1, gu1), (Gv1, gv1), (Gu2, gu2), (Gv2, gv2)]


    for t in 0:2.0/1000.0:2.0
        println("Current time $t")
        iteration = 0
        tstep += 1
        updatebcs!(fp, t)
        while true
            iteration += 1
            if iteration > solver.max_iters
                warn("Max iterations hit.")
                break
            end

            int_f = assemble_intf(fp)
            force_imbalance = - int_f


            #display(force_imbalance)

            #residual = norm(force_imbalance) / norm(load)
            #if norm(load) < 1.00^(-15)
                residual = norm(int_f)
           # else
           #     residual = norm(force_imbalance) / norm(load)
           # end


            println("\n\t\tIteration $iteration, relative residual $residual")

            println("\n Residual:")
            for dof in dofferinos
                @printf("%s: %1.2e   \n", dof[1], norm(int_f[dof[2]]))
            end

            if residual < solver.tol
                println("Converged!")
                break
            end


            K = assembleK(fp)

            #du = cholfact(Symmetric(K, :L)) \ force_imbalance

            du = K \ force_imbalance


            println("\nUpdated:")
            for dof in dofferinos
                @printf("%s: %1.2e   \n", dof[1], norm(du[dof[2]]))
            end

            updatedofs!(fp, du)

        end

        update_feproblem(fp)
        if (tstep % 5 == 0)
            n_print += 1
            write_data(fp, exporter, n_print)
        end
    end
end

