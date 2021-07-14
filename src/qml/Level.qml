import QtQuick 2.0

Text {
    id: level
    width: 8*TILE_SIZE; height: 2*TILE_SIZE
    font.pointSize: 20
    horizontalAlignment: Text.AlignRight
    text: "Level\n"+game.level
}

