import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.0
import "."

ColumnLayout {
    signal update()

    onUpdate: {
        nextCanvas.requestPaint()
    }

    Text {
        id: next
        width: 8*TILE_SIZE; height: 1*TILE_SIZE
        verticalAlignment : Text.AlignBottom
        horizontalAlignment: Text.AlignRight
        font.pointSize: 20
        text: "Next"
    }

    Canvas {
        width: 8*TILE_SIZE; height: 2*TILE_SIZE
        id: nextCanvas

        onPaint: {
            var ctx = nextCanvas.getContext('2d');
            var rows = game.next
            if (rows.length == 0) {
                return;
            }
            drawSquares(ctx, 0, 0, rows, Global.nextRows)
            Global.nextRows = copyRows(rows)
        }
    }
}
