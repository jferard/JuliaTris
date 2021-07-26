import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.0

Item {
    function start(gameType) {
        tetrisGame.start(gameType, level.value, height.value)
    }

    Column {
        id: column
        Component.onCompleted: {
            for (var item in children)
                children[item].anchors.horizontalCenter = column.horizontalCenter;
        }

        Row {
            Text {
                width: 8*TILE_SIZE; height: 4*TILE_SIZE
                font.pointSize: 20
                horizontalAlignment: Text.AlignRight
                text: "JuliaTris"
            }
        }

        Row {
            Button {
                width: 5*TILE_SIZE; height: 4*TILE_SIZE
                text: "Unlimited"
                onClicked: {
                    stack.push(tetrisGame)
                    start("unlimited")
                }
            }
            Button {
                width: 5*TILE_SIZE; height: 4*TILE_SIZE
                text: "25 lines"
                onClicked: {
                    stack.push(tetrisGame)
                    start("25")
                }
            }
            Button {
                width: 5*TILE_SIZE; height: 4*TILE_SIZE
                text: "Touch ground!"
                onClicked: {
                    stack.push(tetrisGame)
                    start("ground")
                }
            }
            Button {
                width: 5*TILE_SIZE; height: 4*TILE_SIZE
                text: "The cleaner"
                onClicked: {
                    stack.push(tetrisGame)
                    start("cleaner")
                }
            }
        }

        Row {
            id: rLevel

            width: 20*TILE_SIZE; height: 4*TILE_SIZE
            Component.onCompleted: {
                for (var item in children)
                    children[item].anchors.verticalCenter = rLevel.verticalCenter;
            }

            Text {
                width: 4*TILE_SIZE;
                font.pointSize: 16
                text: "Level"
            }

            Slider {
                id: level
                from : 0
                to : 19
                stepSize : 1
                // tickmarksEnabled : true
                value: 0
            }

            Text {
                width: 2*TILE_SIZE;
                font.pointSize: 16
                horizontalAlignment: Text.AlignRight
                text: level.value.toString()
            }
        }

        Row {
            width: 20*TILE_SIZE; height: 4*TILE_SIZE

            Text {
                width: 4*TILE_SIZE;
                font.pointSize: 16
                text: "Height"
            }

            Slider {
                id: height
                from : 0
                to : 14
                stepSize : 1
                // tickmarksEnabled : true
                value: 0
            }

            Text {
                width: 2*TILE_SIZE;
                font.pointSize: 16
                horizontalAlignment: Text.AlignRight
                text: height.value.toString()
            }
        }

        Row {
            width: 4*TILE_SIZE; height: 4*TILE_SIZE

            Button {
                width: 4*TILE_SIZE; height: 4*TILE_SIZE
                text: "Classic"
                onClicked: {
                    stack.push(tetrisGame)
                    tetrisGame.start("unlimited", level.value, 0)
                }
            }
        }
    }
}
