pragma Singleton
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import "../Common"

// Talks to power-profiles-daemon over D-Bus
Singleton {
    id: root

    readonly property var profiles: [
        { id: PowerProfile.PowerSaver,  label: "Eco"         },
        { id: PowerProfile.Balanced,    label: "Balanced"    },
        { id: PowerProfile.Performance, label: "Performance" }
    ].filter(p => p.id !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

    readonly property int current: PowerProfiles.profile

    readonly property color tint:
          root.current === PowerProfile.PowerSaver  ? Glass.cool
        : root.current === PowerProfile.Performance ? Glass.fire
        :                                             Glass.warm

    function set(profile) { PowerProfiles.profile = profile; }
}
