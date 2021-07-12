import QtQuick 2.0

Text {
    id: score
    width: 8*TILE_SIZE; height: 1*TILE_SIZE
    font.pointSize: 20
    horizontalAlignment: Text.AlignRight
    text: "Score\n" + game.score
}

