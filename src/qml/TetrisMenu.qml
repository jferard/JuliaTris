import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

Item {
    Column {
        Row {
            Text {
                width: 8*TILE_SIZE; height: 4*TILE_SIZE
                font.pointSize: 20
                horizontalAlignment: Text.AlignRight
                text: "JuliaTris"
            }
        }

        Row {
            width: 20*TILE_SIZE; height: 20*TILE_SIZE

            Button {
                width: 4*TILE_SIZE; height: 4*TILE_SIZE
                text: "A"
                onClicked: {
                    stack.push(tetris_game)
                    tetris_game.start("A")
                }
            }
            Button {
                width: 4*TILE_SIZE; height: 4*TILE_SIZE
                text: "B"
                onClicked: {
                    stack.push(tetris_game)
                    tetris_game.start("B")
                }
            }
        }
    }
}
