module PulseqReader

using Scanf
using StructArrays
using StyledStrings
using Unitful
using UnicodePlots

const μs = typeof(1.0u"μs")
const ns = typeof(1.0u"ns")
const Hz = typeof(1.0u"Hz")
const rad = typeof(1.0u"rad")
const Hzm⁻¹ = typeof(1.0u"Hz/m")

include("types.jl")
include("utils.jl")
include("section_parsers.jl")

"""
    read_pulseq(filename::String)

Reads a Pulseq sequence file and returns a `Sequence` object containing the parsed data.

Note that this function does not check integrity or validity of the .seq file.
It does not do any processing either: it's intended to make the contents of the
.seq file available within Julia with a convenient syntax.

# Example usage:

```julia
# Load .seq file
filename = "path/to/your/sequence.seq"
seq = read_pulseq(filename)

# Get amplitude of a single RF event
seq.rf[1].amplitude

# Get amplitude of all RF events (made possible by using StructArrays.jl)
seq.rf.amplitude
```
"""
function read_pulseq(filename::String)

    lines = readlines(filename)

    version = parse_version_section(lines)

    if version < v"1.4"
        @warn "This code was written assuming Pulseq version >= v1.4."
    end

    return Sequence(
        parse_version_section(lines),
        parse_definitions_section(lines),
        parse_blocks_section(lines),
        parse_trap_section(lines),
        parse_rf_section(lines),
        parse_adc_section(lines),
        parse_extensions_section(lines),
        parse_shapes_section(lines),
    )
end

#! format: off
# JuliaFormatter somehow doesn't properly recognize the public keyword as of yet
public read_pulseq
#! format: on

end