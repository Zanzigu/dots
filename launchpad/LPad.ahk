#Requires AutoHotkey v2.0
#include "Midi2.ahk"

I_Icon := "./lpad.ico"
If FileExist(I_Icon)
	TraySetIcon(I_Icon)

; Launchpad S's key numbers:      |
;   0   1   2   3   4   5   6   7    8
;  16  17  18  19  20  21  22  23   24
;  32  33  34  35  36  37  38  39   40
;  48  49  50  51  52  53  54  55   56
;  64  65  66  67  68  69  70  71   72
;  80  81  82  83  84  85  86  87   88
;  96  97  98  99 100 101 102 103  104
; 112 113 114 115 116 117 118 119  120

global midi := AHKMidi()
midi.midiEventPassThrough := false
midi.midiLabelCallbacks := false
midi.specificProcessCallback := false
midi.settingFilePath := A_ScriptDir . "\setting.ini"

Class colors {
    static green := 124
    static lowGreen := 125
    static yellow := 62
    static amber := 63
    static orange := 47
    static dimOrange := 26
    static dimmerOrange := 25
    static red := 15
    static dimRed := 9
    static lowRed := 27
    static off := 12
}

global volumeSteps := [2, 4, 20, 30, 50, 80, 100]
global apps := [
    {
        exe: "chrome.exe",
        color: colors.amber,
        vol: 0
    },
    {
        exe: "discord.exe",
        color: colors.yellow,
        vol: 0
    },
    {
        exe: "spotify.exe",
        color: colors.lowGreen,
        vol: 0
    }
]

global micDevice := "Microphone (Trust GXT 232 Microphone)" 

; DISCORD:
micOn := False
audioOn := False

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
        midi.MidiOut "N1", 1, 72, colors.orange
        ; media next
        midi.MidiOut "CC", 1, 107, colors.amber
        ; media prev
        midi.MidiOut "CC", 1, 106, colors.amber

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
            midi.MidiOut "N1", 1, 120, colors.amber
        else
            midi.MidiOut "N1", 1, 120, colors.red
        ; audio
        if audioOn
            midi.MidiOut "N1", 1, 104, colors.orange
        else
            midi.MidiOut "N1", 1, 104, colors.red
    }
    ; discord mute mic
    MidiNoteOn120(event) {
        this.toggleDiscordMic()
    }
    ; discord mute audio
    MidiNoteOn104(event) {
        this.toggleDiscordAudio()
    }
    ; reset discord status
    MidiNoteOn88(event) {
        global micOn, audioOn
        midi.MidiOut "N1", 1, 88, colors.red
        micOn := true
        audioOn := true
        this.updateDiscordLed()
    }
    MidiNoteOff88(event) {
        midi.MidiOut "N0", 1, 88, colors.off
    }


    ; media play/pause
    MidiNoteOn72(event) {
        Send "{Media_Play_Pause}"
    }
    ; media next
    MidiControlChange107(event) {
        if event.Value == 127
            Send "{Media_Next}"
    }
    ; media prev
    MidiControlChange106(event) {
        if event.Value == 127
            Send "{Media_Prev}"
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

Class defaultDelegate extends baseDelegate
{
    __New() {
        allOff()
        this.setupBase()

        ; default mode -> User 1
        midi.MidiOut "CC", 1, 109, colors.yellow

        ; 1st row for volume
        vol := SoundGetVolume()
        loop 7 {
            if vol >= volumeSteps[A_Index]
                midi.MidiOut "N1", 1, A_Index, colors.yellow
        }
        midi.MidiOut "N1", 1, 0, colors.green
    }

    ; set mixer mode
    MidiControlChange111(event) {
        if event.Value == 127
            midi.delegate := mixerDelegate()
    }

    ; volume management
    MidiNoteOn(event) {
        ; 1st row
        if event.noteNumber == 0 {
            if SoundGetMute() {
                SoundSetMute 0
                midi.MidiOut "N1", 1, 0, colors.green
            }
            else {
                SoundSetMute 1
                midi.MidiOut "N1", 1, 0, colors.red
            }
        }
        else if event.noteNumber <= 7 {
            SoundSetVolume volumeSteps[event.noteNumber]
            loop 7 {
                if A_Index > event.noteNumber {
                    midi.MidiOut "N0", 1, A_Index, colors.off
                }
                else {
                    midi.MidiOut "N1", 1, A_Index, colors.yellow
                }
            }
        }

        ; as if this func wasn't executed:
        event.eventHandled := false
    }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mixer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Class mixerDelegate extends baseDelegate {
    __New() {
        allOff()
        this.setupBase()

        ; default mode -> User 1
        midi.MidiOut "CC", 1, 111, colors.yellow

        this.volumeLights()
    }

    volumeLights() {
        ; 1st column for general
        vol := SoundGetVolume()
        i := 0
        loop 7 {
            if vol >= volumeSteps[A_Index]
                midi.MidiOut "N1", 1, 96-i, colors.yellow
            i += 16
        }
        if vol == 0
            midi.MidiOut "N1", 1, 112, colors.red
        else
            midi.MidiOut "N1", 1, 112, colors.green

        ; other columns
        for app in apps {
            vol := RunWait('volume.ahk get ' app.exe)
            app.vol := vol
            if not vol < 0 {
                if vol == 0 {
                    ; muted
                    midi.MidiOut "N1", 1, 112+A_Index, colors.red
                }
                else {
                    col := A_Index
                    midi.MidiOut "N1", 1, 112+col, colors.green
                    ; color
                    loop 7 {
                        if vol >= volumeSteps[A_Index]
                            midi.MidiOut "N1", 1, (16*(7-A_Index))+col, app.color
                    }
                }
            }
        }
    }

    ; set default mode
    MidiControlChange109(event) {
        if event.Value == 127
            midi.delegate := defaultDelegate()
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
                    midi.MidiOut "N1", 1, 112, colors.green
                }
                else {
                    SoundSetMute 1
                    midi.MidiOut "N1", 1, 112, colors.red
                }
            }
            else {
                ; vol
                SoundSetVolume volumeSteps[button]
                loop 7 {
                    if A_Index > button
                        midi.MidiOut "N0", 1, A_Index, colors.off
                    else
                        midi.MidiOut "N1", 1, A_Index, colors.yellow
                }
            }
        }
        else {
            ; per app volume
            if button == 0 {
                vol := RunWait('volume.ahk get ' apps[col].exe)
                ; manage mute/unmute
                if vol == 0 {
                    vol := RunWait("volume.ahk set " apps[col].exe " " apps[col].vol)
                    midi.MidiOut "N1", 1, (112+col), colors.green
                }
                else {
                    vol := RunWait("volume.ahk set " apps[col].exe " 0")
                    midi.MidiOut "N1", 1, (112+col), colors.red
                }
            }
            else {
                ; manage level
                vol := RunWait("volume.ahk set " apps[col].exe " " volumeSteps[button])
                apps[col].vol := vol
                i := 0
                loop 7 {
                    if A_Index <= button
                        midi.MidiOut "N1", 1, (96+col)-i, apps[col].color
                    else
                        midi.MidiOut "N0", 1, (96+col)-i, colors.off
                        i += 16
                }
                midi.MidiOut "N1", 1, (112+col), colors.green
            }
        }
    }
}

;
midi.delegate := defaultDelegate()