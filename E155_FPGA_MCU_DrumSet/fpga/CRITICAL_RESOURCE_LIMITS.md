# Critical Resource Limits - iCE40UP5K

## EXACT LIMITS (From Datasheet)

**iCE40UP5K**:
- **Logic Cells (LUTs)**: **5280** (HARD LIMIT)
- **EBR Blocks**: 30 (120 kb)
- **SPRAM Blocks**: 4 (1024 kb)  
- **DSP Blocks**: 8
- **User I/O**: 39 GPIO pins

## Current Problem

**Estimated usage is ~2095 LUTs, but synthesis may use 3500-4500+ LUTs due to:**
1. **Synthesis tool overhead**: 20-40% additional LUTs
2. **Routing complexity**: Interconnects use extra LUTs
3. **State machine encoding**: Large FSMs are expensive
4. **Multiplier inference**: 16x16 multiplies without DSP blocks

## Biggest Resource Consumers

### 1. I2C Controllers (CRITICAL - ~1200-1600 LUTs total)
- **25-state FSM** per controller = ~600-800 LUTs each
- **Delay counters** = ~100-200 LUTs each
- **System Bus interface** = ~100-150 LUTs each
- **Total: ~1600-2300 LUTs for both** ⚠️ **BIGGEST ISSUE**

### 2. System Bus Masters (~400-600 LUTs total)
- **6-state FSM** per master = ~200-300 LUTs each
- **Total: ~400-600 LUTs for both**

### 3. Quaternion Math (~500 LUTs)
- Multiplications without DSP blocks
- Pipeline registers

### 4. Gesture Recognition (~150 LUTs)
- Already minimal

### 5. Top-level (~250 LUTs)
- Mux/demux, calibration

**REALISTIC TOTAL: 2900-3800 LUTs** (may exceed 5280 with overhead)

## Required Cuts

To fit in 5280 LUTs with safety margin, need to reduce to **~3500 LUTs max**:

1. **Simplify I2C controllers**: Reduce from 25 to ~12 states = **-800 LUTs**
2. **Simplify System Bus masters**: Reduce from 6 to 4 states = **-200 LUTs**
3. **Further simplify quaternion math**: Use EBR lookup or remove more = **-200 LUTs**
4. **Remove unnecessary delays**: Simplify initialization = **-100 LUTs**

**Target: ~2200-2500 LUTs** (with 50% margin for synthesis overhead)

