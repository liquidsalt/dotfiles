pragma Singleton
import QtQuick

QtObject {
    id: root
    property Item owner: null

    function toggle(item) { root.owner = root.owner === item ? null : item; }
    function close()      { root.owner = null; }
}
