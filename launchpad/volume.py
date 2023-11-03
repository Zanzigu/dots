from pycaw.pycaw import AudioUtilities, ISimpleAudioVolume
import sys
import time

def getVolume(exe):
    sessions = AudioUtilities.GetAllSessions()
    for session in sessions:
        volume = session._ctl.QueryInterface(ISimpleAudioVolume)
        if session.Process and session.Process.name() == exe:
            return round(volume.GetMasterVolume()*100)

def setVolume(exe, vol):
    sessions = AudioUtilities.GetAllSessions()
    for session in sessions:
        volume = session._ctl.QueryInterface(ISimpleAudioVolume)
        if session.Process and session.Process.name() == exe:
            volume.SetMasterVolume(vol/100, None)

def graduallySetVolume(exe, vol):
    current = getVolume(exe)
    deltaVol = int(abs(vol-current))
    tmp = current
    for x in range(deltaVol):
        tmp = tmp + ((vol-current)/deltaVol)
        setVolume(exe, tmp)

if len(sys.argv) < 3:
    sys.exit(-1)
else:
    match sys.argv[1]:
        case "get":
            sys.exit(getVolume(sys.argv[2]))
            
        case "set":
            sys.exit(graduallySetVolume(sys.argv[2], float(sys.argv[3])))

        case _:
            sys.exit(-2)