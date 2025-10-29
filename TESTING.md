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
1. To do This step it is first necessary to do any of the previous tests (1-4) until the Run: `./recycle_bin.sh delete ...`
2. Run: `./recycle_bin.sh list`
**Expected Result**
- All files/directories/both are listed
**Actual Result** All files/directories/both are listed
**Status:** Pass
**Screenshots:**
To be added

### Test Case 6: List Files in Recycle Bin sorted by date/size
**Objective:** Verify that deleted files/directories appear in the recycle bin list sorted by either size or date 
**Steps**
1. To do This step it is first necessary to do any of the previous tests (1-4) until the Run: `./recycle_bin.sh delete ...`
2. Run: `./recycle_bin.sh list --sort date` or `./recycle_bin.sh list --sort size`
**Expected Result**
- All files/directories/both are listed in the specified order (date/size)
**Actual Result** All files/directories/both are listed in the specified order (date/size)
**Status:** Pass
**Screenshots:**
To be added

### Test Case 7: List Files in Recycle Bin in detailed mode
**Objective:** Verify that deleted files/directories appear in the recycle bin list in detailed mode 
**Steps**
1. To do This step it is first necessary to do any of the previous tests (1-4) until the Run: `./recycle_bin.sh delete ...`
2. Run: `./recycle_bin.sh list --detailed`
**Expected Result**
- All files/directories/both are listed
**Actual Result** All files/directories/both are listed in detailed mode
**Status:** Pass
**Screenshots:**
To be added

### Test Case 8: List Files in Recycle Bin in detailed mode and sorted by date/size
**Objective:** Verify that deleted files/directories appear in the recycle bin list in detailed mode and also sorted by name/size
**Steps**
1. To do This step it is first necessary to do any of the previous tests (1-4) until the Run: `./recycle_bin.sh delete ...`
2. Run: `./recycle_bin.sh list --detailed --sort date` or `./recycle_bin.sh list --detailed --sort size`
**Expected Result**
- All files/directories/both are listed
**Actual Result** All files/directories/both are listed in detailed mode and in the specified order (date/size)
**Status:** Pass
**Screenshots:**
To be added

### NOTE: In Tests 5 and 7 the items are by default sorted by name, it can be specified in tests 6 and 8 that the list is supposed to be sorted by name but it is redundant to do so

### Test Case 9: Restore a file by id
**Objective:** Verify that a file that has previously been deleted is now restored to its original path
**Steps**
1. To do This step it is first necessary to do any of the previous tests (5-8) for the user to be able to have both a deleted file to restore and also be able to see the file id
2. Run: `./recycle_bin.sh restore id` "id" = the numerical id of the file attributed to it during the deletion process
**Expected Result**
- Specified file is restored to its original path, keeping timestamps and permissions
- Metadata Entrie of the file is Removed
**Actual Result** Specified file is restored to its original path, keeping timestamps and permissions
**Status:** Pass
**Screenshots:**
To be added

### Test Case 10: Restore a file by name
**Objective:** Verify that a file that has previously been deleted is now restored to its original path
**Steps**
1. To do This step it is first necessary to do any of the previous tests (5-8) for the user to be able to have both a deleted file to restore and also be able to see the file name if it the current user doesn't remeber the deleted file name
2. Run: `./recycle_bin.sh restore name` name = the name of the file before deletion 
**Expected Result**
- Specified file is restored to its original path, keeping timestamps and permissions
- Metadata Entrie of the file is Removed
**Actual Result** Specified file is restored to its original path, keeping timestamps and permissions
**Status:** Pass
**Screenshots:**
To be added

### Test Case 11: Restore a Directory by id
**Objective:** Verify that a Directory that has previously been deleted is now restored to its original path
**Steps**
1. To do This step it is first necessary to do any of the previous tests (5-8) for the user to be able to have both a deleted directory to restore and also be able to see the directory id
2. Run: `./recycle_bin.sh restore id` "id" = the numerical id of the directory attributed to it during the deletion process
**Expected Result**
- Specified directory is restored to its original path
- Metadata Entrie of the directory is Removed
**Actual Result** Specified directory is restored to its original path
**Status:** Pass
**Screenshots:**
To be added

### Test Case 12: Restore a Directory by name
**Objective:** Verify that a Directory that has previously been deleted is now restored to its original path
**Steps**
1. To do This step it is first necessary to do any of the previous tests (5-8) for the user to be able to have both a deleted Directory to restore and also be able to see the file name if it the current user doesn't remeber the deleted Directory name
2. Run: `./recycle_bin.sh restore name` name = the name of the Directory before deletion 
**Expected Result**
- Specified directory is restored to its original path
- Metadata Entrie of the directory is Removed
**Actual Result** Specified direcotry is restored to its original path
**Status:** Pass
**Screenshots:**
To be added


### Test Case 13: Restore a file when original directories are missing
**Objective:** Verify that a file that has previously been deleted and has directory(ies) missing off of its original path is now restored to its original path
**Steps**
1. To do This step it is first necessary to do any of the previous tests (5-8) for the user to be able to have both a deleted file to restore and also be able to see the file name if it the current user doesn't remeber the deleted file name
2. Run: `./recycle_bin.sh restore name` name = the name of the file before deletion or `./recycle_bin.sh restore id` "id" = the numerical id of the file attributed to it during the deletion process
**Expected Result**
- Missing Directories were recreated to have the file be on its original path
- Specified file is restored to its original path, keeping timestamps and permissions
- Metadata Entrie of the file is Removed
**Actual Result** Specified file is restored to its original path, keeping timestamps and permissions
**Status:** Pass
**Screenshots:**
To be added

### Test Case 14: Restore a file when there is a file with the same name in the original path (Overwrite)
**Objective:** Verify that a file that has previously been deleted and is being restored to a path where there already exists a file with the same name is correctly overwrites the file with the same name
**Steps**
1. To do This step it is first necessary to do any of the previous tests (5-8) for the user to be able to have both a deleted file to restore and also be able to see the file name if it the current user doesn't remeber the deleted file name
2. For the purpose of testing the user must create a file with the same name and type in the original path of the deleted file
3. Run: `./recycle_bin.sh restore name` name = the name of the file before deletion or `./recycle_bin.sh restore id` "id" = the numerical id of the file attributed to it during the deletion process
4. When asked for user input user must press O (Overwrite)
**Expected Result**
- Specified file is restored to its original path, keeping timestamps and permissions and overwriting the file with the same name
- Metadata Entrie of the file is Removed
**Actual Result** Specified file is restored to its original path, keeping timestamps and permissions and overwriting the file with the same name
**Status:** Pass
**Screenshots:**
To be added

### Test Case 15: Restore a file when there is a file with the same name in the original path (Resotre With Modified Name)
**Objective:** Verify that a file that has previously been deleted and is being restored to a path where there already exists a file with the same name is correctly restored with a modified name (original name + _ + id + .type)
**Steps**
1. To do This step it is first necessary to do any of the previous tests (5-8) for the user to be able to have both a deleted file to restore and also be able to see the file name if it the current user doesn't remeber the deleted file name
2. For the purpose of testing the user must create a file with the same name and type in the original path of the deleted file
3. Run: `./recycle_bin.sh restore name` name = the name of the file before deletion or `./recycle_bin.sh restore id` "id" = the numerical id of the file attributed to it during the deletion process
4. When asked for user input user must press R (Restore with modified name)
**Expected Result**
- Specified file is restored to its original path, keeping timestamps and permissions and changing its name to not cause conflict with the pre-existing file
- Metadata Entrie of the file is Removed
**Actual Result** Specified file is restored to its original path, keeping timestamps and permissions and changing its name to not cause conflict with the pre-existing file
**Status:** Pass
**Screenshots:**
To be added

### Test Case 16: Restore a file when there is a file with the same name in the original path (Cancel)
**Objective:** Verify that a file that has previously been deleted and is being restored to a path where there already exists a file with the same name is correctly restored with a modified name (original name + _ + id + .type)
**Steps**
1. To do This step it is first necessary to do any of the previous tests (5-8) for the user to be able to have both a deleted file to restore and also be able to see the file name if it the current user doesn't remeber the deleted file name
2. For the purpose of testing the user must create a file with the same name and type in the original path of the deleted file
3. Run: `./recycle_bin.sh restore name` name = the name of the file before deletion or `./recycle_bin.sh restore id` "id" = the numerical id of the file attributed to it during the deletion process
4. When asked for user input user must press C
**Expected Result**
- Process is canceled
- Specified file is not restored
**Actual Result** Specified file is not restored
**Status:** Pass
**Screenshots:**
To be added

### Test Case 17: Restore a directory with a directory with the same name in the original path
**Objective:** Verify that a directory that has previously been deleted and is being restored to a path where there already exists a directory with the same name is correctly restored
**Steps**
1. To do This step it is first necessary to do any of the previous tests (5-8) for the user to be able to have both a deleted directory to restore and also be able to see the directory name if it the current user doesn't remeber the deleted directory name
2. For the purpose of testing the user must create a directory with the same name in the original path of the deleted directory
3. Run: `./recycle_bin.sh restore name` name = the name of the directory before deletion or `./recycle_bin.sh restore id` "id" = the numerical id of the file attributed to it during the deletion process
**Expected Result**
- Specified directory is "Merged" with the pre-existing one
- Metadata Entrie of the directory is Removed
**Actual Result** Specified directory is "Merged" with the pre-existing one
**Status:** Pass
**Screenshots:**
To be added

### Test Case 18: Empty Recycle bin with confirmation
**Objective:** Verify recycle bin has been completely emptied
**Steps**
1. To do This step it is first necessary to do any of the previous tests (1-4) for the user to have anything so it he is able to empty the recycle bin
2. Run `./recycle_bin.sh empty`
3. When asked for user input user must press Y
**Expected Result**
- Recycle-Bin is emptied 
- All metadata entries are removed
**Actual Result** Recycle bin is emptied
**Status:** Pass
**Screenshots:**
To be added

### Test Case 19: Empty Recycle bin without confirmation
**Objective:** Verify recycle bin has been completely emptied
**Steps**
1. To do This step it is first necessary to do any of the previous tests (1-4) for the user to have anything so it he is able to empty the recycle bin
2. Run `./recycle_bin.sh empty --force`
**Expected Result**
- Recycle-Bin is emptied 
- All metadata entries are removed
**Actual Result** Recycle bin is emptied
**Status:** Pass
**Screenshots:**
To be added

### Test Case 20: Permenantly delete a file/directory in the recycle bin with confirmation using id
**Objective:** Verify that a file/directory has been permanently deleted
**Steps**
1. To do This step it is first necessary to do any of the previous tests (5-8) for the user to have anything so he is able to empty the recycle bin, also if needed the user uses list to know the id of the file being deleted
2. Run `./recycle_bin.sh empty id` "id" = the numerical id of the directory attributed to it during the deletion process
3. When asked for user input user must press Y
**Expected Result**
- File/Directory is permanently deleted
- Metadata entrie is removed
**Actual Result** File/Directory is permanently deleted
**Status:** Pass
**Screenshots:**
To be added

### Test Case 20: Permenantly delete a file/directory in the recycle bin with confirmation using name
**Objective:** Verify that a file/directory has been permanently deleted
**Steps**
1. To do This step it is first necessary to do any of the previous tests (5-8) for the user to have anything so he is able to empty the recycle bin
2. Run `./recycle_bin.sh empty name` "name" = the original file/directory name
3. When asked for user input user must press Y
**Expected Result**
- File/Directory is permanently deleted
- Metadata entrie is removed
**Actual Result** File/Directory is permanently deleted
**Status:** Pass
**Screenshots:**
To be added

### Test Case 21: Search for a file/directory by its original name
**Objective:** Verify that the search function displays the file/directory being searched on the screen
**Steps**
1. To do This step it is first necessary to do any of the previous tests (1-4)
2. Run `./recycle_bin.sh search name` "name" = the original file/directory name
**Expected Result**
- File/Directory information is displayed on screen
**Actual Result** File/Directory information is displayed on screen
**Status:** Pass
**Screenshots:**
To be added

### Test Case 21: Search for a file/directory by its original type
**Objective:** Verify that the search function displays all the files/directories of the searched type on the screen
**Steps**
1. To do This step it is first necessary to do any of the previous tests (1-4)
2. Run `./recycle_bin.sh search type` "type" = the type of the files / directories being searched, in case of searching for directories user must use DIR as the type
**Expected Result**
- Files/Directories information are displayed on screen
**Actual Result** Files/Directories information are displayed on screen
**Status:** Pass
**Screenshots:**
To be added

### Test Case 22: Search for a file/directory by its date range
**Objective:** Verify that the search function displays all the files/directories of the searched date range on the screen
**Steps**
1. To do This step it is first necessary to do any of the previous tests (1-4)
2. Run `./recycle_bin.sh search date range` "date range" = two dates spanning across time 
**Expected Result**
- Files/Directories, inside the date range, information are displayed on screen
**Actual Result** Files/Directories, inside the date range, information are displayed on screen
**Status:** Pass
**Screenshots:**
To be added

