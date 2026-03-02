"""
    parse_version_section(lines, idx)

Parses the [VERSION] section of the sequence file into Julia's built-in
`VersionNumber` type.
"""
function parse_version_section(lines, idx)
    section_content = get_section(lines, idx["VERSION"], true)
    format_string, types = get_scanf_args("VERSION")
    _, version_values... = scanf(section_content, format_string, types...)
    return VersionNumber(version_values...)
end

"""
    parse_definitions_section(lines, idx)

Parses the [DEFINITIONS] section of the sequence file.
"""
function parse_definitions_section(lines, idx)
    section_content = get_section(lines, idx["DEFINITIONS"], true)
    format_string, types = get_scanf_args("DEFINITIONS")
    _, definition_values... = scanf(section_content, format_string, types...)
    return Definitions(definition_values...)
end

"""
    parse_blocks_section(lines, idx)

Parses the [BLOCKS] section of the sequence file into a `StructArray` of `Block`
structs.
"""
function parse_blocks_section(lines, idx)
    range = idx["BLOCKS"]

    # Count data lines first
    n = 0
    for i in range
        line = lines[i]
        !isempty(line) && line[1] != '#' && (n += 1)
    end

    # Pre-allocate column arrays
    dur = Vector{Int}(undef, n)
    rf  = Vector{Int}(undef, n)
    gx  = Vector{Int}(undef, n)
    gy  = Vector{Int}(undef, n)
    gz  = Vector{Int}(undef, n)
    adc = Vector{Int}(undef, n)
    delay = Vector{Int}(undef, n)
    ext = Vector{Int}(undef, n)

    row = 0
    for i in range
        line = lines[i]
        (isempty(line) || line[1] == '#') && continue
        row += 1

        len = ncodeunits(line)

        # Skip first field (block index)
        pos = skip_whitespace(line, 1)
        _, pos = parse_inline_int(line, pos)

        # Parse up to 8 fields, defaulting to 0 if line is shorter
        @inbounds dur[row], pos = pos <= len ? parse_inline_int(line, pos) : (0, pos)
        @inbounds rf[row],  pos = pos <= len ? parse_inline_int(line, pos) : (0, pos)
        @inbounds gx[row],  pos = pos <= len ? parse_inline_int(line, pos) : (0, pos)
        @inbounds gy[row],  pos = pos <= len ? parse_inline_int(line, pos) : (0, pos)
        @inbounds gz[row],  pos = pos <= len ? parse_inline_int(line, pos) : (0, pos)
        @inbounds adc[row], pos = pos <= len ? parse_inline_int(line, pos) : (0, pos)
        @inbounds delay[row], pos = pos <= len ? parse_inline_int(line, pos) : (0, pos)
        @inbounds ext[row],   _   = pos <= len ? parse_inline_int(line, pos) : (0, pos)
    end

    return StructArray{Block}((dur, rf, gx, gy, gz, adc, delay, ext))
end

"""
    parse_rf_section(lines, idx)

Parses the [RF] section of the sequence file into a `StructArray` of `RF`
structs.
"""
function parse_rf_section(lines, idx)
    section_lines = get_section(lines, idx["RF"])
    n = length(section_lines)

    amplitude     = Vector{Hz}(undef, n)
    mag_id        = Vector{Int}(undef, n)
    phase_id      = Vector{Int}(undef, n)
    time_shape_id = Vector{Int}(undef, n)
    delay         = Vector{μs}(undef, n)
    freq          = Vector{Hz}(undef, n)
    phase         = Vector{rad}(undef, n)

    for i in 1:n
        line = section_lines[i]
        _, pos = parse_inline_int(line, 1)          # skip id
        v, pos = parse_inline_float(line, pos)
        amplitude[i] = Hz(v)
        mag_id[i], pos = parse_inline_int(line, pos)
        phase_id[i], pos = parse_inline_int(line, pos)
        time_shape_id[i], pos = parse_inline_int(line, pos)
        v, pos = parse_inline_float(line, pos)
        delay[i] = μs(v)
        v, pos = parse_inline_float(line, pos)
        freq[i] = Hz(v)
        v, _ = parse_inline_float(line, pos)
        phase[i] = rad(v)
    end

    return StructArray{RF}((amplitude, mag_id, phase_id, time_shape_id, delay, freq, phase))
end

"""
    parse_trap_section(lines, idx)

Parses the [TRAP] section of the sequence file into a `StructArray` of `TRAP`
structs.
"""
function parse_trap_section(lines, idx)
    section_lines = get_section(lines, idx["TRAP"])
    n = length(section_lines)

    amplitude = Vector{Hzm⁻¹}(undef, n)
    rise      = Vector{μs}(undef, n)
    flat      = Vector{μs}(undef, n)
    fall      = Vector{μs}(undef, n)
    delay     = Vector{μs}(undef, n)

    for i in 1:n
        line = section_lines[i]
        _, pos = parse_inline_int(line, 1)          # skip id
        v, pos = parse_inline_float(line, pos)
        amplitude[i] = Hzm⁻¹(v)
        v, pos = parse_inline_float(line, pos)
        rise[i] = μs(v)
        v, pos = parse_inline_float(line, pos)
        flat[i] = μs(v)
        v, pos = parse_inline_float(line, pos)
        fall[i] = μs(v)
        v, _ = parse_inline_float(line, pos)
        delay[i] = μs(v)
    end

    return StructArray{TRAP}((amplitude, rise, flat, fall, delay))
end

"""
    parse_adc_section(lines, idx)

Parses the [ADC] section of the sequence file into a `StructArray` of `ADC`
structs.
"""
function parse_adc_section(lines, idx)
    section_lines = get_section(lines, idx["ADC"])
    n = length(section_lines)

    num   = Vector{Int}(undef, n)
    dwell = Vector{ns}(undef, n)
    delay = Vector{μs}(undef, n)
    freq  = Vector{Hz}(undef, n)
    phase = Vector{rad}(undef, n)

    for i in 1:n
        line = section_lines[i]
        _, pos = parse_inline_int(line, 1)          # skip id
        num[i], pos = parse_inline_int(line, pos)
        v, pos = parse_inline_float(line, pos)
        dwell[i] = ns(v)
        v, pos = parse_inline_float(line, pos)
        delay[i] = μs(v)
        v, pos = parse_inline_float(line, pos)
        freq[i] = Hz(v)
        v, _ = parse_inline_float(line, pos)
        phase[i] = rad(v)
    end

    return StructArray{ADC}((num, dwell, delay, freq, phase))
end

"""
    parse_extensions_section(lines, idx)

Parses the [EXTENSIONS] section of the sequence file into a `StructArray` of
`Extension` structs.
"""
function parse_extensions_section(lines, idx)
    section_lines = get_section(lines, idx["EXTENSIONS"])

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
    parse_shapes_section(lines, idx)

Parses the [SHAPES] section of the sequence file into a `StructArray` of `Shape`
structs.
"""
function parse_shapes_section(lines, idx)
    section_lines = get_section(lines, idx["SHAPES"])
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
