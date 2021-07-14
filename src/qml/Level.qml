import QtQuick 2.0

Text {
    function getLevel(lines) {
        return (lines < 200 ? Math.floor(lines / 10)+1 : 20).toString()
    }

    id: level
    width: 8*TILE_SIZE; height: 2*TILE_SIZE
    font.pointSize: 20
    horizontalAlignment: Text.AlignRight
    text: "Level\n"+getLevel(game.lines)
}

