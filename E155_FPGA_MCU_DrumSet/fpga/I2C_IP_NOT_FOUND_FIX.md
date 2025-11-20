# Fix: "cannot find port i2c1_scl_io on this module"

## 🚨 Error Explanation

The error `cannot find port i2c1_scl_io on this module` means:
- Synthesis tool cannot find the `i2c_block` module definition
- Without the module definition, it doesn't know what ports exist
- This happens when `i2c_block.v` is not added to the project or not found

## ✅ Solution Steps

### Step 1: Verify i2c_block.v Exists
1. Check if `i2c_block.v` file exists in your project directory
2. Location should be: Your Radiant project folder or Module Generator output folder
3. If it doesn't exist, generate it using Module Generator (see `IP_REGENERATION_GUIDE.md`)

### Step 2: Add i2c_block.v to Radiant Project
**CRITICAL**: The file must be explicitly added to the project!

1. In Lattice Radiant, open your project
2. Look in the **Project Navigator** under **Source Files**
3. Check if `i2c_block.v` appears in the list
4. If NOT present:
   - Right-click on **Source Files** (or project name)
   - Select **Add Source Files...**
   - Browse to find `i2c_block.v`
   - Select it and click **OK**
   - It should now appear in Source Files list

### Step 3: Verify File Location
The `i2c_block.v` file should be:
- In your Radiant project directory, OR
- In a location accessible to the project
- Added to the Source Files list (not just in the folder)

### Step 4: Check File Path
If the file is in a different location:
1. Check the file path in Project Navigator
2. Ensure the path is correct (no spaces, valid characters)
3. If path is wrong, remove and re-add the file

### Step 5: Verify Module Name
Open `i2c_block.v` and check:
```verilog
module i2c_block (
    i2c2_scl_io,
    i2c2_sda_io,
    i2c1_scl_io,    // ← This port exists
    i2c1_sda_io,    // ← This port exists
    ...
);
```

The module name must be exactly `i2c_block` (matches your instantiation).

### Step 6: Re-run Synthesis
After adding the file:
1. Clean the project: **Process → Clean**
2. Re-run synthesis: **Process → Run Synthesis**
3. The error should be resolved

## 🔍 Troubleshooting

### Issue: File still not found after adding
**Solution**: 
- Check file extension is `.v` (not `.sv` or `.txt`)
- Verify file is not corrupted
- Try removing and re-adding the file
- Check if file is in a subdirectory that needs to be included

### Issue: "Multiple definitions of i2c_block"
**Solution**:
- Remove duplicate `i2c_block.v` files from project
- Keep only one instance in Source Files

### Issue: File path has spaces or special characters
**Solution**:
- Move file to a path without spaces
- Re-add to project

## ✅ Verification Checklist

After fixing, verify:
- [ ] `i2c_block.v` appears in Source Files list
- [ ] No errors in Project Navigator
- [ ] Synthesis completes without "cannot find port" error
- [ ] Module name in file matches: `module i2c_block`

## 📝 Quick Fix Summary

**The problem**: `i2c_block.v` is not added to Radiant project Source Files

**The solution**: Add `i2c_block.v` to project Source Files list

**How to add**:
1. Right-click project → Add Source Files
2. Select `i2c_block.v`
3. Click OK
4. Re-run synthesis

