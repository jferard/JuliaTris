import QtQuick 2.0
import QtQuick.Controls 2.5
import org.julialang 1.0

Item {
    width: 12*TILE_SIZE; height: 21*TILE_SIZE

    Label {
        anchors.centerIn: parent

         background: Rectangle {
            anchors.centerIn: parent
            radius: 20
            color: "black"
            width: parent.width * 1.1
            height: parent.height * 3

        }
        font.pointSize: 16
        color: "white"
        text: "Press space"
    }
}
