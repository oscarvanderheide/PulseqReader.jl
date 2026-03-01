"""
    parse_version_section(lines)

Parses the [VERSION] section of the sequence file into Julia's built-in
`VersionNumber` type.
"""
function parse_version_section(lines)
    section_content = get_section(lines, "VERSION")
    format_string, types = get_scanf_args("VERSION")
    _, version_values... = scanf(section_content, format_string, types...)
    return VersionNumber(version_values...)
end

"""
    parse_definitions_section(lines)

Parses the [DEFINITIONS] section of the sequence file.
"""
function parse_definitions_section(lines)
    section_content = get_section(lines, "DEFINITIONS")
    format_string, types = get_scanf_args("DEFINITIONS")
    _, definition_values... = scanf(section_content, format_string, types...)
    return Definitions(definition_values...)
end

"""
    parse_blocks_section(lines)

Parses the [BLOCKS] section of the sequence file into a `StructArray` of `Block`
structs.
"""
function parse_blocks_section(lines)
    section_lines = get_section(lines, "BLOCKS")
    n = length(section_lines)

    # Pre-allocate column arrays
    dur = Vector{Int}(undef, n)
    rf  = Vector{Int}(undef, n)
    gx  = Vector{Int}(undef, n)
    gy  = Vector{Int}(undef, n)
    gz  = Vector{Int}(undef, n)
    adc = Vector{Int}(undef, n)
    delay = Vector{Int}(undef, n)
    ext = Vector{Int}(undef, n)

    for i in 1:n
        parts = split(section_lines[i])
        np = length(parts)
        # Skip first column (block index), parse remaining fields, pad with 0
        dur[i]   = np >= 2 ? parse(Int, parts[2]) : 0
        rf[i]    = np >= 3 ? parse(Int, parts[3]) : 0
        gx[i]    = np >= 4 ? parse(Int, parts[4]) : 0
        gy[i]    = np >= 5 ? parse(Int, parts[5]) : 0
        gz[i]    = np >= 6 ? parse(Int, parts[6]) : 0
        adc[i]   = np >= 7 ? parse(Int, parts[7]) : 0
        delay[i] = np >= 8 ? parse(Int, parts[8]) : 0
        ext[i]   = np >= 9 ? parse(Int, parts[9]) : 0
    end

    return StructArray{Block}((dur, rf, gx, gy, gz, adc, delay, ext))
end

"""
    parse_rf_section(lines)

Parses the [RF] section of the sequence file into a `StructArray` of `RF`
structs.
"""
function parse_rf_section(lines)
    section_lines = get_section(lines, "RF")
    n = length(section_lines)

    amplitude     = Vector{Hz}(undef, n)
    mag_id        = Vector{Int}(undef, n)
    phase_id      = Vector{Int}(undef, n)
    time_shape_id = Vector{Int}(undef, n)
    delay         = Vector{μs}(undef, n)
    freq          = Vector{Hz}(undef, n)
    phase         = Vector{rad}(undef, n)

    for i in 1:n
        parts = split(section_lines[i])
        amplitude[i]     = Hz(parse(Float64, parts[2]))
        mag_id[i]        = parse(Int, parts[3])
        phase_id[i]      = parse(Int, parts[4])
        time_shape_id[i] = parse(Int, parts[5])
        delay[i]         = μs(parse(Float64, parts[6]))
        freq[i]          = Hz(parse(Float64, parts[7]))
        phase[i]         = rad(parse(Float64, parts[8]))
    end

    return StructArray{RF}((amplitude, mag_id, phase_id, time_shape_id, delay, freq, phase))
end

"""
    parse_trap_section(lines)

Parses the [TRAP] section of the sequence file into a `StructArray` of `TRAP`
structs.
"""
function parse_trap_section(lines)
    section_lines = get_section(lines, "TRAP")
    n = length(section_lines)

    amplitude = Vector{Hzm⁻¹}(undef, n)
    rise      = Vector{μs}(undef, n)
    flat      = Vector{μs}(undef, n)
    fall      = Vector{μs}(undef, n)
    delay     = Vector{μs}(undef, n)

    for i in 1:n
        parts = split(section_lines[i])
        amplitude[i] = Hzm⁻¹(parse(Float64, parts[2]))
        rise[i]      = μs(parse(Float64, parts[3]))
        flat[i]      = μs(parse(Float64, parts[4]))
        fall[i]      = μs(parse(Float64, parts[5]))
        delay[i]     = μs(parse(Float64, parts[6]))
    end

    return StructArray{TRAP}((amplitude, rise, flat, fall, delay))
end

"""
    parse_adc_section(lines)

Parses the [ADC] section of the sequence file into a `StructArray` of `ADC`
structs.
"""
function parse_adc_section(lines)
    section_lines = get_section(lines, "ADC")
    n = length(section_lines)

    num   = Vector{Int}(undef, n)
    dwell = Vector{ns}(undef, n)
    delay = Vector{μs}(undef, n)
    freq  = Vector{Hz}(undef, n)
    phase = Vector{rad}(undef, n)

    for i in 1:n
        parts = split(section_lines[i])
        num[i]   = parse(Int, parts[2])
        dwell[i] = ns(parse(Float64, parts[3]))
        delay[i] = μs(parse(Float64, parts[4]))
        freq[i]  = Hz(parse(Float64, parts[5]))
        phase[i] = rad(parse(Float64, parts[6]))
    end

    return StructArray{ADC}((num, dwell, delay, freq, phase))
end

"""
    parse_extensions_section(lines)

Parses the [EXTENSIONS] section of the sequence file into a `StructArray` of
`Extension` structs.
"""
function parse_extensions_section(lines)
    section_lines = get_section(lines, "EXTENSIONS")

    type    = Int[]
    ref     = Int[]
    next_id = Int[]

    for line in section_lines
        parts = split(line)
        np = length(parts)
        np >= 3 || continue
        # First column must be numeric (skip "extension LABELSET ..." lines)
        tryparse(Int, parts[1]) === nothing && continue

        v2 = something(tryparse(Int, parts[2]), 0)
        v3 = np >= 3 ? something(tryparse(Int, parts[3]), 0) : 0
        v4 = np >= 4 ? something(tryparse(Int, parts[4]), 0) : 0

        push!(type,    v2)
        push!(ref,     v3)
        push!(next_id, v4)
    end

    return StructArray{Extension}((type, ref, next_id))
end

"""
    parse_shapes_section(lines)

Parses the [SHAPES] section of the sequence file into a `StructArray` of `Shape`
structs.
"""
function parse_shapes_section(lines)
    section_lines = get_section(lines, "SHAPES")
    shapes = Shape[]

    # Find indices of lines containing "shape_id"
    shape_id_indices = findall(startswith("shape_id"), section_lines)
    num_shapes = length(shape_id_indices)


    for i = 1:num_shapes
        # Extract shape_id
        shape_id_line = section_lines[shape_id_indices[i]]
        _, shape_id_str = split(strip(shape_id_line))
        shape_id = parse(Int, shape_id_str)

        # Extract num_samples from the next line
        num_samples_line = section_lines[shape_id_indices[i]+1]
        _, num_samples_str = split(strip(num_samples_line))
        num_samples = parse(Int, num_samples_str)

        # Parse sample values
        start_samples = shape_id_indices[i] + 2
        end_samples =
            i < num_shapes ? shape_id_indices[i+1] - 1 : length(section_lines)

        samples = [
            parse(Float64, strip(section_lines[j])) for
            j = start_samples:end_samples
        ]

        push!(shapes, Shape(num_samples, samples))
    end

    return StructArray(shapes)
end
