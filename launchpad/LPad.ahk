#Requires AutoHotkey v2.0
#include "Midi2.ahk"

I_Icon := "./lpad.ico"
If FileExist(I_Icon)
	TraySetIcon(I_Icon)

global midi := AHKMidi()
midi.midiEventPassThrough := false
midi.midiLabelCallbacks := false
midi.specificProcessCallback := false
midi.settingFilePath := A_ScriptDir . "\setting.ini"

Class colors {
    static green := 0x3c
    static lowGreen := 0x2c
    static dimGreen := 0x1c
    static greenish := 0x3d

    static yellow := 0x3e
    static lowYellow := 0x2d

    static amber := 0x3f
    static lowAmber := 0x2e
    static dimAmber := 0x1d

    static orange := 0x2f
    static lowOrange := 0x1e

    static reddish := 0x1f
    static red := 0x0f
    static lowRed := 0x0e
    static dimRed := 0x0d

    static off := 0x0c
    static sysColor := colors.lowYellow
    static muted := colors.lowRed
    static notMuted := colors.lowGreen
}

global volumeSteps := [1, 2, 30, 40, 50, 80, 100]
global apps := [
    {
        exe: "chrome.exe",
        color: colors.lowAmber,
        vol: 0
    },
    {
        exe: "Discord.exe",
        color: colors.lowYellow,
        vol: 0
    },
    {
        exe: "Spotify.exe",
        color: colors.dimGreen,
        vol: 0
    }
]

global micDevice := "Microphone (Trust GXT 232 Microphone)" 

; DISCORD:
micOn := true
audioOn := true

; right shift + F1 to reload
>+F1:: {
    midi := ""
    Reload
}

; spegne tutto
allOff() {
    i := 104
    loop 8 {
        midi.MidiOut "CC", 1, i, 12
        i += 1
    }
    i := 0
    loop 8 {
        loop 9 {
            midi.MidiOut("N0", 1, i, colors.off)
            i += 1
        }
        i += 7
    }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Base
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Class baseDelegate {
    setupBase() {
        global micOn, audioOn

        ; media play/pause
        midi.MidiOut "N1", 1, 120, colors.orange

        ; discord
        this.updateDiscordLed()

        ;microphone
        micMute := SoundGetMute(, micDevice)
        midi.MidiOut "N1", 1, 24, micMute?colors.red:colors.lowGreen
    }
    ; Discord
    toggleDiscordMic() {
        global micOn, audioOn
        Send "{F13}"
        if !audioOn {
            audioOn := true
            micOn := true
        }
        else
            micOn := !micOn
    
        this.updateDiscordLed()
    }
    toggleDiscordAudio() {
        global micOn, audioOn
        if !audioOn {
            ; if audio is disabled, reactivates using microphone button
            this.toggleDiscordMic()
            return
        }

        Send "{F14}"
        audioOn := !audioOn
        if !audioOn
            micOn := false
        this.updateDiscordLed()
    }
    updateDiscordLed() {
        global micOn, audioOn
        ; mic
        if micOn
            midi.MidiOut "N1", 1, 104, colors.amber
        else
            midi.MidiOut "N1", 1, 104, colors.red
        ; audio
        if audioOn
            midi.MidiOut "N1", 1, 88, colors.amber
        else
            midi.MidiOut "N1", 1, 88, colors.red
    }
    ; discord mute mic
    MidiNoteOn104(event) {
        this.toggleDiscordMic()
    }
    ; discord mute audio
    MidiNoteOn88(event) {
        this.toggleDiscordAudio()
    }
    ; reset discord status
    MidiNoteOn72(event) {
        global micOn, audioOn
        midi.MidiOut "N1", 1, 72, colors.red
        micOn := true
        audioOn := true
        this.updateDiscordLed()
    }
    MidiNoteOff72(event) {
        midi.MidiOut "N0", 1, 72, colors.off
    }

    ; media play/pause
    MidiNoteOn120(event) {
        Send "{Media_Play_Pause}"
    }

    ; micfophone
    toggleMicAudio() {
        current := SoundGetMute(, micDevice)
        SoundSetMute !current, , micDevice
        if current
            midi.MidiOut "N1", 1, 24, colors.lowGreen
        else
            midi.MidiOut "N1", 1, 24, colors.red
    }
    MidiNoteOn24(event) {
        this.toggleMicAudio()
    }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Default
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Class defaultDelegate extends baseDelegate {
    __New() {
        allOff()
        this.setupBase()

        this.volumeLights()

        ; media prev, next
        midi.MidiOut "N1", 1, 119, colors.amber
        midi.MidiOut "N1", 1, 118, colors.amber
    }

    ; media prev, media next
    MidiNoteOn119(event) {
        Send "{Media_Prev}"
    }
    MidiNoteOn118(event) {
        Send "{Media_Next}"
    }

    volumeLights() {
        ; 1st column for general
        vol := SoundGetVolume()
        i := 0
        loop 7 {
            if vol >= volumeSteps[A_Index]
                midi.MidiOut "N1", 1, 96-i, colors.sysColor
            i += 16
        }
        if vol == 0
            midi.MidiOut "N1", 1, 112, colors.muted
        else
            midi.MidiOut "N1", 1, 112, colors.notMuted

        ; other columns
        for app in apps {
            vol := RunWait('pythonw volume.py get ' app.exe)
            app.vol := vol
            if not vol < 0 {
                if vol == 0 {
                    ; muted
                    midi.MidiOut "N1", 1, 112+A_Index, colors.muted
                }
                else {
                    col := A_Index
                    midi.MidiOut "N1", 1, 112+col, colors.notMuted
                    ; color
                    loop 7 {
                        if vol >= volumeSteps[A_Index]
                            midi.MidiOut "N1", 1, (16*(7-A_Index))+col, app.color
                    }
                }
            }
        }
    }

    ; volume management
    MidiNoteOn(event) {
        ; check if pressed is target
        col := Mod(event.noteNumber, 16)
        if col > apps.Length {
            event.eventHandled := false
            return
        }

        ; volume management
        button := 7 - (event.noteNumber - col)/16
        if col == 0 {
            ; general volume
            vol := SoundGetVolume()
            if button == 0 {
                ; manage mute/unmute
                if SoundGetMute() {
                    SoundSetMute 0
                    midi.MidiOut "N1", 1, 112, colors.notMuted
                }
                else {
                    SoundSetMute 1
                    midi.MidiOut "N1", 1, 112, colors.muted
                }
            }
            else {
                ; vol
                SoundSetVolume volumeSteps[button]
                loop 7 {
                    if A_Index > button
                        midi.MidiOut "N0", 1, (16*(7-A_Index))+col, colors.off
                    else
                        midi.MidiOut "N1", 1, (16*(7-A_Index))+col, colors.sysColor
                }
            }
        }
        else {
            ; per app volume
            if button == 0 {
                vol := RunWait('pythonw volume.py get ' apps[col].exe)
                ; manage mute/unmute
                if vol == 0 {
                    vol := RunWait("pythonw volume.py set " apps[col].exe " " apps[col].vol)
                    midi.MidiOut "N1", 1, (112+col), colors.notMuted
                }
                else {
                    vol := RunWait("pythonw volume.py set " apps[col].exe " 0")
                    midi.MidiOut "N1", 1, (112+col), colors.muted
                }
            }
            else {
                ; manage level
                vol := RunWait("pythonw volume.py set " apps[col].exe " " volumeSteps[button])
                apps[col].vol := vol
                i := 0
                loop 7 {
                    if A_Index <= button
                        midi.MidiOut "N1", 1, (96+col)-i, apps[col].color
                    else
                        midi.MidiOut "N0", 1, (96+col)-i, colors.off
                        i += 16
                }
                midi.MidiOut "N1", 1, (112+col), colors.notMuted
            }
        }
    }
}

;
midi.delegate := defaultDelegate()