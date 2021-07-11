import QtQuick 2.0

Text {
    id: lines
    width: 8*TILE_SIZE; height: 2*TILE_SIZE
    horizontalAlignment: Text.AlignRight

    font.pointSize: 24
    text: "Lines\n" + game.lines
}
