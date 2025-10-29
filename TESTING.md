### Test Case 1: Delete Single File
**Objective:** Verify that a single file can be deleted successfully
**Steps:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin
**Expected Result:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output
**Actual Result:** File is moved to ~/.recycle_bin/files
**Status:** Pass
**Screenshots:** 
To be added

### Test Case 2: Delete Multiple Files
**Objective:** Verify that multiple files can be deleted successfully
**Steps:**
1. Create test1 file: `echo "test1" > test1.txt`
2. Create test2 file: `echo "test2" > test2.txt`
3. Run: `./recycle_bin.sh delete test1.txt test2.txt`
4. Verify files are removed from current directory
5. Run: `./recycle_bin.sh list`
6. Verify files appears in recycle bin
**Expected Result:**
- Files are moved to ~/.recycle_bin/files/
- Metadata entries are created
- Success message is displayed
- Files appear in list output
**Actual Result:** Files are moved to ~/.recycle_bin/files
**Status:** Pass
**Screenshots:**
To be added

### Test Case 3: Delete an empty Directory
**Objective:** Verify that an empty Directory can be deleted successfully
**Steps:**
1. Create test1 file: `mkdir Test_Dir`
2. Run: `./recycle_bin.sh delete Test_Dir`
3. Verify the Directory is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify Directory appears in recycle bin
**Expected Result:**
- Directory is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- Directory appears in list output
**Actual Result:** Directory is moved to ~/.recycle_bin/files
**Status:** Pass
**Screenshots:**
To be added

### Test Case 4: Delete Directory with Files and Subdirectories
**Objective:** Verify that a directory containing files and subdirectories can be deleted successfully
**Steps**
1. Create a directory with contents: `mkdir -p Test_Dir/SubDir`
2. Create files: `echo "file1" > Test_Dir/file1.txt`, `echo "file2" > Test_Dir/SubDir/file2.txt`
3. Run: `./recycle_bin.sh delete Test_Dir`
4. Verify the directory and all its contents are removed from current directory
5. Run: `./recycle_bin.sh list`
6. Verify directory appears in recycle bin along with its metadata
**Expected Result**
- Directory and all files/subdirectories are moved to ~/.recycle_bin/files/
- Metadata entries are created for all items
- Success message is displayed
- Directory appears in list output
**Actual Result** Directory and containing files/subdirectories are moved to ~/.recycle_bin/files
**Status:** Pass
**Screenshots:**
To be added

### Test Case 5: List Files in Recycle Bin
**Objective:** Verify that deleted files/directories appear in the recycle bin list
**Steps**
1. To do This step it is first necessary to do any of the previous steps until the Run: `./recycle_bin.sh delete ...`
2. Run: `./recycle_bin.sh list`
**Expected Result**
- All files/directories/both are listed
**Actual Result** All files/directories/both are listed
**Status:** Pass
**Screenshots:**
To be added

aa