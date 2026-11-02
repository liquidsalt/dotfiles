import QtQuick
import QtQuick.Shapes
import "../Common"

Item {
    id: root

    property real centreX:    0
    property real centreY:    0
    property real radius:     0     // the arc's centre line
    property real thickness:  2     // the arc's own stroke width
    property real startAngle: 135
    property real sweepAngle: 0     // the lit length, not the full travel

    property color base:      Glass.fire
    property real  amplitude: 4     // the tallest tongue

    property real density:  1.3   // tongues per unit of radius
    property real cusp:     0.50  // below 1 for a pointed apex
    property real flank:    0.60  // below 1 for flanks that leave the line steeply
    property real bed:      0.12  // the sheath that runs the whole lit length
    property real skew:     0.70  // lean
    property real floorFrac: 0.42 // the shortest tongue, against the tallest
    property real gamma:    2.4   // how rare a tall head is
    property real crown:    0.52  // how much shorter the ends are than the middle
    property real crownP:   1.4   // how quickly it falls away toward them
    property real spread:   0.9   // how much tongue widths vary
    property real jitter:   0.45  // how far a tongue sits off its nominal place
    property real bend:     0.85  // how hard tips are pulled upright
    property real lick:     3.0   // how far a tip drifts along the arc
    property int  samples:  8     // polyline points per tongue

    readonly property int tongues: Math.max(3, Math.round(radius * density))

    property bool burning: false

    opacity: burning ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 280 } }

    property real phase: 0

    // Cheap repeatable noise, one value per tongue
    function hash(n) {
        var x = Math.sin(n * 127.1 + 311.7) * 43758.5453;
        return x - Math.floor(x);
    }

    readonly property real root_: radius + thickness * 0.5

    function firePath() {
        if (root.sweepAngle <= 0 || root.amplitude <= 0) return "";

        var cx = root.centreX, cy = root.centreY;
        var r0 = root.root_;
        var K = Math.max(2, root.tongues);
        var N = K * root.samples;
        var rad = Math.PI / 180;

        var cen = [], halfw = [], tall = [], drift = [];
        var baseW = 1 / K;
        for (var i = 0; i < K; i++) {
            var f1 = 0.55 + 1.25 * root.hash(i);
            var f2 = 0.55 + 1.25 * root.hash(i + 97);
            var f3 = 0.55 + 1.25 * root.hash(i + 211);
            var o1 = 6.2832 * root.hash(i + 331);
            var o2 = 6.2832 * root.hash(i + 457);
            var o3 = 6.2832 * root.hash(i + 613);

            var w1 = Math.sin(root.phase * f1 + o1);
            var w2 = Math.sin(root.phase * f2 + o2);
            var w3 = Math.sin(root.phase * f3 + o3);

            var c0 = (i + 0.5) / K;
            cen.push(c0 + baseW * root.jitter * w2);
            halfw.push(baseW * (0.55 + root.spread * (0.5 + 0.5 * w3)));

            var crownF = 1 - root.crown * Math.pow(Math.abs(2 * c0 - 1), root.crownP);

            tall.push(root.amplitude * crownF * (root.floorFrac + (1 - root.floorFrac)
                      * Math.pow(0.5 + 0.5 * w1, root.gamma)));
            drift.push(root.lick * w2);
        }

        var out = [], back = [];
        for (var j = 0; j <= N; j++) {
            var s = j / N;

            var h = root.bed * root.amplitude;
            var lean = 0;
            for (i = 0; i < K; i++) {
                var d = (s - cen[i]) / halfw[i];
                if (d <= -1 || d >= 1) continue;
                var t = Math.abs(Math.pow((d + 1) * 0.5, root.skew) * 2 - 1);
                var hh = tall[i] * Math.pow(1 - Math.pow(t, root.cusp), root.flank);
                // The tallest tongue at this point wins
                if (hh > h) { h = hh; lean = drift[i]; }
            }

            var a  = (root.startAngle + root.sweepAngle * s
                      + lean * (h / root.amplitude)) * rad;
            var ab = (root.startAngle + root.sweepAngle * s) * rad;
            var rr = r0 + h;

            out.push([cx + rr * Math.cos(a), cy + rr * Math.sin(a) - root.bend * h]);
            back.push([cx + r0 * Math.cos(ab), cy + r0 * Math.sin(ab)]);
        }

        var p = "M " + out[0][0].toFixed(2) + " " + out[0][1].toFixed(2);
        for (j = 1; j <= N; j++) p += " L " + out[j][0].toFixed(2) + " " + out[j][1].toFixed(2);
        for (j = N; j >= 0; j--) p += " L " + back[j][0].toFixed(2) + " " + back[j][1].toFixed(2);
        return p + " Z";
    }

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.centreX; centerY: root.centreY
                centerRadius: root.root_ + root.amplitude
                focalX: root.centreX; focalY: root.centreY
                // Positions are fractions of centerRadius
                GradientStop {
                    position: root.root_ / (root.root_ + root.amplitude)
                    color: root.base
                }
                GradientStop {
                    position: root.root_ / (root.root_ + root.amplitude) * 0.30 + 0.52
                    color: "#FF9B2A"
                }
                GradientStop { position: 0.88; color: "#FFFFD166" }
                GradientStop { position: 1.00; color: "#00FFE7B0" }
            }
            PathSvg { path: root.firePath() }
        }
    }

    NumberAnimation on phase {
        from: 0; to: 2 * Math.PI
        duration: 2600
        loops: Animation.Infinite
        running: root.burning  // a hidden fire would still rebuild the path every frame
    }
}
