import QtQuick
import Qt.labs.folderlistmodel

FolderListModel {
    id: root

    property string path: ""
    readonly property var names: {
        var out = [];
        for (var i = 0; i < root.count; i++) out.push(root.get(i, "fileName"));
        return out;
    }

    folder: root.path ? "file://" + root.path : ""
    showDirs: true
    showFiles: true
    showHidden: true
    showDotAndDotDot: false
}
