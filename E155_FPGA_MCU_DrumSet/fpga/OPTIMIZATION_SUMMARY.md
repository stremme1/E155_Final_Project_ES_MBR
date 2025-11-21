# Design Optimization Summary

## DSP Block Usage

### Quaternion to Euler Module
- **Multiplications**: All multiplications use DSP blocks via synthesis attributes
  - Quaternion squares: `quat_w * quat_w`, etc. (6 DSP blocks)
  - Quaternion products: `quat_w * quat_x`, etc. (6 DSP blocks)
  - Radian to degree conversion: `roll_rad * RAD_TO_DEG_Q16` (3 DSP blocks)
  - **Total: ~15 DSP blocks per sensor (30 total for 2 sensors)**

### Synthesis Attributes Used:
```systemverilog
(* use_dsp48 = "yes" *)  // Xilinx
(* use_dsp = "yes" *)     // Intel/Altera
(* syn_useioff = 1 *)     // Lattice (if needed)
```

## BRAM Usage

### BNO085 Controller Module
- **Data Buffer**: 64 bytes × 8 bits = 512 bits
  - Uses BRAM via synthesis attribute: `(* ram_style = "block" *)`
  - **Total: 1 BRAM block per sensor (2 total for 2 sensors)**
  - Each BRAM typically 9Kb or 18Kb depending on FPGA

### Synthesis Attributes Used:
```systemverilog
(* ram_style = "block" *)      // Xilinx
(* ramstyle = "M9K" *)         // Intel/Altera
(* syn_ramstyle = "block_ram" *) // Lattice
```

## Resource Estimation

### Per Sensor:
- **DSP Blocks**: ~15
- **BRAM**: 1 block (9Kb or 18Kb)
- **LUTs**: ~2000-3000 (estimated)
- **FFs**: ~500-800 (estimated)

### Total System (2 sensors):
- **DSP Blocks**: ~30
- **BRAM**: 2 blocks
- **LUTs**: ~4000-6000
- **FFs**: ~1000-1600

## FPGA Compatibility

### Xilinx (Artix-7, Kintex-7, etc.):
- DSP48E1 blocks: 30 used (typical FPGAs have 90-240)
- BRAM36K: 2 blocks (typical FPGAs have 50-200)
- **Compatibility**: ✅ Excellent

### Intel/Altera (Cyclone V, Arria, etc.):
- DSP blocks: 30 used (typical FPGAs have 50-200)
- M9K/M10K: 2 blocks (typical FPGAs have 50-500)
- **Compatibility**: ✅ Excellent

### Lattice (iCE40, ECP5, etc.):
- DSP blocks: May need to check availability
- EBR (Embedded Block RAM): 2 blocks
- **Compatibility**: ⚠️ Check DSP availability

## Verification

### Synthesis Reports to Check:
1. **DSP Inference**: Look for "DSP48" or "MULT" in synthesis report
2. **BRAM Inference**: Look for "RAMB36" or "M9K" in synthesis report
3. **Resource Utilization**: Should show DSP and BRAM usage

### Expected Synthesis Messages:
```
Inferring DSP48 for multiplication...
Inferring Block RAM for data_buffer...
```

### If DSP/BRAM Not Inferred:
1. Check synthesis attributes syntax for your tool
2. Verify array sizes meet minimum requirements
3. Check for conflicting attributes
4. Review synthesis tool documentation

## Optimization Benefits

1. **Area Reduction**: 
   - DSP blocks are dedicated hardware (faster, smaller)
   - BRAM is dedicated memory (efficient storage)

2. **Performance**:
   - DSP blocks: Single-cycle multiplications
   - BRAM: Single-cycle read/write access

3. **Power**:
   - Dedicated blocks consume less power than LUT-based implementations

## Notes

- Synthesis attributes are vendor-specific
- Some tools may require different attribute names
- Always verify with synthesis reports
- Consider using IP cores for complex operations (CORDIC, etc.)


