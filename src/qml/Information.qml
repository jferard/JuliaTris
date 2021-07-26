import QtQuick 2.0
import org.julialang 1.0

Item {
    width: 12*TILE_SIZE; height: 21*TILE_SIZE

    Text {
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        font.pointSize: 16
        text: "Press space"
    }
}
