using FEM


FEM.vtkexportmod()
using FEM.VTKExportMod

# Generates a mesh of the shape known as the "Cook membrane"
# Possible mesh elements are GeoTrig for 3 node triangles,
# GeoQTrig for 6 node triangles and GeoQuad for 4 node quadraterials
n_ele = 5
geomesh = gencook(n_ele, n_ele, GeoTrig)


# We create two node sets, one on the right edge and one on the left.
# This is done by giving an anonymous function that is satisfied by
# the edges.

push!(geomesh, gennodeset(n->n.coords[1]>47.999999, "right", geomesh.nodes))
push!(geomesh, gennodeset(n->n.coords[1]<0.00001, "left", geomesh.nodes))

# We create an element set containing all the elements
push!(geomesh, ElementSet("all", collect(1:length(geomesh.elements))))

# We create a material section of a linear isotropic material
# and assigns it to all the elements.
mat_section = MaterialSection(FEM.linearisotropicmod().LinearIsotropic(1, 0.3))
push!(mat_section, geomesh.element_sets["all"])

# We create an element section and assign it to all the
# elements.
ele_section = ElementSection(FEM.lintrigmod().LinTrig)
push!(ele_section, geomesh.element_sets["all"])

# Apply Dirichlet BC to the left side in both x (Du) and y (Dv)
bcs = Any[DirichletBC("0.0", [FEM.Du], geomesh.node_sets["left"]),
       DirichletBC("0.0", [FEM.Dv], geomesh.node_sets["left"])]
# Since we currently don't have edge load we give a nodal load
# on the right node set.
loads = Any[NodeLoad("1/($n_ele+1)", [FEM.Dv], geomesh.node_sets["right"])]



# Create the fe problem
fp = FEM.create_feproblem("cook_example_quad", geomesh, [ele_section], [mat_section], bcs, loads)

# Output fields are added by pushing them into the exporter.
# We want to export the stress and strain so push them.
vtkexp = VTKExporter()
# Output fields are added by pushing them into the exporter
push!(vtkexp, Stress)
push!(vtkexp, Strain)
push!(vtkexp, VonMises)
set_binary!(vtkexp, false)


#solver = FEM.LinSolver()

solver = NRSolver(abs_tol = 1e-2, max_iters = 20)

# Solve the fe problem using the solver and using the vtk exporter.
solve(solver, fp, vtkexp)