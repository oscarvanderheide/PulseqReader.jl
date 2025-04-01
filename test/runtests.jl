using Test
using PulseqReader

import PulseqReader: decode, Shape

function get_example_seq()

    example_seq_str = """
    # Pulseq sequence file
    # Created by PyPulseq

    [VERSION]
    major 1
    minor 4
    revision 2

    [DEFINITIONS]
    AdcRasterTime 1e-07 
    BlockDurationRaster 1e-05 
    GradientRasterTime 1e-05 
    RadiofrequencyRasterTime 1e-06 
    TotalDuration 217.6272 

    # Format of blocks:
    # NUM DUR RF  GX  GY  GZ  ADC  EXT
    [BLOCKS]
    1 1036   1   0   0   0  0  0
    2 1084   0   0   0   1  0  0

    # Format of RF events:
    # id amplitude mag_id phase_id time_shape_id delay freq phase
    # ..        Hz   ....     ....          ....    us   Hz   rad
    [RF]
    1      563.681 1 2 3 100 0 0
    2      91.6859 4 5 6 100 0 6.2484

    # Format of trapezoid gradients:
    # id amplitude rise flat fall delay
    # ..      Hz/m   us   us   us    us
    [TRAP]
    1  1.14958e+06 400 10040 400   0
    2      -675676 200  540 200   0

    # Format of ADC events:
    # id num dwell delay freq phase
    # ..  ..    ns    us   Hz   rad
    [ADC]
    1 448 7721 50 0 6.2484
    2 448 7721 50 0 6.17907

    # Format of extension lists:
    # id type ref next_id
    # next_id of 0 terminates the list
    # Extension list is followed by extension specifications
    [EXTENSIONS]
    1 1 1 0
    2 1 2 1
    3 1 3 2

    # Extension specification for setting labels:
    # id set labelstring
    extension LABELSET 1
    1 -111 PAR
    2 -101 LIN
    3 0 ECO

    # Sequence Shapes
    [SHAPES]

    shape_id 1
    num_samples 4
    0.1
    0.2
    0.3
    0.4

    shape_id 2
    num_samples 1024
    0.5
    0.5

    shape_id 3
    num_samples 1024
    5
    10
    10
    1021

    shape_id 4
    num_samples 2
    1
    1

    shape_id 5
    num_samples 2
    0
    0

    shape_id 6
    num_samples 2
    0
    120


    [SIGNATURE]
    # This is the hash of the Pulseq file, calculated right before the [SIGNATURE] section was added
    # It can be reproduced/verified with md5sum if the file trimmed to the position right above [SIGNATURE]
    # The new line character preceding [SIGNATURE] BELONGS to the signature (and needs to be stripped away for recalculating/verification)
    Type md5
    Hash 6c397e92e115794b4c947a4ba5c28a3e
    """

    path_tmp, io_tmp = mktemp()
    write(io_tmp, example_seq_str)
    close(io_tmp) # Ensure data is flushed and file is closed before reading
    # Now call your original function with the temp file path
    seq = PulseqReader.read_pulseq(path_tmp) # Assuming this is your function

    return seq
end

seq = get_example_seq();

@testset "Test parsing of [VERSION] section" begin
    @test seq.version == v"1.4.2"
end

@testset "Test parsing of [DEFINITIONS] section" begin
    @test seq.definitions.AdcRasterTime == 1e-7
    @test seq.definitions.BlockDurationRaster == 1e-5
    @test seq.definitions.GradientRasterTime == 1e-5
    @test seq.definitions.RadiofrequencyRasterTime == 1e-6
    @test seq.definitions.TotalDuration == 217.6272
end

@testset "Test parsing of [BLOCKS] section" begin
    @test length(seq.blocks) == 2
    @test seq.blocks[1].dur == 1036
    @test seq.blocks[1].rf == 1
    @test seq.blocks[1].gx == 0
    @test seq.blocks[1].gy == 0
    @test seq.blocks[1].gz == 0
    @test seq.blocks[1].adc == 0
    @test seq.blocks[1].delay == 0
    @test seq.blocks[1].ext == 0

    @test seq.blocks[2].dur == 1084
    @test seq.blocks[2].rf == 0
    @test seq.blocks[2].gx == 0
    @test seq.blocks[2].gy == 0
    @test seq.blocks[2].gz == 1
    @test seq.blocks[2].adc == 0
    @test seq.blocks[2].delay == 0
    @test seq.blocks[2].ext == 0
end

@testset "Test parsing of [RF] section" begin
    @test length(seq.rf) == 2
    @test seq.rf[1].amplitude.val == 563.681
    @test seq.rf[1].mag_id == 1
    @test seq.rf[1].phase_id == 2
    @test seq.rf[1].time_shape_id == 3
    @test seq.rf[1].delay.val == 100.0
    @test seq.rf[1].freq.val == 0.0
    @test seq.rf[1].phase.val == 0.0
    @test seq.rf[2].amplitude.val == 91.6859
    @test seq.rf[2].mag_id == 4
    @test seq.rf[2].phase_id == 5
    @test seq.rf[2].time_shape_id == 6
    @test seq.rf[2].delay.val == 100
    @test seq.rf[2].freq.val == 0.0
    @test seq.rf[2].phase.val == 6.2484
end

@testset "Test parsing of [TRAP] section" begin
    @test length(seq.trap) == 2
    @test seq.trap[1].amplitude.val == 1.14958e6
    @test seq.trap[1].rise.val == 400.0
    @test seq.trap[1].flat.val == 10040.0
    @test seq.trap[1].fall.val == 400.0
    @test seq.trap[1].delay.val == 0
    @test seq.trap[2].amplitude.val == -675676.0
    @test seq.trap[2].rise.val == 200.0
    @test seq.trap[2].flat.val == 540.0
    @test seq.trap[2].fall.val == 200.0
    @test seq.trap[2].delay.val == 0.0
end

@testset "Test parsing of [ADC] section" begin
    @test length(seq.adc) == 2
    @test seq.adc[1].num == 448
    @test seq.adc[1].dwell.val == 7721.0
    @test seq.adc[1].delay.val == 50.0
    @test seq.adc[1].freq.val == 0.0
    @test seq.adc[1].phase.val == 6.2484
    @test seq.adc[2].num == 448
    @test seq.adc[2].dwell.val == 7721.0
    @test seq.adc[2].delay.val == 50.0
    @test seq.adc[2].freq.val == 0.0
    @test seq.adc[2].phase.val == 6.17907
end

# @testset "Test parsing of [EXTENSIONS] section" begin

#     @test length(seq.extensions) == 3
#     @test seq.extensions[1].type == 1
#     @test seq.extensions[1].ref == 1
#     @test seq.extensions[1].next_id == 0
#     @test seq.extensions[2].type == 1
#     @test seq.extensions[2].ref == 2
#     @test seq.extensions[2].next_id == 1
#     @test seq.extensions[3].type == 1
#     @test seq.extensions[3].ref == 3
#     @test seq.extensions[3].next_id == 2

#     # # Test extension labels
#     # @test seq.extensions.labels[1].id == 1
#     # @test seq.extensions.labels[1].label == "PAR"
#     # @test seq.extensions.labels[2].id == 2
#     # @test seq.extensions.labels[2].label == "LIN"
#     # @test seq.extensions.labels[3].id == 3
#     # @test seq.extensions.labels[3].label == "ECO"
# end

@testset "Test parsing of [SHAPES] section" begin
    @test length(seq.shapes) == 6
    @test seq.shapes[1].num_samples == 4
    @test seq.shapes[1].samples == [0.1, 0.2, 0.3, 0.4]
    @test seq.shapes[2].num_samples == 1024
    @test seq.shapes[2].samples == [0.5, 0.5]
    @test seq.shapes[3].num_samples == 1024
    @test seq.shapes[3].samples == [5, 10, 10, 1021]
    @test seq.shapes[4].num_samples == 2
    @test seq.shapes[4].samples == [1, 1]
    @test seq.shapes[5].num_samples == 2
    @test seq.shapes[5].samples == [0, 0]
    @test seq.shapes[6].num_samples == 2
    @test seq.shapes[6].samples == [0, 120]
end


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