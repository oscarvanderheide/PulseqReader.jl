"""
    build_section_index(lines)

Scans the file lines once and returns a Dict mapping section names to their
line ranges (excluding the header line itself).
"""
function build_section_index(lines::Vector{String})
    # Find all section header positions in a single pass
    headers = Tuple{String,Int}[]
    for i in eachindex(lines)
        line = lines[i]
        if !isempty(line) && line[1] == '['
            # Extract section name between [ and ]
            j = findfirst(']', line)
            j !== nothing && push!(headers, (line[2:j-1], i))
        end
    end

    index = Dict{String,UnitRange{Int}}()
    for k in 1:length(headers)-1
        name, start = headers[k]
        _, next_start = headers[k+1]
        index[name] = (start + 1):(next_start - 1)
    end
    # Last section goes to end of file
    if !isempty(headers)
        name, start = headers[end]
        index[name] = (start + 1):length(lines)
    end

    return index
end

"""
    get_section(lines, range, join_lines=false)

Extracts non-empty, non-comment lines from the given range.
If `join_lines` is true, joins them into a single string (for VERSION/DEFINITIONS).
"""
function get_section(lines::Vector{String}, range::UnitRange{Int}, join_lines::Bool=false)
    section = [line for line in @view(lines[range]) if !is_empty_or_comment_line(line)]
    join_lines ? join(section, " ") : section
end

"""
    is_empty_or_comment_line(line)

Checks if a line is empty or a comment line (starts with #). This check is used
to skip lines that do not contain relevant data.
"""
function is_empty_or_comment_line(line::AbstractString)
    return isempty(line) || line[1] == '#'
end

# --- Zero-allocation inline parsers ---

"""
    skip_whitespace(s, pos)

Advance `pos` past any ASCII whitespace in string `s`.
"""
@inline function skip_whitespace(s::String, pos::Int)
    @inbounds while pos <= ncodeunits(s) && (codeunit(s, pos) == 0x20 || codeunit(s, pos) == 0x09)
        pos += 1
    end
    return pos
end

"""
    parse_inline_int(s, pos) -> (value, next_pos)

Parse an integer directly from string bytes starting at `pos`.
Returns the parsed value and the position after the integer.
"""
@inline function parse_inline_int(s::String, pos::Int)
    pos = skip_whitespace(s, pos)
    neg = false
    len = ncodeunits(s)
    @inbounds if pos <= len && codeunit(s, pos) == 0x2d  # '-'
        neg = true
        pos += 1
    end
    val = 0
    @inbounds while pos <= len
        d = codeunit(s, pos) - 0x30
        d > 0x09 && break
        val = val * 10 + d
        pos += 1
    end
    return neg ? -val : val, pos
end

"""
    parse_inline_float(s, pos) -> (value, next_pos)

Parse a float directly from string bytes starting at `pos`.
Uses `parse(Float64, ...)` on the token but avoids allocating a `split` array.
"""
@inline function parse_inline_float(s::String, pos::Int)
    pos = skip_whitespace(s, pos)
    start = pos
    len = ncodeunits(s)
    @inbounds while pos <= len
        c = codeunit(s, pos)
        # Break on whitespace
        (c == 0x20 || c == 0x09) && break
        pos += 1
    end
    val = parse(Float64, SubString(s, start, pos - 1))
    return val, pos
end

"""
    get_scanf_args(section::AbstractString)

Returns information (`format_string` and `types`) needed to parse the specified
section of the sequence file with `scanf`.

Used only for VERSION and DEFINITIONS sections (called once each).
"""
function get_scanf_args(section::AbstractString)
    if section == "VERSION"
        format_string = "%*s %d %*s %d %*s %d"
        types = (Int, Int, Int)
    elseif section == "DEFINITIONS"
        format_string = "%*s %f %*s %f %*s %f %*s %f %*s %f"
        types = (Float64, Float64, Float64, Float64, Float64)
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

    return Shape(s.num_samples, decoded_shape)
end
