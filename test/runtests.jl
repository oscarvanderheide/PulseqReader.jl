using Test
using PulseqReader

import PulseqReader: decode, Shape

@testset "Check decoding of shapes from Pulseq documentation" begin

    compressed_shape = Shape(100, [0, 0, 98])
    uncompressed_samples = zeros(100)
    @test decode(compressed_shape).samples == uncompressed_samples

    compressed_shape = Shape(100, [1, 0, 0, 97])
    uncompressed_samples = ones(100)
    @test decode(compressed_shape).samples == uncompressed_samples

    compressed_shape = Shape(
        15,
        [0.0, 0.1, 0.15, 0.25, 0.5, 0.0, 0.0, 4.0, -0.25, -0.25, 2.0]
    )
    uncompressed_samples =
        [0.0, 0.1, 0.25, 0.5, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.75, 0.5, 0.25, 0.0]

    @test decode(compressed_shape).samples == uncompressed_samples
end