' Fresh Mart Launcher — invisible window, finds Godot or installs it, launches game
' This script is the entry point for the desktop shortcut

Option Explicit

Dim oShell, oFSO, oWshEnv
Dim godotPath, appDir, scriptDir
Dim wingetPath, wingetPkg, localApp

Set oShell = CreateObject("WScript.Shell")
Set oFSO = CreateObject("Scripting.FileSystemObject")

' Get the directory where this script lives (the install directory)
scriptDir = oFSO.GetParentFolderName(WScript.ScriptFullName)
appDir = scriptDir

' ---- Find Godot ----
godotPath = FindGodot()

If godotPath = "" Then
    ' Try to install via winget
    Dim choice
    choice = MsgBox("Godot 4 (required to run Fresh Mart) was not found on this computer." & vbCrLf & vbCrLf & _
                    "Would you like to install it automatically? (uses Windows Package Manager)" & vbCrLf & vbCrLf & _
                    "Click YES to install automatically, NO to open the Godot download page.", _
                    vbYesNo + vbQuestion, "Fresh Mart — Godot 4 Required")
    
    If choice = vbYes Then
        ' Install Godot via winget
        Dim installMsg
        installMsg = "Installing Godot 4... This may take a minute." & vbCrLf & "The game will launch automatically when done."
        MsgBox installMsg, vbInformation + vbOKOnly, "Installing Godot 4"
        
        oShell.Run "cmd /c winget install GodotEngine.GodotEngine --silent --accept-package-agreements --accept-source-agreements", 0, True
        
        ' Try finding Godot again
        godotPath = FindGodot()
        
        If godotPath = "" Then
            MsgBox "Godot 4 installation could not be completed automatically." & vbCrLf & _
                   "Please install it manually from: https://godotengine.org/download/windows/" & vbCrLf & _
                   "Then run Fresh Mart again.", vbExclamation, "Fresh Mart"
            oShell.Run "https://godotengine.org/download/windows/"
            WScript.Quit
        End If
    Else
        oShell.Run "https://godotengine.org/download/windows/"
        WScript.Quit
    End If
End If

' ---- Launch Fresh Mart ----
Dim cmd
cmd = """" & godotPath & """ --path """ & appDir & """"
oShell.Run cmd, 1, False
WScript.Quit

' ---- Helper: Find Godot ----
Function FindGodot()
    FindGodot = ""
    Dim paths(10), i
    Dim localAppData
    localAppData = oShell.ExpandEnvironmentStrings("%LOCALAPPDATA%")
    
    ' WinGet symlink (most common)
    paths(0) = localAppData & "\Microsoft\WinGet\Links\godot.exe"
    ' WinGet package folder pattern
    paths(1) = localAppData & "\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.3-stable_win64\Godot_v4.3-stable_win64.exe"
    paths(2) = localAppData & "\Microsoft\WinGet\Packages\GodotEngine.GodotEngine.Mono_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe"
    ' Program Files
    paths(3) = "C:\Program Files\Godot\Godot_v4.3-stable_win64.exe"
    paths(4) = "C:\Program Files\Godot Engine\Godot_v4.3-stable_win64.exe"
    ' User desktop / downloads
    paths(5) = oShell.ExpandEnvironmentStrings("%USERPROFILE%") & "\Desktop\Godot_v4.3-stable_win64.exe"
    paths(6) = oShell.ExpandEnvironmentStrings("%USERPROFILE%") & "\Downloads\Godot_v4.3-stable_win64.exe"
    paths(7) = ""
    paths(8) = ""
    paths(9) = ""
    paths(10) = ""
    
    For i = 0 To 10
        If paths(i) <> "" Then
            If oFSO.FileExists(paths(i)) Then
                FindGodot = paths(i)
                Exit Function
            End If
        End If
    Next
    
    ' Try searching WinGet packages folder for any godot exe
    Dim pkgRoot
    pkgRoot = localAppData & "\Microsoft\WinGet\Packages"
    If oFSO.FolderExists(pkgRoot) Then
        Dim subFolder
        For Each subFolder In oFSO.GetFolder(pkgRoot).SubFolders
            If InStr(LCase(subFolder.Name), "godot") > 0 Then
                Dim subSubFolder
                For Each subSubFolder In subFolder.SubFolders
                    Dim fileObj
                    For Each fileObj In subSubFolder.Files
                        If InStr(LCase(fileObj.Name), "godot") > 0 And Right(LCase(fileObj.Name), 4) = ".exe" Then
                            If InStr(LCase(fileObj.Name), "unin") = 0 Then
                                FindGodot = fileObj.Path
                                Exit Function
                            End If
                        End If
                    Next
                Next
            End If
        Next
    End If
End Function
