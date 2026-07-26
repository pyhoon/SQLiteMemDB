B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.5
@EndOfDesignText@
Sub Class_Globals
	Private db As SQL
End Sub

Public Sub Initialize
	'CreateTestDatabase
End Sub
    
'Private Sub CreateTestDatabase
'	db.InitializeSQLite("", "test.db", True)
'	db.ExecNonQuery("CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, data TEXT)")
'	db.ExecNonQuery("INSERT INTO test (data) VALUES ('Test1'), ('Test2'), ('Test3')")
'	db.Close
'End Sub

Public Sub CheckVacuumCompatibility As Boolean
    Dim version As String = db.ExecQuerySingleResult("SELECT sqlite_version()")
    Dim parts() As String = Regex.Split("\.", version)
    If parts.Length >= 2 Then
        Dim major As Int = parts(0)
        Dim minor As Int = parts(1)
        Return (major > 3) Or (major = 3 And minor >= 27)
    End If
    Return False
End Sub

' Method 1: ATTACH DATABASE (Simple)
Public Sub BackupWithAttach (SourceFile As String, DestFile As String) As Boolean
	Try
		Dim source As SQL
		source.InitializeSQLite("", SourceFile, True)
            
		source.ExecNonQuery("ATTACH DATABASE '" & DestFile & "' AS dest")
            
		' Copy schema
		Dim rs As ResultSet = source.ExecQuery("SELECT sql FROM main.sqlite_master WHERE type='table'")
		Do While rs.NextRow
			Dim CreateSQL As String = rs.GetString("sql")
			If CreateSQL <> "" Then
				' Modify table name if needed
				source.ExecNonQuery(CreateSQL.Replace("main.", "dest."))
			End If
		Loop
		rs.Close
            
		' Copy data
		rs = source.ExecQuery("SELECT name FROM main.sqlite_master WHERE type='table'")
		Do While rs.NextRow
			Dim TableName As String = rs.GetString("name")
			source.ExecNonQuery("INSERT INTO dest." & TableName & " SELECT * FROM main." & TableName)
		Loop
		rs.Close
            
		source.ExecNonQuery("DETACH DATABASE dest")
		source.Close
            
		Return True
	Catch
		Log("Attach backup failed: " & LastException.Message)
		Return False
	End Try
End Sub
    
' Method 2: VACUUM INTO (SQLite 3.27+)
Public Sub BackupWithVacuum (SourceFile As String, DestFile As String) As Boolean
	Try
		Dim source As SQL
		source.InitializeSQLite("", SourceFile, True)
		source.ExecNonQuery("VACUUM INTO '" & DestFile & "'")
		source.Close
		Return True
	Catch
		Log("VACUUM INTO failed: " & LastException.Message)
		Return False
	End Try
End Sub
    
' Method 3: Manual copy with SELECT INTO
Public Sub BackupManual (SourceFile As String, DestFile As String) As Boolean
	Try
		Dim source As SQL
		source.InitializeSQLite("", SourceFile, True)
            
		' Create empty destination
		Dim dest As SQL
		dest.InitializeSQLite("", DestFile, True)
            
		' Get all tables from source
		Dim rs As ResultSet = source.ExecQuery("SELECT name, sql FROM main.sqlite_master WHERE type='table'")
		Do While rs.NextRow
			Dim TableName As String = rs.GetString("name")
			Dim CreateSQL As String = rs.GetString("sql")
                
			' Create table in destination
			dest.ExecNonQuery(CreateSQL)
                
			' Copy data
			Dim DataRS As ResultSet = source.ExecQuery("SELECT * FROM " & TableName)
			Dim ColCount As Int = DataRS.ColumnCount
                
			' Build INSERT statement
			Dim Columns As List
			Columns.Initialize
			For i = 0 To ColCount - 1
				Columns.Add(DataRS.GetColumnName(i + 1))
			Next
                
			Dim InsertSQL As String = $"INSERT INTO ${TableName} (data) VALUES (?)"$
			Do While DataRS.NextRow
				Dim Values As List
				Values.Initialize
				For i = 0 To ColCount - 1
					Values.Add(DataRS.GetString2(i + 1))
				Next
				dest.ExecNonQuery2(InsertSQL, Values)
			Loop
			DataRS.Close
		Loop
		rs.Close
            
		source.Close
		dest.Close
            
		Return True
	Catch
		Log("Manual backup failed: " & LastException.Message)
		Return False
	End Try
End Sub
    
'Private Sub JoinStrings(List As List, Separator As String) As String
'	Dim sb As StringBuilder
'	sb.Initialize
'	For i = 0 To List.Size - 1
'		If i > 0 Then sb.Append(Separator)
'		sb.Append(List.Get(i))
'	Next
'	Return sb.ToString
'End Sub
    
' Backup in-memory database
'Public Sub BackupInMemory (DestFile As String) As Boolean
'	Try
'		Dim mem As SQL
'		mem.InitializeSQLite("", ":memory:", True)
'            
'		' Create some data in memory
'		mem.ExecNonQuery("CREATE TABLE temp (id INTEGER PRIMARY KEY, value TEXT)")
'		mem.ExecNonQuery("INSERT INTO temp (value) VALUES ('Memory1'), ('Memory2'), ('Memory3')")
'            
'		' Backup to file using VACUUM INTO
'		mem.ExecNonQuery("VACUUM INTO '" & DestFile & "'")
'		mem.Close
'            
'		Return True
'	Catch
'		Log("In-memory backup failed: " & LastException.Message)
'		Return False
'	End Try
'End Sub