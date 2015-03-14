immutable BilinQuad <: Element
    vertices::Vertex4
    gps::Vector{GaussPoint2}
    n_dofs::Int
    n::Int
    interp::BilinQuadInterp
end


function BilinQuad(vertices::Vertex4, n)

    n_dofs = 8

    p = 1 / sqrt(3)
    gps = [GaussPoint2(Point2(-p, -p), 1.0);
           GaussPoint2(Point2( p, -p), 1.0);
           GaussPoint2(Point2( p,  p), 1.0);
           GaussPoint2(Point2(-p,  p), 1.0)]


    interp = BilinQuadInterp()

    BilinQuad(vertices, gps, n_dofs, n, interp)
end


function doftypes(elem::BilinQuad, vertex::Int)
    return [Du, Dv]
end


function Bmatrix(elem::BilinQuad, gp::GaussPoint2, nodes::Vector{Node2})
    dNdx = dNdxmatrix(elem.interp, gp.local_coords, elem.vertices, nodes)
    B = zeros(4, 8)

    for i in 1:4
        B[1, 2 * i - 1] = dNdx[i, 1]
        B[2, 2 * i]     = dNdx[i, 2]

        B[4, 2 * i - 1] = dNdx[i, 2]
        B[4, 2 * i]     = dNdx[i, 1]
    end
    return B
end


