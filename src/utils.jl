"""
    get_section(lines::Vector{String}, section_name::String)

Extracts the lines corresponding to a specific section in the sequence file.

  - Removes empty lines and comment lines (lines starting with #).
  - For sections like VERSION and DEFINITIONS, joins the lines into a single
    string.
"""
function get_section(lines::Vector{String}, section_name::String)
    section_range = get_section_range(lines, section_name)
    section = [
        line for line in lines[section_range] if !is_empty_or_comment_line(line)
    ]

    if section_name ∈ ["VERSION", "DEFINITIONS"]
        section = join(section, " ")
    end

    return section
end

"""
    get_section_range(section_name::String)

Sections are defined by lines starting with a square bracket (e.g., [RF], [ADC],
etc.). The function returns a range of line indices that correspond to the
specified section.
"""
function get_section_range(lines, section_name::String)

    println("Parsing section: ", section_name)
    start_section = findfirst(contains("[$section_name]"), lines) + 1

    # The next line with "[" indicates the start of the next section Note that
    # [SIGNATURE] always comes last and is not parsed so we don't need to worry
    # about the end of the file
    end_section = findnext(contains("["), lines, start_section) - 1

    return start_section:end_section
end

"""
    is_empty_or_comment_line(line)

Checks if a line is empty or a comment line (starts with #). This check is used
to skip lines that do not contain relevant data.
"""
function is_empty_or_comment_line(line::AbstractString)
    return isempty(line) || startswith(line, "#")
end

"""
    get_scanf_args(section::AbstractString)

Returns information (`format_string` and `types`) needed to parse the specified
section of the sequence file with `scanf`.

The `format_string` contains the format string for `Scanf.scanf` converted
`Scanf.Format`. The `types` field contains the types for each of the extracted
values.
"""
function get_scanf_args(section::AbstractString)
    if section == "VERSION"
        # major, minor, revision
        format_string = "%*s %d %*s %d %*s %d"
        types = (Int, Int, Int)
    elseif section == "DEFINITIONS"
        # AdcRasterTime, BlockDurationRaster, GradientRasterTime,
        # RadiofrequencyRasterTime, TotalDuration
        format_string = "%*s %f %*s %f %*s %f %*s %f %*s %f"
        types = (Float64, Float64, Float64, Float64, Float64)
    elseif section == "BLOCKS"
        # dur, rf, gx, gy, gz, adc, delay, ext
        format_string = "%*d %d %d %d %d %d %d %d %d"
        types = (Int, Int, Int, Int, Int, Int, Int, Int)
    elseif section == "RF"
        # amplitude, mag_id, phase_id, time_shape_id, delay, frequency, phase
        format_string = "%*d %f %d %d %d %f %f %f"
        types = (Float64, Int, Int, Int, Float64, Float64, Float64)
    elseif section == "TRAP"
        # amplitude, rise, flat, fall, delay
        format_string = "%*d %f %f %f %f %f"
        types = (Float64, Float64, Float64, Float64, Float64)
    elseif section == "ADC"
        # num, dwell, delay, frequency, phase
        format_string = "%*d %d %f %f %f %f"
        types = (Int, Float64, Float64, Float64, Float64)
    elseif section == "EXTENSIONS"
        # ext_id, ext_type, ext_value
        format_string = "%*d %d %d %d"
        types = (Int, Int, Int)
    else
        error("Unknown section: $section")
    end

    return Scanf.Format(format_string), types
end

import PulseqReader: Shape

"""
    decode(s::Shape)

Decompresses a compressed `Shape` by decoding the derivative in a run-length
compressed format.

  - The function takes a `Shape` object as input and returns a new `Shape`
    object with the decompressed samples.
  - The function checks if the shape is compressed by comparing the number of
    samples in the shape with the length of the samples array. If they are
    equal, it returns the original shape.
  - The decoding algorithm checks if a value is repeated in the compressed
    shape. If it is, it reads the number of repetitions from the next value in
    the array and fills the decoded shape with the current derivative value.
  - The first sample of the compressed shape is always the actual first sample.
"""
function decode(s::Shape)

    # Check if the shape is compressed, if not return the original shape
    if s.num_samples == length(s.samples)
        return s
    end

    # decoded_derivative = zeros(num_samples)
    decoded_shape = zeros(s.num_samples)

    # First sample of the compressed shape is always the actual first sample
    decoded_shape[1] = s.samples[1]

    idx = 1
    compressed_idx = 1

    while compressed_idx <= length(s.samples) && idx <= s.num_samples

        current_derivative = s.samples[compressed_idx]
        next_derivative = s.samples[compressed_idx+1]

        # If the current derivative is the same as the next one, then the value
        # after that is the number of additional repetitions
        if current_derivative == next_derivative
            repetitions = Int(s.samples[compressed_idx+2]) + 2
            compressed_idx += 3
        else
            repetitions = 1
            compressed_idx += 1
        end

        # Fill the decoded shape array with the current derivative value
        for j = 1:repetitions
            previous_value = idx > 1 ? decoded_shape[idx-1] : 0.0
            decoded_shape[idx] = previous_value + current_derivative
            idx += 1
        end

    end

    return Shape(s.num_samples, decoded_shape)  # Return the decompressed shape
end