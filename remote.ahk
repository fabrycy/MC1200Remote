#InstallKeybdHook

;Must be in auto-execute section if I want to use the constants
#Include AHKHID.ahk
#Include Console.ahk
#Include WinHttpRequest.ahk

;Create GUI to receive messages
Gui, +LastFound
hGui := WinExist()

;Intercept WM_INPUT messages
WM_INPUT := 0xFF
OnMessage(WM_INPUT, "InputMsg")

;Register Remote Control with RIDEV_INPUTSINK (so that data is received even in the background)
r := AHKHID_Register(65468, 136, hGui, RIDEV_INPUTSINK)

;Checking Recording Service Timer
checksCount := 0
SetTimer, CheckRecordingService, 60000

reloaded := 0

;Prefix loop
Loop {
    Sleep 1000
    If WinActive("ahk_exe dvbviewer.exe") 
        sPrefix := "DVB"
    Else If WinActive("ahk_class Kodi")
        sPrefix := "Kodi"
    Else 
        sPrefix := "Default"

    ; Process, Exist, Launcher4Kodi.exe
    ; LauncherPid := ErrorLevel
    ; if (LauncherPid > 0 and reloaded = 0)
    ; {
    ;     Suspend, On
    ;     Suspend, Off
    ;     reloaded++
    ; }
    ; else if (LauncherPid = 0 and reloaded != 0)
    ; {
    ;     reloaded := 0
    ; }
    ;StdOut(sPrefix)
}

Return

^+t::
    RunDVB()
    Return

#!Enter::
    RunKodi()
    Return

; AppsKey
#If, (sPrefix = "DVB")
AppsKey::
    SendInput ^+I
    Return

=:: ; Volume UP
    Denon_VolumeUp()
    Return

-:: ; Volume Down
    Denon_VolumeDown()
    Return

#If, (sPrefix = "Kodi")

=:: ; Volume UP
    Denon_VolumeUp()
    Return

-:: ; Volume Down
    Denon_VolumeDown()
    Return

#if
!=:: ; Volume UP
    Denon_VolumeUp()
    Return

!-:: ; Volume Down
    Denon_VolumeDown()
    Return

Return

InputMsg(wParam, lParam) {
    Local devh, iKey, sLabel

    Critical

    ;Get handle of device
    devh := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)

    ;Check for error
    If (devh <> -1) ;Check that it is my HP remote
    And (AHKHID_GetDevInfo(devh, DI_DEVTYPE, True) = RIM_TYPEHID)
    And (AHKHID_GetDevInfo(devh, DI_HID_VENDORID, True) = 7511)
    And (AHKHID_GetDevInfo(devh, DI_HID_PRODUCTID, True) = 44033)
    And (AHKHID_GetDevInfo(devh, DI_HID_VERSIONNUMBER, True) = 9050) {

        ;Get data
        iKey := AHKHID_GetInputData(lParam, uData)

        ;Check for error
        If (iKey <> -1) {

            ;Get keycode (located at the 6th byte)
            ;iKey := NumGet(uData, 5, "UChar")
            iKey := NumGet(uData, 0, "UInt")
            ;Call the appropriate sub if it exists
            sLabel := sPrefix "_" iKey
            ;StdOut(sLabel)
            If IsLabel(sLabel)
            Gosub, %sLabel%
        }
    }
}

RunKodi() {
    If WinExist("ahk_exe dvbviewer.exe")
        OSD("Zatrzymujê Telewizjê")  
        WinClose, ahk_exe dvbviewer.exe
        WinWaitClose,ahk_exe dvbviewer.exe,,5
        if ErrorLevel <> 0
            OSD("Wymuszam zatrzymanie Telewizji")
            Process, Close, dvbviewer.exe

    If !WinExist("ahk_exe kodi.exe")
        OSD("Uruchamiam Kodi")
        Run, c:\Program Files\Kodi\kodi.exe
        WinWait, ahk_exe kodi.exe,,10
}

RunDVB() {
    If WinExist("ahk_exe kodi.exe")
        OSD("Zatrzymujê Kodi")
        WinClose,ahk_exe kodi.exe
        WinWaitClose,ahk_exe kodi.exe,,5
        if ErrorLevel <> 0
            OSD("Wymuszam zatrzymanie Kodi")
            Process, Close, kodi.exe

    If !WinExist("ahk_exe dvbviewer.exe")
        OSD("Uruchamiam Telewizjê")
        Run, c:\Program Files (x86)\DVBViewer\dvbviewer.exe
        WinWait, ahk_exe dvbviewer.exe,,10
}

Denon_VolumeUp() {
    OSD("Zwiêkszam g³oœnoœæ")
    WinHttpRequest("http://192.168.1.100/MainZone/index.put.asp?cmd0=PutMasterVolumeBtn/>")
}

Denon_VolumeDown() {
    OSD("Zmniejszam g³oœnoœæ")
    WinHttpRequest("http://192.168.1.100/MainZone/index.put.asp?cmd0=PutMasterVolumeBtn/<")    
}

DVB_4100: ; Red button
SendInput {F5}
Return

DVB_1028: ; Green button
SendInput {F6}
Return

DVB_2052: ; Yellow button
SendInput {F7}
Return

DVB_516: ; Blue button
SendInput {F8}
Return

DVB_8196: ; DVR Button
SendInput ^+R
Return

Default_260: ; Start Kodi
DVB_260: 
Kodi_260:
    RunKodi()
    SendInput ^+S
Return

Kodi_4100:
    SendInput ^e
Return

Kodi_1028:
    SendInput ^m
Return

Kodi_2052:
    SendInput ^i
Return

Kodi_516:
    SendInput ^t
Return

Kodi_8196:
    SendInput ^o
Return

OSD(text)
{
	#Persistent
	; borderless, no progressbar, font size 25, color text 009900
	Progress, hide Y600 W1000 b zh0 cwFFFFFF FM50 WM800 CT00BB00,, %text%, AutoHotKeyProgressBar, Calibri
    DetectHiddenWindows, On
    WinSet, TransColor, FFFFFF 255, AutoHotKeyProgressBar
    DetectHiddenWindows, Off
	Progress, show
	SetTimer, RemoveToolTip, 3000

	Return


RemoveToolTip:
	SetTimer, RemoveToolTip, Off
	Progress, Off
	return
}

CheckRecordingService()
{
    global checksCount
    checksCount := checksCount + 1
 
    SetTimer,, 15000
    ;OSD("Checking Recording Service...: ")

    result := WinHttpRequest("http://192.168.1.55:8089/index.html")
    if (result == -1) {
        checksCount := 0
    } else {     
        if (checksCount > 4)
        {
            OSD("Restarting system. Recording Service is not responding.")
            Sleep, 2000
            Shutdown, 6
        }
    }
}
 