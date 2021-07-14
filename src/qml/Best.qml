import QtQuick 2.0

Text {
    width: 8*TILE_SIZE; height: 3*TILE_SIZE
    font.pointSize: 10
    text: "Best\nLines: "+best.linesCount +"\nScore: "+best.score
}

