# Lattice Radiant Project - Required Files

## ✅ REQUIRED Source Files (Must Add to Project)

Add these files to your Lattice Radiant project in this order:

### 1. I2C IP Block (USE REPOSITORY FILE)
**File:** `i2c_block.v`  
**Location:** `E155_FPGA_MCU_DrumSet/fpga/verilog/i2c_block.v` (from repository)  
**Status:** ✅ **USE REPOSITORY FILE - DO NOT USE MODULE GENERATOR FILE**  
**Action:** 
- **CRITICAL:** Use the `i2c_block.v` from this repository
- **DO NOT** use the Module Generator file from `E155_finalp/i2c_block/rtl/`
- Add repository file to project: Right-click Source Files → Add Source Files → Select `i2c_block.v` from repository
- See `FIX_RADIANT_FILE_SELECTION.md` for detailed instructions

### 2. Top Module
**File:** `drum_system_top.sv`  
**Location:** `E155_FPGA_MCU_DrumSet/fpga/verilog/drum_system_top.sv`  
**Status:** ✅ Required  
**Description:** Main top-level module that instantiates all components

### 3. I2C Controller
**File:** `bno055_i2c_controller_gyro_only.sv`  
**Location:** `E155_FPGA_MCU_DrumSet/fpga/verilog/bno055_i2c_controller_gyro_only.sv`  
**Status:** ✅ Required  
**Description:** I2C controller for reading gyroscope data from BNO055

### 4. Gesture Recognition
**File:** `gesture_recognition_gyro_only.sv`  
**Location:** `E155_FPGA_MCU_DrumSet/fpga/verilog/gesture_recognition_gyro_only.sv`  
**Status:** ✅ Required  
**Description:** Gesture recognition logic using gyroscope data

## 📋 Complete File List

### Source Files (Add to Radiant Project):
```
1. i2c_block.v                    (Generated IP - MUST BE FIRST)
2. drum_system_top.sv             (Top module)
3. bno055_i2c_controller_gyro_only.sv  (I2C controller)
4. gesture_recognition_gyro_only.sv     (Gesture recognition)
```

### Test Bench Files (NOT added to project, used for simulation):
```
- drum_system_top_gyro_tb.sv     (Test bench - simulation only)
```

## 🔧 How to Add Files to Lattice Radiant

### Method 1: Add Source Files Dialog
1. In Lattice Radiant, right-click on your project name
2. Select **Add Source Files...**
3. Browse to `E155_FPGA_MCU_DrumSet/fpga/verilog/`
4. Select files in this order:
   - `i2c_block.v` (if generated, or generate first)
   - `drum_system_top.sv`
   - `bno055_i2c_controller_gyro_only.sv`
   - `gesture_recognition_gyro_only.sv`
5. Click **OK**

### Method 2: Drag and Drop
1. Open Windows Explorer / Finder
2. Navigate to `E155_FPGA_MCU_DrumSet/fpga/verilog/`
3. Drag files into Radiant's Source Files window
4. Ensure `i2c_block.v` is first (if available)

## ⚠️ Critical Notes

### 1. I2C IP Block (`i2c_block.v`)
- **MUST be generated first** using Module Generator
- **MUST be added to project** before synthesis
- If missing, synthesis will fail with "module not found"
- See `IP_REGENERATION_GUIDE.md` for generation steps

### 2. File Order Matters
- Add `i2c_block.v` first (it's instantiated by top module)
- Then add `drum_system_top.sv` (instantiates I2C IP)
- Then add supporting modules

### 3. File Types
- `.sv` files are SystemVerilog (supported by Radiant)
- `.v` files are Verilog (supported by Radiant)
- Both work, but `.sv` is preferred for this project

## ✅ Verification Checklist

After adding files, verify:

- [ ] `i2c_block.v` is in Source Files list
- [ ] `drum_system_top.sv` is in Source Files list
- [ ] `bno055_i2c_controller_gyro_only.sv` is in Source Files list
- [ ] `gesture_recognition_gyro_only.sv` is in Source Files list
- [ ] All files show no errors in Project Navigator
- [ ] Top module is set to `drum_system_top` (right-click → Set as Top)

## 🚫 Files NOT to Add

Do NOT add these to your project (they're for reference or simulation only):
- `drum_system_top_gyro_tb.sv` (test bench - simulation only)
- `drum_system_top_tb.sv` (old test bench)
- `drum_system_fpga_audit_tb.sv` (old test bench)
- `drum_system_top_with_i2c_ip.sv` (reference file)
- `*.vvp` files (simulation artifacts)
- `ErrorCodes.txt` (error log, not source code)
- `bno055_i2c_controller.sv` (old version, not used)
- `gesture_recognition.sv` (old version, not used)
- `quaternion_to_euler.sv` (removed, not used)
- `system_bus_master.sv` (inlined, not used)

## 📁 File Locations

All source files are located in:
```
E155_FPGA_MCU_DrumSet/fpga/verilog/
```

The generated I2C IP file (`i2c_block.v`) will be in:
- Your Radiant project directory, OR
- The Module Generator output directory (check Module Generator settings)

## 🎯 Quick Start

1. **Generate I2C IP** (if not done):
   - Tools → Module Generator
   - Configure I2C1 (enable), I2C2 (disable)
   - Generate → Save as `i2c_block.v`

2. **Add to Project**:
   - Right-click project → Add Source Files
   - Add: `i2c_block.v`, `drum_system_top.sv`, `bno055_i2c_controller_gyro_only.sv`, `gesture_recognition_gyro_only.sv`

3. **Set Top Module**:
   - Right-click `drum_system_top.sv` → Set as Top

4. **Run Synthesis**:
   - Process → Run Synthesis

## 📞 Troubleshooting

### Error: "Module i2c_block not found"
**Solution:** Add `i2c_block.v` to project source files

### Error: "Module bno055_i2c_controller_gyro_only not found"
**Solution:** Add `bno055_i2c_controller_gyro_only.sv` to project source files

### Error: "Multiple top modules"
**Solution:** Right-click `drum_system_top.sv` → Set as Top

### Warning: "File not found"
**Solution:** Check file paths, ensure files are in correct directory

