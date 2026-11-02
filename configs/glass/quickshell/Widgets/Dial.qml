import QtQuick
import QtQuick.Shapes
import "../Common"

Item {
    id: root

    property var rings: []  // [{ value: 0-100, color, burning }], outermost first

    property real core:      3.2    // the hole left in the middle
    property real thickness: 2.0
    property real gap:       1.3
    property real maxSize:   23
    property real outer:     0      // fixed size, 0 sizes to the rings

    // Open at the bottom, from 7:30 clockwise to 4:30
    property real startAngle: 135
    property real travel:     270

    property real fire: 0  // flame height, 0 for none

    readonly property int  count: rings.length
    readonly property real step:  thickness + gap
    readonly property real ideal: 2 * (core + count * step)
    readonly property real size:  outer > 0 ? outer : Math.min(ideal, maxSize)
    // Shrinks the rings once they would outgrow maxSize
    readonly property real squeeze: outer > 0 || ideal <= maxSize ? 1 : maxSize / ideal

    implicitWidth:  size
    implicitHeight: size

    Repeater {
        model: root.rings

        delegate: Shape {
            id: ring

            required property var modelData
            required property int index

            anchors.fill: parent
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer

            readonly property real mid:   root.size / 2
            readonly property real width_: root.thickness * root.squeeze
            readonly property real radius: root.size / 2 - width_ / 2
                                         - index * root.step * root.squeeze

            readonly property real sweep:
                root.travel * Math.max(0, Math.min(100, modelData.value)) / 100

            // Background track
            ShapePath {
                strokeColor: Qt.rgba(1, 1, 1, 0.12)
                strokeWidth: ring.width_
                fillColor:   "transparent"
                capStyle:    ShapePath.RoundCap
                PathAngleArc {
                    centerX: ring.mid; centerY: ring.mid
                    radiusX: ring.radius; radiusY: ring.radius
                    startAngle: root.startAngle; sweepAngle: root.travel
                }
            }

            ShapePath {
                strokeColor: ring.modelData.color
                strokeWidth: ring.width_
                fillColor:   "transparent"
                capStyle:    ShapePath.RoundCap
                PathAngleArc {
                    centerX: ring.mid; centerY: ring.mid
                    radiusX: ring.radius; radiusY: ring.radius
                    startAngle: root.startAngle
                    sweepAngle: ring.sweep
                    Behavior on sweepAngle {
                        NumberAnimation { duration: 460; easing.type: Easing.OutCubic }
                    }
                }
            }

            ArcFire {
                anchors.fill: parent
                centreX: ring.mid; centreY: ring.mid
                radius:    ring.radius
                thickness: ring.width_
                startAngle: root.startAngle
                sweepAngle: ring.sweep
                base:      ring.modelData.color
                amplitude: root.fire
                burning:   root.fire > 0 && ring.modelData.burning === true
            }
        }
    }
}
