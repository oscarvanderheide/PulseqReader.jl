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
    format_string, types = get_scanf_args("BLOCKS")
    blocks = Block[]
    sizehint!(blocks, length(section_lines))

    for line in section_lines
        _, dur, rf, gx, gy, gz, adc, delay, ext =
            scanf(line, format_string, types...)
        push!(blocks, Block(dur, rf, gx, gy, gz, adc, delay, ext))
    end

    return StructArray(blocks)
end

"""
    parse_rf_section(lines)

Parses the [RF] section of the sequence file into a `StructArray` of `RF`
structs.
"""
function parse_rf_section(lines)
    section_lines = get_section(lines, "RF")
    format_string, types = get_scanf_args("RF")
    rf_events = RF[]
    sizehint!(rf_events, length(section_lines))

    for line in section_lines
        _, amplitude, mag_id, phase_id, time_shape_id, delay, frequency, phase =
            scanf(line, format_string, types...)
        push!(
            rf_events,
            RF(
                Hz(amplitude),
                mag_id,
                phase_id,
                time_shape_id,
                μs(delay),
                Hz(frequency),
                rad(phase),
            ),
        )
    end

    return StructArray(rf_events)
end

"""
    parse_trap_section(lines)

Parses the [TRAP] section of the sequence file into a `StructArray` of `TRAP`
structs.
"""
function parse_trap_section(lines)
    section_lines = get_section(lines, "TRAP")
    format_string, types = get_scanf_args("TRAP")
    trap_events = TRAP[]
    sizehint!(trap_events, length(section_lines))

    for line in section_lines
        _, amplitude, rise, flat, fall, delay =
            scanf(line, format_string, types...)
        push!(
            trap_events,
            TRAP(Hzm⁻¹(amplitude), μs(rise), μs(flat), μs(fall), μs(delay)),
        )
    end

    return StructArray(trap_events)
end

"""
    parse_adc_section(lines)

Parses the [ADC] section of the sequence file into a `StructArray` of `ADC`
structs.
"""
function parse_adc_section(lines)
    section_lines = get_section(lines, "ADC")
    format_string, types = get_scanf_args("ADC")
    adc_events = ADC[]
    sizehint!(adc_events, length(section_lines))

    for line in section_lines
        _, num, dwell, delay, frequency, phase =
            scanf(line, format_string, types...)
        push!(
            adc_events,
            ADC(num, ns(dwell), μs(delay), Hz(frequency), rad(phase)),
        )
    end

    return StructArray(adc_events)
end

"""
    parse_extensions_section(lines)

Parses the [EXTENSIONS] section of the sequence file into a `StructArray` of
`Extension` structs.
"""
function parse_extensions_section(lines)
    section_lines = get_section(lines, "EXTENSIONS")
    format_string, types = get_scanf_args("EXTENSIONS")
    extensions = Extension[]
    sizehint!(extensions, length(section_lines))

    for line in section_lines
        _, ext_id, ext_type, ext_value = scanf(line, format_string, types...)
        push!(extensions, Extension(ext_id, ext_type, ext_value))
    end

    return StructArray(extensions)
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
