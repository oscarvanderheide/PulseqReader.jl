# PulseqReader.jl

A Julia package for reading Pulseq MRI sequence files (.seq).

## Installation

```julia
pkg> add git@github.com:oscarvanderheide/PulseqReader.jl.git
```

## Usage

```julia
using PulseqReader

# Load .seq file
filename = "path/to/your/sequence.seq"
seq = read_pulseq(filename)

# Access Pulseq version and sequence definitions
seq.version
seq.definitions

# Access all blocks/events/shapes
seq.blocks 
seq.rf
seq.trap 
seq.adc 
seq.extensions    
seq.shapes 

# Get specific blocks/events/shapes
seq.blocks[1]
seq.rf[2]
seq.shapes[3]

# Access properties of specific blocks/events/shapes
seq.blocks[1].dur
seq.rf[2].amplitude
seq.shapes[3].samples

# Access properties of all events at once (using StructArrays.jl)
seq.blocks.dur
seq.rf.amplitude
seq.shapes.samples
```

## Current Status

This package is in active development. It has been tested with a limited number of Pulseq v1.4.2 sequence files.

### Known Limitations

1. **Definitions Structure**:
   - The current `Definitions` type needs to be modified to accommodate optional fields that may be present in some sequence files.

2. **Missing Section Parsers**:
   - `[GRADIENTS]` section parser needs to be implemented
   - `[DELAYS]` section parser needs to be implemented

3. **Specification Discrepancies**:
   - Some fields specified in the Pulseq documentation for GR and RF events are not present in our test files
   - These may be legacy fields from older versions of the specification

4. **Version Compatibility**:
   - Currently only tested with Pulseq v1.4.2 sequence files
   - Compatibility with other versions is not guaranteed
