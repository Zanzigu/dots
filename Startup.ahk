#Requires AutoHotkey v2.0-beta
#SingleInstance force

SetNumLockState(false)

; Icona di windows blu
I_Icon := "./startup.ico"
If FileExist(A_ScriptDir I_Icon)
	TraySetIcon(A_ScriptDir I_Icon)

return

;INS == F24
Ins::F24

; doppio click su MEDIA_pause per MEDIA_next-track
~Media_Play_Pause:: {
    If (A_ThisHotkey = A_PriorHotkey and A_TimeSincePriorHotkey < 200)
        Send "{Media_Next}"
}

; fix double middle click problem
$*Mbutton:: {
	if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 150 )
		return

	Send "{MButton}"
}

#b:: {
	run "ms-settings:nightlight"
}

; == == == == ==
; ==  NUMPAD  ==
; == == == == == 

NumpadIns:: {
	if (WinActive("Rainbow Six"))
		Send "!{Tab}"
		; Send "^{Esc}"
	else if (WinExist("Rainbow Six"))
		WinActivate
	else
		run "uplay://launch/635/1"
}

NumpadDel:: {
    if WinExist("ahk_exe sndvol.exe")
        WinActivate
    else {
        Run "sndvol",,, &sndvolPid
        WinWait "ahk_pid " sndvolPid, , 3
        winmove 440, 680, 1050, , "ahk_pid " sndvolPid
    }
}

NumpadSub::Reload