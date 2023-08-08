DetectHiddenWindows True


SoundPIDs() {
    PIDs := []

    IMMDeviceEnumerator := ComObjValue(ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}"))

    DllCall(NumGet(NumGet(IMMDeviceEnumerator, "uptr") + 4 * A_PtrSize, "uptr"), "UPtr", IMMDeviceEnumerator, "UInt", 0, "UInt", 1, "UPtrP", &IMMDevice := 0, "UInt")

    GUID := buffer(16)
    DllCall("Ole32.dll\CLSIDFromString", "Str", "{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}", "UPtr", GUID)
    DllCall(NumGet(NumGet(IMMDevice, "uptr") + 3 * A_PtrSize, "uptr"), "UPtr", IMMDevice, "UPtr", GUID, "UInt", 23, "UPtr", 0, "UPtrP", &IAudioSessionManager2 := 0, "UInt")

    ObjRelease(IMMDevice)

    DllCall(NumGet(NumGet(IAudioSessionManager2, "uptr") + 5 * A_PtrSize, "uptr"), "UPtr", IAudioSessionManager2, "UPtrP", &IAudioSessionEnumerator := 0, "UInt")

    ObjRelease(IAudioSessionManager2)

    DllCall(NumGet(NumGet(IAudioSessionEnumerator, "uptr") + 3 * A_PtrSize, "uptr"), "UPtr", IAudioSessionEnumerator, "UIntP", &SessionCount := 0, "UInt")
    Loop SessionCount
    {
        DllCall(NumGet(NumGet(IAudioSessionEnumerator, "uptr") + 4 * A_PtrSize, "uptr"), "UPtr", IAudioSessionEnumerator, "Int", A_Index - 1, "UPtrP", &IAudioSessionControl := 0, "UInt")
        IAudioSessionControl2 := ComObjValue(ComObjQuery(IAudioSessionControl, "{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}"))
        ObjRelease(IAudioSessionControl)

        DllCall(NumGet(NumGet(IAudioSessionControl2, "uptr") + 14 * A_PtrSize, "uptr"), "UPtr", IAudioSessionControl2, "UIntP", &PID := 0, "UInt")

        ISimpleAudioVolume := ComObjValue(ComObjQuery(IAudioSessionControl2, "{87CE5498-68D6-44E5-9215-6DA47EF883D8}"))

        DllCall(NumGet(NumGet(ISimpleAudioVolume, "uptr") + 4 * A_PtrSize, "uptr"), "UPtr", ISimpleAudioVolume, "FloatP", &Volume := 0, "UInt")
        if PID
        PIDs.push([PID, WinGetProcessPath("ahk_pid" PID), Volume])
        ObjRelease(IAudioSessionControl2)
    }
    ObjRelease(IAudioSessionEnumerator)
    ObjRelease(IMMDeviceEnumerator)

    return PIDs
}

msgbox SoundPIDs()