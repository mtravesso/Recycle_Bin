# TECHNICAL_DOC.md  
## Linux Recycle Bin Simulation
## Authors
Nuno Costa (125120) & Martim Travesso Dais(12595)

## 1. System Architecture Diagram
![alt text](ScreenShots/Diagrams/Architecture_Diagram.jpg)

## 2. Data Flow Diagrams
#### **File Deletion Data Flow**
![alt text](ScreenShots/Diagrams/DeleteFIle_DataFlow.jpg)

#### **File Restoration Data Flow**  
![alt text](ScreenShots/Diagrams/Restorefile_DataFlow.jpg)

#### **File List Data Flow** 
![alt text](ScreenShots/Diagrams/list_recycled_DataFlow.jpg)

#### **File Search Data Flow** 
![alt text](ScreenShots/Diagrams/Search_FIle_DataFlow.jpg)

#### **Empty Recycle Bin Data Flow**  
![alt text](ScreenShots/Diagrams/Empty_DataFlow.jpg)

#### **Show Statistics Data Flow**  
![alt text](ScreenShots/Diagrams/show_statistics_DataFlow.jpg)

#### **Cleanup Data Flow**
![alt text](ScreenShots/Diagrams/Auto_cleanup_DataFlow.jpg)

#### **Preview File Data Flow**
![alt text](ScreenShots/Diagrams/Preview_file_DataFlow.jpg)

#### **Check quota Data Flow**
![alt text](ScreenShots/Diagrams/Check_quota_DataFLow.jpg)

## 3. Metadata Schema Explanation
The metadata.db file is a CSV database used by the recycle bin to keep track of all deleted files and directories. Each entry represents a single item that has been moved to the recycle bin, preserving key information needed for listing, searching, and restoring, each item in the Metadata.db file follows a set of entries in the file, these being comprised of the following: 
- **ID:** Unique Indentifier for each item moved to the recycle bin, it aids in most of the operations and allows for items of the same name and type to not have conflict with each other, since the items are renamed with their respective id on entering the recycle bin
- **ORIGINAL_NAME:** Name of the item before it was moved to the Recycle bin
- **ORIGINAL_PATH:** Path of the item before it was moved to the Recycle bin
- **DELETION_DATE:** Date the item was moved to the Recycle bin
- **FILE_SIZE:** The Size of the item
- **FILE_TYPE:** The type of the item (In case of directories the type is presented as DIR since directories don't have a specific .type appended to the end of their names)
- **PERMISSIONS:** The Permissions the file has, these are stored so it can be restored with all its permissions intact
- **OWNER:** Original Owner of the file


## 4. Function descriptions

#### 1. initialize_recyclebin()
    Description: Creates recycle bin directory structure and required files;
    Parameters: None;
    Return: Returns 0 on success and 1 on failure.

#### 2. generate_unique_id()
    Description: Generates a unique identifier for deleted files;
    Parameters: None;
    Return: Prints unique ID to stdout.

#### 3. delete_file()
    Description: Moves file/directory to recycle bin with metadata tracking;
    Parameters: One or more file/directory paths;
    Return: Returns 0 if all operations succeed, 1 if any fail.

#### 4. list_recycled()
    Description: Lists all items in recycle bin in formatted table;
    Parameters: (Optional) --detailed for detailed view, --sort for sorting;
    Return: Returns 0 on success.

#### 5. restore_file()
    Description: Restores a file from recycle bin to its original location;
    Parameters: File ID or original filename;
    Return: Returns 0 on success and 1 on failure.

#### 6. empty_recyclebin()
    Description: Permanently deletes items from recycle bin;
    Parameters: (Optional) File ID for single item, --force to skip confirmation;
    Return: Returns 0 on success.

#### 7. search_recycled()
    Description: Searches for files in recycle bin by pattern or date range;
    Parameters: Search pattern or "date start_date end_date";
    Return: Returns 0 on success.

#### 8. display_help()
    Description: Shows comprehensive usage information and examples;
    Parameters: None;
    Return: Returns 0.

#### 9. show_statistics()
    Description: Displays recycle bin usage statistics and metrics;
    Parameters: None;
    Return: Returns 0 on success.

#### 10. auto_cleanup()
    Description: Automatically removes items older than retention period;
    Parameters: None;
    Return: Returns 0 on success.

#### 11. check_quota()
    Description: Checks recycle bin size against configured quota limits;
    Parameters: None;
    Return: Returns 0.

#### 12. preview_file()
    Description: Shows preview of file contents for identification;
    Parameters: File ID or original filename;
    Return: Returns 0 on success, 1 on failure.


## 5. Design decisions and rationale
### Language:
    The whole project was written in Bash in order to be compatible with most linux distros, it also ensures that no extra dependencies are necessary.

### Metadata Entries:
    As explained in the third section, the Metadata file is structured specifically so all the processes within the script run with no problems, 
    since it obligates all of the entries to follow a specific set of rules that cannot be broken, unless changed by manual modification.

### Logging Operations:
    By logging all operations, the user can keep track of actions performed by the script, helping prevent cases of misguided accountability 
    toward the script or other users on the same system. This also helps identify issues such as accidental deletion or restoration of files.

### Error Handling:
    The script includes comprehensive error handling to ensure the system remains robust and user-friendly. 
    When an operation fails for any reason, the script provides clear error messages and warnings, allowing the user to understand why 
    the operation did not complete successfully.

### Base Functionalities:
    The script includes a plethora of base functionalities such as, item(s) deletion, item restoration, item listing and searching and permanent 
    deletion of an item or the entirety of the items in the recycle bin.
    This functionalities ensure that for one, the script works as an alternative to built-in commands like -rm that allow no recovering of deleted items
    by including an item deletion system that doesn't consist of permanent delition, instead moving the item to a folder before being either restored 
    or permanently deleted.
    In the same vein by including restoration and permanent deletion processes the user can have more control over the files while not taking away the
    permanent deletion functionality a command like -rm provides.
    As well as includin this features, to ensure the user has an all in one experience with no need to use external tools such as a file manager to view
    the deleted files, the script also comes built-in with listing and searching functionalities that allow the user to view the items in the recycle bin
    with ease

### Extra Functionalities:
    In addition to its core features, the script includes several optional functions that enhance usability. These include showing statistics, 
    automatic cleanup, quota checking, and file preview.
    The quota check feature allows users to set a limit on how much space the recycle bin can occupy. Once the limit is reached, the script
    can automatically delete the oldest files to free up space.
    The automatic cleanup function permanently deletes files older than a configurable period (30 days by default), helping maintain 
    disk space without user intervention.
    The show statistics function provides detailed information about the recycle bin itself, not just the files it contains, giving users 
    insights into usage patterns.
    The file preview functionality allows users to view a limited number of lines from a deleted file, making it easier to identify 
    files before restoring or permanently deleting them.

### Help Function:
    The script includes a comprehensive help function that guides users through its features and usage. 
    By running the help command, users can view a clear description of available operations, their expected arguments, and examples of usage. 
    This functionality ensures that even users unfamiliar with the script or command-line interfaces can understand and use the recycle bin effectively.

