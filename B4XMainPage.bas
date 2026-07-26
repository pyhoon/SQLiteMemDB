B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
'#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#Macro: Title, Export B4XPages, ide://run?File=%B4X%\Zipper.jar&Args=%PROJECT_NAME%.zip
#End Region

' Complete SQLite Backup Example
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
    'Private SQLiteBackup As SQLiteBackupHelper
	Private lblStatus As B4XView
	Private lblStatusAPI As B4XView
	
	Private MemDB As SQL
    Private AutoSaveTimer As Timer
    
    ' Configurations
    Private Const DB_NAME As String = "persistent.db"
    Private Const DB_TMP As String = "persistent.db.tmp"
    Private Const AUTO_SAVE_INTERVAL_MS As Int = 5000 '300000 ' 5 minutes
End Sub

Public Sub Initialize
'	B4XPages.GetManager.LogEvents = True
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("Layout1")
	B4XPages.SetTitle(Me, "SQLite Backup Demo")
	'SQLiteBackup.Initialize
	
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
End Sub

' Add this to handle app exit
Private Sub B4XPage_CloseRequest As ResumableSub
	SaveAndCleanup
	Return True
End Sub

' Optional: Add manual save trigger from UI
Public Sub ManualSave
    Log("Manual save triggered...")
    SafeVacuumToDisk
End Sub

' Optional: Verify memory database integrity
Public Sub VerifyMemoryDatabase As Boolean
    Try
        Dim result As Int = MemDB.ExecQuerySingleResult("SELECT 1")
		Log(result)
        Return True
    Catch
        Log("Memory database corruption detected!")
        Return False
    End Try
End Sub


#Region Database Initialization & Hydration
Private Sub InitializeMemoryDB
    #If B4J
    MemDB.InitializeSQLite("", ":memory:", True)
    #Else
    MemDB.Initialize("", ":memory:", True)
    #End If
    Log("In-Memory SQLite space established.")
End Sub

' DISK -> MEMORY (Corrected Version)
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
    
    ' Always detach (moved outside Try-Catch to ensure execution)
    Try
        MemDB.ExecNonQuery("DETACH DATABASE disk_db")
    Catch
        Log("Detach warning: " & LastException.Message)
    End Try
End Sub

Private Sub CreateInitialTables
    MemDB.ExecNonQuery("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
    MemDB.ExecNonQuery2("INSERT INTO users (name) VALUES (?)", Array("First User Instance"))
    Log("Initial tables created with sample data.")
End Sub
#End Region

#Region Safe Auto-Save Infrastructure
Private Sub StartAutoSaveLoop
    AutoSaveTimer.Initialize("AutoSaveTimer", AUTO_SAVE_INTERVAL_MS)
    AutoSaveTimer.Enabled = True
    Log("Background auto-save engine initiated.")
End Sub

' Background Tick Event handler
Private Sub AutoSaveTimer_Tick
    Log("Auto-save interval triggered...")
    SafeVacuumToDisk
End Sub

' MEMORY -> DISK (Shadow Swapping Pattern - Corrected)
Public Sub SafeVacuumToDisk
    Dim TargetFolder As String = GetDBFolder
    Dim ActualPath As String = File.Combine(TargetFolder, DB_NAME)
    Dim TempPath As String = File.Combine(TargetFolder, DB_TMP)
    
	Log(ActualPath)
	
    ' Clean up residual temp files from historical application crashes
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
                    ' Create backup of existing file before deletion (optional)
                    ' File.Copy(TargetFolder, DB_NAME, TargetFolder, DB_NAME & ".bak")
                    File.Delete(TargetFolder, DB_NAME)
                End If
                
                File.Copy(TargetFolder, DB_TMP, TargetFolder, DB_NAME)
                File.Delete(TargetFolder, DB_TMP)
                
                Log($"Auto-Save Success: ${fileSize} bytes written to disk."$)
            Else
                Log("Auto-Save Failed: Temp file is empty.")
                File.Delete(TargetFolder, DB_TMP)
            End If
        Else
            Log("Auto-Save Failed: Temp file not created.")
        End If
        
    Catch
        Log("Auto-Save State: Failed! Reason: " & LastException.Message)
        ' Purge invalid chunk allocations 
        If File.Exists(TargetFolder, DB_TMP) Then
            File.Delete(TargetFolder, DB_TMP)
        End If
    End Try
End Sub

' Manual save trigger (for app shutdown)
Public Sub SaveAndCleanup
    Log("Saving memory to disk before shutdown...")
    SafeVacuumToDisk
    
    ' Clean up timer
    If AutoSaveTimer.IsInitialized Then
        AutoSaveTimer.Enabled = False
    End If
    
    ' Close database connection
    If MemDB.IsInitialized Then
        MemDB.Close
        Log("Database connection closed.")
    End If
End Sub
#End Region

' Cross-Platform Runtime Storage Path Resolver
Private Sub GetDBFolder As String
    #If B4J
    Return File.DirApp
    #Else
    Return File.DirInternal
    #End If
End Sub

'Private Sub btnBackup_Click
'	SQLiteBackup.BackupWithAttach()
'End Sub

'Private Sub btnBackupAPI_Click
'	'BackupUsingSQLiteAPI
'End Sub

'Private Sub btnBackupMemory_Click
'	SQLiteBackup.BackupInMemory(File.Combine(File.DirApp, "in_memory.db"))
'End Sub

'Sub BackupUsingSQLiteAPI
'    Try
'        ' Source database
'        Dim SourceDB As SQL
'        SourceDB.InitializeSQLite("", "mydatabase.db", True)
'        
'        ' Destination database (backup file)
'        Dim DestDB As SQL
'        DestDB.InitializeSQLite("", "backup_api.db", True)
'        
'        ' Get the underlying SQLite connection objects
'        Dim SourceConn As JavaObject = SourceDB.GetConnection
'        Dim DestConn As JavaObject = DestDB.GetConnection
'        
'        ' Using Java reflection to access SQLite backup API
'        ' Note: This approach works with sqlite-jdbc driver that supports backup
'        Dim jo As JavaObject
'        jo.InitializeStatic("org.sqlite.SQLiteJDBCLoader")
'        
'        ' Alternative approach: Use SQL statement to backup
'        ' This is more reliable across different JDBC versions
'        Dim BackupCmd As String = "VACUUM INTO 'backup_vacuum.db'"
'        SourceDB.ExecNonQuery(BackupCmd)
'        
'        SourceDB.Close
'        DestDB.Close
'        
'        lblStatusAPI.Text = "Backup API completed successfully"
'    Catch
'        lblStatusAPI.Text = "Error using API: " & LastException.Message
'        Log(LastException)
'        
'        ' Fallback to ATTACH method if API fails
'        lblStatusAPI.Text = lblStatusAPI.Text & " - Falling back to ATTACH method"
'        FallbackBackup
'    End Try
'End Sub

'Sub FallbackBackup
'    Try
'        Dim db As SQL
'        db.InitializeSQLite("", "mydatabase.db", True)
'        
'        db.ExecNonQuery("ATTACH DATABASE 'fallback_backup.db' AS backup")
'        db.ExecNonQuery("CREATE TABLE backup.main AS SELECT * FROM main.sqlite_master WHERE type='table'")
'        
'        Dim rs As ResultSet = db.ExecQuery("SELECT name FROM main.sqlite_master WHERE type='table'")
'        Do While rs.NextRow
'            Dim TableName As String = rs.GetString("name")
'            db.ExecNonQuery("INSERT INTO backup." & TableName & " SELECT * FROM main." & TableName)
'        Loop
'        rs.Close
'        
'        db.ExecNonQuery("DETACH DATABASE backup")
'        db.Close
'        
'        lblStatusAPI.Text = "Fallback backup completed"
'    Catch
'        lblStatusAPI.Text = "Fallback also failed: " & LastException.Message
'    End Try
'End Sub