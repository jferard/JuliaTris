import QtQuick 2.0
import QtQuick.Controls 2.5
import org.julialang 1.0

Item {
    width: 12*TILE_SIZE; height: 21*TILE_SIZE
    property alias text: informationLabel.text

    Label {
        id: informationLabel
        anchors.centerIn: parent

         background: Rectangle {
            anchors.centerIn: parent
            radius: 20
            color: "#1e1b18"
            width: parent.width * 1.1
            height: parent.height * 3

        }
        font.pointSize: 16
        color: "white"
        text: "Press space"
    }

    Label {
         id: escLabel

         background: Rectangle {
            anchors.centerIn: parent
            radius: 20
            color: "#1e1b18"
            width: parent.width * 1.1
            height: parent.height * 1.2

        }
        font.pointSize: 12
        color: "white"
        text: "Quit: press ESC"
    }
}
