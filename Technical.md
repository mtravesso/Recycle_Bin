# TECHNICAL_DOC.md  
## Linux Recycle Bin Simulation
## Authors
Nuno Costa (125120) & Martim Travesso Dais(12595)

### 1. System Architecture Diagram
![alt text](ScreenShots/Diagrams/Architecture_Diagram.jpg)

### 2. Data Flow Diagrams
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

### 3. Metadata Schema Explanation


### 4. Function descriptions

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


