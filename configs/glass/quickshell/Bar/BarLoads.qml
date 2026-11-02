import Quickshell
import QtQuick
import "../Services"
import "../Common"
import "../Widgets"

Row {
    id: root
    spacing: 8

    readonly property string gpuGlyph: String.fromCodePoint(0xF08AE)

    function gib(n) { return n.toFixed(1); }

    function ring(load, temp, limit) {
        return { value: load, color: Glass.heat(temp, limit), burning: Glass.overheating(temp, limit) };
    }

    function heatLine(temp, limit) {
        if (temp <= 0) return "";
        return temp + " °C" + (limit > 0 ? " of " + limit + " °C" : "");
    }

    function gpuDetail(g) {
        if (!g.awake) return ["Asleep"];
        var out = [];
        if (g.temp > 0)     out.push(root.heatLine(g.temp, g.limit) + (g.integrated ? ", shared with the CPU" : ""));
        if (g.memTotal > 0) out.push("VRAM  " + root.gib(g.memUsed / 1024) + " / " + root.gib(g.memTotal / 1024) + " GiB");
        out.push(g.clock + (g.maxClock > 0 ? " / " + g.maxClock : "") + " MHz");
        return out;
    }

    Item {
        id: gpu
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth:  gpuDial.implicitWidth
        implicitHeight: gpuDial.implicitHeight

        BarDial {
            id: gpuDial
            glyph:     root.gpuGlyph
            glyphFont: Glass.fontGlyph
            glyphSize: 14
            rings:     Gpus.list.map(g => root.ring(g.load, g.temp, g.limit))
        }

        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    PopupState.toggle(gpu)
        }

        BarPopup {
            owner: gpu
            title: "Graphics"

            Repeater {
                model: Gpus.list
                delegate: PopupGauge {
                    required property var modelData
                    width: parent.width
                    glyph:     root.gpuGlyph
                    glyphFont: Glass.fontGlyph
                    glyphSize: 15
                    title:  modelData.name
                    value:  modelData.load
                    tint:   Glass.heat(modelData.temp, modelData.limit)
                    detail: root.gpuDetail(modelData)
                }
            }
        }
    }

    Item {
        id: cpu
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth:  cpuDial.implicitWidth
        implicitHeight: cpuDial.implicitHeight

        BarDial {
            id: cpuDial
            glyph: ""  // memory
            rings: [root.ring(SystemStats.cpuPercent, SystemStats.cpuTemp, SystemStats.cpuTempMax)]
        }

        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    PopupState.toggle(cpu)
        }

        BarPopup {
            owner: cpu
            title: "Processor"

            PopupGauge {
                width: parent.width
                glyph:  ""  // memory
                title:  SystemStats.cpuModel
                value:  SystemStats.cpuPercent
                tint:   Glass.heat(SystemStats.cpuTemp, SystemStats.cpuTempMax)
                detail: [
                    root.heatLine(SystemStats.cpuTemp, SystemStats.cpuTempMax),
                    "Load average  " + SystemStats.loadAvg,
                    SystemStats.cpuThreads + " threads"
                ]
            }
        }
    }

    Item {
        id: mem
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth:  memDial.implicitWidth
        implicitHeight: memDial.implicitHeight

        BarDial {
            id: memDial
            glyph: ""  // memory_alt
            rings: [{ value: SystemStats.memPercent, color: Glass.accent }]
        }

        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    PopupState.toggle(mem)
        }

        BarPopup {
            owner: mem
            title: "Memory"

            PopupGauge {
                width: parent.width
                glyph:  ""  // memory_alt
                title:  "RAM"
                value:  SystemStats.memPercent
                tint:   Glass.accent
                detail: [
                    root.gib(SystemStats.memUsedGiB) + " / " + root.gib(SystemStats.memTotalGiB) + " GiB in use",
                    root.gib(SystemStats.memAvailGiB) + " GiB available   ·   " + root.gib(SystemStats.memCacheGiB) + " GiB cache"
                ]
            }

            PopupGauge {
                width: parent.width
                visible: SystemStats.swapTotalGiB > 0
                glyph:  ""  // memory_alt
                title:  "Swap"
                value:  SystemStats.swapTotalGiB > 0 ? Math.round(SystemStats.swapUsedGiB / SystemStats.swapTotalGiB * 100) : 0
                tint:   Glass.accent
                detail: [root.gib(SystemStats.swapUsedGiB) + " / " + root.gib(SystemStats.swapTotalGiB) + " GiB"]
            }
        }
    }
}
