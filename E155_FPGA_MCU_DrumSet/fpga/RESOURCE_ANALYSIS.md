# Resource Analysis - iCE40UP5K Exact Limits

## iCE40UP5K Resource Limits (From Datasheet)

**Exact Limits**:
- **Logic Cells (LUT + Flip-Flop)**: **5280**
- **EBR Memory Blocks**: 30 (120 kb)
- **SPRAM Memory Blocks**: 4 (1024 kb)
- **DSP Blocks**: 8
- **Package**: 48-ball QFN
- **Total User I/O**: 39 GPIO pins

## Current Resource Usage Breakdown

### Estimated Usage (May be higher in actual synthesis):

1. **I2C Controllers (2x)**: ~800-1200 LUTs
   - Large state machine (25 states)
   - Delay counters
   - System Bus interface logic
   - **This is likely the biggest consumer**

2. **System Bus Masters (2x)**: ~400-600 LUTs
   - State machine (6 states)
   - Protocol handling
   - **Could be optimized**

3. **Quaternion-to-Euler (shared)**: ~500 LUTs
   - Multiplications
   - Pipeline stages
   - **Already optimized but could use EBR lookup tables**

4. **Gesture Recognition**: ~150 LUTs
   - Comparisons
   - Debounce logic
   - **Already minimal**

5. **Top-level Logic**: ~250 LUTs
   - Mux/demux
   - Calibration
   - Button debounce
   - **Could be reduced**

6. **Routing Overhead**: ~200-400 LUTs
   - Synthesis tool overhead
   - Signal routing
   - **Unavoidable but varies**

**Total Estimated**: ~2300-3100 LUTs (but synthesis may use more)

## Why It Might Not Fit

1. **Synthesis overhead**: Tools add 10-30% overhead
2. **I2C controllers**: Large state machines are expensive
3. **Routing**: Complex interconnects use extra LUTs
4. **Multipliers**: 16x16 multiplies are expensive without DSP blocks

## Critical Areas for Further Reduction

### Priority 1: I2C Controllers (~800-1200 LUTs)
- **Reduce state machine**: Combine states, remove unnecessary delays
- **Simplify initialization**: Remove soft reset, use minimal delays
- **Reduce delay counters**: Use smaller counters or remove some delays

### Priority 2: System Bus Masters (~400-600 LUTs)
- **Simplify state machine**: Reduce from 6 to 4 states
- **Remove unnecessary signals**: Simplify protocol handling

### Priority 3: Quaternion Math (~500 LUTs)
- **Use EBR lookup tables**: Replace atan2/asin with pre-computed tables
- **Further reduce precision**: Use 8-bit instead of 16-bit where possible
- **Remove more pipeline stages**: Go from 4 to 2 stages

### Priority 4: Top-level (~250 LUTs)
- **Simplify mux/demux**: Use simpler multiplexing
- **Reduce calibration logic**: Simplify yaw offset handling

