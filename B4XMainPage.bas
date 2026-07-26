B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
#Macro: After Save, Sync Layouts, ide://run?File=%ADDITIONAL%\..\B4X\JsonLayouts.jar&Args=%PROJECT%&Args=%PROJECT_NAME%
#Macro: Title, JsonLayouts folder, ide://run?File=%WINDIR%\explorer.exe&Args=%PROJECT%\JsonLayouts
'#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#Macro: Title, Export B4XPages, ide://run?File=%B4X%\Zipper.jar&Args=%PROJECT_NAME%.zip
#End Region

Sub Class_Globals

    Private Root As B4XView
    Private xui As XUI
    
    Private MemDB As SQL
    Private AutoSaveTimer As Timer
    Private DataManagementTimer As Timer
    
    ' UI Controls
	Private pnlTop As B4XView
	Private pnlInput As B4XView
	Private pnlButtons As B4XView
	Private lblTitle As B4XView
    Private lstData As ListView
    Private txtName As TextField
	Private txtEmail As TextField
    Private btnAdd As B4XView
    Private btnUpdate As B4XView
    Private btnDelete As B4XView
    Private lblStatus As Label
    Private lblRecordCount As Label
    
    ' Configurations
    Private Const DB_NAME As String = "persistent.db"
    Private Const DB_TMP As String = "persistent.db.tmp"
    Private Const AUTO_SAVE_INTERVAL_MS As Int = 10000 '300000 ' 5 minutes
    Private Const DATA_CLEANUP_INTERVAL_MS As Int = 20000 '60000 ' 1 minute
    Private Const MAX_RECORDS As Int = 1000
    Private Const OLD_RECORD_DAYS As Int = 30
End Sub

Public Sub Initialize
    ' Basic initialization
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
    Root = Root1
	Root.LoadLayout("Layout1")
	
    'CreateProgrammaticUI
    B4XPages.SetTitle(Me, "SQLite MemDB Demo")

    ConfigureListView
    
    ' 1. Spin up the fresh in-memory space
    InitializeMemoryDB
    
    ' 2. Hydrate memory from disk backup if it exists
    If File.Exists(GetDBFolder, DB_NAME) Then
        LoadBackupIntoMemory
    Else
        CreateInitialTables ' First run configuration
    End If
    
    ' 3. Boot up the background auto-save loop
    StartAutoSaveLoop
    
    ' 4. Start data management (cleanup old records)
    StartDataManagementLoop
    
    ' 5. Refresh UI
    RefreshDataDisplay
End Sub

#Region UI

Private Sub ConfigureListView
    UpdateStatus("Ready")
End Sub

#End Region

#Region Programmatic UI
'Private Sub CreateProgrammaticUI
	'Root.SetLayoutAnimated(0, -1, -1, -1, -1)
	'Root.Color = xui.Color_White

    'Dim pnlTop As Panel
    'pnlTop.Initialize("pnlTop")
	'pnlTop.SetLayoutAnimated(0, 0, 0, Root.Width, 100)
	'Root.AddView(pnlTop, 0, 0, Root.Width, 100)

    'Dim lblTitle As Label
    'lblTitle.Initialize("lblTitle")
	'lblTitle.Text = "SQLite Memory Database Demo"
	'lblTitle.SetLayoutAnimated(0, 10, 10, Root.Width - 20, 30)
	'lblTitle.TextSize = 18
	'lblTitle.TextColor = xui.Color_RGB(0, 102, 204)
	'lblTitle.Font = xui.CreateFont("Arial", 18)
	'pnlTop.AddView(lblTitle, 10, 10, Root.Width - 20, 30)

	'lblRecordCount.Initialize("lblRecordCount")
	'lblRecordCount.Text = "Total: 0 active records"
	'lblRecordCount.SetLayoutAnimated(0, 10, 50, Root.Width - 20, 24)
	'lblRecordCount.TextSize = 12
	'lblRecordCount.TextColor = xui.Color_RGB(80, 80, 80)
	'pnlTop.AddView(lblRecordCount, 10, 50, Root.Width - 20, 24)

	'lblStatus.Initialize("lblStatus")
	'lblStatus.Text = "Ready"
	'lblStatus.SetLayoutAnimated(0, 10, 75, Root.Width - 20, 20)
	'lblStatus.TextSize = 10
	'lblStatus.TextColor = xui.Color_RGB(100, 100, 100)
	'pnlTop.AddView(lblStatus, 10, 75, Root.Width - 20, 20)

    'Dim pnlInput As Panel
    'pnlInput.Initialize("pnlInput")
    'pnlInput.SetLayoutAnimated(0, 0, 105, Root.Width, 50)
    'Root.AddView(pnlInput, 0, 105, Root.Width, 50)

	'Dim lblName As Label
	'lblName.Initialize("lblName")
	'lblName.Text = "Name:"
	'lblName.SetLayoutAnimated(0, 10, 5, 40, 30)
	'lblName.TextSize = 12
	'pnlInput.AddView(lblName, 10, 5, 40, 30)
	'
	'txtName.Initialize("txtName")
	'txtName.SetLayoutAnimated(0, 55, 5, Root.Width - 65, 30)
	'txtName.PromptText = "Enter user name..."
	'pnlInput.AddView(txtName, 55, 5, Root.Width - 65, 30)

    'Dim pnlButtons As Panel
    'pnlButtons.Initialize("pnlButtons")
    'pnlButtons.SetLayoutAnimated(0, 0, 160, Root.Width, 40)
    'Root.AddView(pnlButtons, 0, 160, Root.Width, 40)

    'Dim btnWidth As Int = (Root.Width - 40) / 3
    'btnAdd.Initialize("btnAdd")
    'btnAdd.Text = "Add"
    'btnAdd.SetLayoutAnimated(0, 10, 5, btnWidth, 32)
    'btnAdd.SetColorAndBorder(xui.Color_RGB(76, 175, 80), 0, 0, 0)
    'btnAdd.TextColor = xui.Color_White
    'pnlButtons.AddView(btnAdd, 10, 5, btnWidth, 32)

    'btnUpdate.Initialize("btnUpdate")
    'btnUpdate.Text = "Update"
    'btnUpdate.SetLayoutAnimated(0, 20 + btnWidth, 5, btnWidth, 32)
    'btnUpdate.SetColorAndBorder(xui.Color_RGB(33, 150, 243), 0, 0, 0)
    'btnUpdate.TextColor = xui.Color_White
    'pnlButtons.AddView(btnUpdate, 20 + btnWidth, 5, btnWidth, 32)

    'btnDelete.Initialize("btnDelete")
    'btnDelete.Text = "Delete"
    'btnDelete.SetLayoutAnimated(0, 30 + 2 * btnWidth, 5, btnWidth, 32)
    'btnDelete.SetColorAndBorder(xui.Color_RGB(244, 67, 54), 0, 0, 0)
    'btnDelete.TextColor = xui.Color_White
    'pnlButtons.AddView(btnDelete, 30 + 2 * btnWidth, 5, btnWidth, 32)

    'lstData.Initialize("lstData")
    'Dim lstY As Int = 205
    'lstData.SetLayoutAnimated(0, 0, lstY, Root.Width, Max(100, Root.Height - lstY - 10))
    'Root.AddView(lstData, 0, lstY, Root.Width, Max(100, Root.Height - lstY - 10))
'End Sub
#End Region

#Region Database Initialization & Hydration

Private Sub InitializeMemoryDB
    #If B4J
    MemDB.InitializeSQLite("", ":memory:", True)
    #Else
    MemDB.Initialize("", ":memory:", True)
    #End If
    Log("In-Memory SQLite space established.")
End Sub

' DISK -> MEMORY
Private Sub LoadBackupIntoMemory
    Dim FullDiskPath As String = File.Combine(GetDBFolder, DB_NAME)
    Try
        ' Attach disk database
        MemDB.ExecNonQuery2("ATTACH DATABASE ? AS disk_db", Array(FullDiskPath))
        
        ' Begin transaction for atomic operation
        MemDB.ExecNonQuery("BEGIN TRANSACTION")
        
        ' Check if users table exists in memory
        Dim rs As ResultSet = MemDB.ExecQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='users'")
        If rs.NextRow Then
            rs.Close
            ' Table exists - drop it to refresh
            MemDB.ExecNonQuery("DROP TABLE users")
        End If
        rs.Close
        
        ' Create table with data from disk (correct way)
        MemDB.ExecNonQuery("CREATE TABLE users AS SELECT * FROM disk_db.users")
        
        ' Commit the transaction
        MemDB.ExecNonQuery("COMMIT")
        
        ' Verify data was loaded
        Dim count As Int = MemDB.ExecQuerySingleResult("SELECT COUNT(*) FROM users")
        Log($"Hydration Complete: ${count} users loaded into RAM."$)
        
    Catch
        Log("Hydration Failure: " & LastException.Message)
        ' Rollback on error
        Try
            MemDB.ExecNonQuery("ROLLBACK")
        Catch
            ' Ignore rollback errors
			Log(LastException.Message)
        End Try
    End Try
    
    ' Always detach
    Try
        MemDB.ExecNonQuery("DETACH DATABASE disk_db")
    Catch
        Log("Detach warning: " & LastException.Message)
    End Try
End Sub

Private Sub CreateInitialTables
    ' Create table with timestamps
    MemDB.ExecNonQuery("CREATE TABLE users (" & _
                       "id INTEGER PRIMARY KEY AUTOINCREMENT, " & _
                       "name TEXT NOT NULL, " & _
                       "email TEXT, " & _
                       "age INTEGER, " & _
                       "created_at TEXT DEFAULT CURRENT_TIMESTAMP, " & _
                       "updated_at TEXT DEFAULT CURRENT_TIMESTAMP, " & _
                       "is_active INTEGER DEFAULT 1)")
    
    ' Create index for faster queries
    MemDB.ExecNonQuery("CREATE INDEX idx_users_created ON users(created_at)")
    MemDB.ExecNonQuery("CREATE INDEX idx_users_updated ON users(updated_at)")
    MemDB.ExecNonQuery("CREATE INDEX idx_users_active ON users(is_active)")
    
    ' Insert sample data
    Dim sampleNames As List = Array("John Doe", "Jane Smith", "Bob Johnson", "Alice Williams", "Charlie Brown")
    For Each name As String In sampleNames
        Dim email As String = name.ToLowerCase.Replace(" ", ".") & "@example.com"
        Dim age As Int = 20 + Rnd(1, 40)
        AddUser(name, email, age)
    Next
    
    Log("Initial tables created with sample data.")
End Sub

#End Region

#Region CRUD Operations

' CREATE - Add new user
Public Sub AddUser (name As String, email As String, age As Int) As Boolean
    Try
        If name.Trim = "" Then
            UpdateStatus("Error: Name cannot be empty")
            Return False
        End If
        
        Dim sql As String = "INSERT INTO users (name, email, age, created_at, updated_at) VALUES (?, ?, ?, datetime('now'), datetime('now'))"
        MemDB.ExecNonQuery2(sql, Array(name.Trim, email.Trim, age))
        
        UpdateStatus($"User '${name}' added successfully"$)
        RefreshDataDisplay
        Return True
        
    Catch
        Log("Add user error: " & LastException.Message)
        UpdateStatus("Error adding user: " & LastException.Message)
        Return False
    End Try
End Sub

' READ - Get all users (active only)
Public Sub GetUsers As List
    Dim users As List
    users.Initialize
    
    Try
        Dim sql As String = "SELECT id, name, email, age, created_at, updated_at, is_active FROM users WHERE is_active = 1 ORDER BY created_at DESC"
        Dim rs As ResultSet = MemDB.ExecQuery(sql)
        
        Do While rs.NextRow
            Dim user As Map
            user.Initialize
            user.Put("id", rs.GetInt("id"))
            user.Put("name", rs.GetString("name"))
            user.Put("email", rs.GetString("email"))
            user.Put("age", rs.GetInt("age"))
            user.Put("created_at", rs.GetString("created_at"))
            user.Put("updated_at", rs.GetString("updated_at"))
            user.Put("is_active", rs.GetInt("is_active"))
            users.Add(user)
        Loop
        rs.Close
        
    Catch
        Log("Get users error: " & LastException.Message)
    End Try
    
    Return users
End Sub

' READ - Get user by ID
Public Sub GetUserById(id As Int) As Map
    Dim user As Map
    user.Initialize
    
    Try
        Dim sql As String = "SELECT id, name, email, age, created_at, updated_at, is_active FROM users WHERE id = ?"
        Dim rs As ResultSet = MemDB.ExecQuery2(sql, Array(id))
        
        If rs.NextRow Then
            user.Put("id", rs.GetInt("id"))
            user.Put("name", rs.GetString("name"))
            user.Put("email", rs.GetString("email"))
            user.Put("age", rs.GetInt("age"))
            user.Put("created_at", rs.GetString("created_at"))
            user.Put("updated_at", rs.GetString("updated_at"))
            user.Put("is_active", rs.GetInt("is_active"))
        End If
        rs.Close
        
    Catch
        Log("Get user error: " & LastException.Message)
    End Try
    
    Return user
End Sub

' UPDATE - Update user
Public Sub UpdateUser (id As Int, name As String, email As String, age As Int) As Boolean
    Try
        If name.Trim = "" Then
            UpdateStatus("Error: Name cannot be empty")
            Return False
        End If
        
        Dim sql As String = "UPDATE users SET name = ?, email = ?, age = ?, updated_at = datetime('now') WHERE id = ? AND is_active = 1"
        MemDB.ExecNonQuery2(sql, Array(name.Trim, email.Trim, age, id))
        Dim rowsAffected As Int = MemDB.ExecQuerySingleResult("SELECT changes()")
        
        If rowsAffected > 0 Then
            UpdateStatus($"User '${name}' updated successfully"$)
            RefreshDataDisplay
            Return True
        Else
            UpdateStatus("User not found or already deleted")
            Return False
        End If
        
    Catch
        Log("Update user error: " & LastException.Message)
        UpdateStatus("Error updating user: " & LastException.Message)
        Return False
    End Try
End Sub

' DELETE - Soft delete user (set inactive)
Public Sub DeleteUser(id As Int) As Boolean
    Try
        ' Get name for status message
        Dim user As Map = GetUserById(id)
        Dim userName As String = user.Get("name")
        
        ' Soft delete - mark as inactive
        Dim sql As String = "UPDATE users SET is_active = 0, updated_at = datetime('now') WHERE id = ?"
        MemDB.ExecNonQuery2(sql, Array(id))
        Dim rowsAffected As Int = MemDB.ExecQuerySingleResult("SELECT changes()")
        
        If rowsAffected > 0 Then
            UpdateStatus($"User '${userName}' deleted (soft delete)"$)
            RefreshDataDisplay
            Return True
        Else
            UpdateStatus("User not found or already deleted")
            Return False
        End If
        
    Catch
        Log("Delete user error: " & LastException.Message)
        UpdateStatus("Error deleting user: " & LastException.Message)
        Return False
    End Try
End Sub

' HARD DELETE - Permanently remove inactive users
Public Sub HardDeleteInactiveUsers() As Int
    Try
        MemDB.ExecNonQuery("DELETE FROM users WHERE is_active = 0")
        Dim rowsAffected As Int = MemDB.ExecQuerySingleResult("SELECT changes()")
        
        If rowsAffected > 0 Then
            Log($"Hard deleted ${rowsAffected} inactive users"$)
            UpdateStatus($"Permanently removed ${rowsAffected} inactive users"$)
            RefreshDataDisplay
        End If
        
        Return rowsAffected
        
    Catch
        Log("Hard delete error: " & LastException.Message)
        Return 0
    End Try
End Sub

#End Region

#Region Data Management & Cleanup

Private Sub StartDataManagementLoop
    DataManagementTimer.Initialize("DataManagementTimer", DATA_CLEANUP_INTERVAL_MS)
    DataManagementTimer.Enabled = True
    Log("Data management engine initiated.")
End Sub

Private Sub DataManagementTimer_Tick
    Log("Data management check triggered...")
    
    ' 1. Check record count and delete oldest if over limit
    ManageRecordCount
    
    ' 2. Delete records older than 30 days
    DeleteOldRecords
    
    ' 3. Optional: Hard delete inactive users that were soft-deleted > 7 days ago
    HardDeleteOldInactiveUsers
End Sub

Private Sub ManageRecordCount
    Try
        Dim count As Int = MemDB.ExecQuerySingleResult("SELECT COUNT(*) FROM users WHERE is_active = 1")
        
        If count > MAX_RECORDS Then
            Dim toDelete As Int = count - MAX_RECORDS
            Log($"Record limit exceeded (${count}/${MAX_RECORDS}). Deleting ${toDelete} oldest active records..."$)
            
            ' Delete oldest active records
            Dim sql As String = "DELETE FROM users WHERE id IN (" & _
                               "SELECT id FROM users WHERE is_active = 1 " & _
                               "ORDER BY created_at ASC LIMIT ?)"
            MemDB.ExecNonQuery2(sql, Array(toDelete))
            
            UpdateStatus($"Auto-cleanup: Removed ${toDelete} oldest records (limit: ${MAX_RECORDS})"$)
            RefreshDataDisplay
        End If
        
    Catch
        Log("Manage record count error: " & LastException.Message)
    End Try
End Sub

Private Sub DeleteOldRecords
    Try
        MemDB.ExecNonQuery2("DELETE FROM users WHERE is_active = 1 AND created_at < datetime('now', ?)", Array("-" & OLD_RECORD_DAYS & " days"))
        Dim rowsAffected As Int = MemDB.ExecQuerySingleResult("SELECT changes()")
        
        If rowsAffected > 0 Then
            Log($"Deleted ${rowsAffected} records older than ${OLD_RECORD_DAYS} days"$)
            UpdateStatus($"Removed ${rowsAffected} old records (>${OLD_RECORD_DAYS} days)"$)
            RefreshDataDisplay
        End If
        
    Catch
        Log("Delete old records error: " & LastException.Message)
    End Try
End Sub

Private Sub HardDeleteOldInactiveUsers
    Try
        MemDB.ExecNonQuery("DELETE FROM users WHERE is_active = 0 AND updated_at < datetime('now', '-7 days')")
        Dim rowsAffected As Int = MemDB.ExecQuerySingleResult("SELECT changes()")
        
        If rowsAffected > 0 Then
            Log($"Hard deleted ${rowsAffected} old inactive users"$)
            UpdateStatus($"Permanently removed ${rowsAffected} old inactive users"$)
            RefreshDataDisplay
        End If
        
    Catch
        Log("Hard delete old inactive error: " & LastException.Message)
    End Try
End Sub

#End Region

#Region Auto-Save Infrastructure

Private Sub StartAutoSaveLoop
    AutoSaveTimer.Initialize("AutoSaveTimer", AUTO_SAVE_INTERVAL_MS)
    AutoSaveTimer.Enabled = True
    Log("Background auto-save engine initiated.")
End Sub

Private Sub AutoSaveTimer_Tick
    Log("Auto-save interval triggered...")
    SafeVacuumToDisk
End Sub

Public Sub SafeVacuumToDisk
    Dim TargetFolder As String = GetDBFolder
    Dim ActualPath As String = File.Combine(TargetFolder, DB_NAME)
    Dim TempPath As String = File.Combine(TargetFolder, DB_TMP)
    
    ' Clean up residual temp files
    If File.Exists(TargetFolder, DB_TMP) Then
        File.Delete(TargetFolder, DB_TMP)
    End If
    
    Try
        ' Verify memory database has data before saving
        Dim recordCount As Int = MemDB.ExecQuerySingleResult("SELECT COUNT(*) FROM users")
        If recordCount = 0 Then
            Log("Warning: No data in memory, skipping save.")
            Return
        End If
        
        ' 1. Vacuum memory directly into the isolated sandbox file
        MemDB.ExecNonQuery2("VACUUM INTO ?", Array(TempPath))
        
        ' Verify the temp file was created
        If File.Exists(TargetFolder, DB_TMP) Then
            Dim fileSize As Long = File.Size(TargetFolder, DB_TMP)
            If fileSize > 0 Then
                ' 2. Atomic swap on physical filesystem
                If File.Exists(TargetFolder, DB_NAME) Then
                    File.Delete(TargetFolder, DB_NAME)
                End If
                
                File.Copy(TargetFolder, DB_TMP, TargetFolder, DB_NAME)
                File.Delete(TargetFolder, DB_TMP)
                
                Log($"Auto-Save Success: ${fileSize} bytes written to disk."$)
                UpdateStatus($"Auto-save completed (${recordCount} records)"$)
            Else
                Log("Auto-Save Failed: Temp file is empty.")
                File.Delete(TargetFolder, DB_TMP)
            End If
        Else
            Log("Auto-Save Failed: Temp file not created.")
        End If
        
    Catch
        Log("Auto-Save State: Failed! Reason: " & LastException.Message)
        UpdateStatus("Auto-save failed: " & LastException.Message)
        ' Purge invalid chunk allocations 
        If File.Exists(TargetFolder, DB_TMP) Then
            File.Delete(TargetFolder, DB_TMP)
        End If
    End Try
End Sub

Public Sub SaveAndCleanup
    Log("Saving memory to disk before shutdown...")
    SafeVacuumToDisk
    
    ' Clean up timers
    If AutoSaveTimer.IsInitialized Then
        AutoSaveTimer.Enabled = False
    End If
    
    If DataManagementTimer.IsInitialized Then
        DataManagementTimer.Enabled = False
    End If
    
    ' Close database connection
    If MemDB.IsInitialized Then
        MemDB.Close
        Log("Database connection closed.")
    End If
End Sub

#End Region

#Region UI Event Handlers

Private Sub btnAdd_Click
    Dim name As String = txtName.Text
    Dim email As String = name.ToLowerCase.Replace(" ", ".") & "@example.com"
    Dim age As Int = 25 ' Default age or get from another field
    
    AddUser(name, email, age)
    txtName.Text = ""
End Sub

Private Sub btnUpdate_Click
    If lstData.SelectedIndex >= 0 Then
        Dim selectedItem As String = lstData.SelectedItem
        Dim parts() As String = Regex.Split(":", selectedItem)
        If parts.Length >= 2 Then
            Dim id As Int = parts(0).Trim
            Dim name As String = txtName.Text
            Dim email As String = txtEmail.Text
            
            If name.Trim <> "" Then
                Dim user As Map = GetUserById(id)
                If user.Size > 0 Then
                    Dim email As String = user.Get("email")
                    Dim age As Int = user.Get("age")
                    UpdateUser(id, name, email, age)
                    txtName.Text = ""
                End If
            Else
                UpdateStatus("Please enter a name to update")
            End If
        End If
    Else
        UpdateStatus("Please select a user to update")
    End If
End Sub

Private Sub btnDelete_Click
    If lstData.SelectedIndex >= 0 Then
        Dim selectedItem As String = lstData.SelectedItem
        Dim parts() As String = Regex.Split(":", selectedItem)
        If parts.Length >= 2 Then
            Dim id As Int = parts(0).Trim
            DeleteUser(id)
        End If
    Else
        UpdateStatus("Please select a user to delete")
    End If
End Sub

' UI Helper - Refresh the list view
Private Sub RefreshDataDisplay
    Dim users As List = GetUsers
    lstData.Items.Clear
    
    For Each user As Map In users
        Dim id As Int = user.Get("id")
        Dim name As String = user.Get("name")
        Dim email As String = user.Get("email")
        Dim age As Int = user.Get("age")
        Dim displayText As String = $"${id}: ${name} (${email}) - Age: ${age}"$
        lstData.Items.Add(displayText)
    Next
    
    Dim count As Int = users.Size
    lblRecordCount.Text = $"Total: ${count} active records"$
End Sub

Private Sub UpdateStatus(message As String)
    lblStatus.Text = DateTime.Now & " - " & message
    Log(DateTime.Now & " - " & message)
End Sub

#End Region

#Region Utility Functions

' Cross-Platform Runtime Storage Path Resolver
Private Sub GetDBFolder As String
    #If B4J
    Return File.DirApp
    #Else
    Return File.DirInternal
    #End If
End Sub

' Debug - Display database statistics
Public Sub ShowDatabaseStats
    Try
        Dim total As Int = MemDB.ExecQuerySingleResult("SELECT COUNT(*) FROM users")
        Dim active As Int = MemDB.ExecQuerySingleResult("SELECT COUNT(*) FROM users WHERE is_active = 1")
        Dim inactive As Int = MemDB.ExecQuerySingleResult("SELECT COUNT(*) FROM users WHERE is_active = 0")
        Dim oldest As String = MemDB.ExecQuerySingleResult("SELECT MIN(created_at) FROM users")
        Dim newest As String = MemDB.ExecQuerySingleResult("SELECT MAX(created_at) FROM users")
        
        Log($"=== Database Stats ==="$)
        Log($"Total records: ${total}"$)
        Log($"Active records: ${active}"$)
        Log($"Inactive records: ${inactive}"$)
        Log($"Oldest record: ${oldest}"$)
        Log($"Newest record: ${newest}"$)
        Log($"======================"$)
        
    Catch
        Log("Stats error: " & LastException.Message)
    End Try
End Sub

#End Region

' Handle app close
Private Sub B4XPage_CloseRequest (EventData As Event)
    SaveAndCleanup
End Sub

Private Sub lstData_SelectedIndexChanged (Index As Int)
	
End Sub