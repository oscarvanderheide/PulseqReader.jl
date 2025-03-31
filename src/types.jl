# Note that for storing the [VERSION] section we use Julia's built-in VersionNumber type

"""
    Definitions

The Definitions struct contains the timings. 
    
It includes the raster times for ADC, block duration, TRAPadient, and RF events, as well as the total duration of the sequence. The raster times are used to determine the timing of the events in the sequence. The total duration is the sum of all the block durations.
"""
struct Definitions
    AdcRasterTime::Float64
    BlockDurationRaster::Float64
    TRAPadientRasterTime::Float64
    RadiofrequencyRasterTime::Float64
    TotalDuration::Float64
end

"""
    Block 

Pulseq sequences are built from a series of Blocks. Each block has a duration given by
`dur` times the BlockRasterTime. The `rf`, `gx`, `gy`, `gz`, `adc`, `delay` and `ext` fields are integers that indicate which element of the RF, TRAP, ADC, Delay and Extension arrays are present in the block.
"""
struct Block
    dur::Int
    rf::Int
    gx::Int
    gy::Int
    gz::Int
    adc::Int
    delay::Int
    ext::Int
end

function Base.show(io::IO, block::Block)
    # Main summary
    println(io)
    println(io, styled"{yellow:Block Summary}:")
    println(io, "===============")
    println(io, "Duration:\t", block.dur)
    println(io, "RF:\t\t", block.rf)
    println(io, "gx:\t\t", block.gx)
    println(io, "gy:\t\t", block.gy)
    println(io, "gz:\t\t", block.gz)
    println(io, "ADC:\t\t", block.adc)
    println(io, "Delay:\t\t", block.delay)
    println(io, "Extension:\t", block.ext)
end

"""
    RF event

The RF struct represents a radiofrequency event. It contains the amplitude, magnitude ID, phase ID, time shape ID, delay, frequency, and phase of the RF event.

Note that the IDs are used to reference the corresponding shapes in the array of `Shape`s.
"""
struct RF
    amplitude::Hz
    mag_id::Int
    phase_id::Int
    time_shape_id::Int
    delay::μs
    freq::Hz
    phase::rad
end

function Base.show(io::IO, rf::RF)
    println(io)
    println(io, styled"{yellow:RF Summary}:")
    println(io, "===============")
    println(io, "Amplitude:\t", rf.amplitude)
    println(io, "Magnitude ID:\t", rf.mag_id)
    println(io, "Phase ID:\t", rf.phase_id)
    println(io, "Time Shape ID:\t", rf.time_shape_id)
    println(io, "Delay:\t\t", rf.delay)
    println(io, "Frequency:\t", rf.freq)
    println(io, "Phase:\t\t", rf.phase)
end


"""
    TRAP event

The TRAP struct represents a TRAPadient event. It contains the amplitude, rise time, flat time, fall time, and delay of the TRAPadient event.
"""
struct TRAP
    amplitude::Hzm⁻¹
    rise::μs
    flat::μs
    fall::μs
    delay::μs
end

function Base.show(io::IO, trap::TRAP)
    println(io)
    println(io, styled"{yellow:TRAP Summary}:")
    println(io, "===============")
    println(io, "Amplitude:\t", trap.amplitude)
    println(io, "Rise time:\t", trap.rise)
    println(io, "Flat time:\t", trap.flat)
    println(io, "Fall time:\t", trap.fall)
    println(io, "Delay:\t\t", trap.delay)
end

"""
    ADC event

The ADC struct represents an analog-to-digital converter event. It contains the number of samples, dwell time, delay, frequency, and phase of the ADC event.
"""
struct ADC
    num::Int
    dwell::ns
    delay::μs
    freq::Hz
    phase::rad
end

function Base.show(io::IO, adc::ADC)
    println(io)
    println(io, styled"{yellow:ADC Summary}:")
    println(io, "===============")
    println(io, "Number of samples:\t", adc.num)
    println(io, "Dwell time:\t\t", adc.dwell)
    println(io, "Delay:\t\t\t", adc.delay)
    println(io, "Frequency:\t\t", adc.freq)
    println(io, "Phase:\t\t\t", adc.phase)
end

"""
    Extension

The Extension struct represents an extension. The extensions concept allows for implementing additional features without requiring major revisions of the Pulseq format specification. It contains the type, reference, and next ID of the extension event.
"""
struct Extension
    type::Int
    ref::Int
    next_id::Int
end

function Base.show(io::IO, ext::Extension)
    println(io)
    println(io, styled"{yellow:Extension Summary}:")
    println(io, "===============")
    println(io, "Type:\t\t", ext.type)
    println(io, "Reference:\t", ext.ref)
    println(io, "Next ID:\t", ext.next_id)
end

"""
    Shape

The Shape struct represents a shape of things like RF waveforms (amplitude and phase). It contains the number of samples and the actual samples of the shape.

If `length(samples) < num_samples` then the samples are compressed by encoding the derivative in a run-length compressed format. 
"""
struct Shape
    num_samples::Int
    samples::Vector{Float64}
end

function Base.show(io::IO, shape::Shape)

    # Decode the shape
    shape = decode(shape)

    min_val, max_val = round.(extrema(shape.samples), digits=2)

    # Only show plot if there's meaningful variation in the data
    # if min_val != max_val && shape.num_samples > 1
    p = lineplot(1:shape.num_samples,
        shape.samples,
        width=60,
        height=15,
        title="Shape",
        ylim=(min_val, max_val),
        xlim=(1, shape.num_samples),
        xlabel="Sample (1 to $(shape.num_samples))")
    println(io, p)

end

"""
    Sequence

The Sequence struct is a Julia representation of the contents of a `.seq` file. It's unopinated in the sense that it does not do any validation or processing of the contents of the file. It simply reads the file and stores the contents in a way that is easy to access and manipulate from within Julia.
    
It contains the version, definitions, blocks, TRAPadient events, RF events, ADC events, extensions, and shapes of the sequence.

Rather than storing, for example, the blocks as a `Vector{Blocks}`, this struct instead requires a `StructArray{Block}`. This makes it possible to access the duration of all blocks with the syntax `seq.blocks.dur` instead of having to do `[block.dur for block in seq.blocks]`. At the same time, it is still possible to access fields of individual elements using `seq.blocks[1].dur`. See the documentation of `StructArrays.jl` for more information.
"""
struct Sequence
    version::VersionNumber
    definitions::Definitions
    blocks::StructArray{Block}
    trap::StructArray{TRAP}
    rf::StructArray{RF}
    adc::StructArray{ADC}
    extensions::StructArray{Extension}
    shapes::StructArray{Shape}
end

function Base.show(io::IO, seq::Sequence)
    # Main summary
    println(io)
    println(io, styled"{yellow:Sequence Summary}:")
    println(io, "================")

    function add_gray_dots(str, max_width=35)
        num_dots = max_width - length(str)
        dots = '.'^num_dots
        return styled"$(str){gray:$(dots)}"
    end

    # Print version
    println(io, add_gray_dots("Version"), seq.version)
    println(io, "")

    # Print definitions
    println(io, "Definitions")
    for property in propertynames(seq.definitions)
        value = getfield(seq.definitions, property)
        println(io, add_gray_dots("  " * String(property)), value)
    end
    println(io, "")


    # Print counts of different events
    println(io, add_gray_dots("Blocks"), length(seq.blocks))
    println(io, add_gray_dots("TRAP events"), length(seq.trap))
    println(io, add_gray_dots("RF events"), length(seq.rf))
    println(io, add_gray_dots("ADC events"), length(seq.adc))
    println(io, add_gray_dots("Extensions"), length(seq.extensions))
    println(io, add_gray_dots("Shapes"), length(seq.shapes))
end